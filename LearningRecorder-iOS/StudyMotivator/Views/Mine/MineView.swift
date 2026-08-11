import SwiftUI

/// 我的页面 - 对应 H5 版 src/mine.js
/// 用户信息 + 金币 + 统计 + 金币记录 + 商城/衣柜 Tab + 成就墙 + 本周学习
struct MineView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager

    @State private var currentTab: MineTab = .shop
    @State private var toastMessage: String? = nil
    @State private var toastToken = UUID()
    @State private var purchaseRequest: PurchaseRequest? = nil

    private enum MineTab { case shop, wardrobe }

    var body: some View {
        ZStack {
            ThemedBackground()
            PageDecorationLayer(page: .mine)
            ScrollView {
                VStack(spacing: 16) {
                    Text("👤 我的")
                        .font(theme.fontDesign.font(size: 24, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    userInfoCard
                    coinCard
                    statsGrid
                    coinRecordsCard
                    tabSwitcher

                    if currentTab == .shop {
                        ThemeShopView(
                            onBuyTheme: { purchaseRequest = .theme($0) },
                            onBuyAccessory: { purchaseRequest = .accessory($0, $1) },
                            showToast: showToast
                        )
                    } else {
                        WardrobeView(
                            onBuyAccessory: { purchaseRequest = .accessory($0, $1) },
                            showToast: showToast
                        )
                    }

                    AchievementsView()
                    weeklyCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            if let toastMessage {
                toastView(toastMessage)
            }
            if let purchaseRequest {
                confirmOverlay(purchaseRequest)
            }
        }
    }

    // MARK: - 用户信息卡（H5 无昵称/等级系统，等级规则为本模块新增：每累计学习 2 小时升 1 级）

    private var userInfoCard: some View {
        let totalSeconds = store.totalStudyTime
        let level = totalSeconds / 7200 + 1
        let secondsToNext = level * 7200 - totalSeconds
        return ThemedCard {
            HStack(spacing: 14) {
                Text("🎓")
                    .font(.system(size: 44))
                    .frame(width: 64, height: 64)
                    .background(Color.css(theme.backgroundStyle.bgColor).opacity(0.6))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("学习者")
                        .font(theme.fontDesign.font(size: 18, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    Text("Lv.\(level)")
                        .font(theme.fontDesign.font(size: 13, weight: .semibold))
                        .foregroundColor(Color.css(theme.taskStyle.check))
                    Text("再学习 \(TimeFormatter.humanReadable(secondsToNext)) 升级")
                        .font(theme.fontDesign.font(size: 11))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - 金币卡片（对应 H5 mine-coin-card）

    private var coinCard: some View {
        ThemedCard {
            VStack(spacing: 4) {
                Text("💰 \(store.coins)")
                    .font(theme.fontDesign.font(size: 32, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                Text("金币余额")
                    .font(theme.fontDesign.font(size: 13))
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 统计（对应 H5 mine-stats-grid）

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(number: "\(store.streakDays)", label: "连续打卡")
            statCard(number: studyTimeString, label: "累计学习")
            statCard(number: "\(store.coinRecords.count)", label: "获取次数")
        }
    }

    private func statCard(number: String, label: String) -> some View {
        ThemedCard(padding: 12) {
            VStack(spacing: 4) {
                Text(number)
                    .font(theme.fontDesign.font(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(theme.fontDesign.font(size: 11))
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// 对应 H5: totalHours > 0 ? "XhYm" : "X分钟"
    private var studyTimeString: String {
        let total = store.totalStudyTime
        let hours = total / 3600
        let mins = (total % 3600) / 60
        return hours > 0 ? "\(hours)h\(mins)m" : "\(mins)分钟"
    }

    // MARK: - 金币记录（对应 H5 金币记录卡片，最近 10 条倒序）

    private var coinRecordsCard: some View {
        let recentRecords = store.coinRecords.suffix(10).reversed()
        return ThemedCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("📊 金币记录")
                    .font(theme.fontDesign.font(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                if recentRecords.isEmpty {
                    Text("还没有金币记录，开始学习赚取金币吧！")
                        .font(theme.fontDesign.font(size: 13))
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(recentRecords.enumerated()), id: \.offset) { _, record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.reason)
                                    .font(theme.fontDesign.font(size: 14))
                                    .foregroundColor(theme.textPrimary)
                                    .lineLimit(1)
                                Text(formatRecordDate(record.date))
                                    .font(theme.fontDesign.font(size: 11))
                                    .foregroundColor(theme.textSecondary)
                            }
                            Spacer()
                            Text("\(record.amount > 0 ? "+" : "")\(record.amount)")
                                .font(theme.fontDesign.font(size: 14, weight: .semibold))
                                .foregroundColor(record.amount > 0
                                                 ? Color.css(theme.taskStyle.check)
                                                 : theme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    /// 对应 H5 formatDate: 今天显示"今天"，否则"X月X日"
    private func formatRecordDate(_ dateStr: String) -> String {
        if dateStr == DateHelper.today { return "今天" }
        guard let date = DateHelper.date(from: dateStr) else { return dateStr }
        let cal = Calendar(identifier: .gregorian)
        return "\(cal.component(.month, from: date))月\(cal.component(.day, from: date))日"
    }

    // MARK: - 商城 / 衣柜 Tab 切换（对应 H5 sw-tab）

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(title: "🎨 商城", tab: .shop)
            tabButton(title: "👔 衣柜", tab: .wardrobe)
        }
        .padding(4)
        .background(Color.css(theme.backgroundStyle.cardBg))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
        )
    }

    private func tabButton(title: String, tab: MineTab) -> some View {
        let active = currentTab == tab
        return Button {
            currentTab = tab
        } label: {
            Text(title)
                .font(theme.fontDesign.font(size: 15, weight: active ? .bold : .regular))
                .foregroundColor(active ? .white : theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(active ? Color.css(theme.taskStyle.check) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 本周学习柱状图 + 统计摘要（对应 H5 renderWeeklyChart / renderStatsSummary）

    private var weeklyCard: some View {
        let weekData = store.getRecentStudyDays(7)
        let maxSeconds = max(weekData.map(\.seconds).max() ?? 0, 1)
        return ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("📈 本周学习")
                    .font(theme.fontDesign.font(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(weekData, id: \.date) { day in
                        let mins = day.seconds / 60
                        let isToday = day.date == DateHelper.today
                        VStack(spacing: 4) {
                            Text(mins >= 60 ? "\(mins / 60)h" : "\(mins)m")
                                .font(theme.fontDesign.font(size: 9))
                                .foregroundColor(theme.textSecondary)
                            ZStack(alignment: .bottom) {
                                Color.clear
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(isToday
                                          ? Color.css(theme.taskStyle.check)
                                          : theme.textSecondary.opacity(0.35))
                                    .frame(height: max(4, CGFloat(day.seconds) / CGFloat(maxSeconds) * 80))
                            }
                            .frame(height: 80)
                            Text(day.label)
                                .font(theme.fontDesign.font(size: 10))
                                .foregroundColor(isToday ? theme.textPrimary : theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Rectangle()
                    .fill(Color.css(theme.backgroundStyle.cardBorder))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    summaryItem(value: studyTimeString, label: "总学习时长")
                    summaryItem(value: "\(store.totalCompletedTasks)", label: "完成任务数")
                    summaryItem(value: "\(totalEarnedCoins)", label: "总获取金币")
                }
            }
        }
    }

    /// 对应 H5: 总获取金币 = 所有正向流水之和
    private var totalEarnedCoins: Int {
        store.coinRecords.reduce(0) { $0 + max(0, $1.amount) }
    }

    private func summaryItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(theme.fontDesign.font(size: 16, weight: .bold))
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(theme.fontDesign.font(size: 11))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Toast（对应 H5 showToast，2 秒后消失）

    private func showToast(_ message: String) {
        toastToken = UUID()
        let token = toastToken
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if toastToken == token { toastMessage = nil }
        }
    }

    private func toastView(_ message: String) -> some View {
        VStack {
            Text(message)
                .font(theme.fontDesign.font(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .padding(.top, 12)
            Spacer()
        }
    }

    // MARK: - 购买确认弹窗（对应 H5 showConfirmDialog）

    @ViewBuilder
    private func confirmOverlay(_ request: PurchaseRequest) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { purchaseRequest = nil }
            switch request {
            case .theme(let themeId):
                themeConfirmDialog(themeId: themeId)
            case .accessory(let themeId, let dim):
                accessoryConfirmDialog(themeId: themeId, dim: dim)
            }
        }
    }

    private func dialogContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12, content: content)
            .padding(20)
            .frame(maxWidth: 320)
            .background(Color.css(theme.backgroundStyle.cardBg))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding(32)
    }

    private func confirmRow(_ title: String, value: String, highlight: Bool = false, strikethrough: Bool = false, valueColor: Color? = nil) -> some View {
        HStack {
            Text(title)
                .font(theme.fontDesign.font(size: 13))
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(theme.fontDesign.font(size: 13, weight: highlight ? .bold : .regular))
                .foregroundColor(valueColor ?? (highlight ? Color.css(theme.taskStyle.check) : theme.textPrimary))
                .strikethrough(strikethrough)
        }
    }

    private func dialogActions(canConfirm: Bool, confirmTitle: String, onConfirm: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button {
                purchaseRequest = nil
            } label: {
                Text("再想想")
                    .font(theme.fontDesign.font(size: 15, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.css(theme.backgroundStyle.bgColor).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onConfirm) {
                Text(confirmTitle)
                    .font(theme.fontDesign.font(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(canConfirm ? Color.css(theme.taskStyle.check) : Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
        }
    }

    /// 整主题购买确认（对应 H5 confirm type = 'theme'）
    private func themeConfirmDialog(themeId: String) -> some View {
        let t = ThemeData.theme(byId: themeId)
        let info = theme.remainingBundleInfo(themeId: themeId)
        let canAfford = store.coins >= info.price
        return dialogContainer {
            Text(t.emoji).font(.system(size: 40))
            Text(t.name)
                .font(theme.fontDesign.font(size: 18, weight: .bold))
                .foregroundColor(theme.textPrimary)
            TierBadge(tier: t.tier)
            VStack(spacing: 8) {
                confirmRow("配饰数量",
                           value: "\(info.total) 个维度" + (info.ownedCount > 0 ? "（已拥有 \(info.ownedCount) 件）" : ""))
                confirmRow("整主题原价", value: "\(info.fullPrice) 金币", strikethrough: true, valueColor: theme.textSecondary)
                if info.ownedCount > 0 {
                    confirmRow("已购配饰抵扣", value: "-\(info.ownedCount * info.singlePrice) 金币",
                               valueColor: Color(hex: 0x4CAF50))
                }
                confirmRow("实际应付", value: "💰 \(info.price) 金币", highlight: true)
                confirmRow("当前余额", value: "💰 \(store.coins) 金币")
            }
            Text("购买后配饰将自动装备到衣柜，也可在衣柜中自由混搭")
                .font(theme.fontDesign.font(size: 11))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            dialogActions(canConfirm: canAfford, confirmTitle: canAfford ? "确认购买" : "金币不足") {
                let result = theme.purchaseTheme(themeId)
                purchaseRequest = nil
                showToast(result.message)
            }
        }
    }

    /// 单个配饰购买确认（对应 H5 confirm type = 'accessory'）
    private func accessoryConfirmDialog(themeId: String, dim: WardrobeDimension) -> some View {
        let t = ThemeData.theme(byId: themeId)
        let price = t.tier.singlePrice
        let owned = theme.isAccessoryOwned(themeId: themeId, dim: dim)
        let canBuy = store.coins >= price && !owned
        let buttonTitle = owned ? "已拥有" : (store.coins < price ? "金币不足" : "确认购买")
        return dialogContainer {
            Text(t.emoji).font(.system(size: 40))
            Text("\(t.name) - \(dim.name)")
                .font(theme.fontDesign.font(size: 18, weight: .bold))
                .foregroundColor(theme.textPrimary)
            TierBadge(tier: t.tier)
            VStack(spacing: 8) {
                confirmRow("配饰维度", value: "\(dim.icon) \(dim.name)")
                confirmRow("价格", value: "💰 \(price) 金币", highlight: true)
                confirmRow("当前余额", value: "💰 \(store.coins) 金币")
            }
            Text("购买后可在衣柜中装备此配饰")
                .font(theme.fontDesign.font(size: 11))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            dialogActions(canConfirm: canBuy, confirmTitle: buttonTitle) {
                let result = theme.purchaseAccessory(themeId: themeId, dim: dim)
                purchaseRequest = nil
                showToast(result.message)
            }
        }
    }
}

/// 购买确认请求（整主题 / 单件配饰）
enum PurchaseRequest: Identifiable {
    case theme(String)
    case accessory(String, WardrobeDimension)

    var id: String {
        switch self {
        case .theme(let themeId): return "theme-\(themeId)"
        case .accessory(let themeId, let dim): return "acc-\(themeId)-\(dim.rawValue)"
        }
    }
}

/// 等级徽章（对应 H5 theme-tier 标签）
struct TierBadge: View {
    let tier: ThemeTier

    var body: some View {
        Text(tier.name)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(tier.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(tier.color, lineWidth: 1))
    }
}

private extension Color {
    /// 按 RGB 整数构造（用于 H5 中的固定色值，如 #4CAF50）
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
