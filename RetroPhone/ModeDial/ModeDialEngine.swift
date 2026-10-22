import Foundation
import Observation

/// Turns the ring like a camera's mode dial: it follows the finger with a
/// click at every digit, coasts when flicked, and settles on the nearest
/// digit. Letting go after a turn enters the digit under the index; so does
/// tapping a digit, which spins it round first.
@MainActor
@Observable
final class ModeDialEngine {
    enum Phase: Equatable {
        case idle
        case dragging
        /// Coasting or springing onto a detent.
        case settling
    }

    /// How far the ring has turned; the digit under the index is the one whose
    /// rest angle equals this. Can briefly leave its range while rubber-banding.
    private(set) var offset: Double
    private(set) var phase: Phase = .idle
    /// The item a finger is resting on.
    private(set) var pressedItem: Int?
    /// Bumped each time a digit is entered, for the window's flash.
    private(set) var entries = 0

    let geometry: ModeDialGeometry
    @ObservationIgnored var onEnter: ((Int) -> Void)?
    @ObservationIgnored var reduceMotion = false

    var armedItem: Int { geometry.nearestItem(toOffset: offset) }
    var armedDigit: Int { geometry.digit(ofItem: armedItem) }

    // Feel
    private static let springStiffness = 260.0
    private static let springDamping = 2 * 260.0.squareRoot()
    /// Coasting friction; velocity halves about every 0.12 s.
    private static let friction = 5.8
    /// Below this speed a released ring springs straight onto its detent.
    private static let crawlSpeed = 240.0
    /// A flick carries at most this many digits past the release point.
    private static let maxCoastSteps = 4.0
    /// Finger movement that turns a press into a drag rather than a tap.
    private static let tapTravel = 0.35
    private static let tapDuration = 0.3
    private static let rubberBand = 0.3
    private static let detentInterval = 0.04

    private struct Touch {
        let startOffset: Double
        let startTime: TimeInterval
        let item: Int?
        var lastAngle: Double
        var rawOffset: Double
        var travel = 0.0
        var samples: [(time: TimeInterval, offset: Double)] = []
    }

    private struct Motion {
        var target: Double
        var velocity: Double
        var coasting: Bool
        var enters: Bool
    }

    @ObservationIgnored private let feedback: DialFeedback
    @ObservationIgnored private var ticker: FrameTicker?
    @ObservationIgnored private var touch: Touch?
    @ObservationIgnored private var motion: Motion?
    @ObservationIgnored private var queue: [Int] = []
    @ObservationIgnored private var lastArmed: Int
    @ObservationIgnored private var lastDetentTime: TimeInterval = 0
    @ObservationIgnored private var clock: () -> TimeInterval

    init(
        geometry: ModeDialGeometry = ModeDialGeometry(),
        startingAt item: Int = 4,
        feedback: DialFeedback? = nil,
        clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.geometry = geometry
        self.feedback = feedback ?? DialFeedback()
        self.clock = clock
        offset = geometry.offset(forItem: item)
        lastArmed = item
        ticker = FrameTicker { [weak self] dt in self?.advance(by: dt) }
    }

    // MARK: - Touch

    /// `angle` is the finger's angle about the ring's centre; `item` is the
    /// digit under it, if any.
    func touchBegan(angle: Double, item: Int?) {
        let now = clock()
        // Catching the ring stops it where it is.
        if motion != nil {
            motion = nil
            ticker?.stop()
        }
        touch = Touch(startOffset: offset, startTime: now, item: item, lastAngle: angle, rawOffset: offset, samples: [(now, offset)])
        pressedItem = item
        phase = .dragging
        if item != nil { feedback.press() }
    }

    func touchMoved(angle: Double) {
        guard var t = touch else { return }
        var delta = angle - t.lastAngle
        if delta > 180 { delta -= 360 } else if delta < -180 { delta += 360 }
        t.lastAngle = angle
        t.rawOffset -= delta
        t.travel += abs(delta)
        let now = clock()
        t.samples.append((now, t.rawOffset))
        if t.samples.count > 8 { t.samples.removeFirst() }
        touch = t
        if t.travel > geometry.step * Self.tapTravel { pressedItem = nil }
        setOffset(Self.rubberBanded(t.rawOffset, within: 0...geometry.maxOffset))
    }

