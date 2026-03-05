import Foundation
import AVFoundation
import Speech
import Combine

class IrritationViewModel: ObservableObject {
    @Published var isMonitoring: Bool = false
    @Published var events: [DetectionEvent] = []
    @Published var transcription: String = ""
    @Published var micPermissionGranted: Bool = false
    @Published var speechPermissionGranted: Bool = false
    @Published var wordCount: Int = 0
    @Published var impactCount: Int = 0

    // Sub-components
    let scoreEngine = IrritationScoreEngine()
    let responseManager = ResponseManager()

    private let audioCaptureManager = AudioCaptureManager()
    private let speechManager = SpeechManager()
    private let impactDetector = ImpactDetector()

    private var cancellables = Set<AnyCancellable>()

    // Forwarded publishers
    var score: Double { scoreEngine.score }
    var level: IrritationLevel { scoreEngine.level }
    var currentAdvice: String { responseManager.currentAdvice }
    var showAdviceModal: Bool { responseManager.showAdviceModal }

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Forward score changes to response manager
        scoreEngine.$level
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.responseManager.update(for: level)
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        scoreEngine.$score
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        responseManager.$currentAdvice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        responseManager.$showAdviceModal
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Impact detector callback
        impactDetector.onImpactDetected = { [weak self] in
            self?.scoreEngine.addImpact()
            self?.addEvent(.impact)
        }

        // Speech manager callbacks
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

        // Audio buffer routing
        audioCaptureManager.onBuffer = { [weak self] buffer, _ in
            self?.impactDetector.process(buffer: buffer)
            self?.speechManager.appendBuffer(buffer)
        }
    }

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
            let format = audioCaptureManager.outputFormat
            let inputNode = audioCaptureManager.inputNode
            try speechManager.startRecognition(inputNode: inputNode, format: format)

            isMonitoring = true
            print("[ViewModel] Monitoring started.")
        } catch {
            print("[ViewModel] Failed to start monitoring: \(error)")
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

    func dismissModal() {
        DispatchQueue.main.async {
            self.responseManager.showAdviceModal = false
            self.objectWillChange.send()
        }
    }
}

