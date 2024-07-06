//
//  Subscription.swift
//  
//
//  Created by Collin Ilgner on 06.07.24.
//
//

import Foundation
import SwiftData


@Model public class Subscription {
    var amount: Double = 0
    var date: Date
    var isPaused: Bool = false
    var isPinned: Bool = false
    var notes: String?
    var remembercycle: String?
    var repeating: Bool = true
    var repeatPattern: String?
    var timestamp: Date?
    var title: String
    var url: String?
    public init(date: Date, title: String) {
        self.date = date
        self.title = title

    }
    
}
