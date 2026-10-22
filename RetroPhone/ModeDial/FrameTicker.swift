import QuartzCore

/// Calls back once per display frame while running, at up to 120 Hz on ProMotion.
@MainActor
final class FrameTicker {
    private let onFrame: (Double) -> Void
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?

    /// `onFrame` receives the seconds elapsed since the previous frame.
    init(onFrame: @escaping (Double) -> Void) {
        self.onFrame = onFrame
    }

    func start() {
        guard link == nil else { return }
        let link = CADisplayLink(target: Target(owner: self), selector: #selector(Target.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.link = link
        lastTimestamp = nil
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    fileprivate func tick(_ link: CADisplayLink) {
        let now = link.targetTimestamp
        let dt = lastTimestamp.map { now - $0 } ?? link.duration
        lastTimestamp = now
        // A long hitch (backgrounding, a breakpoint) shouldn't fling the wheel.
        onFrame(min(max(dt, 0), 1.0 / 30))
    }

    /// CADisplayLink retains its target, so it holds the ticker only weakly.
    @MainActor
    private final class Target: NSObject {
        weak var owner: FrameTicker?

        init(owner: FrameTicker) {
            self.owner = owner
        }

        @objc func tick(_ link: CADisplayLink) {
            owner?.tick(link)
        }
    }
}
