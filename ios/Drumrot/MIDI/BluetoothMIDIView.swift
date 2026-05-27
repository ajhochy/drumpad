import SwiftUI
import CoreAudioKit

/// Wraps the system Bluetooth-MIDI pairing UI. Real pairing requires hardware.
struct BluetoothMIDIView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CABTMIDICentralViewController {
        CABTMIDICentralViewController()
    }
    func updateUIViewController(_ controller: CABTMIDICentralViewController, context: Context) {}
}
