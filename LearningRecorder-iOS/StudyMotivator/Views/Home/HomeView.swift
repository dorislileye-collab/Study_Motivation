import SwiftUI

/// 首页 - 对应 H5 版 src/home.js
/// 顶部问候 + 金币/连续打卡、每日激励语句、今日任务列表（增删改/勾选）、
/// 快捷计时入口、解压游戏入口、金币余额与全部完成庆祝态
struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var tabRouter: AppTabRouter

    @State private var sheetMode: HomeTaskFormSheet.Mode?
    @State private var taskToDelete: StudyTask?
    @State private var showDeleteConfirm = false
    @State private var showBonusAlert = false
    @State private var bonusCoins = 0

    private var tasks: [StudyTask] { store.getTasksByDate(DateHelper.today) }
    private var completedCount: Int { tasks.filter(\.completed).count }
    private var allDone: Bool { !tasks.isEmpty && completedCount == tasks.count }

    var body: some View {
        ZStack {
            ThemedBackground()
            PageDecorationLayer(page: .home)
            ScrollView {
                VStack(spacing: 16) {
                    header
                    quoteCard
                    taskSection
                    quickTimerButton
                    gameEntryCard
                    coinDisplay
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .sheet(item: $sheetMode) { mode in
            HomeTaskFormSheet(mode: mode)
                .environmentObject(store)
                .environmentObject(theme)
        }
        .alert("确定删除这个任务吗？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let task = taskToDelete { store.deleteTask(id: task.id) }
            }
        }
        .alert("🎉 恭喜！", isPresented: $showBonusAlert) {
            Button("好的") {}
        } message: {
            Text("今日任务全部完成！获得 \(bonusCoins) 金币奖励！")
        }
    }

    // MARK: - 顶部问候 + 金币 + 连续打卡

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(theme.fontDesign.font(size: 24, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text(todayLabel)
                    .font(theme.fontDesign.font(size: 13))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("💰 \(store.coins)")
                    .font(theme.fontDesign.font(size: 16, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text("🔥 连续打卡 \(store.streakDays) 天")
                    .font(theme.fontDesign.font(size: 12))
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早上好 ☀️"
        case 12..<18: return "下午好 🌤"
        default: return "晚上好 🌙"
        }
    }

    private var todayLabel: String {
        let date = Date()
        let cal = Calendar(identifier: .gregorian)
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return "\(month)月\(day)日 \(weekdays[DateHelper.weekday(of: date)])"
    }

    // MARK: - 每日激励语句

    private var quoteCard: some View {
        ThemedCard {
            HStack(alignment: .center, spacing: 12) {
                Text("📖 \(dailyQuote)")
                    .font(theme.fontDesign.font(size: 16, weight: .medium))
                    .foregroundStyle(Color.css(theme.quoteStyle.color))
                    .shadow(color: theme.quoteStyle.glow ? Color.css(theme.quoteStyle.color).opacity(0.6) : .clear,
                            radius: theme.quoteStyle.glow ? 8 : 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let deco = DecorationManager.getQuoteDecorationImage() {
                    SketchImage(name: deco)
                        .frame(width: 40, height: 40)
                }
            }
        }
    }

    /// 与 H5 一致：按一年中的第几天取模选句
    private var dailyQuote: String {
        let day = Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.quotes[day % Self.quotes.count]
    }

    private static let quotes = [
        "今天的努力，是明天的底气！",
        "学如逆水行舟，不进则退。",
        "每一小步，都是大进步！",
        "坚持就是胜利，加油！",
        "知识就是力量，学习成就未来！",
        "不怕慢，只怕站。",
        "你今天的学习，决定了明天的选择。",
        "努力不一定成功，但放弃一定失败。",
        "把每一次作业当作一次成长的机会。",
        "今天的汗水，是明天的微笑！",
        "好好学习，天天向上！",
        "书山有路勤为径，学海无涯苦作舟。",
        "成功 = 努力 + 坚持 + 方法。",
        "越努力，越幸运！",
        "学习是一次没有终点的旅行。",
        "不要害怕失败，要害怕没有尝试。",
        "每天进步一点点，终将遇见更好的自己。",
        "你的未来，藏在你现在的努力里。",
        "勤奋是好运之母。",
        "心有多大，舞台就有多大。",
        "少壮不努力，老大徒伤悲。",
        "千里之行，始于足下。",
        "天才在于积累，聪明在于勤奋。",
        "世上无难事，只要肯攀登。",
        "宝剑锋从磨砺出，梅花香自苦寒来。",
        "读万卷书，行万里路。",
        "活到老，学到老。",
        "知识改变命运，学习成就未来。",
        "一分耕耘，一分收获。",
        "只要功夫深，铁杵磨成针。",
        "积少成多，集腋成裘。",
    ]

    // MARK: - 今日待办

    private var taskSection: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("📋 今日待办")
                        .font(theme.fontDesign.font(size: 17, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Text("\(completedCount)/\(tasks.count)")
                        .font(theme.fontDesign.font(size: 14))
                        .foregroundStyle(theme.textSecondary)
                }

                if tasks.isEmpty {
                    Text("今天还没有任务，点击下方添加吧 ✨")
                        .font(theme.fontDesign.font(size: 14))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    VStack(spacing: 10) {
                        ForEach(tasks) { task in
                            taskRow(task)
                        }
                    }
                }

                Button {
                    sheetMode = .add
                } label: {
                    Text("+ 添加任务")
                        .font(theme.fontDesign.font(size: 15, weight: .medium))
                        .foregroundStyle(Color.css(theme.taskStyle.check))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.taskStyle.radius, style: .continuous)
                                .stroke(Color.css(theme.taskStyle.check).opacity(0.6),
                                        style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func taskRow(_ task: StudyTask) -> some View {
        let style = theme.taskStyle
        return HStack(spacing: 12) {
            // 勾选框：有装饰图用 SketchImage（对应 H5 checkbox-deco），否则用 emoji
            Group {
                if let deco = DecorationManager.getTaskCheckboxImage() {
                    SketchImage(name: deco)
                        .frame(width: 20, height: 20)
                        .opacity(task.completed ? 1 : 0.4)
                        .grayscale(task.completed ? 0 : 0.6)
                } else {
                    Text(task.completed ? "✅" : "⬜")
                        .font(theme.fontDesign.font(size: 17))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(theme.fontDesign.font(size: 16, weight: .medium))
                    .foregroundStyle(task.completed ? theme.textSecondary : theme.textPrimary)
                    .strikethrough(task.completed, color: theme.textSecondary)
                HStack(spacing: 10) {
                    if let duration = task.duration {
                        Text("⏱ \(duration / 60)分钟")
                    }
                    if let count = task.count {
                        Text("🔢 \(task.currentCount)/\(count)次")
                    }
                }
                .font(theme.fontDesign.font(size: 12))
                .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Button {
                sheetMode = .edit(task)
            } label: {
                Text("✏️").font(theme.fontDesign.font(size: 15))
            }
            .buttonStyle(.plain)

            Button {
                taskToDelete = task
                showDeleteConfirm = true
            } label: {
                Text("🗑️").font(theme.fontDesign.font(size: 15))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Group {
                if let bgEnd = style.bgEnd {
                    LinearGradient(colors: [Color.css(style.bg), Color.css(bgEnd)],
                                   startPoint: .leading, endPoint: .trailing)
                } else {
                    Color.css(style.bg)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: style.radius, style: .continuous))
        )
        // 左边框（对应 H5 taskStyle.border 的左竖条）
        .overlay(alignment: .leading) {
            Capsule()
                .fill(Color.css(style.border))
                .frame(width: 4)
                .padding(.vertical, 8)
                .padding(.leading, 3)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggleTask(task) }
    }

    /// 勾选切换：照搬 H5 逻辑 —— 全部完成时领取每日 50 金币 buffer（每天一次）
    private func toggleTask(_ task: StudyTask) {
        guard store.toggleTaskComplete(id: task.id) != nil else { return }
        let todayTasks = store.getTasksByDate(DateHelper.today)
        let done = !todayTasks.isEmpty && todayTasks.allSatisfy(\.completed)
        if done {
            let result = store.claimDailyBuffer()
            if result.claimed {
                bonusCoins = result.coins
                // 对应 H5 setTimeout(300ms) 后再弹窗
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showBonusAlert = true
                }
            }
        }
    }

    // MARK: - 快捷计时入口

    private var quickTimerButton: some View {
        Button {
            tabRouter.selectedTab = 2
        } label: {
            Text("⏱ 开始计时学习")
                .font(theme.fontDesign.font(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.css(theme.taskStyle.check).opacity(tasks.isEmpty ? 0.4 : 1))
                )
        }
        .buttonStyle(.plain)
        .disabled(tasks.isEmpty)
    }

    // MARK: - 解压游戏入口

    private var gameEntryCard: some View {
        let gameUnlocked = completedCount > 0
        let remain = max(0, 20 * 60 - store.gameTimeToday)
        let remainText = String(format: "%d:%02d", remain / 60, remain % 60)

        return ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🎮 解压游戏")
                        .font(theme.fontDesign.font(size: 17, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    if gameUnlocked {
                        Text("剩余 \(remainText)")
                            .font(theme.fontDesign.font(size: 13))
                            .foregroundStyle(theme.textSecondary)
                    } else {
                        Text("完成1个任务解锁 🔒")
                            .font(theme.fontDesign.font(size: 13))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Button {
                    tabRouter.selectedTab = 3
                } label: {
                    Text(gameUnlocked ? "进入游戏 →" : "完成任务后解锁")
                        .font(theme.fontDesign.font(size: 15, weight: .medium))
                        .foregroundStyle(gameUnlocked ? Color.css(theme.gameStyle.bg) : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.css(theme.gameStyle.border), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!gameUnlocked)
            }
        }
    }

    // MARK: - 金币余额 / 全部完成庆祝态

    private var coinDisplay: some View {
        VStack(spacing: 6) {
            Text("💰 \(store.coins) 金币")
                .font(theme.fontDesign.font(size: 18, weight: .bold))
                .foregroundStyle(theme.textPrimary)
            if allDone {
                Text("🎉 今日任务全部完成！")
                    .font(theme.fontDesign.font(size: 14))
                    .foregroundStyle(Color.css(theme.quoteStyle.color))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

}

// MARK: - 添加 / 编辑任务表单

/// 对应 H5 的 showAddDialog / showEditDialog（编辑在 H5 仅能改标题，此处按契约要求支持完整字段）
private struct HomeTaskFormSheet: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    enum Mode: Identifiable {
        case add
        case edit(StudyTask)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let task): return task.id
            }
        }
    }

    enum TimerMode: String, CaseIterable, Identifiable {
        case none, time, count

        var id: String { rawValue }

        var label: String {
            switch self {
            case .none: return "不计时"
            case .time: return "时间模式（分钟）"
            case .count: return "次数模式"
            }
        }
    }

    let mode: Mode

    @State private var title: String
    @State private var timerMode: TimerMode
    @State private var minutes: Int
    @State private var count: Int
    @State private var repeatDays: Set<Int>
    @State private var showTitleAlert = false

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _title = State(initialValue: "")
            _timerMode = State(initialValue: .none)
            _minutes = State(initialValue: 30)
            _count = State(initialValue: 10)
            _repeatDays = State(initialValue: [])
        case .edit(let task):
            _title = State(initialValue: task.title)
            _timerMode = State(initialValue: task.duration != nil ? .time : (task.count != nil ? .count : .none))
            _minutes = State(initialValue: max(1, (task.duration ?? 30 * 60) / 60))
            _count = State(initialValue: max(1, task.count ?? 10))
            _repeatDays = State(initialValue: Set(task.repeatDays))
        }
    }

    private let weekdayLabels = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        NavigationStack {
            Form {
                Section("任务名称") {
                    TextField("例如：数学作业", text: $title)
                        .font(theme.fontDesign.font(size: 16))
                        .onChange(of: title) { _, newValue in
                            // 对应 H5 maxlength=30
                            if newValue.count > 30 { title = String(newValue.prefix(30)) }
                        }
                }

                Section("计时模式") {
                    Picker("计时模式", selection: $timerMode) {
                        ForEach(TimerMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    if timerMode == .time {
                        Stepper("目标时长：\(minutes) 分钟", value: $minutes, in: 1...240)
                            .font(theme.fontDesign.font(size: 15))
                    }
                    if timerMode == .count {
                        Stepper("目标次数：\(count) 次", value: $count, in: 1...999)
                            .font(theme.fontDesign.font(size: 15))
                    }
                }

                Section("重复星期（不选表示仅当天）") {
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            let selected = repeatDays.contains(day)
                            Text(weekdayLabels[day])
                                .font(theme.fontDesign.font(size: 14, weight: selected ? .semibold : .regular))
                                .foregroundStyle(selected ? .white : theme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle().fill(selected
                                                  ? Color.css(theme.taskStyle.check)
                                                  : Color.css(theme.backgroundStyle.cardBorder).opacity(0.4))
                                )
                                .onTapGesture {
                                    if selected { repeatDays.remove(day) } else { repeatDays.insert(day) }
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(mode.id == "add" ? "添加新任务" : "编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.id == "add" ? "添加" : "保存") { save() }
                        .fontWeight(.semibold)
                }
            }
            .alert("请输入任务名称", isPresented: $showTitleAlert) {
                Button("好的") {}
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showTitleAlert = true
            return
        }
        let duration: Int? = timerMode == .time ? minutes * 60 : nil
        let countValue: Int? = timerMode == .count ? count : nil
        let days = repeatDays.sorted()

        switch mode {
        case .add:
            if days.isEmpty {
                store.addTask(title: trimmed, date: DateHelper.today,
                              count: countValue, duration: duration)
            } else {
                for d in RepeatTaskLogic.expandDates(from: DateHelper.today, repeatDays: days) {
                    store.addTask(title: trimmed, date: d,
                                  count: countValue, duration: duration, repeatDays: days)
                }
            }
        case .edit(let task):
            store.updateTask(id: task.id) { t in
                t.title = trimmed
                t.duration = duration
                t.count = countValue
                t.repeatDays = days
            }
        }
        dismiss()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStore.shared)
        .environmentObject(ThemeManager.shared)
    .environmentObject(AppTabRouter())
}
