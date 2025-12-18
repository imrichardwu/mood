import Foundation

struct LocalPersistence {
    private let fileName = "mood_entries.json"

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("MoodJournal", isDirectory: true)
        return dir.appendingPathComponent(fileName, isDirectory: false)
    }

    func loadEntries() throws -> [MoodEntry]? {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MoodEntry].self, from: data)
    }

    func saveEntries(_ entries: [MoodEntry]) throws {
        let url = fileURL
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entries)
        try data.write(to: url, options: [.atomic])
    }
}


