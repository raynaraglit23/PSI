//
//  JournalModel.swift
//  PSI
//
//  Created by Raynara Coelho on 17/05/26.
//

// MARK: - Journal Entry Model
import SwiftUI
import PaperKit
import PencilKit
import Foundation

// MARK: - Canvas Photo Model
struct CanvasPhoto: Identifiable, Codable {
    var id = UUID()
    var position: CGPoint
    var fileName: String
    var scale: CGFloat = 1.0
}

struct JournalEntry: Identifiable {
    let id: UUID
    var title: String
    var date: Date
    var markupDataURL: URL   // persisted PaperKit canvas per entry
    var attachedPhotos: [CanvasPhoto] = []

    init(id: UUID = UUID(), title: String = "", date: Date = Date()) {
        self.id = id
        self.title = title
        self.date = date
        self.markupDataURL = JournalEntry.storageURL(for: id)
    }

    static func storageURL(for id: UUID) -> URL {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("LoreJournal/entries/\(id.uuidString)")
        try? FileManager.default.createDirectory(at: dir,
                                                  withIntermediateDirectories: true)
        return dir.appendingPathComponent("markup.data")
    }
}

// MARK: - Canvas Tool

enum CanvasTool: String, CaseIterable {
    //case pencil = "pencil"
    case text   = "textformat"
    case shape  = "square.on.circle"
    case photo  = "photo"
    case loupe  = "magnifyingglass"

    var label: String {
        switch self {
        //case .pencil: return "Pencil"
        case .text:   return "Text"
        case .shape:  return "Shape"
        case .photo:  return "Photo"
        case .loupe:  return "Loupe"
        }
    }
}

