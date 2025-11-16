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
    @State private var currentLeaderName: String?
    @State private var currentLeaderScore: Int = 0
    @State private var showConfetti = false
    
    private var topPlayer: Player? {
        players.max(by: { $0.euchreCount < $1.euchreCount })
    }
    
    private var displayedLeader: Player? {
        if let leaderName = currentLeaderName {
            return players.first(where: { $0.name == leaderName })
        }
        return nil
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
                if let leader = displayedLeader, currentLeaderScore > 0 {
                    Text(leader.name)
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
        if let top = topPlayer, top.euchreCount > 0 {
            currentLeaderName = top.name
            currentLeaderScore = top.euchreCount
        }
    }
    
    private func checkForLeaderChange() {
        guard let top = topPlayer else {
            // No players or all at 0
            currentLeaderName = nil
            currentLeaderScore = 0
            return
        }
        
        let previousLeader = currentLeaderName
        
        // If top player's score is 0 or less, clear the leader
        if top.euchreCount <= 0 {
            currentLeaderName = nil
            currentLeaderScore = 0
            return
        }
        
        // If there's no current leader, set the top player as leader
        if currentLeaderName == nil {
            currentLeaderName = top.name
            currentLeaderScore = top.euchreCount
            return
        }
        
        // The top player is whoever has the highest score right now
        // If they're different from the current leader, we need to check if we should change
        if top.name != currentLeaderName {
            // The actual top player is different from our stored leader
            // This means either:
            // 1. Someone exceeded the leader's score (top.euchreCount > previousScore)
            // 2. The leader's score dropped below someone else (need to check current leader's actual score)
            
            if let currentLeader = displayedLeader {
                // Check the current leader's actual score
                if top.euchreCount > currentLeader.euchreCount {
                    // Top player has more points, they're the new leader
                    currentLeaderName = top.name
                    currentLeaderScore = top.euchreCount
                    
                    // Trigger confetti for new leader
                    if previousLeader != nil {
                        triggerConfetti()
                    }
                }
            }
        } else {
            // Current leader is still on top, just update their score
            currentLeaderScore = top.euchreCount
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
