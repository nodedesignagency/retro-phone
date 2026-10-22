import Foundation

/// The layout and mechanics of the rotary dial in unit space.
///
/// The finger wheel's rim has radius 1 with its centre at the origin, y grows
/// downward (screen convention), and angles are degrees measured clockwise from
/// twelve o'clock. Rotation of the finger wheel is clockwise-positive too, so a
/// hole's angle on screen is simply its rest angle plus the wheel's rotation.
struct DialGeometry: Equatable, Sendable {
    struct Hole: Equatable, Sendable {
        let digit: Int
        /// Rest angle of the hole's centre.
        let angle: Double
        /// Distance of the hole's centre from the wheel's centre.
        let radius: Double
        /// How far the wheel turns before a finger in this hole meets the stop.
        let travel: Double
    }

    /// Finger-wheel order: "1" first (nearest the stop), "0" last.
    let holes: [Hole]
    /// Radius of a finger hole's opening.
    let holeRadius: Double
    /// Half the width of the dial artwork, in wheel radii. The artwork is
    /// larger than the wheel so the finger stop fits.
    let artworkHalfSize: Double
    /// Radius of the fixed centre cap.
    let capRadius: Double

    /// The chrome GPO dial, measured from its artwork (`DialPlate`, `DialWheel`,
    /// `DialStop` and `DialCenter` in the asset catalog).
    static let chromeGPO = DialGeometry(
        holes: [
            Hole(digit: 1, angle: 51.21, radius: 0.8138, travel: 91.06),
            Hole(digit: 2, angle: 25.93, radius: 0.8096, travel: 116.28),
            Hole(digit: 3, angle: 0.56, radius: 0.8110, travel: 141.67),
            Hole(digit: 4, angle: -24.85, radius: 0.8133, travel: 167.11),
            Hole(digit: 5, angle: -50.09, radius: 0.8157, travel: 192.42),
            Hole(digit: 6, angle: -75.15, radius: 0.8126, travel: 217.40),
            Hole(digit: 7, angle: -101.18, radius: 0.8120, travel: 243.43),
            Hole(digit: 8, angle: -127.05, radius: 0.8033, travel: 269.10),
            Hole(digit: 9, angle: -153.59, radius: 0.7996, travel: 295.54),
            Hole(digit: 0, angle: 179.25, radius: 0.7923, travel: 322.42),
        ],
        holeRadius: 0.1501,
        artworkHalfSize: 1.06,
        capRadius: 0.41
    )

    var holeIndices: Range<Int> { holes.indices }

    func restAngle(ofHole hole: Int) -> Double {
        holes[hole].angle
    }

    func travel(ofHole hole: Int) -> Double {
        holes[hole].travel
    }

    func digit(ofHole hole: Int) -> Int {
        holes[hole].digit
    }

    func hole(forDigit digit: Int) -> Int? {
        holes.firstIndex { $0.digit == digit }
    }

    /// Unit-space centre of a hole once the wheel has turned `rotation` degrees.
    func center(ofHole hole: Int, rotation: Double = 0) -> CGPoint {
        Self.point(angle: holes[hole].angle + rotation, radius: holes[hole].radius)
    }

    /// The hole under a unit-space point, with a forgiving touch radius.
    func hole(at point: CGPoint, rotation: Double = 0, tolerance: Double = 1.3) -> Int? {
        var best: (hole: Int, distance: Double)?
        for hole in holes.indices {
            let distance = Self.distance(point, center(ofHole: hole, rotation: rotation))
            if distance <= holeRadius * tolerance, distance < (best?.distance ?? .infinity) {
                best = (hole, distance)
            }
        }
        return best?.hole
    }

    /// Pulses a wheel turned this far will send on its way home.
    ///
    /// Each threshold sits half a hole short of a digit's full travel, so letting
    /// go at the stop for digit n sends exactly n pulses (ten for 0), and the
    /// slack before the first threshold stays silent like a real dial's lost motion.
    func pulseCount(at rotation: Double) -> Int {
        let spacing = (holes[holes.count - 1].travel - holes[0].travel) / Double(holes.count - 1)
        return holes.filter { $0.travel - spacing / 2 < rotation }.count
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
