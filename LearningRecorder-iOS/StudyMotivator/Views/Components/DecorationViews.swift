import SwiftUI

// MARK: - 确定性伪随机（粒子装饰用，避免每次渲染位置跳变）

/// 由整数种子生成 0..<1 的确定性伪随机值
private func decoHash(_ seed: Int, _ salt: Double) -> Double {
    let x = abs(sin(Double(seed) * 12.9898 + salt * 78.233) * 43758.5453)
    return x - x.rounded(.down)
}

// MARK: - 浮动装饰（上下浮动 / 摇摆 / 探头 / 绕飞）

/// 单个装饰图 + 循环动画。对应 H5 的 deco-gentle-bounce / deco-sway / deco-peek / deco-fly-around
struct FloatDecoration: View {
    enum Motion {
        case still      // 静止
        case float      // 上下轻柔浮动
        case sway       // 左右摇摆
        case peek       // 探头（摇晃 + 轻微上下）
        case flyAround  // 小范围绕飞
    }

    let imageName: String?
    var emoji: String? = nil
    var motion: Motion = .float
    var width: CGFloat = 50
    var height: CGFloat? = nil
    var opacity: Double = 0.6
    var inverted: Bool = false        // 深海主题：反色 + screen 混合发光
    var flipHorizontal: Bool = false
    var contentOffset: CGSize = .zero // 相对对齐点的固定偏移
    var amplitude: CGFloat = 8
    var duration: Double = 4

    @State private var animating = false

    var body: some View {
        Group {
            if inverted {
                base.colorInvert().blendMode(.screen)
            } else {
                base
            }
        }
        .offset(x: contentOffset.width + xDrift, y: contentOffset.height + yDrift)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            guard motion != .still else { return }
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
        .allowsHitTesting(false)
    }

    private var base: some View {
        Group {
            if let emoji {
                Text(emoji).font(.system(size: width * 0.8))
            } else {
                SketchImage(name: imageName)
            }
        }
        .frame(width: width, height: height ?? width)
        .scaleEffect(x: flipHorizontal ? -1 : 1, y: 1)
        .opacity(opacity)
    }

    private var yDrift: CGFloat {
        switch motion {
        case .float, .peek: return animating ? -amplitude : amplitude
        case .flyAround:    return animating ? -6 : 6
        case .still, .sway: return 0
        }
    }

    private var xDrift: CGFloat {
        motion == .flyAround ? (animating ? 10 : -10) : 0
    }

    private var rotation: Double {
        switch motion {
        case .sway: return animating ? 6 : -6
        case .peek: return animating ? 8 : -8
        default:    return 0
        }
    }
}

// MARK: - 飘落装饰（樱花花瓣等，Canvas + TimelineView）

