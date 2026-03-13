import Speech
import AVFoundation
import Foundation

class SpeechManager {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - キーワードリスト（ひらがな・カタカナ・漢字 全形式対応）

    let mildWords: [String] = [
        // うざい系
        "うざい", "うざ", "ウザい", "ウザ",
        // むかつく系
        "むかつく", "ムカつく", "むかつき", "ムカムカ",
        // バカ系
        "バカ", "ばか", "馬鹿", "バカか", "ばかか",
        // アホ系
        "あほ", "アホ", "アホか", "あほか",
        // やばい系
        "やばい", "ヤバい", "やば", "ヤバ", "ヤバすぎ",
        // だるい系
        "だるい", "ダルい", "だりぃ", "ダリぃ", "だる",
        // きもい系
        "きもい", "キモい", "きもっ", "キモっ", "キモ",
        // ひどい系
        "ひどい", "酷い",
        // 下手系
        "下手", "へた", "ヘタ", "下手くそ", "へたくそ",
        // 雑魚系
        "雑魚", "ざこ", "ザコ",
        // ゴミ系
        "ゴミ", "ごみ",
        // ゲーム専用
        "ラグい", "ラグ", "バグ", "エラー",
        // 終了・諦め
        "終わった", "終わり", "終わってる", "オワ", "終わる",
        // 不満の感嘆
        "なんで", "なんなの", "なんだよ", "は？", "はあ？",
        "えっ", "うそ", "ウソ", "嘘",
    ]

    let severeWords: [String] = [
        // くそ系（最頻出）
        "くそ", "クソ", "糞", "くそっ", "クソっ", "くそー", "クソー",
        "クソゲー", "くそげー",
        // 死ね系
        "死ね", "しね", "死んで", "死ねよ", "しねよ",
        // ふざけんな系
        "ふざけんな", "ふざけるな", "ふざけんじゃない", "ふざけんじゃねえ",
        "ふざけんな", "フザけんな",
        // 殺す系
        "殺す", "殺すぞ", "ぶっ殺す", "ぶち殺す",
        // 消えろ系
        "消えろ", "失せろ", "うせろ",
        // 最悪・最低系
        "最悪", "最低", "さいあく", "さいてい",
        // ありえない系
        "ありえない", "あり得ない", "ありえん", "あり得ん",
        // うるさい系
        "うるさい", "うっさい", "うるっさい",
        // クズ系
        "クズ", "くず",
        // カス系
        "カス", "かす",
        // ボケ系
        "ボケ", "ぼけ", "ボケが", "ぼけが",
        // なめんな系
        "なめんな", "ナメんな", "なめてんの", "ナメてんの",
        // ドアホ系
        "ドアホ", "どあほ", "どアホ",
    ]

    // Callbacks
    var onMildWord: ((String) -> Void)?
    var onSevereWord: ((String) -> Void)?
    var onTranscription: ((String) -> Void)?

    // 処理済みテキストの長さ（文字数で追跡）
    private var processedCharCount = 0

    func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    func startRecognition(inputNode: AVAudioInputNode, format: AVAudioFormat) throws {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("[Speech] Recognizer not available")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let text = result.bestTranscription.formattedString
                self.onTranscription?(text)
                self.analyzeText(text)
            }
            if error != nil || (result?.isFinal ?? false) {
                // セッション終了時の未処理テキストをリセットして即座に再起動
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.restartRecognition(inputNode: inputNode, format: format)
                }
            }
        }
        print("[Speech] Recognition started.")
    }

    private func restartRecognition(inputNode: AVAudioInputNode, format: AVAudioFormat) {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        processedCharCount = 0  // 新セッション開始時にリセット
        try? startRecognition(inputNode: inputNode, format: format)
    }

    func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    func stopRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        print("[Speech] Recognition stopped.")
    }

    // MARK: - テキスト解析

    private func analyzeText(_ text: String) {
        let chars = Array(text)

        // 前回処理済みの文字数より少ない場合（認識の修正）はリセット
        if chars.count < processedCharCount {
            processedCharCount = 0
        }

        // 新しく追加された部分だけを取り出す
        guard chars.count > processedCharCount else { return }
        let newPart = String(chars[processedCharCount...])
        processedCharCount = chars.count

        guard !newPart.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // 重度 → 軽度の順に優先チェック
        for word in severeWords {
            if newPart.contains(word) {
                print("[Speech] Severe: '\(word)' in '\(newPart)'")
                onSevereWord?(word)
                return
            }
        }
        for word in mildWords {
            if newPart.contains(word) {
                print("[Speech] Mild: '\(word)' in '\(newPart)'")
                onMildWord?(word)
                return
            }
        }
    }
}

