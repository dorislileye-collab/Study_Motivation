import Foundation
import Combine

/// 数据存储层 - 对应 H5 版 src/store.js
/// 所有状态变化自动持久化到 UserDefaults (key: study_motivator_data)
final class AppStore: ObservableObject {
    static let shared = AppStore()

    private let storageKey = "study_motivator_data"

    @Published private(set) var state: AppState

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           var loaded = try? JSONDecoder().decode(AppState.self, from: data) {
            // 跨天重置游戏时间（对应 H5 load() 里的 _lastGameDate 检查）
            if loaded.lastGameDate != DateHelper.today {
                loaded.gameTimeToday = 0
                loaded.lastGameDate = DateHelper.today
            }
            self.state = loaded
        } else {
            var def = AppState()
            def.lastGameDate = DateHelper.today
            self.state = def
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - 任务操作

    func getTasksByDate(_ date: String) -> [StudyTask] {
        state.tasks.filter { $0.date == date }
    }

    @discardableResult
    func addTask(title: String, date: String? = nil, count: Int? = nil, duration: Int? = nil, repeatDays: [Int] = []) -> StudyTask {
        let task = StudyTask(title: title, date: date ?? DateHelper.today, count: count, duration: duration, repeatDays: repeatDays)
        state.tasks.append(task)
        save()
        return task
    }

    @discardableResult
    func updateTask(id: String, _ mutate: (inout StudyTask) -> Void) -> StudyTask? {
        guard let idx = state.tasks.firstIndex(where: { $0.id == id }) else { return nil }
        mutate(&state.tasks[idx])
        save()
        return state.tasks[idx]
    }

    func deleteTask(id: String) {
        state.tasks.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func toggleTaskComplete(id: String) -> StudyTask? {
        updateTask(id: id) { $0.completed.toggle() }
    }

    // MARK: - 金币操作

    var coins: Int { state.coins }

    @discardableResult
    func addCoins(_ amount: Int, reason: String) -> Int {
        state.coins += amount
        state.coinRecords.append(CoinRecord(date: DateHelper.today, amount: amount, reason: reason))
        save()
        return amount
    }

    /// 花费金币，返回实际花费金额（不足返回 0）
    @discardableResult
    func spendCoins(_ amount: Int, reason: String = "花费金币") -> Int {
        guard state.coins >= amount else { return 0 }
        state.coins -= amount
        state.coinRecords.append(CoinRecord(date: DateHelper.today, amount: -amount, reason: reason))
        save()
        return amount
    }

    var coinRecords: [CoinRecord] { state.coinRecords }

    /// 每日50金币buffer，每次计时完成时调用，每天只能领一次
    func claimDailyBuffer() -> (claimed: Bool, coins: Int) {
        let today = DateHelper.today
        if state.lastDailyBufferDate == today { return (false, 0) }
        state.coins += 50
        state.lastDailyBufferDate = today
        save()
        return (true, 50)
    }

    // MARK: - 打卡连续

    func recordActive() {
        let today = DateHelper.today
        guard state.lastActiveDate != today else { return }
        if state.lastActiveDate == DateHelper.yesterday {
            state.streakDays += 1
        } else {
            state.streakDays = 1
        }
        state.lastActiveDate = today
        save()
    }

    var streakDays: Int { state.streakDays }

    // MARK: - 游戏时间

    var gameTimeToday: Int {
        let today = DateHelper.today
        if state.lastGameDate != today {
            state.gameTimeToday = 0
            state.lastGameDate = today
            save()
        }
        return state.gameTimeToday
    }

    func addGameTime(_ seconds: Int) {
        let today = DateHelper.today
        if state.lastGameDate != today {
            state.gameTimeToday = 0
            state.lastGameDate = today
        }
        state.gameTimeToday += seconds
        save()
    }

    // MARK: - 学习时长

    func addStudyTime(_ seconds: Int) {
        state.totalStudySeconds += seconds
        let today = DateHelper.today
        state.dailyStudySeconds[today, default: 0] += seconds
        save()
    }

    var totalStudyTime: Int { state.totalStudySeconds }

    func getDailyStudySeconds(_ date: String) -> Int {
        state.dailyStudySeconds[date] ?? 0
    }

    /// 最近 N 天学习时长
    func getRecentStudyDays(_ n: Int) -> [(date: String, seconds: Int, label: String)] {
        DateHelper.recentDays(n).map { ($0.date, state.dailyStudySeconds[$0.date] ?? 0, $0.label) }
    }

    var totalCompletedTasks: Int { state.tasks.filter { $0.completed }.count }

    // MARK: - 学习心得

    /// 添加学习心得；taskTitle 在计时完成后填写时传入关联任务名
    func addNote(date: String, note: String, taskTitle: String? = nil) {
        state.dailyNotes[date, default: []].append(StudyNote(text: note, taskTitle: taskTitle))
        save()
    }

    func getNotes(_ date: String) -> [StudyNote] {
        state.dailyNotes[date] ?? []
    }

    /// 修改心得内容
    func updateNote(date: String, id: String, newText: String) {
        guard let idx = state.dailyNotes[date]?.firstIndex(where: { $0.id == id }) else { return }
        state.dailyNotes[date]?[idx].text = newText
        save()
    }

    /// 删除心得
    func deleteNote(date: String, id: String) {
        state.dailyNotes[date]?.removeAll { $0.id == id }
        save()
    }

    // MARK: - 日历

    var datesWithTasks: Set<String> { Set(state.tasks.map { $0.date }) }
    var datesWithCompletedTasks: Set<String> { Set(state.tasks.filter { $0.completed }.map { $0.date }) }

    // MARK: - 白噪音拥有状态

    var ownedWhiteNoises: [String] { state.ownedWhiteNoises }

    func addOwnedWhiteNoise(_ noiseId: String) {
        guard !state.ownedWhiteNoises.contains(noiseId) else { return }
        state.ownedWhiteNoises.append(noiseId)
        save()
    }
}
