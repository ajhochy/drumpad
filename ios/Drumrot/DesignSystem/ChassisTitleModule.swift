import SwiftUI

extension View {
    /// Title-labelled chassis module (used by Play's rail): an SPModuleTitle
    /// header above the content, wrapped in the standard chassis panel.
    /// Overloads the parameterless `chassisModule(padding:)` from Chassis.swift.
    func chassisModule(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SPModuleTitle(title: title)
            self
        }
        .chassisModule()
    }
}
