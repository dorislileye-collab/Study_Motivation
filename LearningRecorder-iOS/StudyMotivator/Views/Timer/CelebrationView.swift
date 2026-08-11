import SwiftUI

/// 全屏庆祝动画 - 对应 H5 版 src/celebration.js 的 showCelebration()
/// 80 个彩带粒子从顶部下落 + 30 个星星粒子从中心爆发（带重力），
/// 颜色表、粒子参数、透明度衰减节奏与 H5 一致；可叠加显示主题庆祝图。
struct CelebrationView: View {
    /// 持续时间（秒），H5 默认 2500ms，计时完成时用 3000ms
    var duration: TimeInterval = 2.5
    /// 主题庆祝图（Resources/Sketches 中的资源名，如 bear 主题的 bear-cheer），nil 不显示
    var imageName: String? = nil
    var onFinished: (() -> Void)? = nil

    private struct Particle {
        var x: CGFloat, y: CGFloat          // 初始位置（彩带 y 为负，从屏幕上方进入）
        var w: CGFloat, h: CGFloat
        var color: Color
        var vx: CGFloat, vy: CGFloat        // 每帧位移（60fps 基准）
        var rotation: CGFloat
        var rotationSpeed: CGFloat          // 每帧弧度
        var isStar: Bool
    }

    /// H5 的彩带颜色表
    private static let palette: [Color] = [
        "#FFD700", "#FF6B6B", "#4ECDC4", "#45B7D1",
        "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8"
    ].map { Color.css($0) }

    @State private var particles: [Particle] = []
    @State private var start = Date()
    @State private var didFinish = false
    @State private var imageBounce = false

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(start)
                let progress = duration > 0 ? min(max(elapsed / duration, 0), 1) : 1

                ZStack {
                    Canvas { ctx, _ in
                        for p in particles {
                            let frames = CGFloat(elapsed * 60)
                            let x = p.x + p.vx * frames
                            let y: CGFloat
                            let opacity: Double
                            if p.isStar {
                                // 中心爆发 + 重力（H5 gravity = 0.08/帧）
                                y = p.y + p.vy * frames + 0.5 * 0.08 * frames * frames
                                opacity = max(0, 1 - Double(progress) * 1.5)
                            } else {
                                // 彩带匀速下落，60% 后开始淡出
                                y = p.y + p.vy * frames
                                opacity = progress > 0.6 ? max(0, 1 - Double((progress - 0.6) / 0.4)) : 1
                            }
                            guard opacity > 0 else { continue }

                            var c = ctx
                            c.translateBy(x: x, y: y)
                            c.rotate(by: .radians(Double(p.rotation + p.rotationSpeed * frames)))
                            let path = p.isStar
                                ? starPath(radius: p.w / 2)
                                : Path(CGRect(x: -p.w / 2, y: -p.h / 2, width: p.w, height: p.h))
                            c.fill(path, with: .color(p.color.opacity(opacity)))
                        }
                    }

                    if let imageName {
                        SketchImage(name: imageName)
                            .frame(width: 140, height: 140)
                            .scaleEffect(imageBounce ? 1.06 : 0.94)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                       value: imageBounce)
                    }
                }
                .onChange(of: progress >= 1) {
                    if progress >= 1 && !didFinish {
                        didFinish = true
                        onFinished?()
                    }
                }
            }
            .onAppear {
                if particles.isEmpty { makeParticles(in: geo.size) }
                imageBounce = true
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// 五角星路径（对应 H5 drawStar）
    private func starPath(radius r: CGFloat) -> Path {
        var path = Path()
        let inner = r * 0.45
        for i in 0..<10 {
            let radius = i % 2 == 0 ? r : inner
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// 生成粒子（参数与 H5 完全一致）
    private func makeParticles(in size: CGSize) {
        var result: [Particle] = []
        // 彩带：顶部随机位置下落
        for _ in 0..<80 {
            result.append(Particle(
                x: CGFloat.random(in: 0...max(size.width, 1)),
                y: -20 - CGFloat.random(in: 0...200),
                w: 6 + CGFloat.random(in: 0...8),
                h: 4 + CGFloat.random(in: 0...4),
                color: Self.palette.randomElement()!,
                vx: (CGFloat.random(in: 0...1) - 0.5) * 4,
                vy: 2 + CGFloat.random(in: 0...4),
                rotation: CGFloat.random(in: 0...(2 * .pi)),
                rotationSpeed: (CGFloat.random(in: 0...1) - 0.5) * 0.2,
                isStar: false))
        }
        // 星星：从中心均匀角度爆发
        let cx = size.width / 2, cy = size.height / 2
        for i in 0..<30 {
            let angle = CGFloat(i) / 30 * 2 * .pi
            let speed = 3 + CGFloat.random(in: 0...5)
            result.append(Particle(
                x: cx, y: cy,
                w: 8 + CGFloat.random(in: 0...6),
                h: 8 + CGFloat.random(in: 0...6),
                color: Self.palette.randomElement()!,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                rotation: 0,
                rotationSpeed: (CGFloat.random(in: 0...1) - 0.5) * 0.3,
                isStar: true))
        }
        particles = result
    }
}
