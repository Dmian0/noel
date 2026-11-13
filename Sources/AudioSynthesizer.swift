import Foundation

/// Synthesizes warm, pleasant Christmas music-box melodies and cozy fireplace audio as PCM WAV Data.
final class AudioSynthesizer {
    static let shared = AudioSynthesizer()

    private let sampleRate: Double = 44100.0
    private var cachedSongs: [Int: Data] = [:]
    private var cachedFireplace: Data?

    struct BuiltInSongInfo {
        let index: Int
        let title: String
        let titleEN: String
    }

    let builtInSongs: [BuiltInSongInfo] = [
        BuiltInSongInfo(index: 0, title: "Jingle Bells (Caja de Música)", titleEN: "Jingle Bells (Music Box)"),
        BuiltInSongInfo(index: 1, title: "We Wish You a Merry Christmas", titleEN: "We Wish You a Merry Christmas"),
        BuiltInSongInfo(index: 2, title: "Noche de Paz (Silent Night)", titleEN: "Silent Night (Music Box)"),
        BuiltInSongInfo(index: 3, title: "Deck the Halls", titleEN: "Deck the Halls"),
        BuiltInSongInfo(index: 4, title: "Carol of the Bells", titleEN: "Carol of the Bells")
    ]

    func titleForBuiltInSong(index: Int, language: AppLanguage) -> String {
        guard let song = builtInSongs.first(where: { $0.index == index }) else {
            return "Song \(index)"
        }
        return language == .en ? song.titleEN : song.title
    }

    private struct NoteEvent {
        let midi: Int // 0 = rest
        let beats: Double
        let bassMidi: Int // 0 = no bass
    }

    private init() {}

    func wavDataForBuiltInSong(index: Int) -> Data {
        if let cached = cachedSongs[index] {
            return cached
        }
        let data: Data
        switch index {
        case 0:
            data = synthesizeSong(bpm: 132, notes: jingleBellsNotes())
        case 1:
            data = synthesizeSong(bpm: 126, notes: weWishYouNotes())
        case 2:
            data = synthesizeSong(bpm: 78, notes: silentNightNotes())
        case 3:
            data = synthesizeSong(bpm: 128, notes: deckTheHallsNotes())
        case 4:
            data = synthesizeSong(bpm: 138, notes: carolOfTheBellsNotes())
        default:
            data = synthesizeSong(bpm: 120, notes: jingleBellsNotes())
        }
        cachedSongs[index] = data
        return data
    }

