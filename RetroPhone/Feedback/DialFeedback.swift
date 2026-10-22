/// What the dial feels and sounds like, one call per mechanical event.
@MainActor
final class DialFeedback {
    private let haptics = Haptics()
    private let clicks = ClickSynth()

    /// A digit passing under the index.
    func detent() {
        haptics.tap(intensity: 0.42, sharpness: 0.7)
        clicks.play(.detent)
    }

    /// A finger landing on a digit.
    func press() {
        haptics.tap(intensity: 0.3, sharpness: 0.4)
    }

    /// A digit entered into the number.
    func enter() {
        haptics.tap(intensity: 0.85, sharpness: 0.55)
        clicks.play(.enter)
    }
}
