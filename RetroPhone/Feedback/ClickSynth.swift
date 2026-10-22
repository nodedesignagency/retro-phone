import AVFoundation

/// The dial's mechanical sounds, synthesised once at launch: no audio files.
///
/// Plays through the ambient session, so it respects the silent switch and
/// mixes with whatever else is playing.
@MainActor
final class ClickSynth {
    enum Sound: CaseIterable {
        /// A digit clicking past the index.
        case detent
        /// A digit entered: a soft, rounder click.
        case enter
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
        case .detent: 0.035
        case .enter: 0.09
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
            case .detent:
                0.10 * noise * decay(t, 0.0012)
                    + 0.07 * tone(3_600, t) * decay(t, 0.004)
            case .enter:
                0.14 * noise * decay(t, 0.002)
                    + 0.16 * tone(1_250, t) * decay(t, 0.016)
                    + 0.20 * tone(170, t) * decay(t, 0.014)
            }
            samples[i] = Float(value)
        }
        return buffer
    }
}
