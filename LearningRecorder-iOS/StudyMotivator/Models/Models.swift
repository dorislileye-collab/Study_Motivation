import Foundation

/// 学习任务（对应 H5 版 store.js 中的 Task）
struct StudyTask: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    /// 日期 YYYY-MM-DD
    var date: String
    var completed: Bool
    /// 次数模式：目标次数
    var count: Int?
    /// 时间模式：目标时长(秒)
    var duration: Int?
    /// 学习心得
    var notes: String
    /// 已用时(秒)
    var elapsed: Int
    /// 已完成次数
    var currentCount: Int
    /// 重复星期几 (0=周日 ... 6=周六)，空数组表示不重复
    var repeatDays: [Int]

    init(id: String = UUID().uuidString,
         title: String,
         date: String,
         completed: Bool = false,
         count: Int? = nil,
         duration: Int? = nil,
         notes: String = "",
         elapsed: Int = 0,
         currentCount: Int = 0,
         repeatDays: [Int] = []) {
        self.id = id
        self.title = title
        self.date = date
        self.completed = completed
        self.count = count
        self.duration = duration
        self.notes = notes
        self.elapsed = elapsed
        self.currentCount = currentCount
        self.repeatDays = repeatDays
    }
}

/// 金币流水记录
struct CoinRecord: Codable, Equatable {
    var date: String
    var amount: Int
    var reason: String
}

/// 持久化的完整应用状态（对应 H5 版 AppState）
struct AppState: Codable {
    var tasks: [StudyTask] = []
    var coins: Int = 0
    var coinRecords: [CoinRecord] = []
    var gameTimeToday: Int = 0
    var streakDays: Int = 0
    var lastActiveDate: String = ""
    var totalStudySeconds: Int = 0
    var dailyStudySeconds: [String: Int] = [:]
    var dailyNotes: [String: [String]] = [:]
    var lastDailyBufferDate: String = ""
    var ownedWhiteNoises: [String] = []
    var lastGameDate: String = ""
}

// MARK: - 日期工具

enum DateHelper {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// 今天日期字符串 YYYY-MM-DD
    static var today: String { formatter.string(from: Date()) }

    static func string(from date: Date) -> String { formatter.string(from: date) }

    static func date(from string: String) -> Date? { formatter.date(from: string) }

    static var yesterday: String {
        formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    }

    /// 星期几 (0=周日 ... 6=周六)，与 JS Date.getDay() 一致
    static func weekday(of date: Date = Date()) -> Int {
        Calendar(identifier: .gregorian).component(.weekday, from: date) - 1
    }

    /// 最近 N 天的 (dateString, seconds查取用, 星期label)
    static func recentDays(_ n: Int) -> [(date: String, label: String)] {
        let labels = ["日", "一", "二", "三", "四", "五", "六"]
        var result: [(String, String)] = []
        let cal = Calendar(identifier: .gregorian)
        for i in stride(from: n - 1, through: 0, by: -1) {
            let d = cal.date(byAdding: .day, value: -i, to: Date())!
            result.append((formatter.string(from: d), labels[cal.component(.weekday, from: d) - 1]))
        }
        return result
    }
}

/// 秒数格式化工具
enum TimeFormatter {
    /// 秒 → "MM:SS" 或 "HH:MM:SS"
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }

    /// 秒 → "X小时X分钟" / "X分钟"
    static func humanReadable(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60
        if h > 0 && m > 0 { return "\(h)小时\(m)分钟" }
        if h > 0 { return "\(h)小时" }
        if m > 0 { return "\(m)分钟" }
        return "\(seconds)秒"
    }
}
