import SwiftUI
import UIKit

/// 泡泡星球引擎（对应 H5 bubble.js：摇摆漂浮、墙壁反弹、泡泡间弹性碰撞、双击戳破）
final class BubbleEngine: ObservableObject {
    struct Bubble {
        let id = UUID()
        var x, y, r, vx, vy: CGFloat
        var hue: Double   // 0...360，对应 H5 的 hsla 色相
        var wobble: Double
    }

    /// 戳破爆裂粒子（对应 H5 Particle）
    struct Shard {
        var x, y, vx, vy, r: CGFloat
        var hue: Double
        var life: Double
        var decay: Double
    }

    private(set) var bubbles: [Bubble] = []
    private(set) var shards: [Shard] = []
    /// 已戳破数量（得分显示）
    @Published private(set) var popped = 0

    private var lastTapTime: Date = .distantPast
    private var lastTapPos: CGPoint = .zero
    private var started = false

    private let maxBubbles = 30
    private let popper = UIImpactFeedbackGenerator(style: .light)

    private func makeBubble(x: CGFloat, y: CGFloat) -> Bubble {
        Bubble(
            x: x, y: y,
            r: 15 + CGFloat.random(in: 0...25),
            vx: CGFloat.random(in: -1.5...1.5),
            vy: CGFloat.random(in: -1.5...1.5),
            hue: Double.random(in: 0...360),
            wobble: Double.random(in: 0...(2 * .pi))
        )
    }

    /// 初始 5 个泡泡（对应 H5 initBubbleGame）
    func ensureStarted(size: CGSize) {
        guard !started, size.width > 0, size.height > 0 else { return }
        started = true
        for _ in 0..<5 {
            bubbles.append(makeBubble(
                x: size.width * CGFloat.random(in: 0.2...0.8),
                y: size.height * CGFloat.random(in: 0.2...0.8)
            ))
        }
    }

    /// 点击处理（对应 H5 handleTap：300ms 内且位移 <30 视为双击戳破，否则生成新泡泡）
    func tap(at point: CGPoint) {
        let now = Date()
        let isDoubleTap = now.timeIntervalSince(lastTapTime) < 0.3
            && hypot(point.x - lastTapPos.x, point.y - lastTapPos.y) < 30

        if isDoubleTap, let idx = bubbles.lastIndex(where: {
            hypot($0.x - point.x, $0.y - point.y) < $0.r
        }) {
            pop(at: idx)
        } else if bubbles.count < maxBubbles {
            bubbles.append(makeBubble(x: point.x, y: point.y))
        }

        lastTapTime = now
        lastTapPos = point
    }

