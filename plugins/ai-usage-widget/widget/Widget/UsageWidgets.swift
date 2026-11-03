import SwiftUI
import WidgetKit

// MARK: Timeline

struct UsageEntry: TimelineEntry {
    let date: Date
    let usage: ProviderUsage
}

struct UsageProvider: TimelineProvider {
    let provider: Provider

    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: .now, usage: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(context.isPreview && current().fetchedAt == nil ? placeholder(in: context) : UsageEntry(date: .now, usage: current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let usage = current()
        var entries = [UsageEntry(date: .now, usage: usage)]
        // Re-render right after each reset so "已重置" shows even before the app's next fetch.
        for date in [usage.fiveHour?.resetsAt, usage.weekly?.resetsAt].compactMap({ $0 })
        where date > .now && date < .now.addingTimeInterval(3600) {
            entries.append(UsageEntry(date: date.addingTimeInterval(1), usage: usage))
        }
        entries.sort { $0.date < $1.date }
        completion(Timeline(entries: entries, policy: .after(.now.addingTimeInterval(5 * 60))))
    }

    private func current() -> ProviderUsage {
        guard let snap = UsageStore.load() else { return ProviderUsage(error: "請先開啟「AI 額度」App") }
        return provider == .claude ? snap.claude : snap.codex
    }
}

extension ProviderUsage {
    static let sample = ProviderUsage(
        plan: "pro",
        fiveHour: UsageWindow(usedPercent: 26, resetsAt: .now.addingTimeInterval(2 * 3600)),
        weekly: UsageWindow(usedPercent: 41, resetsAt: .now.addingTimeInterval(3 * 86400)),
        fetchedAt: .now
    )
}

// MARK: Styling

extension Provider {
    var name: String { self == .claude ? "Claude" : "Codex" }
    var symbol: String { self == .claude ? "sparkle" : "chevron.left.forwardslash.chevron.right" }
    var tint: Color {
        self == .claude
            ? Color(red: 0.85, green: 0.47, blue: 0.34)   // Claude terracotta
            : Color(red: 0.06, green: 0.64, blue: 0.50)   // OpenAI green
    }
}

/// Color by remaining quota: red when nearly out, orange when getting low.
private func barColor(_ left: Double, _ provider: Provider) -> Color {
    left <= 10 ? .red : left <= 25 ? .orange : provider.tint
}

// MARK: Views

struct UsageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let provider: Provider
    let entry: UsageEntry

    private var isStale: Bool {
        guard let fetched = entry.usage.fetchedAt else { return true }
        return entry.usage.error != nil || entry.date.timeIntervalSince(fetched) > 20 * 60
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 10) {
            header
            if entry.usage.fetchedAt == nil, let error = entry.usage.error {
                Spacer(minLength: 0)
                Text(error).font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else if family == .systemSmall {
                WindowRow(title: "5 小時", window: entry.usage.fiveHour, now: entry.date, provider: provider, weekly: false)
                WindowRow(title: "每週", window: entry.usage.weekly, now: entry.date, provider: provider, weekly: true)
            } else {
                HStack(spacing: 14) {
                    RingGauge(title: "5 小時", window: entry.usage.fiveHour, now: entry.date, provider: provider, weekly: false)
                    RingGauge(title: "每週", window: entry.usage.weekly, now: entry.date, provider: provider, weekly: true)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [provider.tint.opacity(0.18), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: provider.symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(provider.tint)
            Text(provider.name).font(.headline)
            if let plan = entry.usage.plan {
                Text(plan.capitalized)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(provider.tint.opacity(0.2), in: Capsule())
            }
            Spacer(minLength: 0)
            if family != .systemSmall, let fetched = entry.usage.fetchedAt {
                Text(fetched, style: .time).font(.caption2).foregroundStyle(.secondary)
            }
            if isStale && entry.usage.fetchedAt != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2).foregroundStyle(.yellow)
                    .help(entry.usage.error ?? "資料可能已過時")
            }
        }
    }
}

/// Remaining percent, treating a reset that already passed as a full window.
private func remaining(_ window: UsageWindow?, now: Date) -> Double? {
    guard let window else { return nil }
    if let r = window.resetsAt, r <= now { return 100 }
    return min(max(100 - window.usedPercent, 0), 100)
}

private struct ResetCaption: View {
    let window: UsageWindow?
    let now: Date
    let weekly: Bool

    var body: some View {
        Group {
            if let r = window?.resetsAt {
                if r <= now {
                    Text("已重置")
                } else if weekly && r.timeIntervalSince(now) > 86400 {
                    Text(r, format: .dateTime.weekday(.abbreviated).hour().minute()) + Text(" 重置")
                } else {
                    Text(r, style: .relative) + Text(" 後重置")
                }
            } else {
                Text(window == nil ? "無資料" : "尚未開始計算")
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private struct WindowRow: View {
    let title: String
    let window: UsageWindow?
    let now: Date
    let provider: Provider
    let weekly: Bool

    var body: some View {
        let left = remaining(window, now: now)
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(title).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if left != nil {
                    Text("剩").font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }
                Text(left.map { "\(Int($0.rounded()))%" } ?? "—")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(barColor(left ?? 100, provider))
                        .frame(width: geo.size.width * (left ?? 0) / 100)
                        .widgetAccentable()
                }
            }
            .frame(height: 6)
            ResetCaption(window: window, now: now, weekly: weekly)
        }
    }
}

private struct RingGauge: View {
    let title: String
    let window: UsageWindow?
    let now: Date
    let provider: Provider
    let weekly: Bool

    var body: some View {
        let left = remaining(window, now: now)
        HStack(spacing: 10) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: (left ?? 0) / 100)
                    .stroke(barColor(left ?? 100, provider), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .widgetAccentable()
                VStack(spacing: -1) {
                    Text(left.map { "\(Int($0.rounded()))%" } ?? "—")
                        .font(.system(.callout, design: .rounded).weight(.bold))
                        .monospacedDigit()
                    if left != nil {
                        Text("剩餘").font(.system(size: 8, weight: .medium)).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(left.map { "已用 \(Int((100 - $0).rounded()))%" } ?? "—")
                    .font(.caption).foregroundStyle(.secondary)
                ResetCaption(window: window, now: now, weekly: weekly)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: Widgets

struct ClaudeUsageWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ClaudeUsage", provider: UsageProvider(provider: .claude)) { entry in
            UsageWidgetView(provider: .claude, entry: entry)
        }
        .configurationDisplayName("Claude 額度")
        .description("Claude 的 5 小時與每週剩餘額度。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CodexUsageWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CodexUsage", provider: UsageProvider(provider: .codex)) { entry in
            UsageWidgetView(provider: .codex, entry: entry)
        }
        .configurationDisplayName("Codex 額度")
        .description("Codex 的 5 小時與每週剩餘額度。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct UsageWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClaudeUsageWidget()
        CodexUsageWidget()
    }
}
