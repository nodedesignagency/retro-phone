import CoreHaptics

/// Crisp, low-latency transient taps through Core Haptics. Silent on hardware
/// without a Taptic Engine.
@MainActor
final class Haptics {
    private var engine: CHHapticEngine?
    private var isRunning = false

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            // The system stops the engine when the app backgrounds; restart on next use.
            engine.stoppedHandler = { [weak self] _ in
                Task { @MainActor in self?.isRunning = false }
            }
            engine.resetHandler = { [weak self] in
                Task { @MainActor in self?.isRunning = false }
            }
            try engine.start()
            self.engine = engine
            isRunning = true
        } catch {
            self.engine = nil
        }
    }

    /// - Parameters:
    ///   - intensity: 0 (barely there) to 1 (full strength).
    ///   - sharpness: 0 (round, dull thud) to 1 (crisp, precise click).
    func tap(intensity: Float, sharpness: Float) {
        guard let engine else { return }
        do {
            if !isRunning {
                try engine.start()
                isRunning = true
            }
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            isRunning = false
        }
    }
}
