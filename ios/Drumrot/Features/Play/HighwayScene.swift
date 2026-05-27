import SpriteKit

/// SpriteKit note highway. Drives the PlaybackEngine from its own per-frame
/// update loop and positions a node per note by `progress` (0 top → 1 strike),
/// plus a dim shadow node one pass ahead for a seamless loop reel.
@MainActor
final class HighwayScene: SKScene {
    var engine: PlaybackEngine?

    private let laneCount = 6
    private var noteNodes: [Int: SKShapeNode] = [:]
    private var shadowNodes: [Int: SKShapeNode] = [:]
    private var countInLabel: SKLabelNode?
    private var strikeY: CGFloat = 90

    private let laneColors: [SKColor] = [
        SKColor(red: 1.0, green: 0.16, blue: 0.48, alpha: 1),   // crash – pink
        SKColor(red: 0.36, green: 0.94, blue: 0.49, alpha: 1),  // hihat – green
        SKColor(red: 0.87, green: 0.89, blue: 0.92, alpha: 1),  // snare – white
        SKColor(red: 1.0, green: 0.23, blue: 0.35, alpha: 1),   // kick – red
        SKColor(red: 1.0, green: 0.54, blue: 0.12, alpha: 1),   // tom – amber
        SKColor(red: 0.30, green: 0.85, blue: 1.0, alpha: 1),   // ride – cyan
    ]

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.039, green: 0.078, blue: 0.063, alpha: 1) // LCD #0a1410
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        strikeY = size.height * 0.16
        removeAllChildren()
        noteNodes.removeAll()
        shadowNodes.removeAll()
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
