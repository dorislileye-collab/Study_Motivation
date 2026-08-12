import SwiftUI

/// 计时页 - 对应 H5 版 src/timer.js
/// 任务选择 → 计时（时间/次数/自由模式由任务设定决定）→ 完成结算
/// （金币奖励 + 每日 buffer + 全部完成/连续打卡加成 + 学习心得 + 庆祝动画）
struct TimerView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var whiteNoise = WhiteNoiseManager.shared

    /// 页面阶段（对应 H5 的 renderTimerPage / renderTimerInterface / showTimerComplete / 奖励结果页）
    private enum Phase {
        case selecting, timing, completed, rewarded
    }

    /// 计时模式（对应 H5 的 mode: time / count / free）
    private enum TimerMode {
        case time, count, free

        var badge: String {
            switch self {
            case .time: return "⏱ 时间模式"
            case .count: return "🔢 次数模式"
            case .free: return "🆓 自由模式"
            }
        }

        /// 大计时器下方的标签（H5 timerLabel）
        var timerLabel: String {
            switch self {
            case .time: return "已用时"
            case .count: return "计时中"
            case .free: return "自由计时"
            }
        }
    }

    /// 计时会话（对应 H5 的 timerState）
    /// elapsed 基于时间戳计算：锁屏/切后台期间 Timer.publish 暂停，但时长不丢失
    private struct Session {
        var taskId: String
        var taskTitle: String
        var mode: TimerMode
        var startedAt: Date? = nil  // 本次运行的起始时刻（暂停时为 nil）
        var accumulated = 0         // 暂停前已累计的秒数
        var credited = 0            // 已记入学习时长的秒数
        var targetTime: Int?        // 目标秒数（时间模式）
        var targetCount: Int?       // 目标次数（次数模式）
        var currentCount = 0        // 已完成次数
        var isRunning = false

        /// 已用秒数（锁屏后依然准确）
        var elapsed: Int {
            var total = accumulated
            if isRunning, let startedAt {
                total += max(0, Int(Date().timeIntervalSince(startedAt)))
            }
            return total
        }
    }

    /// 奖励结算结果（对应 H5 completeTimer 的各 earnedXxx）
    private struct RewardResult {
        var mins: Int
        var earnedTime: Int
        var earnedBuffer: Int
        var earnedBonus: Int
        var streak: Int
        var earnedStreak: Int
        var totalEarned: Int
        var balance: Int
    }

    @State private var phase: Phase = .selecting
    @State private var session: Session?
    @State private var notes = ""
    @State private var reward: RewardResult?
    @State private var showShortEndConfirm = false
    @State private var showCelebration = false
    /// 每秒 +1 驱动 UI 刷新（elapsed 由时间戳算出，需要一个状态变化触发重绘）
    @State private var tickCounter = 0

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var todayTasks: [StudyTask] { store.getTasksByDate(DateHelper.today) }
    private var uncompletedTasks: [StudyTask] { todayTasks.filter { !$0.completed } }

    /// 主题庆祝图（对应 H5 decoration-manager.js 的 timer-celebration 规则：
    /// 衣柜 timer 维度装备 bear 主题时显示 bear-cheer）
    private var celebrationImageName: String? {
        theme.equippedTheme(for: .timer).id == "bear" ? "bear-cheer" : nil
    }

    var body: some View {
        ZStack {
            ThemedBackground()
            PageDecorationLayer(page: .timer)

            ScrollView {
                VStack(spacing: 16) {
                    switch phase {
                    case .selecting: selectionPage
                    case .timing: timingPage
                    case .completed: completedPage
                    case .rewarded: rewardPage
                    }
                }
                .padding()
            }

            if showCelebration {
                CelebrationView(duration: 3, imageName: celebrationImageName) {
                    showCelebration = false
                }
            }
        }
        .onReceive(ticker) { _ in tick() }
        .alert("计时时间太短，确定要结束吗？", isPresented: $showShortEndConfirm) {
            Button("确定") { discardSession() }
            Button("取消", role: .cancel) {}
        }
        // 白噪音离开本 Tab 后继续播放（锁屏也不断，用户可手动停止）
    }

    // MARK: - 任务选择页（H5 renderTimerPage）

    private var selectionPage: some View {
        VStack(spacing: 16) {
            Text("⏱ 计时学习")
                .font(theme.fontDesign.font(size: 22, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if uncompletedTasks.isEmpty {
                ThemedCard {
                    Text("🎉 今日任务已全部完成！")
                        .font(theme.fontDesign.font(size: 15))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            } else {
                ThemedCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("选择任务")
                            .font(theme.fontDesign.font(size: 16, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                            .padding(.bottom, 4)

                        ForEach(Array(uncompletedTasks.enumerated()), id: \.element.id) { index, task in
                            Button {
                                SoundService.shared.playClickSound()
                                startTimer(task)
                            } label: {
                                HStack {
                                    Text(task.title)
                                        .font(theme.fontDesign.font(size: 15))
                                        .foregroundStyle(theme.textPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(modeLabel(task))
                                        .font(theme.fontDesign.font(size: 13))
                                        .foregroundStyle(theme.textSecondary)
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if index < uncompletedTasks.count - 1 {
                                Divider().overlay(Color.css(theme.backgroundStyle.cardBorder))
                            }
                        }
                    }
                }
            }

            // 计时模式说明（H5 的三张静态模式卡片）
            ThemedCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("计时模式")
                        .font(theme.fontDesign.font(size: 16, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)

                    HStack(spacing: 10) {
                        modeCard(icon: "⏱", name: "时间模式", desc: "设定目标时长\n正计时到达后自动停止")
                        modeCard(icon: "🔢", name: "次数模式", desc: "设定目标次数\n同时计时，达成后停止")
                        modeCard(icon: "🆓", name: "自由模式", desc: "不设目标随意计时\n随时开始随时结束")
                    }

                    Text("💡 点击上方任务即可开始，模式由任务设定")
                        .font(theme.fontDesign.font(size: 12))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }

    private func modeCard(icon: String, name: String, desc: String) -> some View {
        VStack(spacing: 6) {
            Text(icon).font(.system(size: 26))
            Text(name)
                .font(theme.fontDesign.font(size: 13, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Text(desc)
                .font(theme.fontDesign.font(size: 10))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(Color.css(theme.timerStyle.bg))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.css(theme.timerStyle.border).opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - 计时界面（H5 renderTimerInterface）

    private var timingPage: some View {
        Group {
            if let s = session {
                VStack(spacing: 20) {
                    // 任务信息
                    HStack {
                        Text(s.taskTitle)
                            .font(theme.fontDesign.font(size: 17, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(s.mode.badge)
                            .font(theme.fontDesign.font(size: 12))
                            .foregroundStyle(Color.css(theme.timerStyle.border))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.css(theme.timerStyle.border).opacity(0.12))
                            .clipShape(Capsule())
                    }

                    // 大计时器（theme.timerStyle：bg/border/number，glow 用 shadow 近似）
                    timerCircle(s)

                    // 目标进度
                    targetInfo(s)

                    // 控制按钮
                    controlButtons(s)

                    // 白噪音面板（H5 内嵌在计时界面中）
                    WhiteNoiseView(manager: whiteNoise)
                }
            }
        }
    }

    private func timerCircle(_ s: Session) -> some View {
        let border = Color.css(theme.timerStyle.border)
        let progress: CGFloat = {
            switch s.mode {
            case .time:
                guard let target = s.targetTime, target > 0 else { return 0 }
                return min(1, CGFloat(s.elapsed) / CGFloat(target))
            case .count:
                guard let target = s.targetCount, target > 0 else { return 0 }
                return min(1, CGFloat(s.currentCount) / CGFloat(target))
            case .free:
                return 0
            }
        }()

        return ZStack {
            Circle()
                .stroke(border.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(border, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)

            VStack(spacing: 6) {
                Text(TimeFormatter.clock(s.elapsed))
                    .font(theme.fontDesign.font(size: 44, weight: .bold))
                    .foregroundStyle(Color.css(theme.timerStyle.number))
                    .monospacedDigit()
                Text(s.mode.timerLabel)
                    .font(theme.fontDesign.font(size: 14))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .frame(width: 220, height: 220)
        .padding(20)
        .background(Color.css(theme.timerStyle.bg))
        .clipShape(Circle())
        .overlay(Circle().stroke(border, lineWidth: 2))
        .shadow(color: theme.timerStyle.glow ? border.opacity(0.6) : .clear,
                radius: theme.timerStyle.glow ? 16 : 0)
    }

    @ViewBuilder
    private func targetInfo(_ s: Session) -> some View {
        switch s.mode {
        case .time:
            if let target = s.targetTime {
                VStack(spacing: 8) {
                    Text("目标 \(target / 60) 分钟")
                        .font(theme.fontDesign.font(size: 14))
                        .foregroundStyle(theme.textSecondary)
                    progressBar(min(1, Double(s.elapsed) / Double(max(target, 1))))
                }
            }
        case .count:
            if let target = s.targetCount {
                VStack(spacing: 8) {
                    Text("进度 \(s.currentCount) / \(target) 次 · 已用时 \(TimeFormatter.clock(s.elapsed))")
                        .font(theme.fontDesign.font(size: 14))
                        .foregroundStyle(theme.textSecondary)
                    progressBar(min(1, Double(s.currentCount) / Double(max(target, 1))))
                }
            }
        case .free:
            Text("自由计时 · 已用时 \(TimeFormatter.clock(s.elapsed))")
                .font(theme.fontDesign.font(size: 14))
                .foregroundStyle(theme.textSecondary)
        }
    }

    private func progressBar(_ progress: Double) -> some View {
        let accent = Color.css(theme.timerStyle.border)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(accent.opacity(0.2))
                Capsule()
                    .fill(accent)
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
            }
        }
        .frame(height: 8)
        .frame(maxWidth: 280)
    }

    @ViewBuilder
    private func controlButtons(_ s: Session) -> some View {
        HStack(spacing: 12) {
            // 开始/暂停
            Button {
                if s.isRunning { stopRunning() } else { resumeRunning() }
            } label: {
                Text(s.isRunning ? "⏸ 暂停" : (s.mode == .count ? "▶ 开始计时" : "▶ 开始"))
                    .timerButtonStyle(theme: theme)
                    .background(theme.currentTheme.btnColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if s.mode == .count {
                // 完成一次（仅计时中可点）
                Button {
                    countOnce()
                } label: {
                    Text(s.currentCount >= (s.targetCount ?? 0)
                         ? "🎉 目标达成！(\(s.currentCount)/\(s.targetCount ?? 0))"
                         : "✅ 完成一次 (\(s.currentCount)/\(s.targetCount ?? 0))")
                        .timerButtonStyle(theme: theme)
                        .background(Color.green.opacity(s.isRunning ? 0.85 : 0.4))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!s.isRunning)
            } else {
                // 重置
                Button {
                    resetTimer()
                } label: {
                    Text(" 重置")
                        .timerButtonStyle(theme: theme)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // 结束
            Button {
                endTimer()
            } label: {
                Text(s.mode == .count ? " 结束" : "⏹ 结束")
                    .timerButtonStyle(theme: theme)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 完成页（H5 showTimerComplete）

    private var completedPage: some View {
        Group {
            if let s = session {
                VStack(spacing: 16) {
                    // 有主题庆祝图时由 CelebrationView 叠加展示，否则显示 🎉（对应 H5 的 fallback）
                    if celebrationImageName == nil {
                        Text("🎉").font(.system(size: 60))
                    }

                    Text("太棒了！")
                        .font(theme.fontDesign.font(size: 24, weight: .bold))
                        .foregroundStyle(theme.textPrimary)

                    ThemedCard {
                        VStack(spacing: 10) {
                            statRow(label: "任务", value: s.taskTitle)
                            statRow(label: "用时", value: "\(s.elapsed / 60)分\(s.elapsed % 60)秒")
                            if s.mode == .count {
                                statRow(label: "完成次数", value: "\(s.currentCount)/\(s.targetCount ?? 0)")
                            }
                        }
                    }

                    ThemedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📝 写下学习心得")
                                .font(theme.fontDesign.font(size: 16, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                            TextEditor(text: $notes)
                                .font(theme.fontDesign.font(size: 14))
                                .foregroundStyle(theme.textPrimary)
                                .frame(height: 80)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color.css(theme.backgroundStyle.bgColor).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("今天学到了什么？有什么收获？")
                                            .font(theme.fontDesign.font(size: 14))
                                            .foregroundStyle(theme.textSecondary.opacity(0.6))
                                            .padding(.horizontal, 13)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .onChange(of: notes) {
                                    if notes.count > 200 {
                                        notes = String(notes.prefix(200))
                                    }
                                }
                        }
                    }

                    Button {
                        completeTimer()
                    } label: {
                        Text("💾 保存并领取奖励")
                            .font(theme.fontDesign.font(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.currentTheme.btnColor)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(theme.fontDesign.font(size: 14))
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .font(theme.fontDesign.font(size: 15, weight: .medium))
                .foregroundStyle(theme.textPrimary)
        }
    }

    // MARK: - 奖励结果页（H5 completeTimer 的结算 HTML）

    private var rewardPage: some View {
        Group {
            if let r = reward {
                VStack(spacing: 16) {
                    Text("🎉").font(.system(size: 60))

                    Text("奖励已领取！")
                        .font(theme.fontDesign.font(size: 24, weight: .bold))
                        .foregroundStyle(theme.textPrimary)

                    if r.totalEarned > 0 {
                        Text("+\(r.totalEarned)")
                            .font(theme.fontDesign.font(size: 36, weight: .bold))
                            .foregroundStyle(Color.css("#FFD700"))
                            .shadow(color: Color.css("#FFD700").opacity(0.5), radius: 8)
                    }

                    ThemedCard {
                        VStack(alignment: .leading, spacing: 10) {
                            if r.earnedBuffer > 0 {
                                rewardLine("🎁 每日首次计时 +\(r.earnedBuffer) 金币")
                            }
                            if r.earnedTime > 0 {
                                rewardLine("⏱ 计时\(r.mins)分钟 +\(r.earnedTime) 金币")
                            }
                            if r.earnedBonus > 0 {
                                rewardLine("🏆 全部完成 +\(r.earnedBonus) 金币")
                            }
                            if r.earnedStreak > 0 {
                                rewardLine("🔥 连续打卡\(r.streak)天 +\(r.earnedStreak) 金币")
                            }
                            if r.totalEarned == 0 {
                                rewardLine("💡 计时即可获得金币奖励（1分钟=1金币）")
                            }
                        }
                    }

                    Text("💰 当前余额：\(r.balance) 金币")
                        .font(theme.fontDesign.font(size: 15, weight: .medium))
                        .foregroundStyle(theme.textPrimary)

                    Button {
                        // H5 此处切换到首页 Tab；iOS 版回到计时任务选择页
                        phase = .selecting
                        reward = nil
                    } label: {
                        Text("🏠 返回首页")
                            .font(theme.fontDesign.font(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.currentTheme.btnColor)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func rewardLine(_ text: String) -> some View {
        Text(text)
            .font(theme.fontDesign.font(size: 14))
            .foregroundStyle(theme.textPrimary)
    }

    // MARK: - 计时控制（对应 H5 startTimer / toggleTimer / resetTimer / endTimer）

    /// 开始计时（模式由任务自身决定：有 duration 为时间模式，有 count 为次数模式，都没有为自由模式）
    private func startTimer(_ task: StudyTask) {
        session = Session(
            taskId: task.id,
            taskTitle: task.title,
            mode: task.duration != nil ? .time : (task.count != nil ? .count : .free),
            targetTime: task.duration,
            targetCount: task.count,
            currentCount: task.currentCount
        )
        phase = .timing
    }

    /// 每秒 tick（对应 H5 setInterval 回调；elapsed 由时间戳算出，锁屏暂停的 tick 会在解锁后自动补齐）
    private func tick() {
        guard var s = session, phase == .timing else { return }
        if s.isRunning {
            // 补记学习时长（锁屏期间没有 tick，这里按时间戳差值一次性补齐）
            let e = s.elapsed
            if e > s.credited {
                store.addStudyTime(e - s.credited)
                s.credited = e
                session = s
            }
            // 时间模式到达目标：自动停止并进入完成流程
            if s.mode == .time, let target = s.targetTime, e >= target {
                stopRunning()
                session?.accumulated = target
                SoundService.shared.playTimerEndSound()
                showTimerComplete()
                return
            }
        }
        tickCounter += 1
    }

    /// 暂停：结算已累计秒数并补记学习时长
    private func stopRunning() {
        guard var s = session, s.isRunning else { return }
        let e = s.elapsed
        s.accumulated = e
        s.startedAt = nil
        s.isRunning = false
        if e > s.credited {
            store.addStudyTime(e - s.credited)
            s.credited = e
        }
        session = s
    }

    /// 开始/继续：记录起始时刻
    private func resumeRunning() {
        guard var s = session, !s.isRunning else { return }
        s.startedAt = Date()
        s.isRunning = true
        session = s
    }

    /// 次数模式：完成一次（对应 H5 btn-timer-count）
    private func countOnce() {
        guard var s = session, s.isRunning else { return }
        SoundService.shared.playClickSound()
        s.currentCount += 1
        session = s
        if let target = s.targetCount, s.currentCount >= target {
            // 次数达成：停止计时，走与时间模式一致的完成流程
            stopRunning()
            SoundService.shared.playTimerEndSound()
            showTimerComplete()
        }
    }

    /// 重置计时（对应 H5 resetTimer；已记入的学习时长保留）
    private func resetTimer() {
        session?.accumulated = 0
        session?.startedAt = nil
        session?.currentCount = 0
        session?.isRunning = false
        whiteNoise.stop()
    }

    /// 结束计时（对应 H5 endTimer：少于10秒且无次数时需确认）
    private func endTimer() {
        guard let s = session else { return }
        stopRunning()
        if s.elapsed < 10 && s.currentCount == 0 {
            showShortEndConfirm = true
        } else {
            showTimerComplete()
        }
    }

    /// 确认放弃过短的计时（对应 H5 confirm 的确定分支）
    private func discardSession() {
        session = nil
        notes = ""
        whiteNoise.stop()
        phase = .selecting
    }

    /// 进入完成页（对应 H5 showTimerComplete：奖励音效 + 3 秒庆祝动画）
    private func showTimerComplete() {
        SoundService.shared.playRewardSound()
        showCelebration = true
        phase = .completed
    }

    /// 完成计时 - 发放奖励（对应 H5 completeTimer，顺序保持一致）
    private func completeTimer() {
        guard let s = session else { return }
        let today = DateHelper.today
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        // 最终用时（时间戳口径），并补记未入账的学习时长
        let finalElapsed = s.elapsed
        if finalElapsed > s.credited {
            store.addStudyTime(finalElapsed - s.credited)
        }

        // 保存学习心得（关联任务名，日历页可见）
        if !trimmed.isEmpty {
            store.addNote(date: today, note: trimmed, taskTitle: s.taskTitle)
        }

        // 更新任务为已完成
        store.updateTask(id: s.taskId) {
            $0.completed = true
            $0.elapsed = finalElapsed
            $0.notes = trimmed
        }

        // 记录打卡
        store.recordActive()

        // 金币奖励：1分钟=1金币
        let mins = finalElapsed / 60
        let earnedTime = store.addCoins(mins, reason: "计时\(mins)分钟")

        // 每日首次计时完成奖励50金币（一天一次）
        let buffer = store.claimDailyBuffer()
        let earnedBuffer = buffer.claimed ? buffer.coins : 0

        // 检查是否全部完成
        let allTasks = store.getTasksByDate(today)
        let allCompleted = !allTasks.isEmpty && allTasks.allSatisfy { $0.completed }
        let earnedBonus = allCompleted ? store.addCoins(50, reason: "完成每日全部任务") : 0

        // 检查连续打卡奖励
        let streak = store.streakDays
        let earnedStreak = (streak >= 7 && streak % 7 == 0)
            ? store.addCoins(100, reason: "连续打卡\(streak)天")
            : 0

        // 延迟播放金币音效（H5 setTimeout 500ms）
        let totalEarned = earnedTime + earnedBuffer + earnedBonus + earnedStreak
        if totalEarned > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SoundService.shared.playCoinSound()
            }
        }

        // 清除计时状态
        session = nil
        notes = ""
        whiteNoise.stop()

        reward = RewardResult(
            mins: mins,
            earnedTime: earnedTime,
            earnedBuffer: earnedBuffer,
            earnedBonus: earnedBonus,
            streak: streak,
            earnedStreak: earnedStreak,
            totalEarned: totalEarned,
            balance: store.coins
        )
        phase = .rewarded
    }

    /// 任务的模式标签（对应 H5 getModeLabel）
    private func modeLabel(_ task: StudyTask) -> String {
        if let duration = task.duration { return "⏱ \(duration / 60)分钟" }
        if let count = task.count { return "🔢 \(count)次" }
        return "自由计时"
    }
}

// MARK: - 按钮样式

private extension Text {
    func timerButtonStyle(theme: ThemeManager) -> some View {
        self
            .font(theme.fontDesign.font(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
