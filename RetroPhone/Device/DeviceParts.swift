import SwiftUI

/// One square module of the device face.
struct Tile<Content: View>: View {
    var color: Color = Palette.tile
    @ViewBuilder var content: Content

    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(color)
            .overlay {
                // A hairline of light along the top edge.
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.05), .clear], startPoint: .top, endPoint: .center),
                        lineWidth: 1
                    )
            }
            .overlay { content }
    }
}

/// A tiny label set on its side along a tile's left edge, like "TRACKS".
struct SideLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 7, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(Palette.microLabel)
            .fixedSize()
            .rotationEffect(.degrees(-90))
    }
}

/// An indicator LED: a pinhole when off, a red glow when lit.
struct LED: View {
    var isOn: Bool
    var size: CGFloat = 5

    var body: some View {
        Circle()
            .fill(isOn ? Palette.ledOn : Palette.ledOff)
            .frame(width: size, height: size)
            .shadow(color: Palette.ledOn.opacity(isOn ? 0.9 : 0), radius: 3)
            .overlay {
                Circle()
                    .strokeBorder(Color.black.opacity(isOn ? 0 : 0.8), lineWidth: 0.5)
            }
    }
}

/// The speaker grille: rows of punched holes.
struct Grille: View {
    var body: some View {
        Canvas { context, size in
            let pitch: CGFloat = 7
            let radius: CGFloat = 1.6
            var y: CGFloat = 4 + pitch / 2
            while y < size.height - 4 {
                var x: CGFloat = 4 + pitch / 2
                while x < size.width - 4 {
                    let hole = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    context.fill(hole, with: .color(Palette.grilleHole))
                    x += pitch
                }
                y += pitch
            }
        }
        .accessibilityHidden(true)
    }
}

/// The round key: a matte cap with an LED, sunk into a collar.
struct RoundKeyStyle: ButtonStyle {
    var diameter: CGFloat = 62
    var showsLED = true

    private static let restingStops: [Gradient.Stop] = [
        Gradient.Stop(color: Palette.capTop, location: 0),
        Gradient.Stop(color: Palette.capMid, location: 0.6),
        Gradient.Stop(color: Palette.capBottom, location: 1),
    ]
    private static let pressedStops: [Gradient.Stop] = [
        Gradient.Stop(color: Palette.capBottom, location: 0),
        Gradient.Stop(color: Color(hex: 0x1C1C1D), location: 1),
    ]

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        ZStack {
            Circle()
                .fill(Palette.collar.shadow(.inner(color: .black.opacity(0.85), radius: 1.5, y: 1)))
            Circle()
                .fill(
                    LinearGradient(
                        stops: pressed ? Self.pressedStops : Self.restingStops,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .shadow(pressed ? .inner(color: .black.opacity(0.7), radius: 3, y: 2) : .inner(color: .white.opacity(0.09), radius: 0, y: 1))
                )
                .shadow(color: .black.opacity(pressed ? 0 : 0.6), radius: pressed ? 0 : 1.5, y: pressed ? 0 : 2)
                .padding(4)
                .offset(y: pressed ? 1 : 0)
            if showsLED {
                LED(isOn: pressed)
                    .offset(y: -diameter / 2 + 11 + (pressed ? 1 : 0))
            }
            configuration.label
                .offset(y: pressed ? 3.5 : 2.5)
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .animation(.easeOut(duration: 0.08), value: pressed)
        .onChange(of: pressed) { _, isDown in
            if isDown { KeyClick.shared.down() }
        }
    }
}

/// The recessed "AUTOPLAY" pill: an LED and a label in a slot.
struct PillKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        HStack(spacing: 7) {
            LED(isOn: pressed)
            configuration.label
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(pressed ? Palette.ink.opacity(0.7) : Palette.label)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(
            Capsule().fill(Palette.pill.shadow(.inner(color: .black.opacity(pressed ? 0.95 : 0.8), radius: pressed ? 4 : 3, y: 1)))
        )
        .contentShape(Capsule())
        .animation(.easeOut(duration: 0.08), value: pressed)
        .onChange(of: pressed) { _, isDown in
            if isDown { KeyClick.shared.down() }
        }
    }
}

/// The big orange button: a glossy cap with an inner ring.
struct OrangeKeyStyle: ButtonStyle {
    var diameter: CGFloat = 58

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        ZStack {
            Circle()
                .fill(Palette.collar.shadow(.inner(color: .black.opacity(0.85), radius: 1.5, y: 1)))
            Circle()
                .fill(
                    RadialGradient(
                        colors: pressed
                            ? [Palette.orange, Palette.orangeDark]
                            : [Palette.orangeLight, Palette.orange, Palette.orangeDark],
                        center: UnitPoint(x: 0.5, y: 0.35),
                        startRadius: 0,
                        endRadius: diameter * 0.55
                    )
                    .shadow(.inner(color: .white.opacity(pressed ? 0.05 : 0.25), radius: 0, y: 1))
                )
                .overlay {
                    // The engraved inner ring: shadowed on top, catching light below.
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.black.opacity(0.4), .white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.2
                        )
                        .padding(diameter * 0.2)
                }
                .shadow(color: .black.opacity(pressed ? 0.2 : 0.6), radius: pressed ? 1 : 2, y: pressed ? 1 : 2)
                .padding(3)
                .offset(y: pressed ? 1 : 0)
            configuration.label
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .animation(.easeOut(duration: 0.08), value: pressed)
        .onChange(of: pressed) { _, isDown in
            if isDown { KeyClick.shared.down() }
        }
    }
}

/// A knob for the speed-dial row, tinted to its tile.
struct KnobStyle: ButtonStyle {
    let tone: Color
    let index: Int
    var isStored: Bool
    var diameter: CGFloat = 58

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let lightness = Double(index) / 3
        Circle()
            .fill(tone.shadow(.inner(color: .white.opacity(0.08 + 0.08 * Double(index)), radius: 0, y: 1)))
            .overlay(alignment: .top) {
                LED(isOn: isStored)
                    .padding(.top, 9)
            }
            .background {
                Circle()
                    .stroke(Color.black.opacity(0.18 - 0.03 * Double(index)), lineWidth: 8)
            }
            .shadow(color: .black.opacity(0.6 - 0.12 * Double(index) - lightness * 0.05), radius: 2, y: pressed ? 0.5 : 2)
            .rotationEffect(.degrees(pressed ? 24 : 0))
            .scaleEffect(pressed ? 0.97 : 1)
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
            .onChange(of: pressed) { _, isDown in
                if isDown { KeyClick.shared.down() }
            }
    }
}
