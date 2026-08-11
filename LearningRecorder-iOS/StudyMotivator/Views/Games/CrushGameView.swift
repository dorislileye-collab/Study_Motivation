import SwiftUI

/// 销毁方式（对应 H5 crush.js 的 4 种 method）
enum CrushMethod: String, CaseIterable, Identifiable {
    case burn, shred, blow, dissolve

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .burn: return "🔥"
        case .shred: return "⚙️"
        case .blow: return "💨"
        case .dissolve: return "💧"
        }
    }

    var name: String {
        switch self {
        case .burn: return "燃烧"
        case .shred: return "粉碎"
        case .blow: return "吹散"
        case .dissolve: return "溶解"
        }
    }

    var desc: String {
        switch self {
        case .burn: return "让火焰吞噬一切"
        case .shred: return "撕成碎片随风散去"
        case .blow: return "一口气吹走烦恼"
        case .dissolve: return "让水滴慢慢融化"
        }
    }

    /// 动画总帧数（30fps，对应 H5 各动画的 maxFrames）
    var maxFrames: Int {
        switch self {
        case .burn: return 120
        case .shred: return 90
        case .blow: return 100
        case .dissolve: return 150
        }
    }

    /// 完成提示（对应 H5 showComplete 文案）
    var completeText: String {
        switch self {
        case .burn: return "烦恼已被火焰吞噬 🔥"
        case .shred: return "烦恼已化为碎片 ⚙️"
        case .blow: return "烦恼已被风吹散 💨"
        case .dissolve: return "烦恼已慢慢溶解 💧"
        }
    }
}

/// 已销毁烦恼的历史记录（对应 H5 crush-history，localStorage → UserDefaults）
struct CrushRecord: Codable, Identifiable, Equatable {
    var id: Double { timestamp }
    let text: String
    let method: String
    let timestamp: Double

    var crushMethod: CrushMethod { CrushMethod(rawValue: method) ?? .burn }

    /// "M月D日 HH:mm"（对应 H5 renderHistory 的日期格式）
    var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: Date(timeIntervalSince1970: timestamp / 1000))
    }
}

enum CrushHistoryStore {
    private static let key = "crush_history"
    private static let maxCount = 20

    static func load() -> [CrushRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([CrushRecord].self, from: data) else { return [] }
        return list
    }

