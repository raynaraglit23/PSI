//
//  ExperienceMapper.swift
//  PSI
//
//  Created by OpenAI Codex on 14/05/26.
//

import CoreLocation
import Foundation

struct ExperienceMapper {
    func map(events: [EventLocation], userCoordinate: CLLocationCoordinate2D?) -> [Experience] {
        events.map { map(event: $0, userCoordinate: userCoordinate) }
    }

    func map(event: EventLocation, userCoordinate: CLLocationCoordinate2D?) -> Experience {
        let referenceCoordinate = userCoordinate ?? EventMapDefaults.fallbackCoordinate

        return Experience(
            id: event.id,
            title: event.title,
            imageName: inferredImageName(for: event.title),
            imageURL: event.imageURL,
            category: inferredCategory(for: event.title),
            distanceKm: distance(from: referenceCoordinate, to: event.coordinate),
            dateText: event.dateText?.nonEmpty ?? "Data a confirmar",
            description: event.details?.nonEmpty ?? "Detalhes deste evento ainda nao foram informados pela API do Mapa Cultural do Ceara.",
            price: event.price?.nonEmpty ?? "Gratuito",
            location: formattedLocation(for: event)
        )
    }

    private func distance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let sourceLocation = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return sourceLocation.distance(from: destinationLocation) / 1000
    }

    private func formattedLocation(for event: EventLocation) -> String {
        let venue = event.venueName.nonEmpty
        let address = event.address.nonEmpty

        switch (venue, address) {
        case let (venue?, address?) where address.localizedCaseInsensitiveContains(venue):
            return address
        case let (venue?, address?):
            return "\(venue), \(address)"
        case let (venue?, nil):
            return venue
        case let (nil, address?):
            return address
        case (nil, nil):
            return "Fortaleza, Ceará"
        }
    }

    private func inferredImageName(for title: String) -> String {
        switch inferredCategory(for: title) {
        case .celebrar:
            return "music.note"
        case .aprender:
            return "book.fill"
        case .mover:
            return "figure.run"
        case .criar:
            return "paintbrush.pointed.fill"
        case .explorar:
            return "binoculars.fill"
        }
    }

    private func inferredCategory(for title: String) -> Category {
        let normalizedTitle = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        if normalizedTitle.contains(anyOf: ["show", "festival", "musica", "concerto", "baile"]) {
            return .celebrar
        }

        if normalizedTitle.contains(anyOf: ["oficina", "workshop", "curso", "aula", "palestra"]) {
            return .aprender
        }

        if normalizedTitle.contains(anyOf: ["esporte", "corrida", "danca", "yoga", "caminhada"]) {
            return .mover
        }

        if normalizedTitle.contains(anyOf: ["arte", "pintura", "desenho", "atelier", "ateli", "criativo"]) {
            return .criar
        }

        return .explorar
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func contains(anyOf values: [String]) -> Bool {
        values.contains { localizedCaseInsensitiveContains($0) }
    }
}
