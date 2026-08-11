import SwiftUI

/// 成就墙 - 对应 H5 版 mine.js 的 ACHIEVEMENTS 定义 + renderAchievements()
/// 成就定义与解锁条件与 H5 完全一致
struct AchievementsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager

    private struct Achievement: Identifiable {
        let id: String
        let icon: String
        let name: String
        let condition: String
        let isUnlocked: (AppStore, ThemeManager) -> Bool
    }

    /// 照搬 mine.js 的 6 个成就定义
    private var achievements: [Achievement] {
        [
            Achievement(id: "first_checkin", icon: "🎯", name: "首次打卡", condition: "完成首次学习打卡") { s, _ in
                s.streakDays >= 1
            },
            Achievement(id: "streak_3", icon: "🔥", name: "连续3天", condition: "连续打卡3天") { s, _ in
                s.streakDays >= 3
            },
            Achievement(id: "streak_7", icon: "⭐", name: "连续7天", condition: "连续打卡7天") { s, _ in
                s.streakDays >= 7
            },
            Achievement(id: "study_10h", icon: "📚", name: "学习10小时", condition: "累计学习满10小时") { s, _ in
                s.totalStudyTime >= 10 * 3600
            },
            Achievement(id: "study_50h", icon: "🏆", name: "学习50小时", condition: "累计学习满50小时") { s, _ in
                s.totalStudyTime >= 50 * 3600
            },
            Achievement(id: "first_theme", icon: "🎨", name: "首次购买主题", condition: "购买任意一个主题") { _, t in
                t.ownedThemeIds.count > 0
            },
        ]
    }

    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("🏆 成就墙")
                    .font(theme.fontDesign.font(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(achievements) { ach in
                        achievementCard(ach)
                    }
                }
            }
        }
    }

    private func achievementCard(_ ach: Achievement) -> some View {
        let unlocked = ach.isUnlocked(store, theme)
        return VStack(spacing: 4) {
            Text(ach.icon)
                .font(.system(size: 28))
                .grayscale(unlocked ? 0 : 1)
            Text(ach.name)
                .font(theme.fontDesign.font(size: 12, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(ach.condition)
                .font(theme.fontDesign.font(size: 9))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if unlocked {
                Text("已解锁")
                    .font(theme.fontDesign.font(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: 0x4CAF50))
            } else {
                Text(" ")
                    .font(theme.fontDesign.font(size: 9))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(unlocked
                    ? Color(hex: 0x4CAF50).opacity(0.08)
                    : Color.css(theme.backgroundStyle.bgColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(unlocked ? Color(hex: 0x4CAF50).opacity(0.5)
                        : Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
        )
        .opacity(unlocked ? 1 : 0.6)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
