import SpriteKit

/// SpriteKit note highway. Drives the PlaybackEngine from its own per-frame
/// update loop and positions a node per note by `progress` (0 top → 1 strike),
/// plus a dim shadow node one pass ahead for a seamless loop reel.
///
/// A transparent scrolling beat-grid overlays the highway so players can judge
/// rhythmic positions (downbeat, quarter, eighth, sixteenth) at a glance.
@MainActor
final class HighwayScene: SKScene {
    var engine: PlaybackEngine?

    private let laneCount = 6
    private var noteNodes: [Int: SKShapeNode] = [:]
    private var shadowNodes: [Int: SKShapeNode] = [:]
    private var countInLabel: SKLabelNode?
    private var strikeY: CGFloat = 90

    // Beat-grid: pool of reusable horizontal line nodes.
    // We keep up to `maxGridLines` nodes alive and reposition them each frame.
    private var gridLineNodes: [SKShapeNode] = []
    private let maxGridLines = 64  // enough for 32 sixteenth-note lines × 2 passes

    private let laneColors: [SKColor] = [
        SKColor(red: 1.0, green: 0.16, blue: 0.48, alpha: 1),   // crash – pink
        SKColor(red: 0.36, green: 0.94, blue: 0.49, alpha: 1),  // hihat – green
        SKColor(red: 0.87, green: 0.89, blue: 0.92, alpha: 1),  // snare – white
        SKColor(red: 1.0, green: 0.23, blue: 0.35, alpha: 1),   // kick – red
        SKColor(red: 1.0, green: 0.54, blue: 0.12, alpha: 1),   // tom – amber
        SKColor(red: 0.30, green: 0.85, blue: 1.0, alpha: 1),   // ride – cyan
    ]

