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
    @State private var currentLeaderNames: [String] = []
    @State private var currentLeaderScore: Int = 0
    @State private var showConfetti = false
    
    private var topPlayers: [Player] {
        guard let maxScore = players.map({ $0.euchreCount }).max(), maxScore > 0 else {
            return []
        }
        return players.filter { $0.euchreCount == maxScore }
    }
    
    private var displayedLeaders: [Player] {
        players.filter { currentLeaderNames.contains($0.name) }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Image at very top
                Image("Euchred")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 100)
                    .padding(.top, 8)
                
                // Leader display
                if !displayedLeaders.isEmpty && currentLeaderScore > 0 {
                    Text(displayedLeaders.map { $0.name }.joined(separator: ", "))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    Text("No Leader Yet")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                }
                
                // Player list
                VStack(spacing: 12) {
                    ForEach(players) { player in
                        PlayerRowView(player: player)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
                
                Spacer()
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }
        }
        .onChange(of: players.map { $0.euchreCount }) { oldValue, newValue in
            checkForLeaderChange()
        }
        .onAppear {
            initializePlayersIfNeeded()
            initializeLeader()
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
    
    private func initializeLeader() {
        let leaders = topPlayers
        if !leaders.isEmpty {
            currentLeaderNames = leaders.map { $0.name }
            currentLeaderScore = leaders.first?.euchreCount ?? 0
        }
    }
    
    private func checkForLeaderChange() {
        let leaders = topPlayers
        
        // If no leaders (all at 0), clear the leader display
        if leaders.isEmpty {
            currentLeaderNames = []
            currentLeaderScore = 0
            return
        }
        
        let previousLeaderNames = currentLeaderNames
        let newLeaderNames = leaders.map { $0.name }
        let newLeaderScore = leaders.first?.euchreCount ?? 0
        
        // If there's no current leader, set the top players as leaders
        if currentLeaderNames.isEmpty {
            currentLeaderNames = newLeaderNames
            currentLeaderScore = newLeaderScore
            return
        }
        
        // Check if the leader(s) changed
        if newLeaderScore > currentLeaderScore {
            // New leader(s) with higher score
            currentLeaderNames = newLeaderNames
            currentLeaderScore = newLeaderScore
            
            // Trigger confetti for new leader(s)
            if !previousLeaderNames.isEmpty {
                triggerConfetti()
            }
        } else if Set(newLeaderNames) != Set(currentLeaderNames) {
            // Same score but different players (tie situation changed)
            currentLeaderNames = newLeaderNames
            currentLeaderScore = newLeaderScore
            
            // Trigger confetti for tie situation
            if !previousLeaderNames.isEmpty {
                triggerConfetti()
            }
        } else {
            // Same leaders, just update score in case it changed
            currentLeaderScore = newLeaderScore
        }
    }
    
    private func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showConfetti = false
        }
    }
}

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Circle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .position(piece.position)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .pink, .orange]
        
        for _ in 0..<100 {
            let piece = ConfettiPiece(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                )
            )
            confettiPieces.append(piece)
            
            animatePiece(piece, in: size)
        }
    }
    
    private func animatePiece(_ piece: ConfettiPiece, in size: CGSize) {
        withAnimation(
            .easeIn(duration: Double.random(in: 2...3))
            .delay(Double.random(in: 0...0.5))
        ) {
            if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                confettiPieces[index].position = CGPoint(
                    x: piece.position.x + CGFloat.random(in: -100...100),
                    y: size.height + 20
                )
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
}

#Preview {
    ContentView()
        .modelContainer(for: Player.self, inMemory: true)
}
