import SwiftUI

@main
struct StudyMotivatorApp: App {
    @StateObject private var store = AppStore.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var tabRouter = AppTabRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .environmentObject(tabRouter)
        }
    }
}
