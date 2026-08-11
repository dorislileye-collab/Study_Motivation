import Foundation
import SwiftUI
import Combine

/// 主题管理器 - 对应 H5 版 src/theme-manager.js
/// 负责：当前主题、衣柜混搭、拥有状态、购买，全部持久化到 UserDefaults
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let themeKey = "studyRecorder_theme"
    private let ownedKey = "studyRecorder_ownedThemes"
    private let ownedAccKey = "studyRecorder_ownedAccessories"
    private let wardrobeKey = "studyRecorder_wardrobe"

    @Published private(set) var currentThemeId: String
    /// 衣柜：维度 -> 主题ID（支持混搭）
    @Published private(set) var wardrobe: [WardrobeDimension: String]
    @Published private(set) var ownedThemeIds: [String]
    /// 已拥有配饰 ["themeId:dimId"]
    @Published private(set) var ownedAccessories: Set<String>

    private let store: AppStore

    init(store: AppStore = .shared) {
        self.store = store
        let defaults = UserDefaults.standard
        self.currentThemeId = defaults.string(forKey: themeKey) ?? ThemeData.defaultThemeId
        self.ownedThemeIds = defaults.stringArray(forKey: ownedKey)
            ?? ThemeData.themes.filter { $0.tier == .default }.map { $0.id }
        if let arr = defaults.stringArray(forKey: ownedAccKey) {
            self.ownedAccessories = Set(arr)
        } else {
            // 默认拥有默认主题的全部配饰
            let def = ThemeData.theme(byId: ThemeData.defaultThemeId)
            self.ownedAccessories = Set(WardrobeDimension.allCases.map { "\(def.id):\($0.rawValue)" })
        }
        // 读取衣柜并校验非法值
        var wb: [WardrobeDimension: String] = [:]
        let saved = defaults.dictionary(forKey: wardrobeKey) as? [String: String] ?? [:]
        for dim in WardrobeDimension.allCases {
            if let candidate = saved[dim.rawValue], ThemeData.themes.contains(where: { $0.id == candidate }) {
                wb[dim] = candidate
            } else {
                wb[dim] = ThemeData.defaultThemeId
            }
        }
        self.wardrobe = wb
    }

    // MARK: - 查询

    var currentTheme: AppTheme { ThemeData.theme(byId: currentThemeId) }
    var allThemes: [AppTheme] { ThemeData.themes }

    /// 当前衣柜生效的各维度样式（视图直接消费这些）
    var fontDesign: AppFontDesign { equipped(.font).accessories.font }
    var calendarStyle: CalendarStyle { equipped(.calendar).accessories.calendar }
    var taskStyle: TaskStyle { equipped(.task).accessories.task }
    var backgroundStyle: BackgroundStyle { equipped(.bg).accessories.bg }
    var quoteStyle: QuoteStyle { equipped(.quote).accessories.quote }
    var timerStyle: TimerStyle { equipped(.timer).accessories.timer }
    var gameStyle: GameStyle { equipped(.game).accessories.game }

    func equippedTheme(for dim: WardrobeDimension) -> AppTheme { equipped(dim) }

    private func equipped(_ dim: WardrobeDimension) -> AppTheme {
        ThemeData.theme(byId: wardrobe[dim] ?? ThemeData.defaultThemeId)
    }

    /// 当前衣柜中某维度的装饰图片资源名
    func decorationImage(for dim: WardrobeDimension) -> String? {
        equipped(dim).accessories.decorationImage(for: dim)
    }

    func isThemeOwned(_ themeId: String) -> Bool { ownedThemeIds.contains(themeId) }

    func isAccessoryOwned(themeId: String, dim: WardrobeDimension) -> Bool {
        ownedAccessories.contains("\(themeId):\(dim.rawValue)")
    }

    func singlePrice(for tier: ThemeTier) -> Int { tier.singlePrice }

    // MARK: - 装备

    @discardableResult
    func equipAccessory(dim: WardrobeDimension, themeId: String) -> (success: Bool, message: String) {
        guard isAccessoryOwned(themeId: themeId, dim: dim) else {
            return (false, "请先购买该配饰")
        }
        wardrobe[dim] = themeId
        saveWardrobe()
        return (true, "已装备")
    }

    @discardableResult
    func equipThemeFull(_ themeId: String) -> (success: Bool, message: String) {
        let theme = ThemeData.theme(byId: themeId)
        guard isThemeOwned(themeId) else { return (false, "请先购买该主题") }
        for dim in WardrobeDimension.allCases { wardrobe[dim] = themeId }
        currentThemeId = themeId
        UserDefaults.standard.set(themeId, forKey: themeKey)
        saveWardrobe()
        return (true, "已整套装备「\(theme.name)」")
    }

    // MARK: - 购买

    /// 整主题剩余应付信息
    func remainingBundleInfo(themeId: String) -> (total: Int, ownedCount: Int, remaining: Int, singlePrice: Int, fullPrice: Int, price: Int) {
        let theme = ThemeData.theme(byId: themeId)
        let dims = WardrobeDimension.allCases
        let ownedCount = dims.filter { isAccessoryOwned(themeId: themeId, dim: $0) }.count
        let fullPrice = theme.bundlePrice
        let price = max(0, fullPrice - ownedCount * theme.tier.singlePrice)
        return (dims.count, ownedCount, dims.count - ownedCount, theme.tier.singlePrice, fullPrice, price)
    }

    @discardableResult
    func purchaseTheme(_ themeId: String) -> (success: Bool, message: String) {
        let theme = ThemeData.theme(byId: themeId)
        guard !isThemeOwned(themeId) else { return (false, "已拥有该主题") }
        let info = remainingBundleInfo(themeId: themeId)
        let price = info.price
        guard store.coins >= price else {
            return (false, "金币不足！需要 \(price) 金币，当前 \(store.coins) 金币")
        }
        if price > 0 {
            guard store.spendCoins(price, reason: "购买主题：\(theme.name)（剩余\(info.remaining)件配饰）") > 0 else {
                return (false, "金币不足，购买失败")
            }
        }
        ownedThemeIds.append(themeId)
        UserDefaults.standard.set(ownedThemeIds, forKey: ownedKey)
        for dim in WardrobeDimension.allCases {
            ownedAccessories.insert("\(themeId):\(dim.rawValue)")
        }
        UserDefaults.standard.set(Array(ownedAccessories), forKey: ownedAccKey)
        for dim in WardrobeDimension.allCases { wardrobe[dim] = themeId }
        saveWardrobe()
        return (true, "购买成功！「\(theme.name)」已装备到衣柜")
    }

    @discardableResult
    func purchaseAccessory(themeId: String, dim: WardrobeDimension) -> (success: Bool, message: String) {
        let theme = ThemeData.theme(byId: themeId)
        guard !isAccessoryOwned(themeId: themeId, dim: dim) else { return (false, "已拥有该配饰") }
        let price = theme.tier.singlePrice
        guard store.coins >= price else {
            return (false, "金币不足！需要 \(price) 金币，当前 \(store.coins) 金币")
        }
        guard store.spendCoins(price, reason: "购买配饰：\(theme.name)·\(dim.name)") > 0 else {
            return (false, "金币不足，购买失败")
        }
        ownedAccessories.insert("\(themeId):\(dim.rawValue)")
        UserDefaults.standard.set(Array(ownedAccessories), forKey: ownedAccKey)
        wardrobe[dim] = themeId
        saveWardrobe()
        return (true, "购买成功！「\(theme.name)·\(dim.name)」已装备")
    }

    // MARK: - 私有

    private func saveWardrobe() {
        var dict: [String: String] = [:]
        for (dim, themeId) in wardrobe { dict[dim.rawValue] = themeId }
        UserDefaults.standard.set(dict, forKey: wardrobeKey)
    }
}
