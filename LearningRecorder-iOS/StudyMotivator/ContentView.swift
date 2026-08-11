import SwiftUI

final class AppTabRouter: ObservableObject {
    @Published var selectedTab = 0
}

/// 根视图 - 对应 H5 版 index.html 的底部 Tab 导航
struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var tabRouter: AppTabRouter

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(0)
            CalendarView()
                .tabItem { Label("日历", systemImage: "calendar") }
                .tag(1)
            TimerView()
                .tabItem { Label("计时", systemImage: "stopwatch.fill") }
                .tag(2)
            GameCenterView()
                .tabItem { Label("游戏", systemImage: "gamecontroller.fill") }
                .tag(3)
            MineView()
                .tabItem { Label("我的", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(Color.css(theme.taskStyle.check))
        .overlay(BackgroundDecorationLayer())
    }
}
