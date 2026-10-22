/// What the dial feels and sounds like, one call per mechanical event.
@MainActor
final class DialFeedback {
    private let haptics = Haptics()
    private let clicks = ClickSynth()

    func detent() {
        haptics.tap(intensity: 0.32, sharpness: 0.55)
        clicks.play(.detent)
    }

    func pulse() {
        haptics.tap(intensity: 0.62, sharpness: 0.92)
        clicks.play(.pulse)
    }

    func stop() {
        haptics.tap(intensity: 1.0, sharpness: 0.42)
        clicks.play(.stop)
    }

    func land() {
        haptics.tap(intensity: 0.75, sharpness: 0.25)
        clicks.play(.land)
    }
}
