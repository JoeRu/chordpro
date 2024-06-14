//
//  HelpButtonsView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI

/// SwiftUI buttons for the main `help` menu
struct HelpButtonsView: View {
    /// The document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The body of the `View`
    var body: some View {
        if let url = URL(string: "https://www.chordpro.org/chordpro/") {
            Link(destination: url) {
                Text("ChordPro File Format")
            }
        }
        if let url = URL(string: "https://groups.io/g/ChordPro") {
            Link(destination: url) {
                Text("ChordPro Community")
            }
        }
        if let sampleSong = Bundle.main.url(forResource: "lib/ChordPro/res/examples/swinglow.cho", withExtension: nil) {
            Divider()
            Button("Insert a Song Example") {
                if let document, let content = try? String(contentsOf: sampleSong, encoding: .utf8) {
                    document.document.text = content
                }
            }
            .disabled(document == nil)
        }
        Divider()
        Text("Trouble Shooting")
        Toggle(isOn: $appState.settings.debug) {
            Text("Enable Debug Info in the PDF")
        }
        if let url = URL(string: "https://chordpro.org/chordpro/trouble-shooting/") {
            Link(destination: url) {
                Text("More Trouble Shooting Help on ChordPro.org")
            }
        }
        Divider()
        if let url = URL(string: "https://github.com/ChordPro/chordpro") {
            Link(destination: url) {
                Text("ChordPro on GitHub")
            }
        }
    }
}
