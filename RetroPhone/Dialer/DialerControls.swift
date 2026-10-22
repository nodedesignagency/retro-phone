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
        ZStack {
            CallButton(action: onCall)
                .modifier(ShakeEffect(shakes: CGFloat(refusals)))
            HStack {
                Spacer()
                if hasDigits {
                    DeleteButton(onDelete: onDelete, onClear: onClear)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .padding(.trailing, 36)
        }
        .frame(height: 80)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hasDigits)
    }
}

private struct CallButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "phone.fill")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .glass(Circle(), tint: Palette.callGreen, interactive: true)
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
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 56, height: 56)
                .glass(Circle(), interactive: true)
        }
        .buttonStyle(PressableButtonStyle())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in onClear() })
        .accessibilityLabel("Delete")
        .accessibilityHint("Touch and hold to clear the number")
        .accessibilityAction(named: "Clear number", onClear)
    }
}
