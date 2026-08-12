import SwiftUI
import AVFoundation

/// 白噪音条目（对应 H5 white-noise.js 的 WHITE_NOISES）
struct WhiteNoise: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    /// 价格（金币），0 为免费
    let price: Int
    /// Bundle 音频文件名（Resources/Audio/*.mp3，不含扩展名）；nil 表示程序化生成（雨声/时钟）
    let audioFile: String?
}

/// 白噪音播放管理器 - 对应 H5 white-noise.js 的模块级播放状态
/// 与 H5 保持一致：雨声（棕噪音+低通滤波）/时钟滴答（800Hz 每秒一滴答）程序化生成；
/// 付费项（溪流/虫鸣/海浪）播放 Bundle 内 mp3 文件（沿用 H5 的文件映射）。
/// 音频会话用 .playback，配合 Info.plist 的 audio 后台模式，锁屏后可持续播放。
final class WhiteNoiseManager: ObservableObject {
    static let shared = WhiteNoiseManager()

    /// 白噪音列表（与 H5 一致：雨声/时钟滴答免费，溪流/虫鸣/海浪付费）
    static let noises: [WhiteNoise] = [
        WhiteNoise(id: "rain",     name: "雨声",     icon: "🌧️", price: 0,   audioFile: nil),
        WhiteNoise(id: "clock",    name: "时钟滴答", icon: "🕐", price: 0,   audioFile: nil),
        WhiteNoise(id: "stream",   name: "溪流潺潺", icon: "🏞️", price: 150, audioFile: "rain"),
        WhiteNoise(id: "crickets", name: "虫鸣夏夜", icon: "", price: 200, audioFile: "clock"),
        WhiteNoise(id: "waves",    name: "海浪轻拍", icon: "🌊", price: 250, audioFile: "snow-mountain"),
    ]

    @Published private(set) var currentId: String?
    @Published private(set) var isMuted = false
    @Published var volume: Double = 0.5 { didSet { applyVolume() } }

    /// 文件类白噪音播放器
    private var player: AVAudioPlayer?
    /// 生成类白噪音引擎（雨声/时钟）
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    /// 固定格式，playerNode 连接与渲染 buffer 必须一致（否则 scheduleBuffer 抛异常）
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

    var isPlaying: Bool { currentId != nil }

    private init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    /// 播放白噪音；付费且未拥有时自动尝试购买（对应 H5 playWhiteNoise）
    /// - Returns: 失败文案（金币不足），nil 表示成功开始播放
    @discardableResult
    func play(_ noise: WhiteNoise, store: AppStore) -> String? {
        // 付费检查 + 自动购买
        if noise.price > 0 && !store.ownedWhiteNoises.contains(noise.id) {
            guard store.spendCoins(noise.price, reason: "购买白噪音：\(noise.name)") > 0 else {
                return "金币不足，需要 \(noise.price) 金币"
            }
            store.addOwnedWhiteNoise(noise.id)
        }

        stopPlayback()

        // playback + mixWithOthers：计时中可持续播放，锁屏后不断（需 audio 后台模式）
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, options: [.mixWithOthers])
        try? audioSession.setActive(true)

        if let file = noise.audioFile {
            // 文件类（付费项）
            guard let url = Bundle.main.url(forResource: file, withExtension: "mp3"),
                  let newPlayer = try? AVAudioPlayer(contentsOf: url) else { return nil }
            newPlayer.numberOfLoops = -1  // 无限循环
            newPlayer.volume = Float(volume)
            newPlayer.play()
            player = newPlayer
        } else {
            // 生成类：雨声 / 时钟滴答（算法与 H5 一致）
            guard let buffer = noise.id == "rain" ? renderRainBuffer() : renderClockBuffer() else { return nil }
            if !engine.isRunning { try? engine.start() }
            guard engine.isRunning else { return nil }
            if !playerNode.isPlaying { playerNode.play() }
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
            playerNode.volume = Float(volume)
        }

