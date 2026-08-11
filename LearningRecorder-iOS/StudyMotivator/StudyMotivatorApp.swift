import SwiftUI

@main
struct StudyMotivatorApp: App {
    @StateObject private var store = AppStore.shared
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        // 每日打卡（对应 H5 版启动时 recordActive）
        AppStore.shared.recordActive()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
        }
    }
}
