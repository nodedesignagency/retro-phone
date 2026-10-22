import SwiftUI

/// Call in the middle, delete to its right: the iPhone keypad's bottom row.
struct DialerControls: View {
    let hasDigits: Bool
    /// Bumped each time a call can't go through, to shake the call button.
    let refusals: Int
    let onCall: () -> Void
    let onDelete: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(maxWidth: .infinity)
            CallButton(action: onCall)
                .modifier(ShakeEffect(shakes: CGFloat(refusals)))
                .frame(maxWidth: .infinity)
            ZStack {
                if hasDigits {
                    DeleteButton(onDelete: onDelete, onClear: onClear)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 88)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: hasDigits)
    }
}

private struct CallButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "phone.fill")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                .frame(width: 80, height: 80)
                .background { GlassOrb(tint: Palette.callGreen, diameter: 80) }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Call")
    }
}

private struct DeleteButton: View {
    let onDelete: () -> Void
    let onClear: () -> Void

    var body: some View {
        Button(action: onDelete) {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Palette.chromeText)
                .frame(width: 58, height: 58)
                .background { GlassOrb(tint: nil, diameter: 58) }
        }
        .buttonStyle(PressableButtonStyle())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in onClear() })
        .accessibilityLabel("Delete")
        .accessibilityHint("Touch and hold to clear the number")
        .accessibilityAction(named: "Clear number", onClear)
    }
}
