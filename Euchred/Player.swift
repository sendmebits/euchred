//
//  Player.swift
//  euch
//
//  Created by sendmebits on 2025-11-15.
//

import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var euchreCount: Int
    var order: Int
    
    init(name: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.euchreCount = 0
        self.order = order
    }
}
