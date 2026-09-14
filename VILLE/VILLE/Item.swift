//
//  Item.swift
//  VILLE
//
//  Created by Ale Gómez Urrea on 21/4/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