/// 花瓣/碎片从上往下飘落，带左右摇摆和自转。对应 H5 的 deco-petal-fall / deco-petal-css
struct FallingPetals: View {
    var imageName: String? = "cherry-blossom"
    var count: Int = 8
    /// 无图时的兜底花瓣颜色
    var tint: Color = Color(red: 1.0, green: 0.72, blue: 0.82)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let ui = imageName.flatMap { UIImage(named: $0) }
                for i in 0..<count {
                    // H5: left 随机、delay 0~10s、duration 8~14s、宽度 12~24px
                    let x0 = decoHash(i, 1.0) * canvasSize.width
                    let duration = 8 + decoHash(i, 2.0) * 6
                    let delay = decoHash(i, 3.0) * duration
                    let progress = (t + delay).truncatingRemainder(dividingBy: duration) / duration
                    let petalSize = 12 + decoHash(i, 4.0) * 12
                    let x = x0 + sin(progress * .pi * 4 + Double(i)) * 24
                    let y = -30 + progress * (canvasSize.height + 60)

                    var ctx = context
                    ctx.opacity = 0.85
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(progress * .pi * 2 + Double(i)))
                    let rect = CGRect(x: -petalSize / 2, y: -petalSize / 2,
                                      width: petalSize, height: petalSize)
                    if let ui {
                        ctx.draw(Image(uiImage: ui), in: rect)
                    } else {
                        ctx.fill(Path(ellipseIn: rect), with: .color(tint))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 蝴蝶飞舞（随机路径飘动，Canvas + TimelineView）

/// 若干只蝴蝶沿平滑随机路径飞舞。对应 H5 的 deco-butterfly-float / deco-bg-float-light
struct ButterflyDecoration: View {
    var imageName: String = "butterfly"
    var count: Int = 3
    var opacity: Double = 0.85

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                guard let ui = UIImage(named: imageName) else { return }
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    // H5: 起点 left 15%~85% / top 20%~70%，周期 6~10s，宽度 25~40px
                    let baseX = (0.15 + decoHash(i, 5.0) * 0.7) * canvasSize.width
                    let baseY = (0.20 + decoHash(i, 6.0) * 0.5) * canvasSize.height
                    let period = 6 + decoHash(i, 7.0) * 4
                    let w = 25 + decoHash(i, 8.0) * 15
                    let phase = Double(i) * 2.1
                    let angle = t / period * .pi * 2 + phase
                    // 两个不同频率的正弦叠加出无规则感的飘动路径
                    let x = baseX + sin(angle) * canvasSize.width * 0.12
                            + sin(angle * 3 + phase) * 10
                    let y = baseY + cos(angle * 1.3) * canvasSize.height * 0.08
                    let flap = sin(t * 10 + phase) * 0.15

                    var ctx = context
                    ctx.opacity = opacity
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(flap))
                    ctx.draw(Image(uiImage: ui),
                             in: CGRect(x: -w / 2, y: -w / 2, width: w, height: w))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 群体漂浮（水母 / 情绪粉碎机氛围）

/// 若干装饰图散布在区域内各自上下漂浮。对应 H5 的 deco-bg-float / crush-floating
struct FloatingGroupDecoration: View {
    var imageName: String
    var count: Int = 4
    var opacity: Double = 0.5
    var inverted: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    // H5: left 10%~90%、尺寸 30~60px、周期 12~20s（crush 场景 25~40px、5~8s）
                    FloatDecoration(
                        imageName: imageName,
                        motion: .float,
                        width: 25 + decoHash(i, 9.0) * 35,
                        opacity: opacity,
                        inverted: inverted,
                        amplitude: 10,
                        duration: (inverted ? 12 : 5) + decoHash(i, 10.0) * 8
                    )
                    .position(x: (0.1 + decoHash(i, 11.0) * 0.8) * geo.size.width,
                              y: (0.15 + decoHash(i, 12.0) * 0.7) * geo.size.height)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 蝙蝠横飞（暗黑哥特日历页）

/// emoji 从屏幕左侧飞到右侧循环。对应 H5 的 deco-bat
private struct BatFlyLayer: View {
    var emoji: String = "🦇"
    var count: Int = 2

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    // H5: 2 只蝙蝠，动画间隔 4s，top 8 / 22
                    let duration = 10.0
                    let progress = (t / duration + Double(i) * 0.4)
                        .truncatingRemainder(dividingBy: 1)
                    let x = -40 + progress * (canvasSize.width + 80)
                    let y = 24 + Double(i) * 30 + sin(progress * .pi * 6) * 8

                    var ctx = context
                    ctx.opacity = 0.8
                    ctx.translateBy(x: x, y: y)
                    ctx.draw(Text(emoji).font(.system(size: 22)), at: .zero)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 单条装饰渲染

/// 把一个 DecorationSpec 渲染成视图（内部使用）
private struct DecorationSpecView: View {
    let spec: DecorationSpec

    var body: some View {
        switch spec.animation {
        case .petalFall:
            FallingPetals(imageName: spec.imageName, count: spec.count)
        case .butterfly:
            ButterflyDecoration(imageName: spec.imageName ?? "butterfly", count: spec.count)
        case .batFly:
            BatFlyLayer(emoji: spec.emoji ?? "🦇", count: spec.count)
        case .floatGroup:
            FloatingGroupDecoration(imageName: spec.imageName ?? "",
                                    count: spec.count, opacity: spec.opacity,
                                    inverted: spec.inverted)
        case .still, .float, .sway, .peek, .flyAround:
            placedSingle
        }
    }

    /// 常规定位装饰：对齐到页面某个角落 + 固定偏移
    private var placedSingle: some View {
        FloatDecoration(
            imageName: spec.imageName,
            emoji: spec.emoji,
            motion: motion,
            width: spec.size.width,
            height: spec.size.height,
            opacity: spec.opacity,
            inverted: spec.inverted,
            flipHorizontal: spec.flipHorizontal,
            contentOffset: spec.offset,
            duration: spec.duration
        )
        .frame(maxWidth: spec.fullWidth ? .infinity : nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: spec.alignment)
    }

    private var motion: FloatDecoration.Motion {
        switch spec.animation {
        case .float:     return .float
        case .sway:      return .sway
        case .peek:      return .peek
        case .flyAround: return .flyAround
        default:         return .still
        }
    }
}

// MARK: - 页面装饰层

/// 页面级装饰层：根据当前衣柜装备渲染某页面的全部装饰。
/// 用法：页面根 ZStack 里放一层 `PageDecorationLayer(page: .home)`，
/// 或用修饰符 `.pageDecorations(.home)`。等价于 H5 的 refreshDecorations()。
struct PageDecorationLayer: View {
    let page: DecorationPage
    /// 订阅衣柜变化，装备切换后自动刷新装饰
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        let specs = DecorationManager.decorations(for: page)
        ZStack {
            ForEach(Array(specs.enumerated()), id: \.offset) { _, spec in
                DecorationSpecView(spec: spec)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// body 级背景装饰层（H5 中挂到 document.body 的水母/天际线/花瓣等），
/// 建议放在 App 根视图 ThemedBackground 之上一层，全局只放一次。
struct BackgroundDecorationLayer: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        let specs = DecorationManager.backgroundDecorations
        ZStack {
            ForEach(Array(specs.enumerated()), id: \.offset) { _, spec in
                DecorationSpecView(spec: spec)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// 在页面上叠加当前主题的页面装饰层
    func pageDecorations(_ page: DecorationPage) -> some View {
        overlay(PageDecorationLayer(page: page))
    }
}

// MARK: - 任务勾选框装饰（对应 H5 applyTaskCheckboxDecoration）

/// 任务勾选框内的装饰图（猫爪/熊爪）。
/// H5 行为：未完成时透明度 0.4 + 半灰度，完成后实色显示。
/// 未装备 task 维度装饰时显示系统对勾，由调用方决定勾选框底色。
struct TaskCheckboxDecoration: View {
    let isCompleted: Bool
    var size: CGFloat = 15
    /// 无装饰图时兜底对勾的颜色（一般传 theme.taskStyle.check 的解析色）
    var checkColor: Color = .green

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        if let image = DecorationManager.getTaskCheckboxImage() {
            SketchImage(name: image)
                .frame(width: size, height: size)
                .opacity(isCompleted ? 1 : 0.4)
                .grayscale(isCompleted ? 0 : 0.5)
        } else if isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.8, weight: .bold))
                .foregroundStyle(checkColor)
        }
    }
}
