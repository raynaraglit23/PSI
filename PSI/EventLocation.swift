//
//  EventLocation.swift
//  PSI
//
//  Created by OpenAI Codex on 14/05/26.
//

import Foundation
import CoreLocation

struct EventLocation: Identifiable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let venueName: String
    let address: String
    let dateText: String?
    let details: String?
    let date: String?
    let price: String?
    let imageURL: URL?
}

extension UUID {
    static func stableIdentifier(from value: String) -> UUID {
        let cleaned = value.unicodeScalars.map(\.value)
        var bytes = [UInt8](repeating: 0, count: 16)

        for (index, scalar) in cleaned.enumerated() {
            bytes[index % 16] = bytes[index % 16] &+ UInt8(truncatingIfNeeded: scalar)
        }

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
