//
//  ContentView.swift
//  euch
//
//  Created by Chris Greco on 2025-11-15.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.order) private var players: [Player]

    var body: some View {
        VStack(spacing: 12) {
            Image("Euchred")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 120)
                .padding(.bottom, 8)
            
            ForEach(players) { player in
                PlayerRowView(player: player)
            }
        }
        .padding(20)
        .onAppear {
            initializePlayersIfNeeded()
        }
    }
    
    private func initializePlayersIfNeeded() {
        if players.isEmpty {
            let defaultPlayers = [
                Player(name: "Player One", order: 0),
                Player(name: "Player Two", order: 1),
                Player(name: "Player Three", order: 2),
                Player(name: "Player Four", order: 3)
            ]
            
            for player in defaultPlayers {
                modelContext.insert(player)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Player.self, inMemory: true)
}
