import AVFoundation

/// 合成音效服务 - 对应 H5 版 src/sound.js
/// H5 用 Web Audio 振荡器实时合成，这里用 AVAudioEngine + 离线渲染 PCM buffer 近似，
/// 波形（sine/square/triangle）、频率、起音/指数衰减包络、各音起止时间与 H5 保持一致。
final class SoundService {
    static let shared = SoundService()

    private enum Waveform { case sine, square, triangle }

    /// 单个音符（对应 H5 一次 oscillator + gain 包络）
    private struct Note {
        var frequency: Double       // 起始频率
        var endFrequency: Double?   // 频率线性滑动目标（对应 H5 linearRampToValueAtTime）
        var start: Double           // 相对本次播放的起始秒
        var duration: Double
        var peak: Float             // 峰值音量
        var attack: Double          // 线性起音时长
        var waveform: Waveform
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    /// 固定的播放格式：player 与 buffer 必须严格一致，
    /// 否则 scheduleBuffer 会抛 NSException 闪退（真机上 format: nil 协商不可靠）
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        // ambient：不打断其他音频、随静音开关静音，符合工具类 App 音效定位
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - 对外 API（与 H5 sound.js 同名）

    /// 点击音效 - 轻微反馈
    func playClickSound() {
        play([Note(frequency: 500, endFrequency: nil, start: 0, duration: 0.1,
                   peak: 0.06, attack: 0.001, waveform: .sine)])
    }

    /// 金币获得音效 - 清脆的硬币声（800/1000/1200Hz 三连音）
    func playCoinSound() {
        let notes = (0..<3).map { i in
            Note(frequency: 800 + Double(i) * 200, endFrequency: nil,
                 start: Double(i) * 0.08, duration: 0.2,
                 peak: 0.1, attack: 0.02, waveform: .sine)
        }
        play(notes)
    }

    /// 奖励音效 - 上升琶音（C5→E5→G5→C6）+ 叮（E6 三角波）
    func playRewardSound() {
        var notes: [Note] = [523.25, 659.25, 783.99, 1046.50].enumerated().map { i, freq in
            Note(frequency: freq, endFrequency: nil, start: Double(i) * 0.12, duration: 0.35,
                 peak: 0.15, attack: 0.05, waveform: .sine)
        }
        notes.append(Note(frequency: 1318.51, endFrequency: nil, start: 0.5, duration: 0.8,
                          peak: 0.12, attack: 0.02, waveform: .triangle))
        play(notes)
    }

    /// 任务完成音效 - 短促的勾选音（600→900Hz 上滑）
    func playCheckSound() {
        play([Note(frequency: 600, endFrequency: 900, start: 0, duration: 0.25,
                   peak: 0.12, attack: 0.001, waveform: .sine)])
    }

    /// 计时结束提示音 - 三声方波提示（880Hz × 3）
    func playTimerEndSound() {
        let notes = (0..<3).map { i in
            Note(frequency: 880, endFrequency: nil, start: Double(i) * 0.25, duration: 0.25,
                 peak: 0.08, attack: 0.02, waveform: .square)
        }
        play(notes)
    }

    // MARK: - 合成与播放

    private func play(_ notes: [Note]) {
        guard let buffer = render(notes) else { return }
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setActive(true)
            try? engine.start()
        }
        // 引擎起不来时宁可静默，也不调度 buffer（避免 NSException 闪退）
        guard engine.isRunning else { return }
        if !player.isPlaying { player.play() }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }

    /// 把一组音符（含各自起始偏移）混音渲染到单个 PCM buffer
    private func render(_ notes: [Note]) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let total = notes.map { $0.start + $0.duration }.max() ?? 0
        guard total > 0 else { return nil }
        let frameCount = AVAudioFrameCount(total * sampleRate) + 1
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        for note in notes {
            let startFrame = Int(note.start * sampleRate)
            let noteFrames = Int(note.duration * sampleRate)
            var phase = 0.0
            for i in 0..<noteFrames {
                let t = Double(i) / sampleRate
                // 频率滑动（对应 H5 的 frequency.linearRampToValueAtTime，0.1 秒内完成）
                var freq = note.frequency
                if let end = note.endFrequency {
                    let rampDuration = min(0.1, note.duration)
                    let p = min(1, t / rampDuration)
                    freq = note.frequency + (end - note.frequency) * p
                }
                phase += 2 * .pi * freq / sampleRate

                let sample: Double
                switch note.waveform {
                case .sine:     sample = sin(phase)
                case .square:   sample = sin(phase) >= 0 ? 1 : -1
                case .triangle: sample = (2 / .pi) * asin(sin(phase))
                }

                // 包络：线性起音 + 指数衰减到 0.001（近似 H5 的 linearRamp + exponentialRamp）
                let envelope: Double
                if t < note.attack {
                    envelope = t / note.attack
                } else {
                    let decay = max(0.0001, note.duration - note.attack)
                    envelope = pow(0.001 / Double(note.peak), (t - note.attack) / decay)
                }

                channel[startFrame + i] += Float(sample) * note.peak * Float(envelope)
            }
        }
        return buffer
    }
}
