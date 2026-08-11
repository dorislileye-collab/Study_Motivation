import SwiftUI

/// 沙画材质（对应 H5 sand.js 的 MATERIALS）
enum SandMaterial: String, CaseIterable, Identifiable {
    case sand, powder, star, water

    var id: String { rawValue }

    var name: String {
        switch self {
        case .sand: return "细沙"
        case .powder: return "彩色粉末"
        case .star: return "星空粒子"
        case .water: return "水滴"
        }
    }

    var icon: String {
        switch self {
        case .sand: return "🏖️"
        case .powder: return "🎨"
        case .star: return "✨"
        case .water: return "💧"
        }
    }

    var colors: [Color] {
        switch self {
        case .sand:
            return ["#F4D03F", "#E67E22", "#D4A574", "#F39C12", "#FDEBD0", "#EDBB99", "#F5CBA7"].map { Color.css($0) }
        case .powder:
            return ["#FF1744", "#FF9100", "#FFEA00", "#00E676", "#00B0FF", "#D500F9", "#F50057", "#76FF03"].map { Color.css($0) }
        case .star:
            return ["#7C4DFF", "#448AFF", "#18FFFF", "#E040FB", "#FF4081", "#FFD740", "#69F0AE"].map { Color.css($0) }
        case .water:
            return ["#00BCD4", "#0097A7", "#4DD0E1", "#80DEEA", "#B2EBF2", "#E0F7FA"].map { Color.css($0) }
        }
    }

    var sizeRange: ClosedRange<CGFloat> {
        switch self {
        case .sand: return 2...5
        case .powder: return 3...7
        case .star: return 2...6
        case .water: return 5...10
        }
    }

    var spread: CGFloat {
        switch self {
        case .sand: return 4
        case .powder: return 6
        case .star: return 5
        case .water: return 3
        }
    }

    var gravity: CGFloat {
        switch self {
        case .sand: return 0.12
        case .powder: return 0.06
        case .star: return 0.03
        case .water: return 0.18
        }
    }

    var opacity: Double {
        switch self {
        case .sand: return 0.9
        case .powder: return 0.85
        case .star: return 1.0
        case .water: return 0.6
        }
    }

    var glow: Bool { self == .powder || self == .star }
    var twinkle: Bool { self == .star }
}

// MARK: - 沙画粒子引擎（对应 H5 sand.js 的粒子系统）

final class SandEngine: ObservableObject {
    struct Particle {
        var x, y, vx, vy: CGFloat
        var size: CGFloat
        var color: Color
        var opacity: Double
        var life: Double
        var decay: Double
        var phase: Double
        var glow: Bool
        var twinkle: Bool
    }

    struct Ambient {
        var x, y, size, speed: CGFloat
        var opacity, phase: Double
    }

    private(set) var particles: [Particle] = []
    private var ambient: [Ambient] = []
    private var ambientInited = false

    /// 当前材质（@Published 驱动材质栏高亮；粒子数组每帧变化，不发布）
    @Published var material: SandMaterial = .sand

    let maxParticles = 1500
    let maxAmbient = 50

    /// 拖动落沙（对应 H5 spawnParticles）
    func spawn(at point: CGPoint, count: Int) {
        let m = material
        for _ in 0..<count {
            if particles.count >= maxParticles { particles.removeFirst() }
            particles.append(Particle(
                x: point.x + CGFloat.random(in: -0.5...0.5) * m.spread,
                y: point.y + CGFloat.random(in: -0.5...0.5) * m.spread,
                vx: CGFloat.random(in: -1.5...1.5),
                vy: CGFloat.random(in: -1.5...1.5),
                size: CGFloat.random(in: m.sizeRange),
                color: m.colors.randomElement() ?? .white,
                opacity: m.opacity,
                life: 1,
                decay: Double.random(in: 0.001...0.003),
                phase: Double.random(in: 0...(2 * .pi)),
                glow: m.glow,
                twinkle: m.twinkle
            ))
        }
    }

    /// 点击粒子喷泉（对应 H5 onClickBurst）
    func burst(at point: CGPoint) {
        let m = material
        for i in 0..<50 {
            if particles.count >= maxParticles { particles.removeFirst() }
            let angle = (2 * CGFloat.pi / 50) * CGFloat(i) + CGFloat.random(in: 0...0.3)
            let speed = 3 + CGFloat.random(in: 0...6)
            particles.append(Particle(
                x: point.x,
                y: point.y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                size: CGFloat.random(in: m.sizeRange),
                color: m.colors.randomElement() ?? .white,
                opacity: m.opacity,
                life: 1,
                decay: Double.random(in: 0.003...0.007),
                phase: Double.random(in: 0...(2 * .pi)),
                glow: m.glow,
                twinkle: m.twinkle
            ))
        }
    }

    func reset() {
        particles.removeAll()
    }