    func touchEnded() {
        guard let t = touch else { return }
        touch = nil
        pressedItem = nil
        let now = clock()
        let isTap = now - t.startTime < Self.tapDuration && t.travel < geometry.step * Self.tapTravel

        if isTap {
            if let item = t.item {
                phase = .idle
                select(item)
            } else {
                settle(velocity: 0, enters: false)
            }
            return
        }

        // Release speed from the last few samples.
        var velocity = 0.0
        if let first = t.samples.first(where: { now - $0.time <= 0.08 }), let last = t.samples.last,
           last.time > first.time {
            velocity = (last.offset - first.offset) / (last.time - first.time)
        }
        settle(velocity: velocity, enters: t.travel >= geometry.step * 0.5)
    }

    func touchCancelled() {
        guard touch != nil else { return }
        touch = nil
        pressedItem = nil
        settle(velocity: 0, enters: false)
    }

    // MARK: - Tap to dial

    /// Spins the ring to a digit and enters it. Digits asked for while the
    /// ring is busy queue up.
    func dial(digit: Int) {
        guard let item = geometry.item(forDigit: digit) else { return }
        select(item)
    }

    private func select(_ item: Int) {
        if reduceMotion {
            setOffset(geometry.offset(forItem: item), silently: true)
            enter(item)
            return
        }
        if phase == .idle, motion == nil {
            if item == armedItem, abs(offset - geometry.offset(forItem: item)) < 0.01 {
                enter(item)
            } else {
                spin(to: item)
            }
        } else if queue.count < 24 {
            queue.append(item)
        }
    }

    private func spin(to item: Int) {
        phase = .settling
        motion = Motion(target: geometry.offset(forItem: item), velocity: 0, coasting: false, enters: true)
        ticker?.start()
    }

    // MARK: - Mechanism

    private func settle(velocity: Double, enters: Bool) {
        let range = 0...geometry.maxOffset
        var target: Double
        var coasting = false
        if abs(velocity) > Self.crawlSpeed, range.contains(offset) {
            let carry = min(max(velocity / Self.friction, -Self.maxCoastSteps * geometry.step), Self.maxCoastSteps * geometry.step)
            target = offset + carry
            coasting = true
        } else {
            target = offset
        }
        target = min(max(target, range.lowerBound), range.upperBound)
        target = geometry.offset(forItem: geometry.nearestItem(toOffset: target))
        phase = .settling
        motion = Motion(target: target, velocity: velocity, coasting: coasting, enters: enters)
        ticker?.start()
    }

    private func enter(_ item: Int) {
        entries += 1
        feedback.enter()
        onEnter?(geometry.digit(ofItem: item))
    }

    private func finishMotion() {
        guard let m = motion else { return }
        motion = nil
        setOffset(m.target, silently: true)
        phase = .idle
        if m.enters { enter(geometry.nearestItem(toOffset: m.target)) }
        if queue.isEmpty {
            ticker?.stop()
        } else {
            select(queue.removeFirst())
        }
    }

    private func setOffset(_ value: Double, silently: Bool = false) {
        offset = value
        let armed = armedItem
        guard armed != lastArmed else { return }
        lastArmed = armed
        guard !silently else { return }
        let now = clock()
        if now - lastDetentTime >= Self.detentInterval {
            lastDetentTime = now
            feedback.detent()
        }
    }

    private func advance(by dt: Double) {
        guard var m = motion else {
            ticker?.stop()
            return
        }
        var x = offset
        var v = m.velocity
        if m.coasting {
            let before = x - m.target
            v *= exp(-Self.friction * dt)
            x += v * dt
            let passed = (before < 0) != (x - m.target < 0)
            if abs(v) < Self.crawlSpeed || passed || abs(x - m.target) < geometry.step * 0.6 {
                m.coasting = false
            }
        } else {
            let steps = 4
            let h = dt / Double(steps)
            for _ in 0..<steps {
                let a = -Self.springStiffness * (x - m.target) - Self.springDamping * v
                v += a * h
                x += v * h
            }
        }
        m.velocity = v
        motion = m
        if abs(x - m.target) < 0.05, abs(v) < 3 {
            finishMotion()
        } else {
            setOffset(x)
        }
    }

    private static func rubberBanded(_ value: Double, within range: ClosedRange<Double>) -> Double {
        if value < range.lowerBound { return range.lowerBound + (value - range.lowerBound) * rubberBand }
        if value > range.upperBound { return range.upperBound + (value - range.upperBound) * rubberBand }
        return value
    }
}
