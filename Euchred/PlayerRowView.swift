//
//  PlayerRowView.swift
//  euch
//
//  Created by Kiro on 2025-11-15.
//

import SwiftUI
import SwiftData

struct PlayerRowView: View {
    @Bindable var player: Player
    @State private var isPressed = false
    @State private var dragOffset: CGFloat = 0
    @State private var showingRenameAlert = false
    @State private var newName = ""
    @State private var showToast = false
    @State private var toastScale: CGFloat = 0.5
    @State private var toastOpacity: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
            
            Text(player.name)
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(player.euchreCount)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color(.systemGray).opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(dragOffset > 0 ? 0.7 : 1.0)
        .animation(.spring(duration: 0.3), value: isPressed)
        .animation(.spring(duration: 0.3), value: player.euchreCount)
        .animation(.spring(duration: 0.2), value: dragOffset)
        .overlay(
            // Big fun +1 toast - overlay doesn't affect layout
            Group {
                if showToast {
                    Text("+1")
                        .font(.system(size: 80, weight: .black))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.5), radius: 20, x: 0, y: 0)
                        .scaleEffect(toastScale)
                        .opacity(toastOpacity)
                }
            }
        )
        .gesture(
            TapGesture()
                .onEnded { _ in
                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    
                    // Increment count on tap
                    isPressed = true
                    player.euchreCount += 1
                    
                    // Show and animate toast
                    showToast = true
                    toastScale = 0.5
                    toastOpacity = 1.0
                    
                    withAnimation(.spring(duration: 0.6, bounce: 0.5)) {
                        toastScale = 1.5
                        toastOpacity = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        showToast = false
                    }
                }
        )
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    // Haptic feedback for long press
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    
                    // Blank the text field by default
                    newName = ""
                    showingRenameAlert = true
                }
        )
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    // Track horizontal drag for visual feedback
                    if value.translation.width > 0 {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    // Detect left-to-right swipe (minimum 50pt horizontal translation)
                    if value.translation.width >= 50 {
                        // Decrement count only if greater than 0
                        if player.euchreCount > 0 {
                            // Haptic feedback for decrement
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            
                            player.euchreCount -= 1
                        }
                    }
                    // Reset drag offset
                    dragOffset = 0
                }
        )
        .alert("Rename Player: \(player.name)", isPresented: $showingRenameAlert) {
            TextField("Player Name", text: $newName)
                .onChange(of: newName) { oldValue, newValue in
                    // Limit input to 20 characters
                    if newValue.count > 20 {
                        newName = String(newValue.prefix(20))
                    }
                }
            Button("Cancel", role: .cancel) {
                newName = ""
            }
            Button("Save") {
                // Validate and update name
                let trimmedName = newName.trimmingCharacters(in: .whitespaces)
                if !trimmedName.isEmpty {
                    player.name = trimmedName
                }
                newName = ""
            }
        }
    }
}

#Preview {
    PlayerRowView(player: Player(name: "Player One", order: 0))
        .padding()
        .modelContainer(for: Player.self, inMemory: true)
}
