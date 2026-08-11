import SwiftUI

/// 主题商城 - 对应 H5 版 mine.js 的 renderShop()
/// 16 套主题网格：已拥有可整套装备，未拥有可整套购买或按维度单买
struct ThemeShopView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager

    let onBuyTheme: (String) -> Void
    let onBuyAccessory: (String, WardrobeDimension) -> Void
    let showToast: (String) -> Void

    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🎨 主题商城")
                        .font(theme.fontDesign.font(size: 16, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("\(store.coins) 金币")
                        .font(theme.fontDesign.font(size: 13))
                        .foregroundColor(theme.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(theme.allThemes) { t in
                        themeCard(t)
                    }
                }
            }
        }
    }

    // MARK: - 单个主题卡片（对应 H5 theme-card）

    private func themeCard(_ t: AppTheme) -> some View {
        let owned = theme.isThemeOwned(t.id)
        let info = theme.remainingBundleInfo(themeId: t.id)
        let singlePrice = t.tier.singlePrice
        // 预览色块：bg 背景色 + calendar 边框色（对应 H5 previewColor / previewAccent）
        let previewColor = Color.css(t.accessories.bg.bgColor)
        let previewAccent = Color.css(t.accessories.calendar.cellBorder)

        return VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(previewColor)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(previewAccent, lineWidth: 2)
                )
            Text(t.emoji).font(.system(size: 26))
            Text(t.name)
                .font(theme.fontDesign.font(size: 13, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)
            TierBadge(tier: t.tier)

            if owned {
                Text("已拥有 · \(info.total)配饰")
                    .font(theme.fontDesign.font(size: 11))
                    .foregroundColor(Color(hex: 0x4CAF50))
                Button {
                    let result = theme.equipThemeFull(t.id)
                    showToast(result.message)
                } label: {
                    Text("🎽 整套装备")
                        .font(theme.fontDesign.font(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(t.btnColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                let canAfford = store.coins >= info.price
                HStack(spacing: 4) {
                    Text("💰 \(info.price)")
                        .font(theme.fontDesign.font(size: 12, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    if info.ownedCount > 0 {
                        Text("已拥有\(info.ownedCount)件，已扣除")
                            .font(theme.fontDesign.font(size: 9))
                            .foregroundColor(Color(hex: 0x4CAF50))
                    } else {
                        Text("\(info.total * singlePrice)")
                            .font(theme.fontDesign.font(size: 9))
                            .foregroundColor(theme.textSecondary)
                            .strikethrough()
                    }
                }
                Button {
                    onBuyTheme(t.id)
                } label: {
                    Text(canAfford ? "购买整主题" : "金币不足")
                        .font(theme.fontDesign.font(size: 12, weight: .bold))
                        .foregroundColor(canAfford ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(canAfford ? t.btnColor : Color.gray.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)

                // 单件购买行：7 个维度，对应 H5 single-buy-row
                HStack(spacing: 3) {
                    ForEach(WardrobeDimension.allCases) { dim in
                        singleBuyButton(t, dim: dim, price: singlePrice)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.css(theme.backgroundStyle.bgColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
        )
    }

    /// 单件配饰购买按钮（对应 H5 single-buy-btn：图标 + 价格，已拥有显示 ✓）
    private func singleBuyButton(_ t: AppTheme, dim: WardrobeDimension, price: Int) -> some View {
        let owned = theme.isAccessoryOwned(themeId: t.id, dim: dim)
        let canBuy = store.coins >= price && !owned
        return Button {
            onBuyAccessory(t.id, dim)
        } label: {
            Text("\(dim.icon)\(owned ? "✓" : "\(price)")")
                .font(theme.fontDesign.font(size: 10))
                .foregroundColor(owned ? t.btnColor : theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(owned ? t.btnColor : Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canBuy)
        .accessibilityLabel("\(dim.name) \(price)金币")
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
