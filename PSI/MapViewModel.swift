//
//  MapViewModel.swift
//  PSI
//
//  Created by OpenAI Codex on 14/05/26.
//

import CoreLocation
import Observation

protocol EventLocationProviding {
    func fetchNearbyEvents() async throws -> [EventLocation]
}

struct MockEventLocationProvider: EventLocationProviding {
    func fetchNearbyEvents() async throws -> [EventLocation] {
        [
            EventLocation(
                id: UUID(),
                title: "Show na Beira Mar",
                coordinate: CLLocationCoordinate2D(latitude: -3.7172, longitude: -38.5006),
                venueName: "Beira Mar",
                address: "Fortaleza, Ceará",
                details: "Show de musica ao vivo.",
                price: "Gratuito",
                imageURL: nil
            ),
            EventLocation(
                id: UUID(),
                title: "Feira Criativa",
                coordinate: CLLocationCoordinate2D(latitude: -3.7432, longitude: -38.5350),
                venueName: "Centro Cultural",
                address: "Fortaleza, Ceará",
                details: "Feira com artistas e criadores locais.",
                price: "Gratuito",
                imageURL: nil
            ),
            EventLocation(
                id: UUID(),
                title: "Workshop de Arte",
                coordinate: CLLocationCoordinate2D(latitude: -3.7278, longitude: -38.5149),
                venueName: "Atelie Aberto",
                address: "Fortaleza, Ceará",
                details: "Oficina artistica para iniciantes.",
                price: "Gratuito",
                imageURL: nil
            )
        ]
    }
}

@MainActor
@Observable
final class MapViewModel {
    private let eventProvider: EventLocationProviding

    var events: [EventLocation] = []
    var isLoading = false
    var errorMessage: String?

    init() {
        self.eventProvider = MapaCulturalAPIService()
    }

    init(eventProvider: EventLocationProviding) {
        self.eventProvider = eventProvider
    }

    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            events = try await eventProvider.fetchNearbyEvents()
        } catch {
            events = []
            errorMessage = error.localizedDescription
        }
    }
}
