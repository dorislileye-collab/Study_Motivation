import SwiftUI

/// 装饰页面（对应 H5 decoration-manager.js 中的 container）
enum DecorationPage: String, CaseIterable {
    case home, calendar, timer, game, mine
}

/// 装饰动画类型（对应 H5 中各 position 的 CSS 动画）
enum DecorationAnimation {
    case still       // 静止摆放
    case float       // 上下轻柔浮动（deco-gentle-bounce）
    case sway        // 左右摇摆（deco-sway）
    case peek        // 角落探头（deco-peek）
    case flyAround   // 小范围绕飞（deco-fly-around）
    case petalFall   // 花瓣飘落（整层粒子，deco-petal-fall）
    case butterfly   // 蝴蝶随机路径飞舞（deco-butterfly-float / deco-bg-float-light）
    case batFly      // 蝙蝠 emoji 横飞（deco-bat）
    case floatGroup  // 群体漂浮（deco-bg-float / crush-floating）
}

/// 单条页面装饰描述：放什么图、在哪、怎么动
/// 页面拿到后交给 PageDecorationLayer 一次性渲染
struct DecorationSpec {
    var imageName: String? = nil          // Sketches 资源名（不含扩展名），nil 时用 emoji
    var emoji: String? = nil              // 蝙蝠等 emoji 装饰
    var animation: DecorationAnimation = .still
    var alignment: Alignment = .topTrailing
    var size: CGSize = CGSize(width: 50, height: 50)
    var opacity: Double = 0.6
    var offset: CGSize = .zero            // 相对对齐点的额外偏移（正 x 向右、正 y 向下）
    var inverted: Bool = false            // 深海主题：反色 + screen 混合，线条发光
    var flipHorizontal: Bool = false      // 水平镜像（如游戏页右侧装饰）
    var count: Int = 1                    // 粒子类装饰的数量
    var duration: Double = 4              // 动画时长（秒）
    var fullWidth: Bool = false           // 横向铺满（城市天际线）
}

/// 装饰管理器 —— 对应 H5 版 src/decoration-manager.js
/// 纯查询层：不持有状态，所有结果由 ThemeManager.shared 的衣柜装备决定。
/// 视图层通过 PageDecorationLayer（持 @EnvironmentObject ThemeManager）订阅衣柜变化自动刷新，
/// 等价于 H5 的 refreshDecorations()。
enum DecorationManager {

    private static var theme: ThemeManager { ThemeManager.shared }

    // MARK: - 查询 API（对应 H5 导出函数）

    /// 任务勾选框装饰图（task 维度，对应 H5 getTaskCheckboxImage）
    static func getTaskCheckboxImage() -> String? {
        firstMatch(.taskCheckbox)
    }

    /// 激励横幅装饰图（quote 维度，对应 H5 getQuoteDecorationImage）
    static func getQuoteDecorationImage() -> String? {
        firstMatch(.quoteRight)
    }

    /// 计时完成庆祝图（timer 维度，对应 H5 getTimerCelebrationImage）
    static func getTimerCelebrationImage() -> String? {
        firstMatch(.timerCelebration)
    }

    // MARK: - 页面级装饰描述

    /// 某页面当前应展示的全部装饰（对应 H5 refreshDecorations 中按 container 放置的部分）
    static func decorations(for page: DecorationPage) -> [DecorationSpec] {
        matchedRules(page: page).flatMap { specs(for: $0) }
    }

    /// body 级背景装饰（H5 中挂到 document.body 的规则，在 App 根视图放一层即可）
    static var backgroundDecorations: [DecorationSpec] {
        matchedRules(page: nil).flatMap { specs(for: $0) }
    }

    // MARK: - 规则表（移植自 H5 DECORATION_RULES，图片路径转为资源名）

    private enum Position: String {
        // 日历页
        case calendarTopRight = "calendar-top-right"
        case calendarBottomRight = "calendar-bottom-right"
        case calendarBottomLeft = "calendar-bottom-left"
        case calendarBatFly = "calendar-bat-fly"
        // 首页（含查询型）
        case quoteRight = "quote-right"
        case taskCheckbox = "task-checkbox"
        case homeCornerTL = "home-corner-tl"
        case homeCornerTR = "home-corner-tr"
        case homeCornerBR = "home-corner-br"
        case homeFloating = "home-floating"
        // body 背景层
        case bgFloating = "bg-floating"
        case bgFloatingLight = "bg-floating-light"
        case bgPetalFall = "bg-petal-fall"
        case bgBottom = "bg-bottom"
        // 游戏页
        case gameBottomRight = "game-bottom-right"
        case gameSides = "game-sides"
        case gameTopPetals = "game-top-petals"
        case gameTopRightFly = "game-top-right-fly"
        case gameBottomLeft = "game-bottom-left"
        case gameWatching = "game-watching"
        case crushFloating = "crush-floating"
        // 计时器页
        case timerCelebration = "timer-celebration"
        case timerCornerDeco = "timer-corner-deco"
        case timerFloating = "timer-floating"
        case timerBottomDeco = "timer-bottom-deco"
        // 我的页
        case mineHeaderDeco = "mine-header-deco"
        case mineCornerDeco = "mine-corner-deco"
        case mineCornerTL = "mine-corner-tl"
        case mineFloatingDeco = "mine-floating-deco"
    }

