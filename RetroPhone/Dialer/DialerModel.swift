import Foundation
import Observation

/// The number being dialled, plus the last number called.
@MainActor
@Observable
final class DialerModel {
    static let maxDigits = 20

    private(set) var digits = ""
    private(set) var lastDialed: String?

    @ObservationIgnored private let defaults: UserDefaults
    private static let lastDialedKey = "lastDialedNumber"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastDialed = defaults.string(forKey: Self.lastDialedKey)
    }

    var isEmpty: Bool { digits.isEmpty }

    var formatted: String { PhoneNumberFormatter.format(digits) }

    var callURL: URL? {
        digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }

    func append(_ digit: Int) {
        guard (0...9).contains(digit), digits.count < Self.maxDigits else { return }
        digits += String(digit)
    }

    func deleteLast() {
        guard !digits.isEmpty else { return }
        digits.removeLast()
    }

    func clear() {
        digits = ""
    }

    /// Keeps only the digits from pasted text.
    func paste(_ text: String) {
        let incoming = text.filter { $0.isASCII && $0.isNumber }
        digits = String((digits + incoming).prefix(Self.maxDigits))
    }

    /// Calling with nothing dialled brings back the last number, like the iPhone keypad.
    @discardableResult
    func recallLastDialed() -> Bool {
        guard digits.isEmpty, let lastDialed else { return false }
        digits = lastDialed
        return true
    }

    func noteCallPlaced() {
        lastDialed = digits
        defaults.set(digits, forKey: Self.lastDialedKey)
    }
}
