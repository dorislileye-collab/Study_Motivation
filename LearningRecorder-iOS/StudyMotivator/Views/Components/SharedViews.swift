import SwiftUI

/// 主题渐变背景（所有页面共用，对应 H5 的 --bg-gradient）
struct ThemedBackground: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        let stops = theme.backgroundStyle.gradient
        let colors = stops.compactMap { Color(css: $0) }
        if colors.count >= 2 {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        } else {
            Color.css(theme.backgroundStyle.bgColor).ignoresSafeArea()
        }
    }
}

/// 主题卡片容器（对应 H5 的 --card-bg / --card-border）
struct ThemedCard<Content: View>: View {
    @EnvironmentObject private var theme: ThemeManager
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.css(theme.backgroundStyle.cardBg))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
            )
    }
}

/// 加载 Resources/Sketches 中的手绘装饰图
struct SketchImage: View {
    let name: String?

    var body: some View {
        if let name, let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
    }
}

/// 主文字 / 次要文字颜色快捷访问
extension ThemeManager {
    var textPrimary: Color { Color.css(backgroundStyle.textPrimary) }
    var textSecondary: Color { Color.css(backgroundStyle.textSecondary) }
}
