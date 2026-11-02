import AVFoundation
import Speech

/// 语音转文字：点一下开始听，再点一下停止。
/// 识别结果通过 onText 回传，调用方负责写进输入框。
final class VoiceInput: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isStarting = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var tapInstalled = false
    private var onText: ((String) -> Void)?
    private var onError: ((String) -> Void)?

    /// 麦克风按钮在不可用时也能给出明确提示
    var isAvailable: Bool { recognizer?.isAvailable ?? false }

    func toggle(onText: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        if isRecording || isStarting {
            stop()
            return
        }
        self.onText = onText
        self.onError = onError

        requestPermissions { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.fail("需要麦克风和语音识别权限，去 设置 → 隐私 里打开")
                return
            }
            self.begin()
        }
    }

    func stop() {
        guard isRecording || isStarting else { return }
        tearDown()
        task?.finish()
        task = nil
        request = nil
    }

    // MARK: - 内部

    private func begin() {
        guard let recognizer, recognizer.isAvailable else {
            fail("语音识别暂时不可用，稍后再试")
            return
        }
        isStarting = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            // 支持离线时优先本地识别，话不出手机
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }
            self.request = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            tapInstalled = true
            engine.prepare()
            try engine.start()

            isStarting = false
            isRecording = true

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                DispatchQueue.main.async {
                    guard self.isRecording else { return }
                    if let result {
                        self.onText?(result.bestTranscription.formattedString)
                        if result.isFinal { self.finishQuietly() }
                    }
                    if error != nil { self.finishQuietly() }
                }
            }
        } catch {
            finishQuietly()
            fail("麦克风启动失败，检查一下权限")
        }
    }

    /// 结束但不再回调识别任务，用于识别自己结束的场景
    private func finishQuietly() {
        guard isRecording || isStarting else { return }
        tearDown()
        request = nil
        task = nil
    }

    private func tearDown() {
        if tapInstalled {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        request?.endAudio()
        isRecording = false
        isStarting = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func fail(_ message: String) {
        onError?(message)
        onError = nil
    }

    private func requestPermissions(_ done: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async { done(false) }
                return
            }
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async { done(granted) }
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async { done(granted) }
                }
            }
        }
    }
}
