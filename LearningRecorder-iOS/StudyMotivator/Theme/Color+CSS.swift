import SwiftUI

extension Color {
    /// 支持 "#RGB" / "#RRGGBB" / "#RRGGBBAA" / "rgb(r,g,b)" / "rgba(r,g,b,a)"
    init?(css: String) {
        let s = css.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") {
            var hex = String(s.dropFirst())
            var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 255
            switch hex.count {
            case 3:
                hex = hex.map { "\($0)\($0)" }.joined()
                fallthrough
            case 6:
                hex += "FF"
                fallthrough
            case 8:
                guard let v = UInt64(hex, radix: 16) else { return nil }
                r = (v >> 24) & 0xFF; g = (v >> 16) & 0xFF; b = (v >> 8) & 0xFF; a = v & 0xFF
            default:
                return nil
            }
            self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
            return
        }
        if s.hasPrefix("rgb") {
            let inner = s.drop(while: { $0 != "(" }).dropFirst().dropLast()
            let parts = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 3,
                  let r = Double(parts[0]), let g = Double(parts[1]), let b = Double(parts[2]) else { return nil }
            let a = parts.count >= 4 ? (Double(parts[3]) ?? 1) : 1
            self.init(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
            return
        }
        return nil
    }

    /// 便捷非可选版本（解析失败回退透明）
    static func css(_ string: String) -> Color {
        Color(css: string) ?? .clear
    }
}
