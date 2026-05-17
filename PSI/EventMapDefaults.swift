//
//  EventMapDefaults.swift
//  PSI
//
//  Created by OpenAI Codex on 14/05/26.
//

import CoreLocation
import MapKit

enum EventMapDefaults {
    static let fallbackCoordinate = CLLocationCoordinate2D(latitude: -3.7319, longitude: -38.5267)
    static let span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    static let region = MKCoordinateRegion(center: fallbackCoordinate, span: span)
}