    /// 新纪录插到最前，只保留最近 20 条（对应 H5 saveToHistory）
    static func add(text: String, method: CrushMethod) {
        var list = load()
        list.insert(CrushRecord(text: text, method: method.rawValue, timestamp: Date().timeIntervalSince1970 * 1000), at: 0)
        if list.count > maxCount { list = Array(list.prefix(maxCount)) }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - 销毁动画引擎（对应 H5 crush.js 的 4 个 30fps setInterval 动画）

final class CrushEngine: ObservableObject {
    /// 通用碎片/粒子（isRect 区分碎片矩形与圆点）
    struct Bit {
        var x, y, vx, vy: CGFloat
        var w, h: CGFloat
        var rotation: CGFloat
        var rotSpeed: CGFloat
        var life: Double
        var decay: Double
        var color: Color
        var isRect: Bool
        var gravity: CGFloat
        var shrink: CGFloat
        var alphaScale: Double
    }

    @Published private(set) var bits: [Bit] = []
    @Published private(set) var frame = 0
    @Published private(set) var finished = false

    private(set) var method: CrushMethod = .burn
    private var timer: Timer?

    /// 画布尺寸（Canvas 每帧写入，供粒子以中心为基准生成）
    var canvasSize: CGSize = .zero

    var progress: Double { min(1, Double(frame) / Double(method.maxFrames)) }

    func start(method: CrushMethod) {
        stop()
        self.method = method
        frame = 0
        finished = false
        bits = []
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        frame += 1
        let p = progress
        let cx = canvasSize.width / 2
        let cy = canvasSize.height / 2

        switch method {
        case .burn:
            // 火焰粒子（对应 animateBurn：前 70% 每 2 帧 3 个）
            if p < 0.7, frame % 2 == 0 {
                for _ in 0..<3 {
                    bits.append(Bit(
                        x: cx + CGFloat.random(in: -100...100),
                        y: cy + CGFloat.random(in: -30...30),
                        vx: CGFloat.random(in: -1...1),
                        vy: -CGFloat.random(in: 1...4),
                        w: CGFloat.random(in: 2...8), h: 0,
                        rotation: 0, rotSpeed: 0,
                        life: 1, decay: Double.random(in: 0.01...0.04),
                        color: Bool.random() ? Color.css("#FF6B35") : Color.css("#FFD700"),
                        isRect: false, gravity: 0, shrink: 0.98, alphaScale: 1
                    ))
                }
            }
            // 灰烬粒子（后期，每 3 帧 1 个）
            if p > 0.5, frame % 3 == 0 {
                bits.append(Bit(
                    x: cx + CGFloat.random(in: -75...75),
                    y: cy + CGFloat.random(in: -20...20),
                    vx: CGFloat.random(in: -0.5...0.5),
                    vy: -CGFloat.random(in: 0.5...2),
                    w: CGFloat.random(in: 1...4), h: 0,
                    rotation: 0, rotSpeed: 0,
                    life: 1, decay: Double.random(in: 0.005...0.025),
                    color: Color.css("#555555"),
                    isRect: false, gravity: 0, shrink: 0.98, alphaScale: 1
                ))
            }
        case .shred:
            // 碎裂阶段（20%~40% 每 2 帧 5 个碎片，对应 animateShred）
            if p >= 0.2, p < 0.4, frame % 2 == 0 {
                let palette = ["#333333", "#666666", "#999999", "#FF6B6B", "#4ECDC4"]
                for _ in 0..<5 {
                    bits.append(Bit(
                        x: cx + CGFloat.random(in: -90...90),
                        y: cy + CGFloat.random(in: -20...20),
                        vx: CGFloat.random(in: -4...4),
                        vy: CGFloat.random(in: -4...4),
                        w: CGFloat.random(in: 4...16),
                        h: CGFloat.random(in: 3...11),
                        rotation: CGFloat.random(in: 0...(2 * .pi)),
                        rotSpeed: CGFloat.random(in: -0.15...0.15),
                        life: 1, decay: Double.random(in: 0.005...0.02),
                        color: Color.css(palette.randomElement() ?? "#666666"),
                        isRect: true, gravity: 0.1, shrink: 1, alphaScale: 1
                    ))
                }
            }
        case .blow:
            // 风粒子（30%~50% 每 2 帧 4 个，对应 animateBlow）
            if p >= 0.3, p < 0.5, frame % 2 == 0 {
                for _ in 0..<4 {
                    bits.append(Bit(
                        x: cx + CGFloat.random(in: -100...100),
                        y: cy + CGFloat.random(in: -30...30),
                        vx: CGFloat.random(in: 2...8),
                        vy: CGFloat.random(in: -1...1),
                        w: CGFloat.random(in: 2...6), h: 0,
                        rotation: 0, rotSpeed: 0,
                        life: 1, decay: Double.random(in: 0.01...0.03),
                        color: Color.css("#B0B0B0"),
                        isRect: false, gravity: 0, shrink: 0.99, alphaScale: 0.6
                    ))
                }
            }
        case .dissolve:
            // 水滴（前 40% 每 3 帧 2 个，对应 animateDissolve）
            if p < 0.4, frame % 3 == 0 {
                for _ in 0..<2 {
                    bits.append(Bit(
                        x: cx + CGFloat.random(in: -80...80),
                        y: cy + CGFloat.random(in: -25...25),
                        vx: CGFloat.random(in: -0.25...0.25),
                        vy: CGFloat.random(in: 0.5...2),
                        w: CGFloat.random(in: 4...12), h: 0,
                        rotation: 0, rotSpeed: 0,
                        life: 1, decay: Double.random(in: 0.005...0.015),
                        color: Color.css("#4ECDC4"),
                        isRect: false, gravity: 0.05, shrink: 0.99, alphaScale: 0.7
                    ))
                }
            }
        }

        for i in bits.indices {
            bits[i].x += bits[i].vx
            bits[i].y += bits[i].vy
            bits[i].vy += bits[i].gravity
            bits[i].rotation += bits[i].rotSpeed
            bits[i].life -= bits[i].decay
            bits[i].w *= bits[i].shrink
            bits[i].h *= bits[i].shrink
        }
        bits.removeAll { $0.life <= 0 }

        if frame >= method.maxFrames {
            finished = true
            stop()
        }
    }

    func draw(context: inout GraphicsContext, size: CGSize) {
        for b in bits {
            let alpha = max(0, b.life) * b.alphaScale
            if b.isRect {
                var g = context
                g.translateBy(x: b.x, y: b.y)
                g.rotate(by: Angle(radians: b.rotation))
                g.fill(
                    Path(CGRect(x: -b.w / 2, y: -b.h / 2, width: b.w, height: b.h)),
                    with: .color(b.color.opacity(alpha))
                )
            } else {
                let r = max(0, b.w / 2)
                guard r > 0 else { continue }
                context.fill(
                    Path(ellipseIn: CGRect(x: b.x - r, y: b.y - r, width: r * 2, height: r * 2)),
                    with: .color(b.color.opacity(alpha))
                )
            }
        }
    }
}

// MARK: - 文字销毁效果（对应 H5 各动画对 animText 的样式操控）

private struct CrushTextEffect {
    var color: Color = .white
    var opacity: Double = 1
    var scale: CGFloat = 1
    var blur: CGFloat = 0
    var offsetX: CGFloat = 0
    var glowColor: Color? = nil
    var glowRadius: CGFloat = 0

    static func make(method: CrushMethod, frame: Int, progress: Double, baseColor: Color) -> CrushTextEffect {
        var e = CrushTextEffect(color: baseColor)
        let p = progress
        switch method {
        case .burn:
            if p < 0.3 {
                e.color = Color.css("#FF6B35")
                e.glowColor = Color.css("#FF6B35")
                e.glowRadius = 10
            } else if p < 0.6 {
                e.color = Color.css("#FF4500")
                e.glowColor = Color.css("#FF4500")
                e.glowRadius = 15
                e.scale = 1 + p * 0.1
            } else if p < 0.8 {
                e.color = Color.css("#8B0000")
                e.glowColor = Color.css("#8B0000")
                e.glowRadius = 5
                e.opacity = max(0, 1 - (p - 0.6) * 3)
            } else {
                e.opacity = 0
            }
        case .shred:
            if p < 0.2 {
                e.offsetX = sin(Double(frame) * 2) * 3
            } else if p < 0.4 {
                let fp = (p - 0.2) / 0.2
                e.opacity = 1 - fp
                e.scale = 1 + fp * 0.3
            } else {
                e.opacity = 0
            }
        case .blow:
            if p < 0.3 {
                e.offsetX = sin(Double(frame) * 3) * 2
            } else if p < 0.5 {
                let fp = (p - 0.3) / 0.2
                e.opacity = 1 - fp * 0.5
            } else {
                e.opacity = 0
            }
        case .dissolve:
            if p < 0.4 {
                let fp = p / 0.4
                e.opacity = 1 - fp * 0.3
                e.blur = fp * 2
                e.scale = 1 + fp * 0.05
            } else if p < 0.7 {
                let fp = (p - 0.4) / 0.3
                e.opacity = 1 - fp
                e.blur = 2 + fp * 3
            } else {
                e.opacity = 0
            }
        }
        return e
    }
}

// MARK: - 情绪粉碎机（对应 H5 game.js enterGame('destroy') + crush.js）

struct CrushGameView: View {
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var engine = CrushEngine()

    @State private var text = ""
    @State private var placeholder = "在这里写下让你烦恼的事情..."
    @State private var isPlaying = false
    @State private var history: [CrushRecord] = CrushHistoryStore.load()
    @State private var shaking = false

    var body: some View {
        GameScreen(title: GameKind.crush.titleWithIcon) {
            if isPlaying {
                destructionView
            } else {
                inputView
            }
        }
        .onDisappear {
            engine.stop()
        }
    }

    // MARK: 输入界面（对应 H5 crush-input-section / crush-methods-section / crush-history）

    private var inputView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 头部副标题（对应 H5 crush-header）
                VStack(spacing: 4) {
                    Text("💭")
                        .font(.system(size: 36))
                    Text("写下烦恼，选择方式销毁它")
                        .font(theme.fontDesign.font(size: 14))
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                // 输入区
                ThemedCard {
                    VStack(spacing: 8) {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $text)
                                .font(theme.fontDesign.font(size: 15))
                                .foregroundStyle(theme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(height: 110)
                                .onChange(of: text) { _, newValue in
                                    if newValue.count > 200 {
                                        text = String(newValue.prefix(200))
                                    }
                                }
                            if text.isEmpty {
                                Text(placeholder)
                                    .font(theme.fontDesign.font(size: 15))
                                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        Text("\(text.count)/200")
                            .font(theme.fontDesign.font(size: 12))
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .offset(x: shaking ? -8 : 0)

                // 销毁方式网格（对应 H5 crush-method-grid）
                VStack(alignment: .leading, spacing: 10) {
                    Text("选择销毁方式")
                        .font(theme.fontDesign.font(size: 16, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(CrushMethod.allCases) { m in
                            Button {
                                startDestruction(method: m)
                            } label: {
                                VStack(spacing: 6) {
                                    Text(m.icon)
                                        .font(.system(size: 30))
                                    Text(m.name)
                                        .font(theme.fontDesign.font(size: 15, weight: .semibold))
                                        .foregroundStyle(theme.textPrimary)
                                    Text(m.desc)
                                        .font(theme.fontDesign.font(size: 11))
                                        .foregroundStyle(theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.css(theme.gameStyle.bg))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.css(theme.gameStyle.border), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 历史记录（对应 H5 crush-history-section）
                VStack(alignment: .leading, spacing: 10) {
                    Text("🎉 已销毁的烦恼")
                        .font(theme.fontDesign.font(size: 16, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)

                    if history.isEmpty {
                        Text("还没有销毁过烦恼哦～")
                            .font(theme.fontDesign.font(size: 13))
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(history) { item in
                                ThemedCard(padding: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.text)
                                            .font(theme.fontDesign.font(size: 14))
                                            .foregroundStyle(theme.textPrimary)
                                            .lineLimit(2)
                                        HStack {
                                            Text("\(item.crushMethod.icon) \(item.crushMethod.name)")
                                            Spacer()
                                            Text(item.dateLabel)
                                        }
                                        .font(theme.fontDesign.font(size: 12))
                                        .foregroundStyle(theme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: 销毁动画界面（对应 H5 crush-canvas-section）

    private var destructionView: some View {
        ZStack {
            TimelineView(.animation) { _ in
                Canvas { ctx, size in
                    engine.canvasSize = size
                    engine.draw(context: &ctx, size: size)
                }
            }

            // 被销毁的文字 / 完成提示
            if engine.finished {
                Text(engine.method.completeText)
                    .font(theme.fontDesign.font(size: 18, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                let effect = CrushTextEffect.make(
                    method: engine.method,
                    frame: engine.frame,
                    progress: engine.progress,
                    baseColor: theme.textPrimary
                )
                Text(text)
                    .font(theme.fontDesign.font(size: 20, weight: .semibold))
                    .foregroundStyle(effect.color)
                    .shadow(color: effect.glowColor ?? .clear, radius: effect.glowRadius)
                    .scaleEffect(effect.scale)
                    .blur(radius: effect.blur)
                    .offset(x: effect.offsetX)
                    .opacity(effect.opacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .allowsHitTesting(false)
            }

            // 「← 继续写」按钮（对应 H5 crush-back-btn）
            VStack {
                Spacer()
                Button {
                    engine.stop()
                    isPlaying = false
                } label: {
                    Text("← 继续写")
                        .font(theme.fontDesign.font(size: 15, weight: .medium))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.css(theme.backgroundStyle.cardBg))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: 开始销毁（对应 H5 startDestruction：空文本抖动提示，存档后进动画）

    private func startDestruction(method: CrushMethod) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            placeholder = "先写下你的烦恼吧..."
            withAnimation(.default.repeatCount(4, autoreverses: true).speed(8)) {
                shaking = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shaking = false
                placeholder = "在这里写下让你烦恼的事情..."
            }
            return
        }

        CrushHistoryStore.add(text: trimmed, method: method)
        history = CrushHistoryStore.load()
        isPlaying = true
        engine.start(method: method)
    }
}
