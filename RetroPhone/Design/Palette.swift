import SwiftUI

enum Palette {
    /// Pastel spectrum for holographic edges and light leaks.
    static let prism: [Color] = [
        Color(red: 1.00, green: 0.55, blue: 0.80),
        Color(red: 0.70, green: 0.55, blue: 1.00),
        Color(red: 0.42, green: 0.72, blue: 1.00),
        Color(red: 0.42, green: 1.00, blue: 0.92),
        Color(red: 0.72, green: 1.00, blue: 0.52),
        Color(red: 1.00, green: 0.92, blue: 0.52),
        Color(red: 1.00, green: 0.64, blue: 0.46),
    ]

    /// The spectrum closed into a loop, for angular gradients.
    static let prismLoop: [Color] = prism + [prism[0]]

    /// Printing ink on silver.
    static let ink = Color(white: 0.09)

    static let callGreen = Color(red: 0.19, green: 0.82, blue: 0.40)

    /// Type that reads as polished metal on black.
    static let chromeText = LinearGradient(
        colors: [Color(white: 0.98), Color(white: 0.64)],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// Metal finishes. Light comes from the top left throughout.
enum Finish {
    /// Dark machined plate with the cone-shaped reflections of a turned disc.
    static let gunmetal = AngularGradient(
        gradient: Gradient(stops: [
            .init(color: Color(white: 0.20), location: 0.00),
            .init(color: Color(white: 0.50), location: 0.07),
            .init(color: Color(white: 0.22), location: 0.14),
            .init(color: Color(white: 0.12), location: 0.26),
            .init(color: Color(white: 0.29), location: 0.38),
            .init(color: Color(white: 0.16), location: 0.49),
            .init(color: Color(white: 0.47), location: 0.57),
            .init(color: Color(white: 0.21), location: 0.64),
            .init(color: Color(white: 0.11), location: 0.76),
            .init(color: Color(white: 0.27), location: 0.88),
            .init(color: Color(white: 0.20), location: 1.00),
        ]),
        center: .center,
        angle: .degrees(200)
    )

    /// Polished chrome for the bezel and the label's retaining ring.
    static let chrome = AngularGradient(
        gradient: Gradient(stops: [
            .init(color: Color(white: 0.55), location: 0.00),
            .init(color: Color(white: 0.98), location: 0.08),
            .init(color: Color(white: 0.42), location: 0.18),
            .init(color: Color(white: 0.80), location: 0.32),
            .init(color: Color(white: 0.30), location: 0.45),
            .init(color: Color(white: 0.93), location: 0.58),
            .init(color: Color(white: 0.45), location: 0.70),
            .init(color: Color(white: 0.86), location: 0.84),
            .init(color: Color(white: 0.55), location: 1.00),
        ]),
        center: .center,
        angle: .degrees(200)
    )

    /// Satin silver for the number wells and the centre card.
    static let silver = LinearGradient(
        colors: [Color(white: 0.96), Color(white: 0.81), Color(white: 0.66)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Bar chrome running the length of the finger stop.
    static let chromeBar = LinearGradient(
        stops: [
            .init(color: Color(white: 0.20), location: 0.00),
            .init(color: Color(white: 0.62), location: 0.16),
            .init(color: Color(white: 1.00), location: 0.36),
            .init(color: Color(white: 0.78), location: 0.50),
            .init(color: Color(white: 0.34), location: 0.70),
            .init(color: Color(white: 0.90), location: 0.88),
            .init(color: Color(white: 0.45), location: 1.00),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
