import Foundation

enum MIDIFileError: Error, Equatable {
    case notMIDI
    case smpteUnsupported
    case truncated
}

struct MIDINoteEvent: Equatable {
    let tick: Int
    let note: Int
    let velocity: Int
}

/// Minimal SMF parser — port of `parseMidiFile` in `js/midi-file.js`. Handles
/// header/track chunks, PPQ timing, running status, note-on (vel>0); skips meta/
/// sysex/other channel messages; rejects SMPTE division.
enum MIDIFileParser {
    static func parse(_ data: Data) throws -> (ppq: Int, events: [MIDINoteEvent]) {
        let b = [UInt8](data)
        var pos = 0

        func need(_ n: Int) throws { if pos + n > b.count { throw MIDIFileError.truncated } }
        func u32() throws -> Int {
            try need(4)
            defer { pos += 4 }
            return Int(b[pos]) << 24 | Int(b[pos+1]) << 16 | Int(b[pos+2]) << 8 | Int(b[pos+3])
        }
        func u16() throws -> Int {
            try need(2)
            defer { pos += 2 }
            return Int(b[pos]) << 8 | Int(b[pos+1])
        }
        func byte() throws -> Int { try need(1); defer { pos += 1 }; return Int(b[pos]) }
        func vlq() throws -> Int {
            var value = 0, c: Int
            repeat { c = try byte(); value = (value << 7) | (c & 0x7F) } while c & 0x80 != 0
            return value
        }

        guard try u32() == 0x4D546864 else { throw MIDIFileError.notMIDI }   // 'MThd'
        _ = try u32()              // header length (6)
        _ = try u16()              // format
        let ntrks = try u16()
        let timeDivision = try u16()
        if timeDivision & 0x8000 != 0 { throw MIDIFileError.smpteUnsupported }
        let ppq = timeDivision

        var events: [MIDINoteEvent] = []

        for _ in 0..<ntrks {
            let magic = try u32()
            let len = try u32()
            if magic != 0x4D54726B { pos += len; continue }   // skip non-'MTrk'
            let end = pos + len
            var tick = 0
            var running = 0

            while pos < end {
                tick += try vlq()
                try need(1)
                var status = Int(b[pos])
                if status & 0x80 != 0 { running = status; pos += 1 } else { status = running }
                let type = status & 0xF0

                if status == 0xFF {
                    _ = try byte()            // meta type
                    let mlen = try vlq()
                    pos += mlen
                    running = 0
                } else if status == 0xF0 || status == 0xF7 {
                    let slen = try vlq()
                    pos += slen
                    running = 0
                } else if type == 0x90 {
                    let note = try byte(), vel = try byte()
                    if vel > 0 { events.append(MIDINoteEvent(tick: tick, note: note, velocity: vel)) }
                } else if type == 0x80 || type == 0xA0 || type == 0xB0 || type == 0xE0 {
                    pos += 2
                } else if type == 0xC0 || type == 0xD0 {
                    pos += 1
                } else {
                    break
                }
            }
            pos = end
        }

        events.sort { $0.tick < $1.tick }
        return (ppq, events)
    }

    /// Build a custom `Lesson` from parsed events (port of `lessonFromMidiEvents`).
    /// Quantizes to eighth-note (ppq/2) steps; one full-length pattern per lane.
    static func lesson(name: String, events: [MIDINoteEvent], ppq: Int) -> Lesson {
        let halfBeat = max(1, ppq / 2)
        var beats: [(lane: Int, beat: Int)] = events.compactMap {
            guard let lane = GMDrumMapper.lane(forNote: $0.note) else { return nil }
            return (lane.rawValue, Int((Double($0.tick) / Double(halfBeat)).rounded()))
        }
        beats.sort { $0.beat != $1.beat ? $0.beat < $1.beat : $0.lane < $1.lane }
        let lastBeat = beats.map(\.beat).max() ?? 0
        let totalBeats = max(16, lastBeat + 1)

        var patterns: [PatternLine] = []
        for lane in DrumLane.allCases {
            let hits = Set(beats.filter { $0.lane == lane.rawValue }.map(\.beat))
            guard !hits.isEmpty else { continue }
            let pattern = (0..<totalBeats).map { hits.contains($0) ? "x" : "." }.joined()
            patterns.append(PatternLine(lane: lane.key, pattern: pattern))
        }
        if patterns.isEmpty {
            patterns = [PatternLine(lane: "kick", pattern: String(repeating: ".", count: totalBeats))]
        }
        return Lesson(name: name, bpm: 80, tip: "MIDI file: \(name)",
                      difficulty: "Custom", genre: "Import", patterns: patterns)
    }
}

/// SMF Type-0 exporter — port of `exportMidiFile`. Channel 10, PPQ 96, GM drum
/// notes, tempo meta. Byte-compatible with the web export.
enum MIDIFileExporter {
    static func export(lanePatterns: [[Bool]], bpm: Int) -> Data {
        let ppq = 96
        let ticksPerStep = ppq / 2
        let usPerBeat = Int((60_000_000.0 / Double(bpm)).rounded())

        struct Raw { let tick: Int; let note: Int; let isOn: Bool; let vel: Int }
        var raw: [Raw] = []
        for (laneIdx, pattern) in lanePatterns.enumerated() {
            guard laneIdx < GMDrumMapper.gmNotes.count else { break }
            let note = GMDrumMapper.gmNotes[laneIdx]
            for (step, on) in pattern.enumerated() where on {
                let tick = step * ticksPerStep
                raw.append(Raw(tick: tick, note: note, isOn: true, vel: 100))
                raw.append(Raw(tick: tick + ticksPerStep / 2, note: note, isOn: false, vel: 0))
            }
        }
        // tick asc; at same tick offs before ons (matches the web sort).
        raw.sort { $0.tick != $1.tick ? $0.tick < $1.tick : (!$0.isOn && $1.isOn ? true : false) }

        func vlq(_ value: Int) -> [UInt8] {
            if value == 0 { return [0] }
            var v = value
            var out: [UInt8] = [UInt8(v & 0x7F)]
            v >>= 7
            while v > 0 { out.insert(UInt8((v & 0x7F) | 0x80), at: 0); v >>= 7 }
            return out
        }

        var track: [UInt8] = []
        track += vlq(0)
        track += [0xFF, 0x51, 0x03,
                  UInt8((usPerBeat >> 16) & 0xFF), UInt8((usPerBeat >> 8) & 0xFF), UInt8(usPerBeat & 0xFF)]
        var cur = 0
        for ev in raw {
            track += vlq(ev.tick - cur)
            cur = ev.tick
            track += [ev.isOn ? 0x99 : 0x89, UInt8(ev.note), UInt8(ev.vel)]
        }
        track += vlq(0)
        track += [0xFF, 0x2F, 0x00]

        var out: [UInt8] = []
        func u32(_ v: Int) { out += [UInt8((v >> 24) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
        func u16(_ v: Int) { out += [UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)] }
        u32(0x4D546864); u32(6); u16(0); u16(1); u16(ppq)         // MThd, fmt0, 1 track, ppq
        u32(0x4D54726B); u32(track.count); out += track          // MTrk
        return Data(out)
    }
}
