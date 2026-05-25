//  JournalModel.swift — PSI
import SwiftUI
import Foundation

// MARK: - Journal Entry

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date

    // Computed — never serialised
    var markupDataURL: URL { JournalEntry.markupURL(for: id) }

    init(id: UUID = UUID(), title: String = "", date: Date = Date()) {
        self.id    = id
        self.title = title
        self.date  = date
    }

    enum CodingKeys: String, CodingKey { case id, title, date }

    static func markupURL(for id: UUID) -> URL {
        entryDir(for: id).appendingPathComponent("markup.data")
    }

    static func entryDir(for id: UUID) -> URL {
        let dir = supportDir.appendingPathComponent(id.uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var supportDir: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("LoreJournal")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

// MARK: - Entries Store

@Observable
final class EntriesStore {
    var entries: [JournalEntry] = []

    private let storeURL: URL = {
        let dir = JournalEntry.supportDir
        return dir.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func load() {
        guard let data    = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data)
        else { return }
        entries = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    func add(_ e: JournalEntry)          { entries.insert(e, at: 0); save() }
    func delete(at idx: IndexSet)        { entries.remove(atOffsets: idx); save() }
    func rename(id: UUID, to t: String)  {
        if let i = entries.firstIndex(where: { $0.id == id }) {
            entries[i].title = t; save()
        }
    }
    func update(_ e: JournalEntry) {
        if let i = entries.firstIndex(where: { $0.id == e.id }) {
            entries[i] = e; save()
        }
    }
}
