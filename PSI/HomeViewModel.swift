//
//  HomeViewModel.swift
//  PSI
//
//  Created by OpenAI Codex on 14/05/26.
//

import CoreLocation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let eventProvider: EventLocationProviding
    private let mapper: ExperienceMapper

    private var loadedEvents: [EventLocation] = []
    private var userCoordinate: CLLocationCoordinate2D?

    var experiences: [Experience] = []
    var isLoading = false
    var errorMessage: String?

    init() {
        self.eventProvider = MapaCulturalAPIService()
        self.mapper = ExperienceMapper()
    }

    init(eventProvider: EventLocationProviding, mapper: ExperienceMapper) {
        self.eventProvider = eventProvider
        self.mapper = mapper
    }

    func loadExperiences() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            loadedEvents = try await eventProvider.fetchNearbyEvents()
            remapExperiences()
        } catch {
            experiences = []
            errorMessage = error.localizedDescription
        }
    }

    func updateUserCoordinate(_ coordinate: CLLocationCoordinate2D?) {
        userCoordinate = coordinate
        remapExperiences()
    }

    private func remapExperiences() {
        experiences = mapper.map(events: loadedEvents, userCoordinate: userCoordinate)
    }
}
