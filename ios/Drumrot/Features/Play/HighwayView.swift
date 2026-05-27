import SwiftUI
import SpriteKit

/// Hosts the HighwayScene and keeps it wired to the engine.
struct HighwayView: View {
    let engine: PlaybackEngine
    var onCountInBeat: (Int) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: makeScene(size: geo.size), options: [.allowsTransparency])
        }
    }

    private func makeScene(size: CGSize) -> HighwayScene {
        let scene = HighwayScene(size: size)
        scene.scaleMode = .resizeFill
        scene.engine = engine
        scene.onCountInBeat = onCountInBeat
        return scene
    }
}
