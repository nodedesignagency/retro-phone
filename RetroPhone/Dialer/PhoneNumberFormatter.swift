import Foundation

/// Formats digits as they are dialled, the way the iPhone keypad does.
enum PhoneNumberFormatter {
    enum Style {
        /// (415) 555-0123, for regions on the North American Numbering Plan.
        case northAmerican
        /// Digits as dialled.
        case plain
    }

    static var currentStyle: Style {
        let region = Locale.current.region?.identifier ?? ""
        return northAmericanRegions.contains(region) ? .northAmerican : .plain
    }

    static func format(_ digits: String, style: Style = currentStyle) -> String {
        guard style == .northAmerican, !digits.isEmpty else { return digits }
        if digits.first == "1" {
            let rest = String(digits.dropFirst())
            if rest.isEmpty { return digits }
            if rest.count <= 3 { return "1 " + rest }
            if rest.count <= 10 { return "1 " + areaCodeForm(rest) }
            return digits
        }
        if digits.first == "0" { return digits }
        switch digits.count {
        case ...3: return digits
        case 4...7: return localForm(digits)
        case 8...10: return areaCodeForm(digits)
        default: return digits
        }
    }

    /// 555-0123
    private static func localForm(_ digits: String) -> String {
        let characters = Array(digits)
        return String(characters[..<3]) + "-" + String(characters[3...])
    }

    /// (415) 555-0123, or as much of it as has been dialled.
    private static func areaCodeForm(_ digits: String) -> String {
        let characters = Array(digits)
        var result = "(" + String(characters[..<3]) + ") "
        result += String(characters[3..<min(6, characters.count)])
        if characters.count > 6 {
            result += "-" + String(characters[6...])
        }
        return result
    }

    private static let northAmericanRegions: Set<String> = [
        "US", "CA", "AG", "AI", "AS", "BB", "BM", "BS", "DM", "DO", "GD", "GU", "JM", "KN",
        "KY", "LC", "MP", "MS", "PR", "SX", "TC", "TT", "VC", "VG", "VI",
    ]
}
