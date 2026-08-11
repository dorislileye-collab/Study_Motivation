import SwiftUI

/// 添加 / 编辑任务弹窗 - 对应 H5 calendar.js 的 showAddTaskForDate / showEditTaskDialog
/// editingTask 为 nil 时是添加模式，否则是编辑模式
struct TaskFormSheet: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    /// 添加模式下的目标日期；编辑模式下为原任务日期
    let date: String
    let editingTask: StudyTask?

    /// 计时模式（对应 H5 的 select：不计时 / 时间模式（分钟）/ 次数模式）
    private enum TimingMode: String, CaseIterable, Identifiable {
        case none, time, count
        var id: String { rawValue }
        var label: String {
            switch self {
            case .none: return "不计时"
            case .time: return "时间模式"
            case .count: return "次数模式"
            }
        }
    }

    /// 编辑重复任务时的修改范围（对应 H5 的 scope-btn）
    private enum EditScope: String, CaseIterable, Identifiable {
        case this, all
        var id: String { rawValue }
        var label: String { self == .this ? "仅这一次" : "所有重复任务" }
    }

    @State private var title: String
    @State private var timingMode: TimingMode
    @State private var minutes: Int
    @State private var count: Int
    @State private var selectedDays: Set<Int>
    @State private var editScope: EditScope = .this
    @State private var showTitleError = false

    /// 星期 chips 的展示顺序：一二三四五六日（对应 H5 [1,2,3,4,5,6,0]）
    private let chipOrder = [1, 2, 3, 4, 5, 6, 0]
    private let dayNames = ["日", "一", "二", "三", "四", "五", "六"]

    init(date: String, editingTask: StudyTask? = nil) {
        self.date = date
        self.editingTask = editingTask
        _title = State(initialValue: editingTask?.title ?? "")
        let mode: TimingMode = editingTask?.duration != nil ? .time : (editingTask?.count != nil ? .count : .none)
        _timingMode = State(initialValue: mode)
        _minutes = State(initialValue: editingTask?.duration.map { max(1, $0 / 60) } ?? 30)
        _count = State(initialValue: editingTask?.count ?? 10)
        _selectedDays = State(initialValue: Set(editingTask?.repeatDays ?? []))
    }

    private var isEditingRepeat: Bool { !(editingTask?.repeatDays.isEmpty ?? true) }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedBackground()
                ScrollView {
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            titleSection
                            modeSection
                            repeatSection
                            if isEditingRepeat { scopeSection }
                            if showTitleError {
                                Text("请输入任务名称")
                                    .font(theme.fontDesign.font(size: 12))
                                    .foregroundStyle(.red)
                            }
                            saveButton
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(editingTask == nil ? "添加任务" : "编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - 任务名称

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("任务名称")
                .font(theme.fontDesign.font(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            TextField("例如：英语单词", text: $title)
                .font(theme.fontDesign.font(size: 14))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Color.css(theme.backgroundStyle.bgColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onChange(of: title) { _, newValue in
                    // 对应 H5 input maxlength=30
                    if newValue.count > 30 { title = String(newValue.prefix(30)) }
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showTitleError = false
                    }
                }
        }
    }

    // MARK: - 计时模式

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("计时模式")
                .font(theme.fontDesign.font(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            Picker("计时模式", selection: $timingMode) {
                ForEach(TimingMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if timingMode == .time {
                Stepper(value: $minutes, in: 1...240) {
                    Text("目标时长：\(minutes) 分钟")
                        .font(theme.fontDesign.font(size: 14))
                        .foregroundStyle(theme.textPrimary)
                }
            } else if timingMode == .count {
                Stepper(value: $count, in: 1...999) {
                    Text("目标次数：\(count) 次")
                        .font(theme.fontDesign.font(size: 14))
                        .foregroundStyle(theme.textPrimary)
                }
            }
        }
    }

    // MARK: - 重复

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("重复")
                .font(theme.fontDesign.font(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                chip("不重复", active: selectedDays.isEmpty) {
                    selectedDays = []
                }
                ForEach(chipOrder, id: \.self) { day in
                    chip(dayNames[day], active: selectedDays.contains(day)) {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 修改范围（仅编辑重复任务时显示）

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("修改范围")
                .font(theme.fontDesign.font(size: 12))
                .foregroundStyle(theme.textSecondary)
            Picker("修改范围", selection: $editScope) {
                ForEach(EditScope.allCases) { scope in
                    Text(scope.label).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: - 保存

    private var saveButton: some View {
        Button { save() } label: {
            Text(editingTask == nil ? "添加" : "保存")
                .font(theme.fontDesign.font(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(theme.currentTheme.btnColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showTitleError = true // 对应 H5 alert('请输入任务名称')
            return
        }
        let duration = timingMode == .time ? minutes * 60 : nil
        let countValue = timingMode == .count ? count : nil
        let days = selectedDays.sorted()

        if let task = editingTask {
            if isEditingRepeat && editScope == .all {
                // 修改所有重复任务（按 H5 的 sorted 分组）
                for t in RepeatTaskLogic.editGroup(for: task, in: store.state.tasks) {
                    store.updateTask(id: t.id) {
                        $0.title = trimmed
                        $0.duration = duration
                        $0.count = countValue
                        $0.repeatDays = days
                    }
                }
            } else {
                // 仅修改这一次
                store.updateTask(id: task.id) {
                    $0.title = trimmed
                    $0.duration = duration
                    $0.count = countValue
                    $0.repeatDays = days
                }
            }
        } else {
            if days.isEmpty {
                // 不重复：只创建当天任务
                store.addTask(title: trimmed, date: date, count: countValue, duration: duration)
            } else {
                // 有重复：为起始日起 2 个月内每个匹配日期创建任务实例（照搬 H5）
                for d in RepeatTaskLogic.expandDates(from: date, repeatDays: days) {
                    store.addTask(title: trimmed, date: d, count: countValue, duration: duration, repeatDays: days)
                }
            }
        }
        dismiss()
    }

    // MARK: - 星期 chip

    private func chip(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(theme.fontDesign.font(size: 13, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? Color.white : theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(active ? Color.css(theme.taskStyle.check) : Color.css(theme.backgroundStyle.bgColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(active ? Color.css(theme.taskStyle.check) : Color.css(theme.backgroundStyle.cardBorder), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
