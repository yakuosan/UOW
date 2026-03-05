import Speech
import AVFoundation
import Foundation

class SpeechManager {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Keyword lists
    let mildWords = ["うざい", "むかつく", "バカ", "ばか", "あほ", "最悪", "うざ", "きもい", "だるい", "うっさい"]
    let severeWords = ["くそ", "死ね", "ふざけんな", "殺す", "うるさい", "消えろ", "最低", "ありえない"]

    // Callbacks
    var onMildWord: ((String) -> Void)?
    var onSevereWord: ((String) -> Void)?
    var onTranscription: ((String) -> Void)?

    private var lastProcessedText = ""

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
                // Restart recognition for continuous mode
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        lastProcessedText = ""

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

    private func analyzeText(_ text: String) {
        // Only analyze new text beyond what was already processed
        guard text != lastProcessedText else { return }
        let newPart = String(text.dropFirst(lastProcessedText.count))
        lastProcessedText = text

        for word in severeWords {
            if newPart.contains(word) {
                print("[Speech] Severe word detected: \(word) in '\(newPart)'")
                onSevereWord?(word)
                return
            }
        }
        for word in mildWords {
            if newPart.contains(word) {
                print("[Speech] Mild word detected: \(word) in '\(newPart)'")
                onMildWord?(word)
                return
            }
        }
    }
}
