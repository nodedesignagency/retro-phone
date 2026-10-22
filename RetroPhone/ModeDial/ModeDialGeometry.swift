import Foundation

/// Layout of the mode dial: a ring of digits that turns under a fixed index
/// mark at twelve o'clock, inside a semicircle of ticks.
///
/// Angles are degrees, clockwise from twelve o'clock. Digit `i` rests at
/// `i * step`; turning the ring by `offset` puts it at `i * step - offset`, so
/// the digit under the index is the one whose rest angle equals the offset.
struct ModeDialGeometry: Equatable, Sendable {
    /// Ring order: "1" first, "0" last.
    let digits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
    /// Angle between neighbouring digits.
    let step = 18.0
    /// Digits fade out between these angles from the index.
    let fadeStart = 100.0
    let fadeEnd = 125.0
    /// How many digits either side of the index wear a white disc.
    let discCount = 4

    /// The index's offset when the last digit is under it.
    var maxOffset: Double { step * Double(digits.count - 1) }

    func restAngle(ofItem item: Int) -> Double {
        Double(item) * step
    }

    /// Where item `item` shows on the ring once it has turned by `offset`.
    func screenAngle(ofItem item: Int, offset: Double) -> Double {
        restAngle(ofItem: item) - offset
    }

    /// The item nearest the index at this offset.
    func nearestItem(toOffset offset: Double) -> Int {
        min(max(Int((offset / step).rounded()), 0), digits.count - 1)
    }

    /// The offset that puts `item` exactly under the index.
    func offset(forItem item: Int) -> Double {
        restAngle(ofItem: item)
    }

    func digit(ofItem item: Int) -> Int {
        digits[item]
    }

    func item(forDigit digit: Int) -> Int? {
        digits.firstIndex(of: digit)
    }

    /// Visibility of an item at this angle from the index, 1 near the top
    /// fading to 0 past `fadeEnd`.
    func visibility(atAngle angle: Double) -> Double {
        1 - Self.smoothstep(fadeStart, fadeEnd, abs(angle))
    }

    /// How much of a white disc an item at this angle wears: none under the
    /// index, full for the nearest few, none again further round.
    func discWeight(atAngle angle: Double) -> Double {
        let a = abs(angle)
        let nearIndex = 1 - Self.smoothstep(0, step / 2, a)
        let far = Self.smoothstep(Double(discCount) * step - step / 2, Double(discCount) * step + step / 2, a)
        return (1 - nearIndex) * (1 - far)
    }

    /// How much an item at this angle is "in the window", 1 exactly under the index.
    func windowWeight(atAngle angle: Double) -> Double {
        1 - Self.smoothstep(0, step / 2, abs(angle))
    }

    // MARK: - Points

    /// Sizes in points for a dial `width` wide. The ring's centre sits so the
    /// index mark touches the top edge; the frame reaches far enough down to
    /// show digits until they have faded out.
    struct Layout: Equatable {
        let width: CGFloat
        let height: CGFloat
        let center: CGPoint
        let itemRadius: CGFloat
        let tickInner: CGFloat
        let tickOuter: CGFloat
        let discRadius: CGFloat
        let itemDiscRadius: CGFloat
        let windowSize: CGSize
    }

    func layout(width: CGFloat) -> Layout {
        let tickOuter = width / 2 - 2
        let indexOverhang: CGFloat = 10
        let centerY = tickOuter + indexOverhang
        let itemRadius = tickOuter - 44
        let lowest = itemRadius * CGFloat(-cos(fadeEnd * .pi / 180)) + 24
        return Layout(
            width: width,
            height: centerY + lowest,
            center: CGPoint(x: width / 2, y: centerY),
            itemRadius: itemRadius,
            tickInner: tickOuter - 10,
            tickOuter: tickOuter,
            discRadius: itemRadius + 26,
            itemDiscRadius: 16,
            windowSize: CGSize(width: 36, height: 60)
        )
    }

    func position(ofItem item: Int, offset: Double, in layout: Layout) -> CGPoint {
        Self.point(angle: screenAngle(ofItem: item, offset: offset), radius: layout.itemRadius, center: layout.center)
    }

    /// The visible item under a point, with a generous touch radius.
    func item(at point: CGPoint, offset: Double, in layout: Layout) -> Int? {
        var best: (item: Int, distance: CGFloat)?
        for item in digits.indices {
            let angle = screenAngle(ofItem: item, offset: offset)
            guard visibility(atAngle: angle) > 0.3 else { continue }
            let p = position(ofItem: item, offset: offset, in: layout)
            let d = hypot(p.x - point.x, p.y - point.y)
            if d <= 24, d < (best?.distance ?? .infinity) {
                best = (item, d)
            }
        }
        return best?.item
    }

    /// Clockwise angle of a point about the ring's centre, in (-180, 180].
    func angle(of point: CGPoint, in layout: Layout) -> Double {
        atan2(Double(point.x - layout.center.x), Double(layout.center.y - point.y)) * 180 / .pi
    }

    static func point(angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let r = angle * .pi / 180
        return CGPoint(x: center.x + CGFloat(sin(r)) * radius, y: center.y - CGFloat(cos(r)) * radius)
    }

    static func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }
}
