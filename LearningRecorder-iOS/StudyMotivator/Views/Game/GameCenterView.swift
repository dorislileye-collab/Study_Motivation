import SwiftUI

/// 游戏规则常量与工具（对应 H5 版 game.js 的 20 分钟上限 / 冻结判断）
enum GameRules {
    /// 每日游戏时间上限：20 分钟 = 1200 秒
    static let maxGameTime = 20 * 60

    static func remaining(used: Int) -> Int { max(0, maxGameTime - used) }

    static func isFrozen(used: Int) -> Bool { used >= maxGameTime }

    /// 状态栏格式 "M:SS"（对应 H5 game.js renderGamePage 的写法）
    static func statusClock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// 游戏中头部格式 "MM:SS"（对应 H5 updateGameTimeDisplay 的写法）
    static func headerClock(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

/// 游戏条目（对应 H5 game.js 的游戏列表数据）
enum GameKind: String, Identifiable, Hashable, CaseIterable {
    case sand, bubble, crush

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sand: return "🏖️"
        case .bubble: return "🫧"
        case .crush: return "💥"
        }
    }

    var name: String {
        switch self {
        case .sand: return "沙画禅境"
        case .bubble: return "泡泡星球"
        case .crush: return "情绪粉碎机"
        }
    }

    var desc: String {
        switch self {
        case .sand: return "手指拖动画画，沙子随手指流动散开"
        case .bubble: return "点击产生彩色泡泡，物理碰撞弹跳"
        case .crush: return "写下烦恼，选择方式销毁它"
        }
    }

    var tag: String {
        switch self {
        case .sand: return "4种材质 · 无目标压力"
        case .bubble: return "物理碰撞 · 戳破爽感"
        case .crush: return "4种销毁方式 · 情绪宣泄"
        }
    }

    var titleWithIcon: String { "\(icon) \(name)" }
}

// MARK: - 游戏中心（对应 H5 game.js renderGamePage）

struct GameCenterView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager
    @State private var path: [GameKind] = []

    /// 今日完成任意 1 个任务后解锁（对应 H5 hasCompletedTask）
    /// 注意：游戏时间只在实际游玩时（GameScreen 内）累计，逛列表不扣时间
    private var hasCompletedTask: Bool {
        store.getTasksByDate(DateHelper.today).contains { $0.completed }
    }

    private var frozen: Bool { GameRules.isFrozen(used: store.gameTimeToday) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                ThemedBackground()
                PageDecorationLayer(page: .game)
                ScrollView {
                    VStack(spacing: 16) {
                        Text("🎮 解压游戏")
                            .font(theme.fontDesign.font(size: 22, weight: .bold))
                            .foregroundStyle(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        statusBar

                        if frozen {
                            frozenCard
                        } else {
                            gameList
                        }

                        if !hasCompletedTask {
                            Text("💡 完成今日任意1个任务后即可解锁游戏")
                                .font(theme.fontDesign.font(size: 14))
                                .foregroundStyle(theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GameKind.self) { kind in
                switch kind {
                case .sand: SandGameView()
                case .bubble: BubbleGameView()
                case .crush: CrushGameView()
                }
            }
        }
    }

    // MARK: 时间状态栏

    private var statusBar: some View {
        ThemedCard {
            Group {
                if hasCompletedTask {
                    Text("今日剩余：\(GameRules.statusClock(GameRules.remaining(used: store.gameTimeToday)))")
                        .foregroundStyle(theme.textPrimary)
                } else {
                    Text("🔒 完成1个任务后解锁")
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .font(theme.fontDesign.font(size: 15, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: 游戏列表（用 theme.gameStyle 的卡片配色）

    private var gameList: some View {
        VStack(spacing: 14) {
            ForEach(GameKind.allCases) { kind in
                Button {
                    guard hasCompletedTask, !frozen else { return }
                    path.append(kind)
                } label: {
                    HStack(spacing: 14) {
                        Text(kind.icon)
                            .font(.system(size: 34))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(kind.name)
                                .font(theme.fontDesign.font(size: 17, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                            Text(kind.desc)
                                .font(theme.fontDesign.font(size: 13))
                                .foregroundStyle(theme.textSecondary)
                            Text(kind.tag)
                                .font(theme.fontDesign.font(size: 11))
                                .foregroundStyle(theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.css(theme.gameStyle.border).opacity(0.25))
                                .clipShape(Capsule())
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.css(theme.gameStyle.bg))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.css(theme.gameStyle.border), lineWidth: 1.5)
                    )
                    .opacity(hasCompletedTask ? 1 : 0.5)
                }
                .buttonStyle(.plain)
                .disabled(!hasCompletedTask || frozen)
            }
        }
    }

    // MARK: 冻结状态（对应 H5 game-freeze-overlay）

    private var frozenCard: some View {
        ThemedCard(padding: 32) {
            VStack(spacing: 12) {
                Text("⏰")
                    .font(.system(size: 48))
                Text("今日游戏时间已用完")
                    .font(theme.fontDesign.font(size: 18, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("明天再来玩吧！")
                    .font(theme.fontDesign.font(size: 14))
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 游戏页公共脚手架（头部 + 计时 + 冻结遮罩）

/// 游戏页容器：对应 H5 game.js enterGame 生成的 game-playing-page 结构。
/// 负责：返回按钮、标题、剩余时间显示（不足 5 分钟变红）、每秒 +1 游戏时间、超时冻结遮罩。
struct GameScreen<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var remaining: Int { GameRules.remaining(used: store.gameTimeToday) }
    private var frozen: Bool { GameRules.isFrozen(used: store.gameTimeToday) }

    var body: some View {
        ZStack {
            ThemedBackground()
            VStack(spacing: 12) {
                header
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()

            if frozen {
                GameFreezeOverlay {
                    dismiss()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(ticker) { _ in
            guard !frozen else { return }
            store.addGameTime(1)
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("← 返回")
                    .font(theme.fontDesign.font(size: 15, weight: .medium))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.css(theme.backgroundStyle.cardBg))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(theme.fontDesign.font(size: 17, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            // 剩余时间（不足 5 分钟变红，对应 H5 updateGameTimeDisplay）
            Text(GameRules.headerClock(remaining))
                .font(theme.fontDesign.font(size: 15, weight: .medium))
                .foregroundStyle(remaining < 300 ? Color.css("#EF5350") : theme.textSecondary)
                .frame(minWidth: 56, alignment: .trailing)
        }
    }
}

/// 冻结遮罩（对应 H5 game-freeze-overlay，退出返回游戏列表）
struct GameFreezeOverlay: View {
    let onExit: () -> Void

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text("⏰")
                    .font(.system(size: 52))
                Text("今日游戏时间已用完")
                    .font(theme.fontDesign.font(size: 19, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("明天再来玩吧！")
                    .font(theme.fontDesign.font(size: 14))
                    .foregroundStyle(theme.textSecondary)
                Button(action: onExit) {
                    Text("退出")
                        .font(theme.fontDesign.font(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 10)
                        .background(theme.currentTheme.btnColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(32)
            .background(Color.css(theme.backgroundStyle.cardBg))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
            )
            .padding(40)
        }
    }
}
