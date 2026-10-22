import Foundation
import Observation

/// Drives the finger wheel the way the mechanism inside a real dial does: it
/// follows the finger round to the stop, then the spring and governor bring it
/// home at a steady pace, sending one pulse per digit.
@MainActor
@Observable
final class RotaryDialEngine {
    enum Phase: Equatable {
        case idle
        /// A finger is in a hole.
        case dragging
        /// Tap-to-dial is pulling the wheel round by itself.
        case winding
        /// The spring is bringing the wheel home.
        case returning
    }

    /// Clockwise rotation of the finger wheel, in degrees.
    private(set) var rotation: Double = 0
    private(set) var phase: Phase = .idle
    /// The hole being dialled; lit until the wheel comes to rest.
    private(set) var engagedHole: Int?

    let geometry: DialGeometry
    /// Called with each digit as it is dialled.
    @ObservationIgnored var onDial: ((Int) -> Void)?
    /// Skips the wheel animation for tap-to-dial.
    @ObservationIgnored var reduceMotion = false

    /// Return speed in degrees per second: about eleven pulses a second, like a real governor.
    private static let governorSpeed = 290.0
    private static let launchAcceleration = 5_200.0
    /// How close to the stop a release still counts as dialled.
    private static let stopTolerance = 6.0
    /// Pause at the stop during tap-to-dial, so the finger "lets go".
    private static let stopDwell = 0.07
    private static let settleStiffness = 900.0
    private static let settleDamping = 33.0
    private static let maxQueuedDigits = 24

    private struct Touch {
        let start: CGPoint
        let startTime: TimeInterval
        let startedIdle: Bool
        /// The digit printed on the plate under the finger, which never moves.
        let printedHole: Int?
        /// The hole the finger caught the wheel by, if any.
        var heldHole: Int?
        var lastAngle: Double
        var wander = 0.0
    }

    private enum Motion {
        case none
        case winding(from: Double, to: Double, elapsed: Double, duration: Double)
        case holding(remaining: Double)
        case returning(velocity: Double)
        case settling(velocity: Double)
    }

    @ObservationIgnored private let feedback: DialFeedback
    @ObservationIgnored private var ticker: FrameTicker?
    @ObservationIgnored private var touch: Touch?
    @ObservationIgnored private var motion = Motion.none
    @ObservationIgnored private var queue: [Int] = []
    @ObservationIgnored private var isAutoDialing = false
    @ObservationIgnored private var restingOnStop = false
    @ObservationIgnored private var pulses = 0
    @ObservationIgnored private var returnDistance = 0.0

    init(geometry: DialGeometry = .chromeGPO, feedback: DialFeedback? = nil) {
        self.geometry = geometry
        self.feedback = feedback ?? DialFeedback()
        ticker = FrameTicker { [weak self] dt in self?.advance(by: dt) }
    }

    // MARK: - Touch

    /// `point` is in unit dial space: centre at the origin, plate radius 1, y down.
    func touchBegan(at point: CGPoint) {
        var touch = Touch(
            start: point,
            startTime: ProcessInfo.processInfo.systemUptime,
            startedIdle: phase == .idle,
            printedHole: geometry.hole(at: point),
            heldHole: nil,
            lastAngle: DialGeometry.angle(of: point)
        )
        switch phase {
        case .idle:
            if let hole = touch.printedHole {
                hold(hole)
                touch.heldHole = hole
            }
        case .returning where !isAutoDialing:
            // Catch the wheel on its way home by whichever hole is under the finger.
            if let hole = geometry.hole(at: point, rotation: rotation),
               rotation < geometry.travel(ofHole: hole) {
                hold(hole)
                touch.heldHole = hole
            }
        default:
            break
        }
        self.touch = touch
    }

    func touchMoved(to point: CGPoint) {
        guard var touch else { return }
        touch.wander = max(touch.wander, DialGeometry.distance(point, touch.start))
        let angle = DialGeometry.angle(of: point)
        var delta = angle - touch.lastAngle
        if delta > 180 { delta -= 360 } else if delta < -180 { delta += 360 }
        touch.lastAngle = angle
        self.touch = touch

        // Near the hub the angle swings wildly, so hold the wheel still there.
        guard phase == .dragging,
              let hole = touch.heldHole,
              DialGeometry.distance(point, .zero) > 0.22
        else { return }

        let travel = geometry.travel(ofHole: hole)
        setRotation(min(max(rotation + delta, 0), travel))
        if rotation >= travel - 0.001 {
            reachStop()
        } else if rotation < travel - 4 {
            restingOnStop = false
        }
    }

