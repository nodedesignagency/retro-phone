import SwiftUI

/// Colours sampled from the reference device.
enum Palette {
    static let body = Color(hex: 0x141414)
    static let tile = Color(hex: 0x222223)
    static let collar = Color(hex: 0x171717)
    static let capTop = Color(hex: 0x2C2C2D)
    static let capMid = Color(hex: 0x232324)
    static let capBottom = Color(hex: 0x1F1F20)
    static let pill = Color(hex: 0x1A1A1B)
    static let ink = Color(hex: 0xE9E9E9)
    static let label = Color(hex: 0x5E5E5F)
    static let microLabel = Color(hex: 0x4B4B4B)
    static let ledOff = Color(hex: 0x0C0C0C)
    static let ledOn = Color(hex: 0xFF4B2B)
    static let grilleHole = Color(hex: 0x0D0D0D)

    static let orangeLight = Color(hex: 0xEC6A42)
    static let orange = Color(hex: 0xDD4F2A)
    static let orangeDark = Color(hex: 0xC2401F)

    static let screenText = Color(hex: 0xEAEAEA)
    static let screenDim = Color(hex: 0x3D3D3D)
    static let screenMuted = Color(hex: 0x5A5A5A)
    static let cursor = Color(hex: 0xFF3B30)

    /// The speed-dial row, dark to light like the reference's knob row.
    static let gradientTiles = [Color(hex: 0x2A2A2B), Color(hex: 0x5A5A5C), Color(hex: 0x9A9A9C), Color(hex: 0xD6D6D7)]
    static let gradientKnobs = [Color(hex: 0x303031), Color(hex: 0x636365), Color(hex: 0xA5A5A7), Color(hex: 0xE2E2E3)]
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
