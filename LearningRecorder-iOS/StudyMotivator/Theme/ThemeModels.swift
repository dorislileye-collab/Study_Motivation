import SwiftUI

/// 7 个衣柜维度（对应 H5 版 themes.js 的 WARDROBE_DIMENSIONS）
enum WardrobeDimension: String, Codable, CaseIterable, Identifiable {
    case font, calendar, task, bg, quote, timer, game

    var id: String { rawValue }

    var name: String {
        switch self {
        case .font: return "全局字体"
        case .calendar: return "日历配饰"
        case .task: return "待办配饰"
        case .bg: return "整体背景"
        case .quote: return "激励语句"
        case .timer: return "计时面板"
        case .game: return "游戏面板"
        }
    }

    var icon: String {
        switch self {
        case .font: return "🔤"
        case .calendar: return "📅"
        case .task: return "📋"
        case .bg: return "🎨"
        case .quote: return "💬"
        case .timer: return "⏱"
        case .game: return "🎮"
        }
    }
}

/// 主题等级（对应 H5 版 TIERS）
enum ThemeTier: String, Codable, CaseIterable {
    case `default`, normal, advanced, high, top, legend

    var name: String {
        switch self {
        case .default: return "默认"
        case .normal: return "普通"
        case .advanced: return "进阶"
        case .high: return "高阶"
        case .top: return "顶级"
        case .legend: return "传说"
        }
    }

    var colorHex: String {
        switch self {
        case .default: return "#8B6914"
        case .normal: return "#607D8B"
        case .advanced: return "#0096B4"
        case .high: return "#7B1FA2"
        case .top: return "#E65100"
        case .legend: return "#FF006E"
        }
    }

    var color: Color { Color.css(colorHex) }

    /// 单件配饰价格
    var singlePrice: Int {
        switch self {
        case .default: return 0
        case .normal: return 50
        case .advanced: return 80
        case .high: return 120
        case .top: return 170
        case .legend: return 250
        }
    }
}

/// 字体风格（iOS 端用系统字体族近似 H5 的 web font）
enum AppFontDesign: String, Codable {
    case system, rounded, serif, monospaced, heavy

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .system: return .system(size: size, weight: weight)
        case .rounded: return .system(size: size, weight: weight, design: .rounded)
        case .serif: return .system(size: size, weight: weight, design: .serif)
        case .monospaced: return .system(size: size, weight: weight, design: .monospaced)
        case .heavy: return .system(size: size, weight: weight == .regular ? .black : weight)
        }
    }
}

// MARK: - 各维度样式（颜色统一用 CSS 字符串存储，Color.css() 解析）

struct CalendarStyle: Codable, Equatable {
    var cellBg: String
    var cellBorder: String
    var radius: CGFloat
    var dot: String
    var decorationImage: String? = nil
}

struct TaskStyle: Codable, Equatable {
    var bg: String
    /// 渐变结束色（H5 中部分主题为线性渐变），nil 表示纯色
    var bgEnd: String? = nil
    var border: String
    var radius: CGFloat
    var check: String
    var decorationImage: String? = nil
}

struct BackgroundStyle: Codable, Equatable {
    var bgColor: String
    /// 背景渐变色标
    var gradient: [String]
    var textPrimary: String
    var textSecondary: String
    var cardBg: String
    var cardBorder: String
}

struct QuoteStyle: Codable, Equatable {
    var color: String
    var glow: Bool
}

struct TimerStyle: Codable, Equatable {
    var bg: String
    var border: String
    var number: String
    var glow: Bool
}

struct GameStyle: Codable, Equatable {
    var bg: String
    var border: String
}

/// 一个主题的全部配饰（对应 H5 版 theme.accessories）
struct ThemeAccessories: Codable, Equatable {
    var font: AppFontDesign
    var calendar: CalendarStyle
    var task: TaskStyle
    var bg: BackgroundStyle
    var quote: QuoteStyle
    var timer: TimerStyle
    var game: GameStyle

    /// 按维度取装饰图片资源名
    func decorationImage(for dim: WardrobeDimension) -> String? {
        switch dim {
        case .calendar: return calendar.decorationImage
        case .task: return task.decorationImage
        default: return nil
        }
    }
}

/// 主题（对应 H5 版 THEMES 条目）
struct AppTheme: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var emoji: String
    var tier: ThemeTier
    var btnColorHex: String
    var price: Int
    var accessories: ThemeAccessories

    var btnColor: Color { Color.css(btnColorHex) }

    /// 整套价格 = 配饰数 × 单价 × 0.85（向下取整）
    var bundlePrice: Int {
        Int(Double(7 * tier.singlePrice) * 0.85)
    }
}
