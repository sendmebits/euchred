//
//  euchApp.swift
//  euch
//
//  Created by Chris  on 2025-11-15.
//

import SwiftUI
import SwiftData

@main
struct euchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Player.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
