import SwiftUI

/// 我的衣柜 - 对应 H5 版 mine.js 的 renderWardrobe()
/// 7 个维度混搭：每维度列出全部主题，已拥有可装备，未拥有显示单价可购买
struct WardrobeView: View {
    @EnvironmentObject private var theme: ThemeManager

    let onBuyAccessory: (String, WardrobeDimension) -> Void
    let showToast: (String) -> Void

    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("👔 我的衣柜")
                        .font(theme.fontDesign.font(size: 16, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("已拥有 \(theme.ownedAccessories.count) 件配饰")
                        .font(theme.fontDesign.font(size: 13))
                        .foregroundColor(theme.textSecondary)
                }

                ForEach(WardrobeDimension.allCases) { dim in
                    dimensionSection(dim)
                }
            }
        }
    }

    // MARK: - 单个维度区块（对应 H5 wardrobe-dimension）

    private func dimensionSection(_ dim: WardrobeDimension) -> some View {
        let equippedId = theme.wardrobe[dim] ?? ThemeData.defaultThemeId
        let equippedTheme = ThemeData.theme(byId: equippedId)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(dim.icon) \(dim.name)")
                    .font(theme.fontDesign.font(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text("\(equippedTheme.emoji) \(equippedTheme.name)")
                    .font(theme.fontDesign.font(size: 12))
                    .foregroundColor(theme.textSecondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(theme.allThemes) { t in
                        optionChip(t, dim: dim)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - 配饰选项（已拥有 → 装备；未拥有 → 显示单价，点击弹出购买确认）

    private func optionChip(_ t: AppTheme, dim: WardrobeDimension) -> some View {
        let owned = theme.isAccessoryOwned(themeId: t.id, dim: dim)
        let isEquipped = theme.wardrobe[dim] == t.id
        return Button {
            if owned {
                let result = theme.equipAccessory(dim: dim, themeId: t.id)
                if result.success { showToast(result.message) }
            } else {
                onBuyAccessory(t.id, dim)
            }
        } label: {
            VStack(spacing: 3) {
                Text(t.emoji).font(.system(size: 20))
                Text(t.name)
                    .font(theme.fontDesign.font(size: 10))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                if owned {
                    Text(isEquipped ? "✓ 已装备" : "可装备")
                        .font(theme.fontDesign.font(size: 9, weight: isEquipped ? .bold : .regular))
                        .foregroundColor(isEquipped ? t.btnColor : theme.textSecondary)
                } else {
                    Text("💰\(t.tier.singlePrice)")
                        .font(theme.fontDesign.font(size: 9))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .frame(width: 78)
            .padding(.vertical, 8)
            .background(isEquipped
                        ? t.btnColor.opacity(0.15)
                        : Color.css(theme.backgroundStyle.bgColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isEquipped ? t.btnColor : Color.css(theme.backgroundStyle.cardBorder),
                            lineWidth: isEquipped ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