    /// 物理更新（对应 H5 render 循环：重力、空气阻力、边界柔和反弹、生命衰减、环境粒子）
    func update(size: CGSize) {
        if !ambientInited, size.width > 0, size.height > 0 {
            ambientInited = true
            ambient = (0..<maxAmbient).map { _ in
                Ambient(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height),
                    size: 1 + CGFloat.random(in: 0...2),
                    speed: 0.2 + CGFloat.random(in: 0...0.5),
                    opacity: 0.1 + Double.random(in: 0...0.3),
                    phase: Double.random(in: 0...(2 * .pi))
                )
            }
        }

        let g = material.gravity * 0.3

        for i in particles.indices {
            particles[i].vy += g
            particles[i].x += particles[i].vx
            particles[i].y += particles[i].vy
            particles[i].vx *= 0.97
            particles[i].vy *= 0.97
            particles[i].life -= particles[i].decay
            particles[i].phase += 0.05

            if particles[i].x < 0 { particles[i].x = 0; particles[i].vx *= -0.3 }
            if particles[i].x > size.width { particles[i].x = size.width; particles[i].vx *= -0.3 }
            if particles[i].y < 0 { particles[i].y = 0; particles[i].vy *= -0.3 }
            if particles[i].y > size.height { particles[i].y = size.height; particles[i].vy *= -0.3 }
        }
        particles.removeAll { $0.life <= 0 }

        for i in ambient.indices {
            ambient[i].y -= ambient[i].speed
            ambient[i].phase += 0.02
            if ambient[i].y < -10 {
                ambient[i].y = size.height + 10
                ambient[i].x = CGFloat.random(in: 0...size.width)
            }
        }
    }

    func draw(context: inout GraphicsContext, size: CGSize) {
        // 环境微光粒子
        for a in ambient {
            let op = a.opacity * (0.5 + 0.5 * sin(a.phase))
            context.fill(
                Path(ellipseIn: CGRect(x: a.x - a.size, y: a.y - a.size, width: a.size * 2, height: a.size * 2)),
                with: .color(.white.opacity(op))
            )
        }

        for p in particles {
            var op = p.opacity * p.life
            if p.twinkle { op *= 0.5 + 0.5 * sin(p.phase) }
            let s = p.size * CGFloat(0.5 + 0.5 * p.life)
            guard s > 0 else { continue }
            let path = Path(ellipseIn: CGRect(x: p.x - s, y: p.y - s, width: s * 2, height: s * 2))
            if p.glow {
                var g = context
                g.addFilter(.shadow(color: p.color.opacity(op), radius: 6))
                g.fill(path, with: .color(p.color.opacity(op)))
            } else {
                context.fill(path, with: .color(p.color.opacity(op)))
            }
        }
    }
}

// MARK: - 沙画禅境（对应 H5 game.js enterGame('sand') + sand.js）

struct SandGameView: View {
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var engine = SandEngine()
    @State private var lastPoint: CGPoint?
    @State private var showHint = true

    var body: some View {
        GameScreen(title: GameKind.sand.titleWithIcon) {
            materialBar

            ZStack {
                // 深色渐变画布底（对应 H5 drawBackground 的渐变）
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.css("#0f0f1a"), Color.css("#1a1a2e"), Color.css("#16213e")],
                        startPoint: .top,
                        endPoint: .bottom
                    ))

                TimelineView(.animation) { _ in
                    Canvas { ctx, size in
                        engine.update(size: size)
                        engine.draw(context: &ctx, size: size)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .gesture(dragGesture)

                if showHint {
                    VStack(spacing: 10) {
                        Text("✨ 拖动手指开始创作")
                        Text("点击画布产生粒子喷泉")
                    }
                    .font(theme.fontDesign.font(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: 材质栏（对应 H5 sand-material-bar）

    private var materialBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SandMaterial.allCases) { m in
                    Button {
                        engine.material = m
                    } label: {
                        Text("\(m.icon) \(m.name)")
                            .font(theme.fontDesign.font(size: 13, weight: engine.material == m ? .semibold : .regular))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(engine.material == m ? 0.3 : 0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    engine.reset()
                } label: {
                    Text("🔄 重置")
                        .font(theme.fontDesign.font(size: 13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.css("#EF5350").opacity(0.35))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: 拖动手势（对应 H5 pointer 事件：按下出簇、移动插值、短按喷泉）

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                showHint = false
                if let last = lastPoint {
                    let dist = hypot(value.location.x - last.x, value.location.y - last.y)
                    let steps = max(1, Int(dist / 3))
                    for i in 0..<steps {
                        let t = CGFloat(i) / CGFloat(steps)
                        engine.spawn(at: CGPoint(
                            x: last.x + (value.location.x - last.x) * t,
                            y: last.y + (value.location.y - last.y) * t
                        ), count: 5)
                    }
                } else {
                    engine.spawn(at: value.location, count: 8)
                }
                lastPoint = value.location
            }
            .onEnded { value in
                // 位移很小视为点击 → 粒子喷泉（对应 H5 click 事件）
                if hypot(value.translation.width, value.translation.height) < 15 {
                    engine.burst(at: value.location)
                }
                lastPoint = nil
            }
    }
}
