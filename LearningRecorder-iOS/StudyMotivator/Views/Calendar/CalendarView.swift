import SwiftUI

/// 日历页 - 对应 H5 版 src/calendar.js
/// 月历视图 + 选中日期的任务管理（增删改勾选）+ 学习心得 + 当日学习时长
struct CalendarView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager

    @State private var displayedMonth: Date = CalendarView.startOfCurrentMonth()
    @State private var selectedDate: String?
    @State private var showAddTask = false
    @State private var editingTask: StudyTask?
    @State private var deletingTask: StudyTask?
    @State private var showDeleteConfirm = false
    @State private var newNote = ""

    private let weekdayLabels = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        ZStack {
            ThemedBackground()
            PageDecorationLayer(page: .calendar)
            ScrollView {
                VStack(spacing: 16) {
                    calendarCard
                    if let date = selectedDate {
                        dayDetailCard(date: date)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .sheet(isPresented: $showAddTask) {
            if let date = selectedDate {
                TaskFormSheet(date: date)
            }
        }
        .sheet(item: $editingTask) { task in
            TaskFormSheet(date: task.date, editingTask: task)
        }
        .confirmationDialog("删除任务", isPresented: $showDeleteConfirm, titleVisibility: .visible, presenting: deletingTask) { task in
            if task.repeatDays.isEmpty {
                Button("删除", role: .destructive) {
                    store.deleteTask(id: task.id)
                }
            } else {
                Button("仅删除这一次") {
                    store.deleteTask(id: task.id)
                }
                Button("删除所有重复任务", role: .destructive) {
                    for t in RepeatTaskLogic.group(for: task, in: store.state.tasks) {
                        store.deleteTask(id: t.id)
                    }
                }
            }
            Button("取消", role: .cancel) {}
        } message: { task in
            Text("确定要删除「\(task.title)」吗？")
        }
    }

    // MARK: - 月历卡片

    private var calendarCard: some View {
        ThemedCard {
            VStack(spacing: 12) {
                // 月份切换头部（对应 H5 .calendar-header）
                HStack {
                    Button { shiftMonth(-1) } label: {
                        Text("◀")
                            .font(theme.fontDesign.font(size: 16, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(theme.fontDesign.font(size: 18, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Button { shiftMonth(1) } label: {
                        Text("▶")
                            .font(theme.fontDesign.font(size: 16, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    // 日历维度装饰图（对应 H5 refreshDecorations 注入的熊头/猫头等）
                    SketchImage(name: theme.decorationImage(for: .calendar))
                        .frame(width: 44, height: 44)
                        .offset(x: 4, y: -8)
                        .allowsHitTesting(false)
                }

                // 星期表头（对应 H5 .calendar-weekdays）
                HStack(spacing: 6) {
                    ForEach(weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(theme.fontDesign.font(size: 12, weight: .medium))
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // 日期格子（对应 H5 .calendar-grid）
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(monthCells) { cell in
                        cellView(cell)
                    }
                }

                // 图例（对应 H5 .calendar-legend）
                HStack(spacing: 16) {
                    legendItem(dot: true, text: "有任务")
                    legendItem(check: true, text: "已打卡")
                    legendItem(today: true, text: "今天")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func legendItem(dot: Bool = false, check: Bool = false, today: Bool = false, text: String) -> some View {
        HStack(spacing: 4) {
            if dot {
                Circle()
                    .fill(Color.css(theme.calendarStyle.dot))
                    .frame(width: 6, height: 6)
            } else if check {
                Text("✓")
                    .font(theme.fontDesign.font(size: 11, weight: .bold))
                    .foregroundStyle(Color.css(theme.taskStyle.check))
            } else if today {
                Circle()
                    .stroke(Color.css(theme.taskStyle.check), lineWidth: 1.5)
                    .frame(width: 8, height: 8)
            }
            Text(text)
                .font(theme.fontDesign.font(size: 12))
                .foregroundStyle(theme.textSecondary)
        }
    }

    // MARK: - 日期格子

    private struct DayCell: Identifiable {
        let id: String
        let dateStr: String?
        let day: Int
    }

    private var monthCells: [DayCell] {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }
        let startWeekday = cal.component(.weekday, from: first) - 1 // 0=周日，与 JS getDay() 一致
        var cells: [DayCell] = (0..<startWeekday).map { DayCell(id: "empty-\($0)", dateStr: nil, day: 0) }
        for day in 1...range.count {
            var dc = comps
            dc.day = day
            if let d = cal.date(from: dc) {
                let str = DateHelper.string(from: d)
                cells.append(DayCell(id: str, dateStr: str, day: day))
            }
        }
        return cells
    }

    private func cellView(_ cell: DayCell) -> some View {
        let style = theme.calendarStyle
        let isToday = cell.dateStr == DateHelper.today
        let hasTask = cell.dateStr.map { store.datesWithTasks.contains($0) } ?? false
        let isDone = cell.dateStr.map { store.datesWithCompletedTasks.contains($0) } ?? false
        let isSelected = cell.dateStr != nil && cell.dateStr == selectedDate

        return Group {
            if cell.dateStr == nil {
                Color.clear.frame(height: 44)
            } else {
                VStack(spacing: 3) {
                    Text("\(cell.day)")
                        .font(theme.fontDesign.font(size: 14, weight: isToday ? .bold : .regular))
                        .foregroundStyle(theme.textPrimary)
                    HStack(spacing: 3) {
                        if hasTask {
                            Circle()
                                .fill(Color.css(style.dot))
                                .frame(width: 5, height: 5)
                        }
                        if isDone {
                            Text("✓")
                                .font(theme.fontDesign.font(size: 9, weight: .bold))
                                .foregroundStyle(Color.css(theme.taskStyle.check))
                        }
                    }
                    .frame(height: 10)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.css(style.cellBg))
                .clipShape(RoundedRectangle(cornerRadius: style.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: style.radius, style: .continuous)
                        .stroke(
                            isToday ? Color.css(theme.taskStyle.check)
                                : (isSelected ? Color.css(style.dot) : Color.css(style.cellBorder)),
                            lineWidth: isToday ? 2 : 1
                        )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDate = cell.dateStr
                    newNote = ""
                }
            }
        }
    }

    // MARK: - 日期详情卡片（对应 H5 #day-detail-panel）

    private func dayDetailCard(date: String) -> some View {
        let tasks = store.getTasksByDate(date)
        let notes = store.getNotes(date)

        return ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                // 头部：标题 + 关闭
                HStack {
                    Text("\(dayLabel(date)) 的任务")
                        .font(theme.fontDesign.font(size: 16, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Button {
                        selectedDate = nil
                    } label: {
                        Text("✕")
                            .font(theme.fontDesign.font(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                            .frame(width: 28, height: 28)
                    }
                }

                // 当日学习时长
                HStack {
                    Text("⏱ 当日学习时长")
                        .font(theme.fontDesign.font(size: 13))
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    Text(TimeFormatter.humanReadable(store.getDailyStudySeconds(date)))
                        .font(theme.fontDesign.font(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }

                // 任务列表
                if tasks.isEmpty {
                    Text("这天没有任务")
                        .font(theme.fontDesign.font(size: 13))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(tasks) { task in
                        taskRow(task)
                    }
                }

                // 添加任务按钮
                Button {
                    showAddTask = true
                } label: {
                    Text("+ 添加任务")
                        .font(theme.fontDesign.font(size: 14, weight: .semibold))
                        .foregroundStyle(theme.currentTheme.btnColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(theme.currentTheme.btnColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                }
                .buttonStyle(.plain)

                Divider()

                // 学习心得（对应 H5 .day-notes）
                Text("📝 学习心得")
                    .font(theme.fontDesign.font(size: 14, weight: .bold))
                    .foregroundStyle(theme.textPrimary)

                if notes.isEmpty {
                    Text("暂无学习心得")
                        .font(theme.fontDesign.font(size: 13))
                        .foregroundStyle(theme.textSecondary)
                } else {
                    ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                        Text("📝 \(note)")
                            .font(theme.fontDesign.font(size: 13))
                            .foregroundStyle(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 添加心得
                HStack(spacing: 8) {
                    TextField("写一条心得…", text: $newNote)
                        .font(theme.fontDesign.font(size: 13))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.css(theme.backgroundStyle.bgColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onSubmit { addNote(to: date) }
                    Button("添加") { addNote(to: date) }
                        .font(theme.fontDesign.font(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(theme.currentTheme.btnColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    // MARK: - 任务行（与首页同款样式）

    private func taskRow(_ task: StudyTask) -> some View {
        let style = theme.taskStyle
        return HStack(spacing: 10) {
            // 勾选
            Button {
                store.toggleTaskComplete(id: task.id)
            } label: {
                Text(task.completed ? "✅" : "⬜")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            // 标题 + 元信息
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(theme.fontDesign.font(size: 14, weight: .medium))
                        .foregroundStyle(theme.textPrimary)
                        .strikethrough(task.completed)
                    if !task.repeatDays.isEmpty {
                        Text("🔁 \(task.repeatDays.map { weekdayLabels[$0] }.joined())")
                            .font(theme.fontDesign.font(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                HStack(spacing: 8) {
                    if let duration = task.duration {
                        Text("⏱ \(duration / 60)分钟")
                            .font(theme.fontDesign.font(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    }
                    if let count = task.count {
                        Text("🔢 \(count)次")
                            .font(theme.fontDesign.font(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }

            Spacer()

            // 编辑 / 删除
            Button {
                editingTask = task
            } label: {
                Text("✏️").font(.system(size: 15))
            }
            .buttonStyle(.plain)
            Button {
                deletingTask = task
                showDeleteConfirm = true
            } label: {
                Text("🗑️").font(.system(size: 15))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(taskRowBackground(style))
        .clipShape(RoundedRectangle(cornerRadius: style.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: style.radius, style: .continuous)
                .stroke(Color.css(style.border), lineWidth: 1)
        )
        .opacity(task.completed ? 0.65 : 1)
    }

    private func taskRowBackground(_ style: TaskStyle) -> some View {
        Group {
            if let end = style.bgEnd {
                LinearGradient(
                    colors: [Color.css(style.bg), Color.css(end)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.css(style.bg)
            }
        }
    }

    // MARK: - 工具

    private func addNote(to date: String) {
        let trimmed = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addNote(date: date, note: trimmed)
        newNote = ""
    }

    private static func startOfCurrentMonth() -> Date {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }

    private func shiftMonth(_ delta: Int) {
        let cal = Calendar(identifier: .gregorian)
        if let next = cal.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = next
        }
    }

    private var monthTitle: String {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        return "\(comps.year ?? 0)年 \(comps.month ?? 0)月"
    }

    private func dayLabel(_ date: String) -> String {
        guard let d = DateHelper.date(from: date) else { return date }
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.month, .day], from: d)
        return "\(comps.month ?? 0)月\(comps.day ?? 0)日"
    }
}

/// 重复任务的分组与日期展开逻辑 - 照搬 H5 calendar.js
enum RepeatTaskLogic {
    /// 删除"所有重复任务"的分组：相同标题 + repeatDays 完全相等（顺序敏感，对应 H5 JSON.stringify 比较）
    static func group(for task: StudyTask, in tasks: [StudyTask]) -> [StudyTask] {
        tasks.filter { $0.title == task.title && !$0.repeatDays.isEmpty && $0.repeatDays == task.repeatDays }
    }

    /// 编辑"所有重复任务"的分组：相同标题 + repeatDays 排序后相等（对应 H5 edit-all 的 sorted 比较）
    static func editGroup(for task: StudyTask, in tasks: [StudyTask]) -> [StudyTask] {
        let key = task.repeatDays.sorted()
        return tasks.filter { $0.title == task.title && !$0.repeatDays.isEmpty && $0.repeatDays.sorted() == key }
    }

    /// 展开重复日期：从起始日起 2 个月内所有命中 repeatDays 的日期（含起止，照搬 H5 showAddTaskForDate）
    static func expandDates(from start: String, repeatDays: [Int]) -> [String] {
        guard let startDate = DateHelper.date(from: start) else { return [] }
        let cal = Calendar(identifier: .gregorian)
        guard let endDate = cal.date(byAdding: .month, value: 2, to: startDate) else { return [] }
        var dates: [String] = []
        var current = startDate
        while current <= endDate {
            let weekday = cal.component(.weekday, from: current) - 1 // 0=周日
            if repeatDays.contains(weekday) {
                dates.append(DateHelper.string(from: current))
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }
}
