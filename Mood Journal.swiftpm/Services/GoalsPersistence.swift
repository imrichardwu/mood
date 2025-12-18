import Foundation

struct GoalsPersistence {
    private let fileName = "goals.json"

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("MoodJournal", isDirectory: true)
        return dir.appendingPathComponent(fileName, isDirectory: false)
    }

    func loadGoals() throws -> [Goal]? {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Goal].self, from: data)
    }

    func saveGoals(_ goals: [Goal]) throws {
        let url = fileURL
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(goals)
        try data.write(to: url, options: [.atomic])
    }
}

