import Foundation

/// 全部 16 套主题数据（逐条翻译自 H5 版 src/themes.js）
enum ThemeData {
    static let themes: [AppTheme] = [
        // ===== 默认免费 =====
        AppTheme(
            id: "wood", name: "米色简约木质风", emoji: "🪵", tier: .default, btnColorHex: "#A9885A", price: 0,
            accessories: ThemeAccessories(
                font: .system,
                calendar: CalendarStyle(cellBg: "#FFFDF7", cellBorder: "#E0D5C1", radius: 12, dot: "#C4A66A"),
                task: TaskStyle(bg: "#FFFDF7", border: "#C4A66A", radius: 10, check: "#C4A66A"),
                bg: BackgroundStyle(bgColor: "#F5F0E8", gradient: ["#F5F0E8", "#EDE4D3", "#F5F0E8"], textPrimary: "#5C4A2A", textSecondary: "#8B7355", cardBg: "#FFFDF7", cardBorder: "#E0D5C1"),
                quote: QuoteStyle(color: "#8B6914", glow: false),
                timer: TimerStyle(bg: "#FFFDF7", border: "#C4A66A", number: "#5C4A2A", glow: false),
                game: GameStyle(bg: "#FFF9F0", border: "#E0D5C1")
            )
        ),
        // ===== 普通 =====
        AppTheme(
            id: "sunrise", name: "日出时分", emoji: "🌅", tier: .normal, btnColorHex: "#FF7043", price: 200,
            accessories: ThemeAccessories(
                font: .rounded,
                calendar: CalendarStyle(cellBg: "#FFF3E6", cellBorder: "#FFB38A", radius: 16, dot: "#FF6B35"),
                task: TaskStyle(bg: "#FFE4D6", bgEnd: "#FFF0E8", border: "#FF6B35", radius: 16, check: "#FF6B35"),
                bg: BackgroundStyle(bgColor: "#FFF0E0", gradient: ["#FFD4A8", "#FFE8CC", "#FFF5EA"], textPrimary: "#7A3B1E", textSecondary: "#B06A45", cardBg: "#FFF8F0", cardBorder: "#FFD4B8"),
                quote: QuoteStyle(color: "#FF6B35", glow: true),
                timer: TimerStyle(bg: "#FFF3E6", border: "#FF6B35", number: "#E5522A", glow: true),
                game: GameStyle(bg: "#FFF0E0", border: "#FFB38A")
            )
        ),
        AppTheme(
            id: "kgray", name: "韩系简约灰", emoji: "🩶", tier: .normal, btnColorHex: "#757575", price: 200,
            accessories: ThemeAccessories(
                font: .system,
                calendar: CalendarStyle(cellBg: "#F7F7F7", cellBorder: "#DDDDDD", radius: 4, dot: "#555555"),
                task: TaskStyle(bg: "#FAFAFA", border: "#9E9E9E", radius: 4, check: "#555555"),
                bg: BackgroundStyle(bgColor: "#EFEFEF", gradient: ["#F5F5F5", "#E8E8E8"], textPrimary: "#333333", textSecondary: "#757575", cardBg: "#FFFFFF", cardBorder: "#E0E0E0"),
                quote: QuoteStyle(color: "#424242", glow: false),
                timer: TimerStyle(bg: "#FFFFFF", border: "#BDBDBD", number: "#212121", glow: false),
                game: GameStyle(bg: "#F5F5F5", border: "#DDDDDD")
            )
        ),
        AppTheme(
            id: "springgreen", name: "春日粉绿", emoji: "🌿", tier: .normal, btnColorHex: "#66BB6A", price: 200,
            accessories: ThemeAccessories(
                font: .rounded,
                calendar: CalendarStyle(cellBg: "#EAF7EC", cellBorder: "#A5D6A7", radius: 999, dot: "#43A047"),
                task: TaskStyle(bg: "#F1F8F2", bgEnd: "#FDF5F7", border: "#66BB6A", radius: 20, check: "#66BB6A"),
                bg: BackgroundStyle(bgColor: "#F0FAF0", gradient: ["#E0F2E9", "#FFF0F5", "#F0FFF4"], textPrimary: "#2E5B3F", textSecondary: "#6B9080", cardBg: "#FBFFFB", cardBorder: "#C8E6C9"),
                quote: QuoteStyle(color: "#43A047", glow: true),
                timer: TimerStyle(bg: "#F1FBF3", border: "#66BB6A", number: "#2E7D32", glow: true),
                game: GameStyle(bg: "#F4FBF4", border: "#A5D6A7")
            )
        ),
        AppTheme(
            id: "minimal", name: "极简灰白", emoji: "⬜", tier: .normal, btnColorHex: "#424242", price: 200,
            accessories: ThemeAccessories(
                font: .system,
                calendar: CalendarStyle(cellBg: "#FFFFFF", cellBorder: "#F0F0F0", radius: 0, dot: "#111111"),
                task: TaskStyle(bg: "#FFFFFF", border: "#111111", radius: 0, check: "#111111"),
                bg: BackgroundStyle(bgColor: "#FFFFFF", gradient: ["#FFFFFF", "#FCFCFC"], textPrimary: "#111111", textSecondary: "#888888", cardBg: "#FFFFFF", cardBorder: "#ECECEC"),
                quote: QuoteStyle(color: "#111111", glow: false),
                timer: TimerStyle(bg: "#FFFFFF", border: "#111111", number: "#111111", glow: false),
                game: GameStyle(bg: "#FFFFFF", border: "#E5E5E5")
            )
        ),
        // ===== 进阶 =====
        AppTheme(
            id: "pixel", name: "像素疯狂", emoji: "👾", tier: .advanced, btnColorHex: "#E65100", price: 400,
            accessories: ThemeAccessories(
                font: .monospaced,
                calendar: CalendarStyle(cellBg: "#16213E", cellBorder: "#00FF41", radius: 0, dot: "#FFD700"),
                task: TaskStyle(bg: "#16213E", border: "#00FF41", radius: 0, check: "#00FF41"),
                bg: BackgroundStyle(bgColor: "#0F0F23", gradient: ["#0F0F23", "#1A1A3E", "#0F2027"], textPrimary: "#E0FFE8", textSecondary: "#7FBC8C", cardBg: "#16213E", cardBorder: "#0F3460"),
                quote: QuoteStyle(color: "#FFD700", glow: true),
                timer: TimerStyle(bg: "#16213E", border: "#00FF41", number: "#00FF41", glow: true),
                game: GameStyle(bg: "#0F0F23", border: "#00FF41")
            )
        ),
        AppTheme(
            id: "cat", name: "浅黄萌猫咪", emoji: "🐱", tier: .advanced, btnColorHex: "#FFA000", price: 400,
            accessories: ThemeAccessories(
                font: .rounded,
                calendar: CalendarStyle(cellBg: "#FFF6C9", cellBorder: "#FFC93C", radius: 22, dot: "#FF9800", decorationImage: "cat-paw"),
                task: TaskStyle(bg: "#FFF6C9", bgEnd: "#FFFBE6", border: "#FFC93C", radius: 22, check: "#FF9800", decorationImage: "cat-head"),
                bg: BackgroundStyle(bgColor: "#FFF9D6", gradient: ["#FFF3B0", "#FFF9D6", "#FFE98A"], textPrimary: "#7A5200", textSecondary: "#B08A2E", cardBg: "#FFFBE6", cardBorder: "#FFD95A"),
                quote: QuoteStyle(color: "#FF8C00", glow: true),
                timer: TimerStyle(bg: "#FFF6C9", border: "#FFC93C", number: "#E68A00", glow: true),
                game: GameStyle(bg: "#FFF9D6", border: "#FFC93C")
            )
        ),
        AppTheme(
            id: "beach", name: "夏日海滩", emoji: "🏖️", tier: .advanced, btnColorHex: "#0096C7", price: 400,
            accessories: ThemeAccessories(
                font: .rounded,
                calendar: CalendarStyle(cellBg: "#E3F4FC", cellBorder: "#4FC3F7", radius: 14, dot: "#006994", decorationImage: "palm-leaf"),
                task: TaskStyle(bg: "#E3F4FC", bgEnd: "#FDF6E3", border: "#0096C7", radius: 14, check: "#006994", decorationImage: "seashell"),
                bg: BackgroundStyle(bgColor: "#DDF2FC", gradient: ["#7FD4F5", "#C8EAF7", "#FCEBB6"], textPrimary: "#075A7A", textSecondary: "#3E8EAD", cardBg: "#F0FAFF", cardBorder: "#8ED8F0"),
                quote: QuoteStyle(color: "#006994", glow: true),
                timer: TimerStyle(bg: "#E3F4FC", border: "#0096C7", number: "#005F8A", glow: true),
                game: GameStyle(bg: "#E8F6FD", border: "#4FC3F7")
            )
        ),
        // ===== 高阶 =====
        AppTheme(
            id: "punk", name: "甜酷朋克", emoji: "🎸", tier: .high, btnColorHex: "#FF2E93", price: 700,
            accessories: ThemeAccessories(
                font: .rounded,
                calendar: CalendarStyle(cellBg: "#2D1B4E", cellBorder: "#FF2E93", radius: 10, dot: "#00E5FF"),
                task: TaskStyle(bg: "#2D1B4E", border: "#FF2E93", radius: 10, check: "#00E5FF"),
                bg: BackgroundStyle(bgColor: "#1A0B2E", gradient: ["#1A0B2E", "#3D1A5C", "#120821"], textPrimary: "#FFE3F2", textSecondary: "#C792EA", cardBg: "#251242", cardBorder: "#5C2E8C"),
                quote: QuoteStyle(color: "#FF2E93", glow: true),
                timer: TimerStyle(bg: "#251242", border: "#FF2E93", number: "#00E5FF", glow: true),
                game: GameStyle(bg: "#1A0B2E", border: "#FF2E93")
            )
        ),
        AppTheme(
            id: "gothic", name: "暗黑哥特", emoji: "🦇", tier: .high, btnColorHex: "#8B0000", price: 700,
            accessories: ThemeAccessories(
                font: .serif,
                calendar: CalendarStyle(cellBg: "#170A1E", cellBorder: "#8B0000", radius: 2, dot: "#B22222"),
                task: TaskStyle(bg: "#1C0D24", border: "#8B0000", radius: 2, check: "#B22222"),
                bg: BackgroundStyle(bgColor: "#0D0512", gradient: ["#0D0512", "#1E0A26", "#0D0512"], textPrimary: "#D8C8E0", textSecondary: "#8A7496", cardBg: "#170A1E", cardBorder: "#3D1A4E"),
                quote: QuoteStyle(color: "#C41E3A", glow: true),
                timer: TimerStyle(bg: "#170A1E", border: "#8B0000", number: "#FF3355", glow: true),
                game: GameStyle(bg: "#0F0616", border: "#4A1040")
            )
        ),
        AppTheme(
            id: "bear", name: "浅卡其玩偶熊", emoji: "🧸", tier: .high, btnColorHex: "#8B5A2B", price: 700,
            accessories: ThemeAccessories(
                font: .serif,
                calendar: CalendarStyle(cellBg: "#F0DCC0", cellBorder: "#8B5A2B", radius: 12, dot: "#6B4423", decorationImage: "bear-paw"),
                task: TaskStyle(bg: "#F0DCC0", bgEnd: "#F7E9D4", border: "#8B5A2B", radius: 12, check: "#6B4423", decorationImage: "bear-head"),
                bg: BackgroundStyle(bgColor: "#E9D2B4", gradient: ["#DFC49F", "#EFDCC2", "#D4B48C"], textPrimary: "#4A2F17", textSecondary: "#7D5A38", cardBg: "#F5E6CF", cardBorder: "#B98E5F"),
                quote: QuoteStyle(color: "#6B4423", glow: false),
                timer: TimerStyle(bg: "#F0DCC0", border: "#8B5A2B", number: "#4A2F17", glow: false),
                game: GameStyle(bg: "#EDD8BC", border: "#B98E5F")
            )
        ),
        // ===== 顶级 =====
        AppTheme(
            id: "matrix", name: "数据矩阵", emoji: "💻", tier: .top, btnColorHex: "#00A550", price: 1200,
            accessories: ThemeAccessories(
                font: .monospaced,
                calendar: CalendarStyle(cellBg: "#050F05", cellBorder: "#00FF41", radius: 0, dot: "#00FF41"),
                task: TaskStyle(bg: "#071207", border: "#00FF41", radius: 0, check: "#00FF41"),
                bg: BackgroundStyle(bgColor: "#000000", gradient: ["#000000", "#041004", "#000500"], textPrimary: "#B8FFC4", textSecondary: "#4E9A5E", cardBg: "#050F05", cardBorder: "#0A4D1C"),
                quote: QuoteStyle(color: "#00FF41", glow: true),
                timer: TimerStyle(bg: "#050F05", border: "#00FF41", number: "#00FF41", glow: true),
                game: GameStyle(bg: "#020802", border: "#0A4D1C")
            )
        ),
        AppTheme(
            id: "doomsday", name: "末日世界", emoji: "☢️", tier: .top, btnColorHex: "#B7410E", price: 1200,
            accessories: ThemeAccessories(
                font: .heavy,
                calendar: CalendarStyle(cellBg: "#2A2520", cellBorder: "#B7410E", radius: 3, dot: "#FF6B1A"),
                task: TaskStyle(bg: "#252018", border: "#B7410E", radius: 3, check: "#FF6B1A"),
                bg: BackgroundStyle(bgColor: "#171410", gradient: ["#171410", "#2A2520", "#141210"], textPrimary: "#E0CBA8", textSecondary: "#9A8265", cardBg: "#221D17", cardBorder: "#5A4632"),
                quote: QuoteStyle(color: "#FF6B1A", glow: true),
                timer: TimerStyle(bg: "#2A2520", border: "#B7410E", number: "#FF4444", glow: true),
                game: GameStyle(bg: "#1A1510", border: "#6B4226")
            )
        ),
        AppTheme(
            id: "deepsea", name: "深海之息", emoji: "🌊", tier: .top, btnColorHex: "#0077B6", price: 1200,
            accessories: ThemeAccessories(
                font: .rounded,
                calendar: CalendarStyle(cellBg: "rgba(0,50,95,0.75)", cellBorder: "#1A6B8A", radius: 14, dot: "#7FDBDA", decorationImage: "jellyfish"),
                task: TaskStyle(bg: "rgba(0,60,110,0.55)", border: "#00B4D8", radius: 14, check: "#7FDBDA", decorationImage: "seashell"),
                bg: BackgroundStyle(bgColor: "#061A30", gradient: ["#020E1D", "#0A2A4A", "#062038"], textPrimary: "#D2F1F4", textSecondary: "#7AAFC0", cardBg: "rgba(4,34,62,0.85)", cardBorder: "#14506B"),
                quote: QuoteStyle(color: "#7FDBDA", glow: true),
                timer: TimerStyle(bg: "rgba(4,30,56,0.9)", border: "#00B4D8", number: "#00FFFF", glow: true),
                game: GameStyle(bg: "#052038", border: "#1A6B8A")
            )
        ),
        // ===== 传说 =====
        AppTheme(
            id: "cyber", name: "霓虹赛博", emoji: "🌆", tier: .legend, btnColorHex: "#8A2BE2", price: 2000,
            accessories: ThemeAccessories(
                font: .monospaced,
                calendar: CalendarStyle(cellBg: "#12122E", cellBorder: "#00D4FF", radius: 6, dot: "#FF006E", decorationImage: "city-skyline"),
                task: TaskStyle(bg: "#14143A", border: "#00D4FF", radius: 6, check: "#FF006E"),
                bg: BackgroundStyle(bgColor: "#08081A", gradient: ["#08081A", "#1C0A38", "#0A1B30"], textPrimary: "#E0F7FF", textSecondary: "#7C93B8", cardBg: "#101030", cardBorder: "#2A2A5A"),
                quote: QuoteStyle(color: "#00FF88", glow: true),
                timer: TimerStyle(bg: "#12122A", border: "#00D4FF", number: "#00FF88", glow: true),
                game: GameStyle(bg: "#0D0D20", border: "#FF006E")
            )
        ),
        AppTheme(
            id: "sakura", name: "日系樱花粉", emoji: "🌸", tier: .legend, btnColorHex: "#EC6A9C", price: 2000,
            accessories: ThemeAccessories(
                font: .rounded,
                calendar: CalendarStyle(cellBg: "#FFF0F5", cellBorder: "#F48FB1", radius: 999, dot: "#EC407A", decorationImage: "cherry-blossom"),
                task: TaskStyle(bg: "#FFE9F1", bgEnd: "#FFF6F9", border: "#F06292", radius: 18, check: "#EC407A", decorationImage: "butterfly"),
                bg: BackgroundStyle(bgColor: "#FFF2F6", gradient: ["#FFE4EE", "#FFF0F5", "#FDE3EC"], textPrimary: "#8C4A62", textSecondary: "#C08497", cardBg: "#FFFAFC", cardBorder: "#F5C6D6"),
                quote: QuoteStyle(color: "#EC407A", glow: true),
                timer: TimerStyle(bg: "#FFF5F8", border: "#F48FB1", number: "#C2185B", glow: true),
                game: GameStyle(bg: "#FFF5F8", border: "#F5C6D6")
            )
        ),
    ]

    static func theme(byId id: String) -> AppTheme {
        themes.first { $0.id == id } ?? themes[0]
    }

    static let defaultThemeId = "wood"
}
