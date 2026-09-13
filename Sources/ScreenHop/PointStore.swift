import Foundation

final class PointStore {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Screen Hop", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("points.json")
    }

    func load() -> [CursorPoint] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([CursorPoint].self, from: data)) ?? []
    }

    func save(_ points: [CursorPoint]) {
        guard let data = try? JSONEncoder().encode(points) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