    func generateFireplaceWAV() -> Data {
        if let cached = cachedFireplace {
            return cached
        }

        let durationSeconds = 12.0
        let totalSamples = Int(sampleRate * durationSeconds)
        var buffer = [Float](repeating: 0, count: totalSamples)

        // Deterministic PRNG for clean, fast noise synthesis
        var rngState: UInt64 = 0x1234_5678_9ABC_DEF0
        func nextUniform() -> Float {
            rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
            let shifted = UInt32((rngState >> 32) & 0xFFFF_FFFF)
            return (Float(shifted) / Float(UInt32.max)) * 2.0 - 1.0
        }

        func nextUnit() -> Float {
            return (nextUniform() + 1.0) * 0.5
        }

        // Low-pass filtered warm rumble + flame flicker LFO
        var lp1: Float = 0.0
        var lp2: Float = 0.0
        var lpMid: Float = 0.0
        let alphaLow: Float = 0.018
        let alphaMid: Float = 0.055

        for i in 0..<totalSamples {
            let t = Float(i) / Float(sampleRate)
            let white = nextUniform()
            lp1 += alphaLow * (white - lp1)
            lp2 += alphaLow * (lp1 - lp2)
            lpMid += alphaMid * (white - lpMid)

            let flicker = 0.78
                + 0.14 * sinf(2.0 * .pi * 0.42 * t)
                + 0.08 * sinf(2.0 * .pi * 1.15 * t + 1.2)

            buffer[i] = (lp2 * 2.8 + lpMid * 0.45) * flicker
        }

        // Add cozy wood crackles and soft sparks
        let crackleCount = 155
        for _ in 0..<crackleCount {
            let startSample = Int(nextUnit() * Float(totalSamples - 4000))
            let isPop = nextUnit() < 0.28
            let decaySamples = isPop ? Int(220 + nextUnit() * 750) : Int(70 + nextUnit() * 240)
            let amplitude: Float = isPop ? (0.18 + nextUnit() * 0.28) : (0.06 + nextUnit() * 0.14)
            let freq: Float = isPop ? (750 + nextUnit() * 1400) : (1900 + nextUnit() * 2800)

            for j in 0..<decaySamples {
                let idx = startSample + j
                if idx >= totalSamples { break }
                let jt = Float(j) / Float(sampleRate)
                let attack = min(1.0, Float(j) / 6.0)
                let env = attack * expf(-Float(j) / Float(max(12, decaySamples / 5)))
                let body = sinf(2.0 * .pi * freq * jt) * 0.65 + nextUniform() * 0.35
                buffer[idx] += body * env * amplitude
            }
        }

        // Seamless equal-power crossfade at loop boundaries (0.5s)
        let fadeSamples = Int(sampleRate * 0.5)
        for i in 0..<fadeSamples {
            let ratio = Float(i) / Float(fadeSamples)
            let tailIndex = totalSamples - fadeSamples + i
            let fadeIn = sinf(ratio * .pi * 0.5)
            let fadeOut = cosf(ratio * .pi * 0.5)
            let blended = buffer[i] * fadeIn + buffer[tailIndex] * fadeOut
            buffer[i] = blended
        }
        let loopedSamples = Array(buffer.prefix(totalSamples - fadeSamples))

        // Normalize gently for ambient background
        var peak: Float = 0.01
        for sample in loopedSamples {
            peak = max(peak, abs(sample))
        }
        let gain = 0.65 / peak
        let normalized = loopedSamples.map { tanhf($0 * gain) * 0.72 }

        let wav = encodeMonoWAV(samples: normalized)
        cachedFireplace = wav
        return wav
    }

    private func synthesizeSong(bpm: Double, notes: [NoteEvent]) -> Data {
        let secondsPerBeat = 60.0 / bpm
        let totalBeats = notes.reduce(0.0) { $0 + $1.beats }
        let tailSeconds = 1.4
        let totalSamples = Int((totalBeats * secondsPerBeat + tailSeconds) * sampleRate)
        var buffer = [Float](repeating: 0, count: totalSamples)

        var currentBeat = 0.0
        for event in notes {
            let startSample = Int(currentBeat * secondsPerBeat * sampleRate)
            let noteDuration = event.beats * secondsPerBeat

            if event.midi > 0 {
                let freq = midiToFreq(event.midi)
                // Music box ringing decay lasts slightly beyond the nominal note step
                let ringSeconds = min(2.2, max(0.55, noteDuration * 1.85))
                let renderSamples = Int(ringSeconds * sampleRate)
                let attackSamples = max(1, Int(0.008 * sampleRate))

                for j in 0..<renderSamples {
                    let idx = startSample + j
                    if idx >= totalSamples { break }
                    let t = Double(j) / sampleRate
                    let attack = j < attackSamples ? Double(j) / Double(attackSamples) : 1.0

                    let env1 = attack * exp(-t * 3.1)
                    let env2 = attack * exp(-t * 5.6)
                    let env3 = attack * exp(-t * 8.5)
                    let env4 = attack * exp(-t * 14.0)

                    let h1 = sin(2.0 * .pi * freq * t) * 0.64 * env1
                    let h2 = sin(2.0 * .pi * freq * 2.0 * t) * 0.22 * env2
                    let h3 = sin(2.0 * .pi * freq * 3.0 * t) * 0.09 * env3
                    let h4 = sin(2.0 * .pi * freq * 4.0 * t) * 0.05 * env4

                    buffer[idx] += Float((h1 + h2 + h3 + h4) * 0.55)
                }
            }

            if event.bassMidi > 0 {
                let bassFreq = midiToFreq(event.bassMidi)
                let bassRing = min(2.6, max(0.8, noteDuration * 2.2))
                let renderSamples = Int(bassRing * sampleRate)
                let attackSamples = max(1, Int(0.015 * sampleRate))

                for j in 0..<renderSamples {
                    let idx = startSample + j
                    if idx >= totalSamples { break }
                    let t = Double(j) / sampleRate
                    let attack = j < attackSamples ? Double(j) / Double(attackSamples) : 1.0
                    let env = attack * exp(-t * 2.1)
                    let warm = (sin(2.0 * .pi * bassFreq * t) * 0.78 + sin(2.0 * .pi * bassFreq * 2.0 * t) * 0.16) * env
                    buffer[idx] += Float(warm * 0.30)
                }
            }

            currentBeat += event.beats
        }

        // Normalize cleanly with soft saturation
        var peak: Float = 0.01
        for sample in buffer {
            peak = max(peak, abs(sample))
        }
        let gain = 0.85 / peak
        let finalSamples = buffer.map { tanhf($0 * gain) * 0.80 }

        return encodeMonoWAV(samples: finalSamples)
    }

