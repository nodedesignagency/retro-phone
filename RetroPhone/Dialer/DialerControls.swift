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
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
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
                .font(.system(size: 31, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(Palette.callGreen, in: Circle())
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
                .font(.system(size: 25, weight: .regular))
                .foregroundStyle(Palette.secondary)
                .frame(width: 76, height: 76)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in onClear() })
        .accessibilityLabel("Delete")
        .accessibilityHint("Touch and hold to clear the number")
        .accessibilityAction(named: "Clear number", onClear)
    }
}
