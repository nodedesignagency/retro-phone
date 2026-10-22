import Foundation
import Observation

/// The number being dialled, the last number called, and four speed dials.
@MainActor
@Observable
final class DialerModel {
    static let maxLength = 20
    static let speedDialCount = 4
    private static let keys = Set("0123456789*#+")

    private(set) var digits = ""
    private(set) var lastDialed: String?
    private(set) var speedDials: [String?]

    @ObservationIgnored private let defaults: UserDefaults
    private static let lastDialedKey = "lastDialedNumber"
    private static let speedDialsKey = "speedDials"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastDialed = defaults.string(forKey: Self.lastDialedKey)
        let stored = defaults.stringArray(forKey: Self.speedDialsKey) ?? []
        speedDials = (0..<Self.speedDialCount).map { slot in
            slot < stored.count && !stored[slot].isEmpty ? stored[slot] : nil
        }
    }

    var isEmpty: Bool { digits.isEmpty }

    /// Only digits, so the display can show it in 000 000 0000 slots.
    var isPlainDigits: Bool { digits.allSatisfy(\.isASCIIDigit) }

    var formatted: String { PhoneNumberFormatter.format(digits) }

    var callURL: URL? {
        guard !digits.isEmpty,
              let encoded = digits.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "+*")))
        else { return nil }
        return URL(string: "tel:\(encoded)")
    }

    /// Appends a key. "+" is only accepted as the first character.
    func append(_ key: Character) {
        guard Self.keys.contains(key), digits.count < Self.maxLength else { return }
        if key == "+", !digits.isEmpty { return }
        digits.append(key)
    }

    func deleteLast() {
        guard !digits.isEmpty else { return }
        digits.removeLast()
    }

    func clear() {
        digits = ""
    }

    /// Keeps only dialable characters from pasted text.
    func paste(_ text: String) {
        for character in text where Self.keys.contains(character) {
            append(character)
        }
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

    // MARK: - Speed dials

    /// Stores the current number in a slot. Returns false when there's nothing to store.
    @discardableResult
    func saveSpeedDial(_ slot: Int) -> Bool {
        guard speedDials.indices.contains(slot), !digits.isEmpty else { return false }
        speedDials[slot] = digits
        defaults.set(speedDials.map { $0 ?? "" }, forKey: Self.speedDialsKey)
        return true
    }

    /// Puts a slot's number on the display. Returns false for an empty slot.
    @discardableResult
    func recallSpeedDial(_ slot: Int) -> Bool {
        guard speedDials.indices.contains(slot), let number = speedDials[slot] else { return false }
        digits = number
        return true
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}