    private func midiToFreq(_ midi: Int) -> Double {
        return 440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }

    private func encodeMonoWAV(samples: [Float]) -> Data {
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let sampleRateInt = UInt32(sampleRate)
        let byteRate = sampleRateInt * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign = numChannels * (bitsPerSample / 8)
        let dataSize = UInt32(samples.count * 2)
        let chunkSize = 36 + dataSize

        var data = Data(capacity: Int(44 + dataSize))
        data.append(contentsOf: "RIFF".utf8)
        appendUInt32(&data, chunkSize)
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        appendUInt32(&data, 16) // Subchunk1Size for PCM
        appendUInt16(&data, 1)  // PCM format
        appendUInt16(&data, numChannels)
        appendUInt32(&data, sampleRateInt)
        appendUInt32(&data, byteRate)
        appendUInt16(&data, blockAlign)
        appendUInt16(&data, bitsPerSample)
        data.append(contentsOf: "data".utf8)
        appendUInt32(&data, dataSize)

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            var intSample = Int16(clamped * 32767.0).littleEndian
            withUnsafeBytes(of: &intSample) { bytes in
                data.append(contentsOf: bytes)
            }
        }
        return data
    }

    private func appendUInt32(_ data: inout Data, _ value: UInt32) {
        var le = value.littleEndian
        withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
    }

    private func appendUInt16(_ data: inout Data, _ value: UInt16) {
        var le = value.littleEndian
        withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
    }

    // MARK: - Melodies (MIDI note numbers: C4=60, D4=62, E4=64, F4=65, F#4=66, G4=67, A4=69, Bb4=70, B4=71, C5=72, D5=74, E5=76, F5=77, G5=79, A5=81)

    private func jingleBellsNotes() -> [NoteEvent] {
        // C major chorus
        let C4 = 48, F4b = 53, G4b = 55
        let C5 = 72, D5 = 74, E5 = 76, F5 = 77, G5 = 79
        return [
            // Jingle bells, jingle bells
            NoteEvent(midi: E5, beats: 1, bassMidi: C4),
            NoteEvent(midi: E5, beats: 1, bassMidi: 0),
            NoteEvent(midi: E5, beats: 2, bassMidi: G4b),
            NoteEvent(midi: E5, beats: 1, bassMidi: C4),
            NoteEvent(midi: E5, beats: 1, bassMidi: 0),
            NoteEvent(midi: E5, beats: 2, bassMidi: G4b),
            // Jingle all the way
            NoteEvent(midi: E5, beats: 1, bassMidi: C4),
            NoteEvent(midi: G5, beats: 1, bassMidi: 0),
            NoteEvent(midi: C5, beats: 1.5, bassMidi: G4b),
            NoteEvent(midi: D5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E5, beats: 4, bassMidi: C4),
            // Oh what fun it is to ride
            NoteEvent(midi: F5, beats: 1, bassMidi: F4b),
            NoteEvent(midi: F5, beats: 1, bassMidi: 0),
            NoteEvent(midi: F5, beats: 1.5, bassMidi: F4b),
            NoteEvent(midi: F5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: F5, beats: 1, bassMidi: C4),
            NoteEvent(midi: E5, beats: 1, bassMidi: 0),
            NoteEvent(midi: E5, beats: 1, bassMidi: C4),
            NoteEvent(midi: E5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E5, beats: 0.5, bassMidi: 0),
            // In a one-horse open sleigh
            NoteEvent(midi: E5, beats: 1, bassMidi: G4b),
            NoteEvent(midi: D5, beats: 1, bassMidi: 0),
            NoteEvent(midi: D5, beats: 1, bassMidi: G4b),
            NoteEvent(midi: E5, beats: 1, bassMidi: 0),
            NoteEvent(midi: D5, beats: 2, bassMidi: G4b),
            NoteEvent(midi: G5, beats: 2, bassMidi: G4b),
            // Second half
            NoteEvent(midi: E5, beats: 1, bassMidi: C4),
            NoteEvent(midi: E5, beats: 1, bassMidi: 0),
            NoteEvent(midi: E5, beats: 2, bassMidi: G4b),
            NoteEvent(midi: E5, beats: 1, bassMidi: C4),
            NoteEvent(midi: E5, beats: 1, bassMidi: 0),
            NoteEvent(midi: E5, beats: 2, bassMidi: G4b),
            NoteEvent(midi: E5, beats: 1, bassMidi: C4),
            NoteEvent(midi: G5, beats: 1, bassMidi: 0),
            NoteEvent(midi: C5, beats: 1.5, bassMidi: G4b),
            NoteEvent(midi: D5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E5, beats: 4, bassMidi: C4),
            NoteEvent(midi: F5, beats: 1, bassMidi: F4b),
            NoteEvent(midi: F5, beats: 1, bassMidi: 0),
            NoteEvent(midi: F5, beats: 1.5, bassMidi: F4b),
            NoteEvent(midi: F5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: F5, beats: 1, bassMidi: C4),
            NoteEvent(midi: E5, beats: 1, bassMidi: 0),
            NoteEvent(midi: E5, beats: 1, bassMidi: C4),
            NoteEvent(midi: E5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G5, beats: 1, bassMidi: G4b),
            NoteEvent(midi: G5, beats: 1, bassMidi: 0),
            NoteEvent(midi: F5, beats: 1, bassMidi: G4b),
            NoteEvent(midi: D5, beats: 1, bassMidi: 0),
            NoteEvent(midi: C5, beats: 4, bassMidi: C4)
        ]
    }

    private func weWishYouNotes() -> [NoteEvent] {
        // G major, 3/4 feel
        let G3 = 55, C4 = 60, A3 = 57, D4b = 50, B3 = 59, E4b = 52
        let D4 = 62, G4 = 67, A4 = 69, Fs4 = 66, E4 = 64, B4 = 71, C5 = 72, D5 = 74
        return [
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: G3),
            NoteEvent(midi: G4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: Fs4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: C4),
            NoteEvent(midi: E4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: 0),

            NoteEvent(midi: A4, beats: 1, bassMidi: A3),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: B4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: Fs4, beats: 1, bassMidi: D4b),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),

            NoteEvent(midi: B4, beats: 1, bassMidi: B3),
            NoteEvent(midi: B4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: C5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: B4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: E4b),
            NoteEvent(midi: E4, beats: 1, bassMidi: 0),
            NoteEvent(midi: D4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: D4, beats: 0.5, bassMidi: 0),

            NoteEvent(midi: E4, beats: 1, bassMidi: C4),
            NoteEvent(midi: A4, beats: 1, bassMidi: D4b),
            NoteEvent(midi: Fs4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 2, bassMidi: G3),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),

            // Good tidings we bring
            NoteEvent(midi: G4, beats: 1, bassMidi: G3),
            NoteEvent(midi: G4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: 0),
            NoteEvent(midi: Fs4, beats: 2, bassMidi: D4b),
            NoteEvent(midi: Fs4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: E4b),
            NoteEvent(midi: Fs4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: 0),
            NoteEvent(midi: D4, beats: 2, bassMidi: D4b),

            NoteEvent(midi: A4, beats: 1, bassMidi: A3),
            NoteEvent(midi: B4, beats: 1, bassMidi: 0),
            NoteEvent(midi: A4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: G3),
            NoteEvent(midi: D5, beats: 1, bassMidi: 0),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: D4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: D4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: C4),
            NoteEvent(midi: A4, beats: 1, bassMidi: D4b),
            NoteEvent(midi: Fs4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 3, bassMidi: G3)
        ]
    }

    private func silentNightNotes() -> [NoteEvent] {
        // C major, 3/4 serene lullaby
        let C4b = 48, F4b = 53, G4b = 55
        let C4 = 60, D4 = 62, E4 = 64, F4 = 65, G4 = 67, A4 = 69, B4 = 71, C5 = 72, D5 = 74, E5 = 76, F5 = 77
        return [
            // Silent night, holy night
            NoteEvent(midi: G4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 3, bassMidi: C4b),

            NoteEvent(midi: G4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 3, bassMidi: C4b),

            // All is calm, all is bright
            NoteEvent(midi: D5, beats: 2, bassMidi: G4b),
            NoteEvent(midi: D5, beats: 1, bassMidi: 0),
            NoteEvent(midi: B4, beats: 3, bassMidi: G4b),

            NoteEvent(midi: C5, beats: 2, bassMidi: C4b),
            NoteEvent(midi: C5, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 3, bassMidi: C4b),

            // Round yon virgin mother and child
            NoteEvent(midi: A4, beats: 2, bassMidi: F4b),
            NoteEvent(midi: A4, beats: 1, bassMidi: 0),
            NoteEvent(midi: C5, beats: 1.5, bassMidi: F4b),
            NoteEvent(midi: B4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: A4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 3, bassMidi: C4b),

            // Repeat phrase
            NoteEvent(midi: A4, beats: 2, bassMidi: F4b),
            NoteEvent(midi: A4, beats: 1, bassMidi: 0),
            NoteEvent(midi: C5, beats: 1.5, bassMidi: F4b),
            NoteEvent(midi: B4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: A4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 3, bassMidi: C4b),

            // Sleep in heavenly peace
            NoteEvent(midi: D5, beats: 2, bassMidi: G4b),
            NoteEvent(midi: D5, beats: 1, bassMidi: 0),
            NoteEvent(midi: F5, beats: 1.5, bassMidi: G4b),
            NoteEvent(midi: D5, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: B4, beats: 1, bassMidi: 0),
            NoteEvent(midi: C5, beats: 3, bassMidi: C4b),
            NoteEvent(midi: E5, beats: 3, bassMidi: C4b),

            NoteEvent(midi: C5, beats: 1.5, bassMidi: G4b),
            NoteEvent(midi: G4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1.5, bassMidi: G4b),
            NoteEvent(midi: F4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: C4, beats: 3, bassMidi: C4b)
        ]
    }

    private func deckTheHallsNotes() -> [NoteEvent] {
        // C major, 4/4 upbeat
        let C4b = 48, F4b = 53, G4b = 55
        let C4 = 60, D4 = 62, E4 = 64, F4 = 65, G4 = 67, A4 = 69, B4 = 71, C5 = 72
        return [
            NoteEvent(midi: G4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: F4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: C4b),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: C4, beats: 1, bassMidi: C4b),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: G4b),
            NoteEvent(midi: C4, beats: 1, bassMidi: 0),

            NoteEvent(midi: D4, beats: 0.5, bassMidi: F4b),
            NoteEvent(midi: E4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: F4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: D4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: D4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: C4, beats: 1, bassMidi: G4b),
            NoteEvent(midi: B4 - 12, beats: 1, bassMidi: 0),
            NoteEvent(midi: C4, beats: 2, bassMidi: C4b),

            // Repeat
            NoteEvent(midi: G4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: F4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: C4b),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: C4, beats: 1, bassMidi: C4b),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: G4b),
            NoteEvent(midi: C4, beats: 1, bassMidi: 0),

            NoteEvent(midi: D4, beats: 0.5, bassMidi: F4b),
            NoteEvent(midi: E4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: F4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: D4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: D4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: C4, beats: 1, bassMidi: G4b),
            NoteEvent(midi: B4 - 12, beats: 1, bassMidi: 0),
            NoteEvent(midi: C4, beats: 2, bassMidi: C4b),

            // Bridge
            NoteEvent(midi: D4, beats: 1.5, bassMidi: G4b),
            NoteEvent(midi: E4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: F4, beats: 1, bassMidi: 0),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: F4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: 0),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),

            NoteEvent(midi: E4, beats: 0.5, bassMidi: F4b),
            NoteEvent(midi: Fs4Or(F4 + 1), beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1, bassMidi: 0),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: B4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: C5, beats: 1, bassMidi: C4b),
            NoteEvent(midi: B4, beats: 1, bassMidi: G4b),
            NoteEvent(midi: A4, beats: 1, bassMidi: 0),
            NoteEvent(midi: G4, beats: 2, bassMidi: G4b),

            // Ending
            NoteEvent(midi: G4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: F4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: C4b),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: C4, beats: 1, bassMidi: C4b),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: G4b),
            NoteEvent(midi: C4, beats: 1, bassMidi: 0),

            NoteEvent(midi: A4, beats: 0.5, bassMidi: F4b),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: A4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: G4, beats: 1.5, bassMidi: C4b),
            NoteEvent(midi: F4, beats: 0.5, bassMidi: 0),
            NoteEvent(midi: E4, beats: 1, bassMidi: G4b),
            NoteEvent(midi: D4, beats: 1, bassMidi: 0),
            NoteEvent(midi: C4, beats: 2, bassMidi: C4b)
        ]
    }

    private func Fs4Or(_ v: Int) -> Int { v }

    private func carolOfTheBellsNotes() -> [NoteEvent] {
        // A minor, 3/4 iconic motif
        let A3b = 57, G3b = 55, F3b = 53, E3b = 52
        let A4 = 69, B4 = 71, C5 = 72, D5 = 74, E5 = 76, F5 = 77, G5 = 79
        var events: [NoteEvent] = []

        func ostinato(bass: Int) {
            events.append(NoteEvent(midi: C5, beats: 1.0, bassMidi: bass))
            events.append(NoteEvent(midi: B4, beats: 0.5, bassMidi: 0))
            events.append(NoteEvent(midi: C5, beats: 0.5, bassMidi: 0))
            events.append(NoteEvent(midi: A4, beats: 1.0, bassMidi: 0))
        }

        for _ in 0..<4 { ostinato(bass: A3b) }
        ostinato(bass: G3b)
        ostinato(bass: F3b)
        ostinato(bass: E3b)
        ostinato(bass: A3b)

        // Rising high bell section
        let highMotifs: [(Int, Int, Int, Int, Int)] = [
            (E5, D5, E5, C5, A3b),
            (E5, D5, E5, C5, G3b),
            (F5, E5, F5, D5, F3b),
            (G5, F5, E5, D5, E3b)
        ]
        for (n1, n2, n3, n4, b) in highMotifs {
            events.append(NoteEvent(midi: n1, beats: 1.0, bassMidi: b))
            events.append(NoteEvent(midi: n2, beats: 0.5, bassMidi: 0))
            events.append(NoteEvent(midi: n3, beats: 0.5, bassMidi: 0))
            events.append(NoteEvent(midi: n4, beats: 1.0, bassMidi: 0))
        }

        ostinato(bass: A3b)
        ostinato(bass: G3b)
        ostinato(bass: F3b)
        events.append(NoteEvent(midi: C5, beats: 1.0, bassMidi: E3b))
        events.append(NoteEvent(midi: B4, beats: 0.5, bassMidi: 0))
        events.append(NoteEvent(midi: C5, beats: 0.5, bassMidi: 0))
        events.append(NoteEvent(midi: A4, beats: 3.0, bassMidi: A3b))

        return events
    }
}
