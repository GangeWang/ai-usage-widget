import SwiftUI
import WidgetKit
import ServiceManagement

@MainActor
final class Refresher: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot = UsageStore.load() ?? .empty
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled

    private var timer: Timer?
    static let interval: TimeInterval = 5 * 60

    init() {
        // Start at login by default on first run.
        if SMAppService.mainApp.status == .notRegistered {
            try? SMAppService.mainApp.register()
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    func refresh() async {
        async let claude = Self.attempt(UsageFetcher.fetchClaude, previous: snapshot.claude)
        async let codex = Self.attempt(UsageFetcher.fetchCodex, previous: snapshot.codex)
        let next = UsageSnapshot(claude: await claude, codex: await codex)
        snapshot = next
        try? UsageStore.save(next)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// On failure keep the last good numbers and just attach the error.
    private static func attempt(_ fetch: () async throws -> ProviderUsage, previous: ProviderUsage) async -> ProviderUsage {
        do {
            return try await fetch()
        } catch {
            var kept = previous
            kept.error = error.localizedDescription
            return kept
        }
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {}
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

@main
struct AIUsageApp: App {
    @StateObject private var refresher = Refresher()

    var body: some Scene {
        MenuBarExtra("AI 額度", systemImage: "gauge.with.dots.needle.33percent") {
            ProviderMenuSection(title: "Claude", usage: refresher.snapshot.claude)
            Divider()
            ProviderMenuSection(title: "Codex", usage: refresher.snapshot.codex)
            Divider()
            Button("立即更新") { Task { await refresher.refresh() } }
                .keyboardShortcut("r")
            Toggle("登入時自動啟動", isOn: Binding(
                get: { refresher.launchAtLogin },
                set: { refresher.setLaunchAtLogin($0) }
            ))
            Divider()
            Button("結束 AI 額度") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

private struct ProviderMenuSection: View {
    let title: String
    let usage: ProviderUsage

    var body: some View {
        Text(title + (usage.plan.map { " · \($0.capitalized)" } ?? ""))
        Text("5 小時：" + format(usage.fiveHour))
        Text("每週：" + format(usage.weekly))
        if let error = usage.error {
            Text("⚠︎ " + error)
        }
    }

    private func format(_ w: UsageWindow?) -> String {
        guard let w else { return "—" }
        if let r = w.resetsAt, r <= .now { return "剩 100%（已重置）" }
        var s = "剩 \(Int(max(100 - w.usedPercent, 0).rounded()))%"
        if let r = w.resetsAt {
            s += "，" + r.formatted(.dateTime.weekday(.abbreviated).hour().minute()) + " 重置"
        }
        return s
    }
}
