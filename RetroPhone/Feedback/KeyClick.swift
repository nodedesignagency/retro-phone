/// The click and tap every key makes when it goes down.
@MainActor
final class KeyClick {
    static let shared = KeyClick()

    private let haptics = Haptics()
    private let clicks = ClickSynth()

    func down() {
        haptics.tap(intensity: 0.55, sharpness: 0.75)
        clicks.play(.key)
    }
}
