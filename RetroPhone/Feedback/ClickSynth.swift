import AVFoundation

/// The dial's mechanical sounds, synthesised once at launch: no audio files.
///
/// Plays through the ambient session, so it respects the silent switch and
/// mixes with whatever else is playing.
@MainActor
final class ClickSynth {
    enum Sound: CaseIterable {
        /// A key going down: a short plastic click.
        case key
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffers: [Sound: AVAudioPCMBuffer] = [:]

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        for sound in Sound.allCases {
            buffers[sound] = Self.render(sound, format: format)
        }
        engine.prepare()
        ensureRunning()
    }

    func play(_ sound: Sound) {
        guard let buffer = buffers[sound], ensureRunning() else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    /// Interruptions and route changes stop the engine; bring it back on demand.
    @discardableResult
    private func ensureRunning() -> Bool {
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                return false
            }
        }
        if !player.isPlaying { player.play() }
        return true
    }

    private static func render(_ sound: Sound, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = switch sound {
        case .key: 0.05
        }
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = frames

        var random = SeededRandom(seed: 0xD1A1)
        func tone(_ frequency: Double, _ t: Double) -> Double { sin(2 * .pi * frequency * t) }
        func decay(_ t: Double, _ tau: Double) -> Double { exp(-t / tau) }

        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let noise = Double.random(in: -1...1, using: &random)
            let value: Double = switch sound {
            case .key:
                0.16 * noise * decay(t, 0.0015)
                    + 0.10 * tone(2_400, t) * decay(t, 0.005)
                    + 0.14 * tone(210, t) * decay(t, 0.009)
            }
            samples[i] = Float(value)
        }
        return buffer
    }
}
