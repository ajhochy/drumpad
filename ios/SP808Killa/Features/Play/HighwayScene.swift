import SpriteKit

/// SpriteKit note highway. Drives the PlaybackEngine from its own per-frame
/// update loop and positions one node per note by `progress` (0 top → 1 strike).
@MainActor
final class HighwayScene: SKScene {
    var engine: PlaybackEngine?
    var onCountInBeat: ((Int) -> Void)?

    private let laneCount = 6
    private var noteNodes: [Int: SKShapeNode] = [:]
    private var strikeY: CGFloat = 90
    private var lastBeat = 0

    private let laneColors: [SKColor] = [
        SKColor(red: 1.0, green: 0.16, blue: 0.48, alpha: 1),   // crash – pink
        SKColor(red: 0.36, green: 0.94, blue: 0.49, alpha: 1),  // hihat – green
        SKColor(red: 0.87, green: 0.89, blue: 0.92, alpha: 1),  // snare – white
        SKColor(red: 1.0, green: 0.23, blue: 0.35, alpha: 1),   // kick – red
        SKColor(red: 1.0, green: 0.54, blue: 0.12, alpha: 1),   // tom – amber
        SKColor(red: 0.30, green: 0.85, blue: 1.0, alpha: 1),   // ride – cyan
    ]

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.04, blue: 0.05, alpha: 1)
        buildLanes()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        strikeY = size.height * 0.16
        removeAllChildren()
        noteNodes.removeAll()
        buildLanes()
    }

    private func laneX(_ lane: Int) -> CGFloat {
        let w = size.width / CGFloat(laneCount)
        return w * (CGFloat(lane) + 0.5)
    }

    private func buildLanes() {
        for lane in 0..<laneCount {
            let guideRect = CGRect(x: laneX(lane) - 1, y: 0, width: 2, height: size.height)
            let guide = SKShapeNode(rect: guideRect)
            guide.fillColor = laneColors[lane].withAlphaComponent(0.10)
            guide.strokeColor = .clear
            addChild(guide)
        }
        let strike = SKShapeNode(rect: CGRect(x: 0, y: strikeY - 2, width: size.width, height: 4))
        strike.fillColor = SKColor.white.withAlphaComponent(0.7)
        strike.strokeColor = .clear
        addChild(strike)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let engine else { return }
        if let beat = engine.update(nowMs: currentTime * 1000) {
            if beat != lastBeat { onCountInBeat?(beat); lastBeat = beat }
        }
        render(notes: engine.notes)
    }

    private func render(notes: [PlaybackEngine.ActiveNote]) {
        var seen = Set<Int>()
        for note in notes {
            seen.insert(note.id)
            let node = noteNodes[note.id] ?? makeNode(for: note)
            let y = size.height - CGFloat(note.progress) * (size.height - strikeY)
            node.position = CGPoint(x: laneX(note.lane), y: y)
            let visible = note.progress >= -0.1 && note.progress <= 1.2 && !note.hit
            node.isHidden = !visible
            if note.hit {
                node.fillColor = SKColor.white
            } else if note.missed {
                node.fillColor = laneColors[note.lane].withAlphaComponent(0.25)
            } else {
                node.fillColor = laneColors[note.lane]
            }
        }
        for (id, node) in noteNodes where !seen.contains(id) {
            node.removeFromParent(); noteNodes[id] = nil
        }
    }

    private func makeNode(for note: PlaybackEngine.ActiveNote) -> SKShapeNode {
        let w = size.width / CGFloat(laneCount) - 16
        let node = SKShapeNode(rectOf: CGSize(width: max(24, w), height: 22), cornerRadius: 6)
        node.strokeColor = .clear
        node.fillColor = laneColors[note.lane]
        addChild(node)
        noteNodes[note.id] = node
        return node
    }
}
