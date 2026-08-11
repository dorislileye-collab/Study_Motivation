# StudyMotivator iOS - 模块契约（所有转换任务必读）

本项目是 H5 应用「学习激励记录仪」(`../learning-recorder/`) 的 SwiftUI 原生重写。
iOS 部署目标 17.0，纯 SwiftUI，无第三方依赖。

## 已存在的核心层（直接 import 使用，不要重新定义）

### AppStore (`Services/AppStore.swift`) — `final class AppStore: ObservableObject`
通过 `@EnvironmentObject private var store: AppStore` 获取。对应 H5 的 `store.js`：
- 状态：`store.state` (`AppState`, Codable)，含 `tasks/coins/coinRecords/gameTimeToday/streakDays/totalStudySeconds/dailyStudySeconds/dailyNotes/ownedWhiteNoises` 等
- 任务：`getTasksByDate(_ date: String)`、`addTask(title:date:count:duration:repeatDays:)`、`updateTask(id:) { inout }`、`deleteTask(id:)`、`toggleTaskComplete(id:)`
- 金币：`coins`、`addCoins(_:reason:)`、`spendCoins(_:reason:)`（返回实际花费，不足为0）、`coinRecords`、`claimDailyBuffer()` → `(claimed: Bool, coins: Int)`
- 打卡：`recordActive()`、`streakDays`
- 游戏时间：`gameTimeToday`（今日已用秒数）、`addGameTime(_:)`
- 学习时长：`addStudyTime(_:)`、`totalStudyTime`、`getDailyStudySeconds(_:)`、`getRecentStudyDays(_ n:)` → `[(date, seconds, label)]`、`totalCompletedTasks`
- 心得：`addNote(date:note:)`、`getNotes(_:)`
- 日历：`datesWithTasks: Set<String>`、`datesWithCompletedTasks: Set<String>`
- 白噪音：`ownedWhiteNoises: [String]`、`addOwnedWhiteNoise(_:)`

### 模型 (`Models/Models.swift`)
- `StudyTask: Identifiable, Codable`：`id/title/date(YYYY-MM-DD)/completed/count:Int?/duration:Int?(秒)/notes/elapsed/currentCount/repeatDays:[Int]`
- `DateHelper.today: String`（YYYY-MM-DD）、`DateHelper.string(from: Date)`、`DateHelper.date(from: String)`、`DateHelper.weekday(of:)`（0=周日）
- `TimeFormatter.clock(_ seconds:)` → "MM:SS"；`TimeFormatter.humanReadable(_:)` → "X小时X分钟"

### ThemeManager (`Theme/ThemeManager.swift`) — `final class ThemeManager: ObservableObject`
通过 `@EnvironmentObject private var theme: ThemeManager` 获取。对应 H5 的 `theme-manager.js`：
- 当前生效样式（视图直接用）：`fontDesign: AppFontDesign`、`calendarStyle: CalendarStyle`、`taskStyle: TaskStyle`、`backgroundStyle: BackgroundStyle`、`quoteStyle: QuoteStyle`、`timerStyle: TimerStyle`、`gameStyle: GameStyle`
- `currentTheme: AppTheme`、`allThemes: [AppTheme]`、`equippedTheme(for: WardrobeDimension)`
- `decorationImage(for dim:) -> String?`（calendar/task 维度的装饰图资源名）
- 购买/装备：`isThemeOwned`、`isAccessoryOwned(themeId:dim:)`、`equipAccessory(dim:themeId:)`、`equipThemeFull(_:)`、`purchaseTheme(_:)`、`purchaseAccessory(themeId:dim:)`、`remainingBundleInfo(themeId:)`，均返回 `(success: Bool, message: String)`
- 枚举：`WardrobeDimension`(font/calendar/task/bg/quote/timer/game，有 `.name`/`.icon`)、`ThemeTier`(有 `.name`/`.color`/`.singlePrice`)
- `AppTheme`：`id/name/emoji/tier/btnColor/price/bundlePrice/accessories`

### 样式结构（`Theme/ThemeModels.swift`）
颜色字段均为 CSS 字符串，用 `Color.css(str)` 转 Color：
- `CalendarStyle`: `cellBg/cellBorder/radius: CGFloat/dot/decorationImage: String?`
- `TaskStyle`: `bg/bgEnd: String?(渐变)/border/radius/check/decorationImage`
- `BackgroundStyle`: `bgColor/gradient: [String]/textPrimary/textSecondary/cardBg/cardBorder`
- `QuoteStyle`: `color/glow: Bool`；`TimerStyle`: `bg/border/number/glow`；`GameStyle`: `bg/border`
- `AppFontDesign.font(size:weight:) -> Font`

### 共享组件（`Views/Components/SharedViews.swift`）
- `ThemedBackground()`：主题渐变背景（`.ignoresSafeArea()` 使用）
- `ThemedCard<Content>`：主题卡片容器
- `SketchImage(name: String?)`：加载 `Resources/Sketches` 中的装饰图（Bundle 内按文件名无扩展名查找，如 "cat-paw"）
- `showToast` 用简单的 `@State` + overlay 自行实现即可

### 资源
- 装饰图：`Resources/Sketches/*.jpeg`（Bundle 根，`UIImage(named: "cat-paw")` 可加载）
- 音频：`Resources/Audio/{rain,clock,snow-mountain}.mp3`（`Bundle.main.url(forResource:withExtension:)`）

## 转换要求
1. 功能与 H5 版对齐，UI 用 SwiftUI 惯用写法（不必逐像素复刻 CSS），但必须套用 `theme.xxxStyle` 主题样式（背景、卡片、文字颜色、圆角、字体）。
2. 所有页面根视图用 `ThemedBackground()` 做背景。
3. 文案保持中文，与 H5 版一致。
4. 不要修改核心层文件（AppStore/ThemeManager/ThemeData/Models）；发现缺失能力时在自己模块内写私有扩展。
5. 不要运行 xcodebuild，不要动 project.pbxproj。文件写到指定路径即可。
6. H5 中的 CSS 特效（发光、pattern 纹理）可简化：`glow=true` 时用 `.shadow(color:radius:)` 近似；pattern 忽略。
7. H5 里 `localStorage` 的读取都已封装在 AppStore/ThemeManager 里，直接用。
