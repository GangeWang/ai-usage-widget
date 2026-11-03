import Foundation

/// One rate-limit window (5-hour or weekly).
struct UsageWindow: Codable, Equatable {
    var usedPercent: Double
    var resetsAt: Date?
}

/// Snapshot for one provider (Claude or Codex).
struct ProviderUsage: Codable, Equatable {
    var plan: String?
    var fiveHour: UsageWindow?
    var weekly: UsageWindow?
    /// Last time data was fetched successfully.
    var fetchedAt: Date?
    /// Error from the latest attempt; nil when it succeeded.
    var error: String?
}

struct UsageSnapshot: Codable, Equatable {
    var claude: ProviderUsage
    var codex: ProviderUsage

    static let empty = UsageSnapshot(claude: ProviderUsage(), codex: ProviderUsage())
}

enum Provider: String, CaseIterable {
    case claude, codex
}

enum UsageStore {
    /// Real home directory (the widget's sandbox redirects NSHomeDirectory into its container).
    static var realHome: String {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            return String(cString: dir)
        }
        return NSHomeDirectory()
    }

    /// Readable by the sandboxed widget through a home-relative read-only exception.
    static var directory: URL {
        URL(fileURLWithPath: realHome).appendingPathComponent("Library/Application Support/AIUsageWidget", isDirectory: true)
    }

    static var fileURL: URL { directory.appendingPathComponent("usage.json") }

    static func load() -> UsageSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(UsageSnapshot.self, from: data)
    }

    static func save(_ snapshot: UsageSnapshot) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
    }
}
