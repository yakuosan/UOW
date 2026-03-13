import Foundation
import AVFoundation
import Speech
import Combine

class IrritationViewModel: ObservableObject {

    // MARK: - @Published（SwiftUI が直接監視できるプロパティ）

    @Published var isMonitoring: Bool = false
    @Published var score: Double = 0.0           // scoreEngine から転送
    @Published var level: IrritationLevel = .calm // scoreEngine から転送
    @Published var showAdviceModal: Bool = false  // responseManager から転送
    @Published var currentAdvice: String = ""    // responseManager から転送

    @Published var events: [DetectionEvent] = []
    @Published var transcription: String = ""
    @Published var micPermissionGranted: Bool = false
    @Published var speechPermissionGranted: Bool = false
    @Published var wordCount: Int = 0
    @Published var impactCount: Int = 0

    // MARK: - Sub-components

    let scoreEngine = IrritationScoreEngine()
    let responseManager = ResponseManager()

    private let audioCaptureManager = AudioCaptureManager()
    private let speechManager = SpeechManager()
    private let impactDetector = ImpactDetector()

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    // MARK: - Bindings

    private func setupBindings() {

        // scoreEngine.score → viewModel.score（@Published に転送することで確実に画面更新）
        scoreEngine.$score
            .receive(on: DispatchQueue.main)
            .assign(to: &$score)

        // scoreEngine.level → viewModel.level
        scoreEngine.$level
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.level = level
                self?.responseManager.update(for: level)
            }
            .store(in: &cancellables)

        // responseManager → viewModel
        responseManager.$currentAdvice
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentAdvice)

        responseManager.$showAdviceModal
            .receive(on: DispatchQueue.main)
            .assign(to: &$showAdviceModal)

        // 台パン検知コールバック
        impactDetector.onImpactDetected = { [weak self] in
            self?.scoreEngine.addImpact()
            self?.addEvent(.impact)
        }

        // 暴言検知コールバック
        speechManager.onMildWord = { [weak self] word in
            self?.scoreEngine.addMildWord()
            self?.addEvent(.mildWord(word))
        }

        speechManager.onSevereWord = { [weak self] word in
            self?.scoreEngine.addSevereWord()
            self?.addEvent(.severeWord(word))
        }

        speechManager.onTranscription = { [weak self] text in
            DispatchQueue.main.async {
                self?.transcription = text
            }
        }

        // マイク音声バッファを2つのコンポーネントに配信
        audioCaptureManager.onBuffer = { [weak self] buffer, _ in
            self?.impactDetector.process(buffer: buffer)
            self?.speechManager.appendBuffer(buffer)
        }
    }

    // MARK: - 操作

    func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.micPermissionGranted = granted
            }
        }
        speechManager.requestPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.speechPermissionGranted = granted
            }
        }
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            try audioCaptureManager.startCapture()
            let format    = audioCaptureManager.outputFormat
            let inputNode = audioCaptureManager.inputNode
            try speechManager.startRecognition(inputNode: inputNode, format: format)

            isMonitoring = true
            print("[ViewModel] Monitoring started.")
        } catch {
            print("[ViewModel] Failed to start: \(error)")
        }
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        audioCaptureManager.stopCapture()
        speechManager.stopRecognition()
        isMonitoring = false
        print("[ViewModel] Monitoring stopped.")
    }

    func resetScore() {
        scoreEngine.reset()
        events.removeAll()
        transcription = ""
        wordCount = 0
        impactCount = 0
    }

    func dismissModal() {
        DispatchQueue.main.async {
            self.showAdviceModal = false
        }
    }

    // MARK: - イベント記録

    private func addEvent(_ type: EventType) {
        let event = DetectionEvent(type: type, timestamp: Date())
        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            if self.events.count > 50 {
                self.events = Array(self.events.prefix(50))
            }
            switch type {
            case .mildWord, .severeWord: self.wordCount += 1
            case .impact:               self.impactCount += 1
            }
        }
    }
}