    private struct Rule {
        let image: String?          // 资源名；nil 表示纯 emoji 动画（蝙蝠）
        let position: Position
        let theme: String           // 触发主题 id
        let dimension: WardrobeDimension
        let page: DecorationPage?   // nil = body 级
    }

    private static let rules: [Rule] = [
        // ===== 日历页 =====
        Rule(image: "bear-head",      position: .calendarTopRight,    theme: "bear",        dimension: .calendar, page: .calendar),
        Rule(image: "cat-head",       position: .calendarTopRight,    theme: "cat",         dimension: .calendar, page: .calendar),
        Rule(image: "seashell",       position: .calendarBottomRight, theme: "beach",       dimension: .calendar, page: .calendar),
        Rule(image: nil,              position: .calendarBatFly,      theme: "gothic",      dimension: .calendar, page: .calendar),
        Rule(image: "potted-plant",   position: .calendarBottomLeft,  theme: "springgreen", dimension: .calendar, page: .calendar),
        Rule(image: "crab",           position: .calendarBottomLeft,  theme: "beach",       dimension: .calendar, page: .calendar),

        // ===== 首页 =====
        Rule(image: "fish-snack",     position: .quoteRight,          theme: "cat",         dimension: .quote,    page: .home),
        Rule(image: "bear-paw",       position: .taskCheckbox,        theme: "bear",        dimension: .task,     page: .home),
        Rule(image: "cat-paw",        position: .taskCheckbox,        theme: "cat",         dimension: .task,     page: .home),
        Rule(image: "cherry-blossom", position: .homeCornerTL,        theme: "sakura",      dimension: .bg,       page: .home),
        Rule(image: "butterfly",      position: .homeFloating,        theme: "springgreen", dimension: .bg,       page: .home),
        Rule(image: "palm-leaf",      position: .homeCornerTR,        theme: "beach",       dimension: .bg,       page: .home),
        Rule(image: "bear-cheer",     position: .homeCornerBR,        theme: "bear",        dimension: .bg,       page: .home),

        // ===== body 背景层 =====
        Rule(image: "jellyfish",      position: .bgFloating,          theme: "deepsea",     dimension: .bg,       page: nil),
        Rule(image: "city-skyline",   position: .bgBottom,            theme: "cyber",       dimension: .bg,       page: nil),
        Rule(image: "butterfly",      position: .bgFloatingLight,     theme: "springgreen", dimension: .bg,       page: nil),
        Rule(image: "cherry-blossom", position: .bgPetalFall,         theme: "sakura",      dimension: .bg,       page: nil),

        // ===== 游戏页（含情绪粉碎机 crush-floating，H5 中同在 page-game 容器）=====
        Rule(image: "crab",           position: .gameBottomRight,     theme: "beach",       dimension: .game,     page: .game),
        Rule(image: "palm-leaf",      position: .gameSides,           theme: "beach",       dimension: .game,     page: .game),
        Rule(image: "cherry-blossom", position: .gameTopPetals,       theme: "sakura",      dimension: .game,     page: .game),
        Rule(image: "butterfly",      position: .gameTopRightFly,     theme: "springgreen", dimension: .game,     page: .game),
        Rule(image: "potted-plant",   position: .gameBottomLeft,      theme: "wood",        dimension: .game,     page: .game),
        Rule(image: "cat-head",       position: .gameWatching,        theme: "cat",         dimension: .game,     page: .game),
        Rule(image: "bear-head",      position: .gameWatching,        theme: "bear",        dimension: .game,     page: .game),
        Rule(image: "butterfly",      position: .crushFloating,       theme: "springgreen", dimension: .game,     page: .game),
        Rule(image: "jellyfish",      position: .crushFloating,       theme: "deepsea",     dimension: .game,     page: .game),

        // ===== 计时器页 =====
        Rule(image: "bear-cheer",     position: .timerCelebration,    theme: "bear",        dimension: .timer,    page: .timer),
        Rule(image: "cat-paw",        position: .timerCornerDeco,     theme: "cat",         dimension: .timer,    page: .timer),
        Rule(image: "bear-paw",       position: .timerCornerDeco,     theme: "bear",        dimension: .timer,    page: .timer),
        Rule(image: "fish-snack",     position: .timerFloating,       theme: "cat",         dimension: .timer,    page: .timer),
        Rule(image: "seashell",       position: .timerBottomDeco,     theme: "beach",       dimension: .timer,    page: .timer),
        Rule(image: "potted-plant",   position: .timerBottomDeco,     theme: "wood",        dimension: .timer,    page: .timer),

        // ===== 我的页面 =====
        Rule(image: "bear-head",      position: .mineHeaderDeco,      theme: "bear",        dimension: .bg,       page: .mine),
        Rule(image: "cat-head",       position: .mineHeaderDeco,      theme: "cat",         dimension: .bg,       page: .mine),
        Rule(image: "crab",           position: .mineCornerDeco,      theme: "beach",       dimension: .bg,       page: .mine),
        Rule(image: "butterfly",      position: .mineFloatingDeco,    theme: "springgreen", dimension: .bg,       page: .mine),
        Rule(image: "cherry-blossom", position: .mineCornerTL,        theme: "sakura",      dimension: .bg,       page: .mine),
    ]

