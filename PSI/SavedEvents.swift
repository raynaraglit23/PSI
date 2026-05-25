import SwiftUI
import Foundation

@Observable
final class SavedEventsStore {
    var savedExperiences: [Experience] = []
    
    // Caminho do arquivo de salvamento (usando a mesma pasta LoreJournal)
    private let storeURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("LoreJournal")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("saved_events.json")
    }()
    
    init() { load() }
    
    func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([Experience].self, from: data)
        else { return }
        savedExperiences = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(savedExperiences) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
    
    func isSaved(_ experience: Experience) -> Bool {
        savedExperiences.contains(where: { $0.id == experience.id })
    }
    
    func toggleSave(for experience: Experience) {
        if let index = savedExperiences.firstIndex(where: { $0.id == experience.id }) {
            savedExperiences.remove(at: index)
        } else {
            savedExperiences.insert(experience, at: 0)
        }
        save() // Salva sempre que houver alteração
    }
}
