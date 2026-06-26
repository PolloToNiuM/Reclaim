//
//  ContentView.swift
//  Reclaim
//
//  Created by Paul Fretard on 26/06/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var tapped = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Reclaim")
                .font(.largeTitle.bold())

            Text(tapped ? "Le bouton marche" : "Test sur iPhone")
                .foregroundStyle(.secondary)

            Button("Appuyer ici") {
                tapped.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