        currentId = noise.id
        volume = 0.5
        isMuted = false
        return nil
    }

    /// 停止播放（对应 H5 stopWhiteNoise）
    func stop() {
        stopPlayback()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        playerNode.stop()
        if engine.isRunning { engine.stop() }
        currentId = nil
    }

    /// 切换静音（对应 H5 toggleMute）
    func toggleMute() {
        isMuted.toggle()
        applyVolume()
    }

    private func applyVolume() {
        let v = isMuted ? 0 : Float(volume)
        player?.volume = v
        playerNode.volume = v
    }

    // MARK: - 程序化生成（与 H5 startRainSound / startClockSound 一致）

    /// 雨声：棕色噪音放大 3.5 倍 + 800Hz 低通，2 秒循环（H5 算法）
    private func renderRainBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(2 * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        // 一阶低通（RC 近似 H5 的 800Hz biquad lowpass）
        let alpha = 1.0 - exp(-2.0 * Double.pi * 800.0 / sampleRate)
        var lastOut = 0.0
        var filtered = 0.0
        var peak: Float = 0.001
        for i in 0..<Int(frameCount) {
            let white = Double.random(in: -1...1)
            // 棕色噪音（更柔和，像雨声）
            lastOut = (lastOut + 0.02 * white) / 1.02
            let brown = lastOut * 3.5
            filtered += alpha * (brown - filtered)
            channel[i] = Float(filtered)
            peak = max(peak, abs(channel[i]))
        }
        // 归一化到 0.8，防止放大后削波
        let gain = 0.8 / peak
        for i in 0..<Int(frameCount) { channel[i] *= gain }
        return buffer
    }

    /// 时钟滴答：每秒一声 800Hz 正弦短音，0.05 秒指数衰减（H5 算法），1 秒循环
    private func renderClockBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        let tickFrames = Int(0.05 * sampleRate)
        for i in 0..<tickFrames {
            let t = Double(i) / sampleRate
            // 指数衰减到 0.001（H5 exponentialRampToValueAtTime）
            let envelope = pow(0.001, t / 0.05)
            channel[i] = Float(sin(2 * .pi * 800 * t) * envelope * 0.3)
        }
        return buffer
    }
}

/// 专注白噪音面板 - 对应 H5 white-noise.js 的 renderWhiteNoisePanel()
struct WhiteNoiseView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject var manager: WhiteNoiseManager

    @State private var toastMessage: String?

    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                // 头部：标题 + 静音按钮（H5：播放中或已静音时显示）
                HStack {
                    Text("专注白噪音")
                        .font(theme.fontDesign.font(size: 16, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    if manager.currentId != nil || manager.isMuted {
                        Button { manager.toggleMute() } label: {
                            Text(manager.isMuted ? "🔇" : "🔊")
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 白噪音列表
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(WhiteNoiseManager.noises) { noise in
                            noiseItem(noise)
                        }
                    }
                    .padding(.vertical, 2)
                }

                // 音量调节（播放中时显示）
                if manager.currentId != nil {
                    HStack(spacing: 8) {
                        Text("🔈").font(.system(size: 14))
                        Slider(value: $manager.volume, in: 0...1)
                            .tint(Color.css(theme.timerStyle.border))
                        Text("🔊").font(.system(size: 14))
                    }
                }
            }
        }
        .overlay(alignment: .top) { toast }
    }

    // MARK: - 子视图

    private func noiseItem(_ noise: WhiteNoise) -> some View {
        let isActive = manager.currentId == noise.id
        let isLocked = noise.price > 0 && !store.ownedWhiteNoises.contains(noise.id)
        let accent = Color.css(theme.timerStyle.border)

        return Button {
            if isActive {
                manager.stop()
            } else if let error = manager.play(noise, store: store) {
                showToast(error)
            }
        } label: {
            VStack(spacing: 4) {
                Text(noise.icon)
                    .font(.system(size: 24))
                Text(noise.name)
                    .font(theme.fontDesign.font(size: 12))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Group {
                    if isLocked {
                        Text("💰 \(noise.price)")
                            .foregroundStyle(theme.textSecondary)
                    } else if isActive && !manager.isMuted {
                        Text("♪")
                            .foregroundStyle(accent)
                    } else {
                        Text(" ")
                    }
                }
                .font(theme.fontDesign.font(size: 11))
                .frame(height: 14)
            }
            .frame(width: 72)
            .padding(.vertical, 8)
            .background(isActive ? accent.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? accent : Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
            )
            .opacity(isLocked ? 0.7 : 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var toast: some View {
        if let msg = toastMessage {
            Text(msg)
                .font(theme.fontDesign.font(size: 13))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .padding(8)
                .transition(.opacity)
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if toastMessage == msg {
                withAnimation { toastMessage = nil }
            }
        }
    }
}