    /// 查询型装饰：取第一条命中规则的图片（对应 H5 三个 get 函数的实现）
    private static func firstMatch(_ position: Position) -> String? {
        for rule in rules where rule.position == position {
            if theme.equippedTheme(for: rule.dimension).id == rule.theme {
                return rule.image
            }
        }
        return nil
    }

    /// 页面命中的规则（排除查询型 position，它们由对应页面通过 get API 单独取用）
    private static func matchedRules(page: DecorationPage?) -> [Rule] {
        rules.filter { rule in
            guard rule.page == page else { return false }
            switch rule.position {
            case .taskCheckbox, .quoteRight, .timerCelebration:
                return false
            default:
                break
            }
            return theme.equippedTheme(for: rule.dimension).id == rule.theme
        }
    }

    // MARK: - 规则 → 装饰描述（尺寸/透明度/时长移植自 H5 applyPositionStyle 及各创建函数）

    private static func specs(for rule: Rule) -> [DecorationSpec] {
        switch rule.position {
        // ----- 日历页 -----
        case .calendarTopRight:
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .topTrailing,
                                   size: .init(width: 50, height: 50), opacity: 0.7,
                                   offset: .init(width: -8, height: 8))]
        case .calendarBottomRight:
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .bottomTrailing,
                                   size: .init(width: 50, height: 50), opacity: 0.7,
                                   offset: .init(width: -10, height: -10))]
        case .calendarBottomLeft:
            // H5: bottom 10 left 10, 50x50, opacity 0.7
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .bottomLeading,
                                   size: .init(width: 50, height: 50), opacity: 0.7,
                                   offset: .init(width: 10, height: -10))]
        case .calendarBatFly:
            // H5: 2 只蝙蝠 emoji 横飞，间隔 4s
            return [DecorationSpec(emoji: "🦇", animation: .batFly, count: 2)]

        // ----- 首页 -----
        case .homeCornerTL:
            // H5: top -5 left -5, 80x80, opacity 0.6
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .topLeading,
                                   size: .init(width: 80, height: 80), opacity: 0.6,
                                   offset: .init(width: -5, height: -5))]
        case .homeCornerTR:
            // H5: top -5 right -10, 70x90, opacity 0.5
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .topTrailing,
                                   size: .init(width: 70, height: 90), opacity: 0.5,
                                   offset: .init(width: 10, height: -5))]
        case .homeCornerBR:
            // H5: bottom 60 right 5, 55x55, opacity 0.5, gentle-bounce 4s
            return [DecorationSpec(imageName: rule.image, animation: .float, alignment: .bottomTrailing,
                                   size: .init(width: 55, height: 55), opacity: 0.5,
                                   offset: .init(width: -5, height: -60), duration: 4)]
        case .homeFloating:
            // H5 createButterflyFloat: 3 只蝴蝶随机位置飘动
            return [DecorationSpec(imageName: rule.image, animation: .butterfly, count: 3)]

        // ----- body 背景层 -----
        case .bgFloating:
            // H5 createFloatingBackground: 4 个水母，反色 + screen 发光
            return [DecorationSpec(imageName: rule.image, animation: .floatGroup,
                                   opacity: 0.5, inverted: true, count: 4)]
        case .bgFloatingLight:
            // H5 createFloatingLight: 5 只轻盈漂浮蝴蝶
            return [DecorationSpec(imageName: rule.image, animation: .butterfly, count: 5)]
        case .bgPetalFall:
            // H5 createPetalFall: 8 片花瓣飘落
            return [DecorationSpec(imageName: rule.image, animation: .petalFall, count: 8)]
        case .bgBottom:
            // H5 createBackgroundBottom: 底部城市天际线，横向铺满
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .bottom,
                                   size: .init(width: 0, height: 140), opacity: 0.5, fullWidth: true)]

        // ----- 游戏页 -----
        case .gameBottomRight:
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .bottomTrailing,
                                   size: .init(width: 50, height: 50), opacity: 0.7,
                                   offset: .init(width: -10, height: -10))]
        case .gameBottomLeft:
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .bottomLeading,
                                   size: .init(width: 50, height: 50), opacity: 0.7,
                                   offset: .init(width: 10, height: -10))]
        case .gameSides:
            // H5 createGameSidesDecoration: 左右各一片叶子，右侧水平镜像
            return [
                DecorationSpec(imageName: rule.image, animation: .still, alignment: .leading,
                               size: .init(width: 60, height: 60), opacity: 0.6,
                               offset: .init(width: 6, height: 0)),
                DecorationSpec(imageName: rule.image, animation: .still, alignment: .trailing,
                               size: .init(width: 60, height: 60), opacity: 0.6,
                               offset: .init(width: -6, height: 0), flipHorizontal: true),
            ]
        case .gameTopPetals:
            // H5 createPetalAnimation: 顶部樱花枝 + 10 片 CSS 花瓣飘落
            return [
                DecorationSpec(imageName: rule.image, animation: .still, alignment: .top,
                               size: .init(width: 110, height: 80), opacity: 0.8,
                               offset: .init(width: 0, height: 4)),
                DecorationSpec(imageName: rule.image, animation: .petalFall, count: 10),
            ]
        case .gameTopRightFly:
            // H5: top 60 right 15, 35x35, opacity 0.7, fly-around 8s
            return [DecorationSpec(imageName: rule.image, animation: .flyAround, alignment: .topTrailing,
                                   size: .init(width: 35, height: 35), opacity: 0.7,
                                   offset: .init(width: -15, height: 60), duration: 8)]
        case .gameWatching:
            // H5 createWatchingDecoration: 角落里偷看的小动物（peek 探头近似）
            return [DecorationSpec(imageName: rule.image, animation: .peek, alignment: .topLeading,
                                   size: .init(width: 55, height: 55), opacity: 0.8,
                                   offset: .init(width: 8, height: 60), duration: 6)]
        case .crushFloating:
            // H5 createCrushFloating: 2 个低透明度漂浮物（情绪粉碎机氛围）
            return [DecorationSpec(imageName: rule.image, animation: .floatGroup,
                                   opacity: 0.3, count: 2)]

        // ----- 计时器页 -----
        case .timerCornerDeco:
            // H5: top 70 right 8, 45x45, opacity 0.5, sway 5s
            return [DecorationSpec(imageName: rule.image, animation: .sway, alignment: .topTrailing,
                                   size: .init(width: 45, height: 45), opacity: 0.5,
                                   offset: .init(width: -8, height: 70), duration: 5)]
        case .timerFloating:
            // H5 createTimerFloating: bottom 100 left 10, 35x35, gentle-bounce 5s
            return [DecorationSpec(imageName: rule.image, animation: .float, alignment: .bottomLeading,
                                   size: .init(width: 35, height: 35), opacity: 0.5,
                                   offset: .init(width: 10, height: -100), duration: 5)]
        case .timerBottomDeco:
            // H5: bottom 80 居中, 60x60, opacity 0.4
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .bottom,
                                   size: .init(width: 60, height: 60), opacity: 0.4,
                                   offset: .init(width: 0, height: -80))]

        // ----- 我的页面 -----
        case .mineHeaderDeco:
            // H5: top 5 right 10, 50x50, opacity 0.6, peek 6s
            return [DecorationSpec(imageName: rule.image, animation: .peek, alignment: .topTrailing,
                                   size: .init(width: 50, height: 50), opacity: 0.6,
                                   offset: .init(width: -10, height: 5), duration: 6)]
        case .mineCornerDeco:
            // H5: bottom 70 right 8, 45x45, opacity 0.5, sway 4s
            return [DecorationSpec(imageName: rule.image, animation: .sway, alignment: .bottomTrailing,
                                   size: .init(width: 45, height: 45), opacity: 0.5,
                                   offset: .init(width: -8, height: -70), duration: 4)]
        case .mineCornerTL:
            // H5: top 0 left 0, 70x70, opacity 0.4
            return [DecorationSpec(imageName: rule.image, animation: .still, alignment: .topLeading,
                                   size: .init(width: 70, height: 70), opacity: 0.4)]
        case .mineFloatingDeco:
            // H5 createButterflyFloat: 3 只蝴蝶随机飘动
            return [DecorationSpec(imageName: rule.image, animation: .butterfly, count: 3)]

        // ----- 查询型（不产出页面装饰）-----
        case .taskCheckbox, .quoteRight, .timerCelebration:
            return []
        }
    }
}
