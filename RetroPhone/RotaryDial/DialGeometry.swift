import Foundation

/// The layout and mechanics of the rotary dial in unit space.
///
/// The plate has radius 1 with its centre at the origin, y grows downward
/// (screen convention), and angles are degrees measured clockwise from twelve
/// o'clock. Rotation of the finger wheel is clockwise-positive too, so a hole's
/// angle on screen is simply its rest angle plus the wheel's rotation.
struct DialGeometry: Equatable, Sendable {
    /// Digits in finger-wheel order. Hole 0 holds "1", the one nearest the stop.
    static let digits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]

    /// Rest angle of the "1" hole, about two o'clock.
    var firstHoleAngle = 58.0
    /// Angle between neighbouring holes; also the wheel travel per pulse.
    var holeSpacing = 30.0
    /// Angle at which the finger stop is drawn, about four o'clock.
    var fingerStopAngle = 122.0
    /// Half the stop's thickness at the hole ring, as an angle.
    var stopHalfWidthAngle = 4.0

    var holeRingRadius = 0.71
    var holeRadius = 0.155
    var wellRadius = 0.128
    var wheelOuterRadius = 0.94
    var wheelInnerRadius = 0.50
    var labelRadius = 0.44

    /// Angular radius of a finger hole seen from the dial centre.
    var holeAngularRadius: Double {
        asin(holeRadius / holeRingRadius) * 180 / .pi
    }

    /// Where a hole's centre sits when the finger in it meets the stop.
    var stopContactAngle: Double {
        fingerStopAngle - holeAngularRadius - stopHalfWidthAngle
    }

    func restAngle(ofHole hole: Int) -> Double {
        firstHoleAngle - Double(hole) * holeSpacing
    }

    /// How far the wheel turns before the finger in `hole` meets the stop.
    func travel(ofHole hole: Int) -> Double {
        stopContactAngle - restAngle(ofHole: hole)
    }

    func digit(ofHole hole: Int) -> Int {
        Self.digits[hole]
    }

    func hole(forDigit digit: Int) -> Int? {
        Self.digits.firstIndex(of: digit)
    }

    /// Unit-space centre of a hole once the wheel has turned `rotation` degrees.
    func center(ofHole hole: Int, rotation: Double = 0) -> CGPoint {
        Self.point(angle: restAngle(ofHole: hole) + rotation, radius: holeRingRadius)
    }

    /// The hole under a unit-space point, with a forgiving touch radius.
    func hole(at point: CGPoint, rotation: Double = 0, tolerance: Double = 1.3) -> Int? {
        var best: (hole: Int, distance: Double)?
        for hole in Self.digits.indices {
            let distance = Self.distance(point, center(ofHole: hole, rotation: rotation))
            if distance <= holeRadius * tolerance, distance < (best?.distance ?? .infinity) {
                best = (hole, distance)
            }
        }
        return best?.hole
    }

    /// Pulses a wheel turned this far will send on its way home.
    ///
    /// Thresholds sit half a hole short of each digit's full travel, so letting go
    /// at the stop for digit n sends exactly n pulses (ten for 0), and the slack
    /// before the first threshold stays silent like a real dial's lost motion.
    func pulseCount(at rotation: Double) -> Int {
        let offset = travel(ofHole: 0) - holeSpacing * 1.5
        let count = Int(((rotation - offset) / holeSpacing).rounded(.up)) - 1
        return min(max(count, 0), Self.digits.count)
    }

    static func point(angle: Double, radius: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(x: sin(radians) * radius, y: -cos(radians) * radius)
    }

    /// Clockwise angle from twelve o'clock, in (-180, 180].
    static func angle(of point: CGPoint) -> Double {
        atan2(Double(point.x), Double(-point.y)) * 180 / .pi
    }

    static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        Double(hypot(a.x - b.x, a.y - b.y))
    }
}
