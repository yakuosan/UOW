import Foundation
import AVFoundation
import Speech
import Combine

class IrritationViewModel: ObservableObject {

    // MARK: - @Published

    @Published var isMonitoring: Bool = false
    @Published var score: Double = 0.0
    @Published var level: IrritationLevel = .calm
    @Published var showAdviceModal: Bool = false
    @Published var currentAdvice: String = ""
    @Published var showBreathingModal: Bool = false

    @Published var events: [DetectionEvent] = []
    @Published var transcription: String = ""
    @Published var micPermissionGranted: Bool = false
    @Published var speechPermissionGranted: Bool = false
    @Published var wordCount: Int = 0
    @Published var impactCount: Int = 0
    @Published var isPlayingMusic: Bool = false

    // MARK: - Sub-components

    let scoreEngine = IrritationScoreEngine()
    let responseManager = ResponseManager()

    private let impactDetector = ImpactDetector()
    private let keywords = SpeechManager()   // キーワードリストのみ

    // MARK: - Audio / Speech

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var processedCharCount = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    // MARK: - Bindings

    private func setupBindings() {

        scoreEngine.$score
            .receive(on: DispatchQueue.main)
            .assign(to: &$score)

        scoreEngine.$level
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (level: IrritationLevel) in
                self?.level = level
                self?.responseManager.update(for: level)
            }
            .store(in: &cancellables)

        responseManager.$currentAdvice
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentAdvice)

        responseManager.$showAdviceModal
            .receive(on: DispatchQueue.main)
            .assign(to: &$showAdviceModal)

        responseManager.$showBreathingModal
            .receive(on: DispatchQueue.main)
            .assign(to: &$showBreathingModal)

        responseManager.$isPlayingMusic
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlayingMusic)

        impactDetector.onImpactDetected = { [weak self] in
            self?.scoreEngine.addImpact()
            self?.addEvent(.impact)
        }
    }

    // MARK: - 権限リクエスト

    func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.micPermissionGranted = granted
                print("[Permission] Mic: \(granted)")
            }
        }
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechPermissionGranted = (status == .authorized)
                print("[Permission] Speech: \(status.rawValue)")
            }
        }
    }

    // MARK: - 開始

    func startMonitoring() {
        guard !isMonitoring else { return }
        print("[ViewModel] startMonitoring() called")

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord,
                                    mode: .measurement,
                                    options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("[ViewModel] AVAudioSession activated.")

            // 順序重要: recognitionRequest を先に作ってからタップを開始する
            startSpeechRecognition()
            startAudioEngine()

            isMonitoring = true
            print("[ViewModel] Monitoring started successfully.")
        } catch {
            print("[ViewModel] Failed to start: \(error)")
        }
    }

    // MARK: - 停止

    func stopMonitoring() {
        guard isMonitoring else { return }

        stopSpeechRecognition()
        stopAudioEngine()
        responseManager.reset()

        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: .notifyOthersOnDeactivation)
        } catch {
            print("[ViewModel] Failed to deactivate session: \(error)")
        }

        isMonitoring = false
        print("[ViewModel] Monitoring stopped.")
    }

    // MARK: - AVAudioEngine

    private var tapCount = 0  // バッファ受信確認カウンター

    private func startAudioEngine() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        print("[AudioEngine] Format: \(format)")

        // 1つのタップで ImpactDetector と SpeechRecognition に同時配信
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.tapCount += 1
            if self.tapCount <= 3 || self.tapCount % 100 == 0 {
                print("[AudioEngine] Tap #\(self.tapCount) received")  // 最初の3回と100回ごとに表示
            }
            self.impactDetector.process(buffer: buffer)
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("[AudioEngine] Started.")
        } catch {
            print("[AudioEngine] Start failed: \(error)")
        }
    }

    private func stopAudioEngine() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        print("[AudioEngine] Stopped.")
    }

    // MARK: - SFSpeechRecognizer

    private func startSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))

        guard let recognizer = speechRecognizer else {
            print("[Speech] Recognizer creation failed.")
            return
        }

        // isAvailable が false でもタスクを開始する（エラー時は自動リトライ）
        print("[Speech] isAvailable=\(recognizer.isAvailable)")

        processedCharCount = 0
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false   // サーバー認識を許可（精度向上）
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async { self.transcription = text }
                self.analyzeTranscription(text)
            }

            if let error = error {
                let code = (error as NSError).code
                // キャンセル（1）と終了時エラー（1101）は無視
                if code != 1 && code != 1101 {
                    print("[Speech] Error \(code): \(error.localizedDescription)")
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    guard let self = self, self.isMonitoring else { return }
                    self.restartSpeechRecognition()
                }
            }
        }
        print("[Speech] Recognition started.")
    }

    private func restartSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        processedCharCount = 0
        startSpeechRecognition()
        print("[Speech] Restarted.")
    }

    private func stopSpeechRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        processedCharCount = 0
        print("[Speech] Stopped.")
    }

    // MARK: - テキスト解析（ViewModel 内で完結）

    private func analyzeTranscription(_ text: String) {
        let chars = Array(text)

        // 認識が修正されて短くなった場合はリセット
        if chars.count < processedCharCount {
            processedCharCount = 0
        }
        guard chars.count > processedCharCount else { return }

        let newPart = String(chars[processedCharCount...])
        processedCharCount = chars.count

        guard !newPart.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        print("[Speech] New: '\(newPart)'")

        // 重度 → 軽度の順に優先チェック
        for word in keywords.severeWords {
            if newPart.contains(word) {
                print("[Speech] Severe: '\(word)'")
                scoreEngine.addSevereWord()
                addEvent(.severeWord(word))
                return
            }
        }
        for word in keywords.mildWords {
            if newPart.contains(word) {
                print("[Speech] Mild: '\(word)'")
                scoreEngine.addMildWord()
                addEvent(.mildWord(word))
                return
            }
        }
    }

    // MARK: - リセット / モーダル

    func resetScore() {
        scoreEngine.reset()
        events.removeAll()
        transcription = ""
        wordCount = 0
        impactCount = 0
    }

    func dismissModal() {
        DispatchQueue.main.async { self.showAdviceModal = false }
    }

    func dismissBreathingModal() {
        responseManager.breathingCompleted()  // 完了時刻を記録してクールダウン開始
    }

    // MARK: - イベント記録

    private func addEvent(_ type: EventType) {
        let event = DetectionEvent(type: type, timestamp: Date())
        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            if self.events.count > 50 { self.events = Array(self.events.prefix(50)) }
            switch type {
            case .mildWord, .severeWord: self.wordCount += 1
            case .impact:               self.impactCount += 1
            }
        }
    }
}