    func touchEnded() {
        guard let touch else { return }
        self.touch = nil
        let duration = ProcessInfo.processInfo.systemUptime - touch.startTime
        let isTap = duration < 0.35 && touch.wander < 0.07

        if isTap, let printed = touch.printedHole {
            // A tap dials whatever is printed under the finger.
            if touch.heldHole != nil {
                if touch.startedIdle {
                    settleAtRest()
                } else {
                    letGo(dialling: false)
                }
            }
            dial(hole: printed)
            return
        }

        guard phase == .dragging, let hole = touch.heldHole else { return }
        letGo(dialling: rotation >= geometry.travel(ofHole: hole) - Self.stopTolerance)
    }

    // MARK: - Tap to dial

    /// Pulls the wheel round from a digit's hole by itself. Digits asked for while
    /// the wheel is busy are queued and dialled in order.
    func dial(digit: Int) {
        guard let hole = geometry.hole(forDigit: digit) else { return }
        dial(hole: hole)
    }

    private func dial(hole: Int) {
        if reduceMotion {
            feedback.stop()
            onDial?(geometry.digit(ofHole: hole))
            return
        }
        if phase == .idle && queue.isEmpty {
            wind(hole)
        } else if queue.count < Self.maxQueuedDigits {
            queue.append(hole)
        }
    }

    // MARK: - Mechanism

    private func hold(_ hole: Int) {
        engagedHole = hole
        phase = .dragging
        motion = .none
        ticker?.stop()
    }

    private func wind(_ hole: Int) {
        isAutoDialing = true
        engagedHole = hole
        phase = .winding
        let target = geometry.travel(ofHole: hole)
        let hurry = queue.isEmpty ? 1.0 : 0.8
        let duration = max((0.12 + (target - rotation) / 760) * hurry, 0.05)
        motion = .winding(from: rotation, to: target, elapsed: 0, duration: duration)
        ticker?.start()
    }

    private func letGo(dialling: Bool) {
        if dialling, let hole = engagedHole {
            onDial?(geometry.digit(ofHole: hole))
        }
        restingOnStop = false
        returnDistance = rotation
        phase = .returning
        motion = .returning(velocity: 0)
        ticker?.start()
    }

    private func settleAtRest() {
        motion = .none
        phase = .idle
        engagedHole = nil
        if rotation != 0 { setRotation(0) }
    }

    private func finishCycle() {
        settleAtRest()
        if queue.isEmpty {
            isAutoDialing = false
            ticker?.stop()
        } else {
            wind(queue.removeFirst())
        }
    }

    private func reachStop() {
        guard !restingOnStop else { return }
        restingOnStop = true
        feedback.stop()
    }

    private func setRotation(_ value: Double) {
        rotation = value
        let count = geometry.pulseCount(at: value)
        guard count != pulses else { return }
        if phase == .returning {
            if count < pulses { feedback.pulse() }
        } else {
            feedback.detent()
        }
        pulses = count
    }

    private func advance(by dt: Double) {
        switch motion {
        case .none:
            ticker?.stop()

        case let .winding(from, to, elapsed, duration):
            let progress = min((elapsed + dt) / duration, 1)
            setRotation(from + (to - from) * Self.easeInOut(progress))
            if progress >= 1 {
                reachStop()
                motion = .holding(remaining: Self.stopDwell)
            } else {
                motion = .winding(from: from, to: to, elapsed: elapsed + dt, duration: duration)
            }

        case let .holding(remaining):
            if remaining <= dt {
                letGo(dialling: true)
            } else {
                motion = .holding(remaining: remaining - dt)
            }

        case var .returning(velocity):
            let topSpeed = Self.governorSpeed * (queue.isEmpty ? 1 : 1.3)
            velocity = max(velocity - Self.launchAcceleration * dt, -topSpeed)
            // The last few degrees ease onto the rest stop.
            let cushion = 0.45 + 0.55 * min(rotation / 14, 1)
            let next = rotation + velocity * cushion * dt
            if next > 0 {
                setRotation(next)
                motion = .returning(velocity: velocity)
            } else {
                if returnDistance > 8 { feedback.land() }
                setRotation(next)
                motion = .settling(velocity: velocity * cushion * 0.45)
            }

        case var .settling(velocity):
            // A stiff, slightly underdamped spring: the wheel nudges past rest and back.
            var position = rotation
            let steps = 4
            let h = dt / Double(steps)
            for _ in 0..<steps {
                velocity += (-Self.settleStiffness * position - Self.settleDamping * velocity) * h
                position += velocity * h
            }
            if abs(position) < 0.02 && abs(velocity) < 0.8 {
                setRotation(0)
                finishCycle()
            } else {
                setRotation(position)
                motion = .settling(velocity: velocity)
            }
        }
    }

    private static func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}
