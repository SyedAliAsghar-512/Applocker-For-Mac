import Foundation

struct LockedApp: Codable, Identifiable, Equatable {
    let id: String // bundle identifier
    let name: String
    let path: String
}

final class RulesStore: ObservableObject {
    @Published var lockedApps: [LockedApp] = []
    private let url: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("com.example.applocker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("rules.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        lockedApps = (try? JSONDecoder().decode([LockedApp].self, from: data)) ?? []
    }

    func save() {
        let data = try? JSONEncoder().encode(lockedApps)
        try? data?.write(to: url)
    }

    func add(app: LockedApp) {
        if !lockedApps.contains(app) {
            lockedApps.append(app)
            save()
        }
    }

    func remove(app: LockedApp) {
        lockedApps.removeAll { $0 == app }
        save()
    }
}