    // Grid line colors by subdivision level.
    private let gridColorDownbeat  = SKColor(white: 1.0, alpha: 0.20)  // bar line — brightest
    private let gridColorQuarter   = SKColor(white: 1.0, alpha: 0.11)  // quarter note
    private let gridColorEighth    = SKColor(white: 1.0, alpha: 0.06)  // eighth note
    private let gridColorSixteenth = SKColor(white: 1.0, alpha: 0.03)  // sixteenth — faintest

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.039, green: 0.078, blue: 0.063, alpha: 1) // LCD #0a1410
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        strikeY = size.height * 0.16
        removeAllChildren()
        noteNodes.removeAll()
        shadowNodes.removeAll()
        gridLineNodes.removeAll()
        countInLabel = nil
        rebuild()
    }

    private func laneX(_ lane: Int) -> CGFloat {
        (size.width / CGFloat(laneCount)) * (CGFloat(lane) + 0.5)
    }

    private func yFor(_ progress: Double) -> CGFloat {
        size.height - CGFloat(progress) * (size.height - strikeY)
    }

    private func rebuild() {
        for lane in 0..<laneCount {
            let guide = SKShapeNode(rect: CGRect(x: laneX(lane) - 1, y: 0, width: 2, height: size.height))
            guide.fillColor = laneColors[lane].withAlphaComponent(0.10)
            guide.strokeColor = .clear
            addChild(guide)
        }

        // Pre-allocate the beat-grid line pool (inserted above lane guides,
        // below notes — zPosition ordering keeps everything readable).
        for _ in 0..<maxGridLines {
            let line = SKShapeNode(rect: CGRect(x: 0, y: -0.75, width: size.width, height: 1.5))
            line.fillColor = gridColorSixteenth
            line.strokeColor = .clear
            line.isHidden = true
            line.zPosition = -1
            addChild(line)
            gridLineNodes.append(line)
        }

        // Red LED hit line + soft glow.
        let red = SKColor(red: 1.0, green: 0.23, blue: 0.35, alpha: 1)
        let glow = SKShapeNode(rect: CGRect(x: 0, y: strikeY - 12, width: size.width, height: 24))
        glow.fillColor = red.withAlphaComponent(0.12)
        glow.strokeColor = .clear
        addChild(glow)
        let strike = SKShapeNode(rect: CGRect(x: 0, y: strikeY - 1.5, width: size.width, height: 3))
        strike.fillColor = red
        strike.strokeColor = .clear
        strike.glowWidth = 6
        addChild(strike)

        let label = SKLabelNode(text: "")
        label.fontName = "Menlo-Bold"
        label.fontSize = 96
        label.fontColor = SKColor(red: 0.36, green: 0.94, blue: 0.49, alpha: 1)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.isHidden = true
        addChild(label)
        countInLabel = label
    }

    override func update(_ currentTime: TimeInterval) {
        guard let engine else { return }
        engine.update(nowMs: currentTime * 1000)
        render(engine: engine)
    }

    private func render(engine: PlaybackEngine) {
        // Count-in number.
        if case let .countIn(n) = engine.phase {
            countInLabel?.text = "\(n)"
            countInLabel?.isHidden = false
        } else {
            countInLabel?.isHidden = true
        }

        // Beat-grid overlay.
        renderBeatGrid(engine: engine)

        var seen = Set<Int>()
        for note in engine.notes {
            seen.insert(note.id)

            // Primary node (current pass).
            let node: SKShapeNode
            if let existing = noteNodes[note.id] {
                node = existing
            } else {
                node = makeNode(lane: note.lane, alpha: 1)
                noteNodes[note.id] = node
            }
            node.position = CGPoint(x: laneX(note.lane), y: yFor(note.progress))
            node.isHidden = !(note.progress >= -0.1 && note.progress <= 1.2 && !note.hit)
            node.fillColor = note.missed ? laneColors[note.lane].withAlphaComponent(0.25) : laneColors[note.lane]

            // Shadow node (next pass) — the seamless reel.
            let shadow: SKShapeNode
            if let existing = shadowNodes[note.id] {
                shadow = existing
            } else {
                shadow = makeNode(lane: note.lane, alpha: 0.45)
                shadowNodes[note.id] = shadow
            }
            shadow.position = CGPoint(x: laneX(note.lane), y: yFor(note.shadowProgress))
            shadow.isHidden = !note.shadowVisible
        }
        for (id, node) in noteNodes where !seen.contains(id) { node.removeFromParent(); noteNodes[id] = nil }
        for (id, node) in shadowNodes where !seen.contains(id) { node.removeFromParent(); shadowNodes[id] = nil }
    }

    // MARK: - Beat-grid overlay

    /// Scrolls horizontal beat lines in sync with the note highway.
    ///
    /// Strategy: a note at beat `b` has `progress = (grooveElapsed - (beatTime(b) - travelMs)) / travelMs`.
    /// We use the same formula for each sixteenth-note grid position.
    /// The groove repeats continuously, so we evaluate two passes (current + next)
    /// to keep lines seamless through a loop boundary.
    private func renderBeatGrid(engine: PlaybackEngine) {
        guard engine.phase != .idle,
              engine.grooveMs > 0,
              engine.halfBeatMs > 0 else {
            gridLineNodes.forEach { $0.isHidden = true }
            return
        }

        // Sixteenth-note interval = halfBeatMs / 2 (halfBeatMs is one eighth note).
        let sixteenthMs = engine.halfBeatMs / 2.0
        let totalBeats  = engine.loopLengthBeats        // in eighth-note beats
        // Number of sixteenth-note steps in the loop.
        let sixteenthSteps = totalBeats * 2

        // grooveElapsed mirrors the engine's internal clock.
        // We replicate the engine's formula but derive it from the notes' progress
        // so we stay perfectly in sync without needing direct access to startMs.
        // Use the first note's progress to back-calculate grooveElapsed:
        // progress = (grooveElapsed - (noteTime - travelMs)) / travelMs
        // → grooveElapsed = progress * travelMs + noteTime - travelMs
        // If no notes, grid stays hidden (pattern is empty).
        guard let firstNote = engine.notes.first else {
            gridLineNodes.forEach { $0.isHidden = true }
            return
        }
        let noteTimeMs = Double(firstNote.beat) * engine.halfBeatMs
        let grooveElapsed = firstNote.progress * PlaybackEngine.travelMs
                          + noteTimeMs
                          - PlaybackEngine.travelMs

        var lineIndex = 0

        // Evaluate current pass and the next (for seamless loop crossfade).
        for pass in 0...1 {
            for step in 0..<sixteenthSteps {
                guard lineIndex < gridLineNodes.count else { break }

                let beatTimeMs = Double(step) * sixteenthMs
                                 + Double(pass) * engine.grooveMs
                let progress = (grooveElapsed - (beatTimeMs - PlaybackEngine.travelMs))
                             / PlaybackEngine.travelMs

                // Only show lines within a slightly extended visible window.
                guard progress >= -0.05 && progress <= 1.1 else { continue }

                let y = yFor(progress)
                let node = gridLineNodes[lineIndex]
                node.position = CGPoint(x: 0, y: y)
                node.isHidden = false

                // Color by subdivision (step is in sixteenth-note units):
                //   halfBeatMs = 1 eighth note, so:
                //     quarter note  = 4 sixteenth steps
                //     1 bar (4/4)   = 16 sixteenth steps  (= 8 eighth notes)
                //   Downbeat marks the start of each bar.
                if step % 16 == 0 {
                    node.fillColor = gridColorDownbeat      // bar / downbeat
                } else if step % 4 == 0 {
                    node.fillColor = gridColorQuarter       // quarter note
                } else if step % 2 == 0 {
                    node.fillColor = gridColorEighth        // eighth note
                } else {
                    node.fillColor = gridColorSixteenth     // sixteenth note
                }

                lineIndex += 1
            }
        }

        // Hide unused nodes in the pool.
        for i in lineIndex..<gridLineNodes.count {
            gridLineNodes[i].isHidden = true
        }
    }

    private func makeNode(lane: Int, alpha: CGFloat) -> SKShapeNode {
        let w = size.width / CGFloat(laneCount) - 16
        let node = SKShapeNode(rectOf: CGSize(width: max(24, w), height: 22), cornerRadius: 6)
        node.strokeColor = .clear
        node.fillColor = laneColors[lane]
        node.alpha = alpha
        addChild(node)
        return node
    }
}
