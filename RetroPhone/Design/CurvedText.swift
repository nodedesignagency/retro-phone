import SwiftUI
import UIKit

/// A line of text set along the top of a circle, letter by letter.
struct CurvedText: View {
    let text: String
    let fontName: String
    let fontSize: CGFloat
    /// Distance from the circle's centre to the letters' centres.
    let radius: CGFloat
    var tracking: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(Array(glyphs.enumerated()), id: \.offset) { _, glyph in
                Text(String(glyph.character))
                    .font(.custom(fontName, size: fontSize))
                    .offset(y: -radius)
                    .rotationEffect(.radians(glyph.angle))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    /// Each letter's angle from twelve o'clock, spaced by its real advance width.
    private var glyphs: [(character: Character, angle: Double)] {
        let font = UIFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .semibold)
        let widths = text.map { (String($0) as NSString).size(withAttributes: [.font: font]).width }
        let total = widths.reduce(0, +) + tracking * CGFloat(max(widths.count - 1, 0))
        var cursor = -total / 2
        var glyphs: [(character: Character, angle: Double)] = []
        for (character, width) in zip(text, widths) {
            glyphs.append((character, Double((cursor + width / 2) / radius)))
            cursor += width + tracking
        }
        return glyphs
    }
}
