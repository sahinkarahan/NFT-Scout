//
//  Card.swift
//  Application
//
//  Created by Şahin Karahan on 18.02.2025.
//

import Foundation
import SwiftUI

struct Card: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var image: String
}

let cards: [Card] = [
    .init(image: "Pic 1"),
    .init(image: "Pic 2"),
    .init(image: "Pic 3"),
    .init(image: "Pic 4"),
    .init(image: "Pic 5"),
    .init(image: "Pic 6"),
]