    /// 戳破：爆裂 12 个粒子（对应 H5 popBubble）
    private func pop(at index: Int) {
        let b = bubbles.remove(at: index)
        for _ in 0..<12 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = 2 + CGFloat.random(in: 0...5)
            shards.append(Shard(
                x: b.x, y: b.y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                r: 2 + CGFloat.random(in: 0...4),
                hue: b.hue,
                life: 1,
                decay: Double.random(in: 0.02...0.05)
            ))
        }
        popped += 1
        popper.impactOccurred()
    }

    /// 每帧物理更新（对应 H5 Bubble.update + checkCollisions + Particle.update）
    func update(size: CGSize) {
        for i in bubbles.indices {
            bubbles[i].wobble += 0.05
            bubbles[i].x += bubbles[i].vx + sin(bubbles[i].wobble) * 0.3
            bubbles[i].y += bubbles[i].vy + cos(bubbles[i].wobble) * 0.2

            let r = bubbles[i].r
            if bubbles[i].x - r < 0 { bubbles[i].x = r; bubbles[i].vx = abs(bubbles[i].vx) * 0.8 }
            if bubbles[i].x + r > size.width { bubbles[i].x = size.width - r; bubbles[i].vx = -abs(bubbles[i].vx) * 0.8 }
            if bubbles[i].y - r < 0 { bubbles[i].y = r; bubbles[i].vy = abs(bubbles[i].vy) * 0.8 }
            if bubbles[i].y + r > size.height { bubbles[i].y = size.height - r; bubbles[i].vy = -abs(bubbles[i].vy) * 0.8 }
        }

        // 泡泡间弹性碰撞（对应 H5 checkCollisions）
        for i in 0..<bubbles.count {
            for j in (i + 1)..<bubbles.count {
                var a = bubbles[i]
                var b = bubbles[j]
                let dx = b.x - a.x
                let dy = b.y - a.y
                let dist = hypot(dx, dy)
                let minDist = a.r + b.r
                guard dist < minDist, dist > 0 else { continue }

                // 分离重叠
                let overlap = (minDist - dist) / 2
                let nx = dx / dist
                let ny = dy / dist
                a.x -= nx * overlap
                a.y -= ny * overlap
                b.x += nx * overlap
                b.y += ny * overlap

                // 弹性碰撞（各承担一半冲量）
                let dot = (a.vx - b.vx) * nx + (a.vy - b.vy) * ny
                if dot > 0 {
                    a.vx -= dot * nx * 0.5
                    a.vy -= dot * ny * 0.5
                    b.vx += dot * nx * 0.5
                    b.vy += dot * ny * 0.5
                }
                bubbles[i] = a
                bubbles[j] = b
            }
        }

        for i in shards.indices {
            shards[i].x += shards[i].vx
            shards[i].y += shards[i].vy
            shards[i].vy += 0.1 // 重力
            shards[i].life -= shards[i].decay
        }
        shards.removeAll { $0.life <= 0 }
    }

    func draw(context: inout GraphicsContext, size: CGSize) {
        for b in bubbles {
            let rect = CGRect(x: b.x - b.r, y: b.y - b.r, width: b.r * 2, height: b.r * 2)
            let circle = Path(ellipseIn: rect)

            // 径向渐变主体（对应 H5 createRadialGradient，高光点偏移左上）
            let gradient = Gradient(colors: [
                Color(hue: b.hue / 360, saturation: 0.8, brightness: 0.92).opacity(0.8),
                Color(hue: b.hue / 360, saturation: 0.7, brightness: 0.75).opacity(0.6),
                Color(hue: b.hue / 360, saturation: 0.7, brightness: 0.6).opacity(0.3)
            ])
            context.fill(circle, with: .radialGradient(
                gradient,
                center: CGPoint(x: b.x - b.r * 0.3, y: b.y - b.r * 0.3),
                startRadius: 0,
                endRadius: b.r
            ))

            // 边框
            context.stroke(circle, with: .color(
                Color(hue: b.hue / 360, saturation: 0.7, brightness: 0.85).opacity(0.9)
            ), lineWidth: 1.5)

            // 高光点
            let hr = b.r * 0.15
            context.fill(
                Path(ellipseIn: CGRect(x: b.x - b.r * 0.3 - hr, y: b.y - b.r * 0.3 - hr, width: hr * 2, height: hr * 2)),
                with: .color(.white.opacity(0.7))
            )
        }

        for s in shards {
            let r = s.r * CGFloat(max(0, s.life))
            guard r > 0 else { continue }
            context.fill(
                Path(ellipseIn: CGRect(x: s.x - r, y: s.y - r, width: r * 2, height: r * 2)),
                with: .color(Color(hue: s.hue / 360, saturation: 0.7, brightness: 0.75).opacity(max(0, s.life)))
            )
        }
    }
}

// MARK: - 泡泡星球（对应 H5 game.js enterGame('bubble') + bubble.js）

struct BubbleGameView: View {
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var engine = BubbleEngine()

    var body: some View {
        GameScreen(title: GameKind.bubble.titleWithIcon) {
            // 提示栏（对应 H5 bubble-tips）
            HStack {
                Text("点击产生泡泡 · 双击戳破")
                Spacer()
                Text("已戳破 \(engine.popped) 个")
            }
            .font(theme.fontDesign.font(size: 13))
            .foregroundStyle(theme.textSecondary)

            TimelineView(.animation) { _ in
                Canvas { ctx, size in
                    engine.ensureStarted(size: size)
                    engine.update(size: size)
                    engine.draw(context: &ctx, size: size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        engine.tap(at: value.location)
                    }
            )
        }
    }
}
