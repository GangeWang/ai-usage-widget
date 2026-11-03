import Foundation

enum FetchError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case .message(let m) = self { return m }
        return nil
    }
}

enum UsageFetcher {
    // MARK: Claude

    /// Reads the OAuth token the Claude app's Code tab (Claude Code) keeps in the login keychain and calls the same endpoint `/usage` uses.
    static func fetchClaude() async throws -> ProviderUsage {
        let raw = try runSecurity(["find-generic-password", "-s", "Claude Code-credentials", "-w"])
        guard let json = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String else {
            throw FetchError.message("找不到 Claude 登入資訊，請在 Claude App 打開 Code 分頁")
        }
        if let exp = oauth["expiresAt"] as? Double, exp / 1000 < Date().timeIntervalSince1970 {
            throw FetchError.message("登入已過期，打開 Claude App 的 Code 分頁即可更新")
        }

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try await send(req)

        func window(_ key: String) -> UsageWindow? {
            guard let w = body[key] as? [String: Any], let pct = w["utilization"] as? Double else { return nil }
            return UsageWindow(usedPercent: pct, resetsAt: (w["resets_at"] as? String).flatMap(parseISODate))
        }
        return ProviderUsage(
            plan: oauth["subscriptionType"] as? String,
            fiveHour: window("five_hour"),
            weekly: window("seven_day"),
            fetchedAt: Date(),
            error: nil
        )
    }

    // MARK: Codex

    /// Uses the ChatGPT token Codex stores in ~/.codex/auth.json.
    static func fetchCodex() async throws -> ProviderUsage {
        let authURL = URL(fileURLWithPath: UsageStore.realHome).appendingPathComponent(".codex/auth.json")
        guard let data = try? Data(contentsOf: authURL),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let token = tokens["access_token"] as? String else {
            throw FetchError.message("找不到 Codex 登入資訊，請在 ChatGPT App 打開 Codex")
        }

        var req = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let account = tokens["account_id"] as? String {
            req.setValue(account, forHTTPHeaderField: "ChatGPT-Account-Id")
        }
        req.setValue("codex-cli", forHTTPHeaderField: "User-Agent")
        let body = try await send(req)

        var usage = ProviderUsage(plan: body["plan_type"] as? String, fetchedAt: Date())
        let limits = body["rate_limit"] as? [String: Any] ?? [:]
        // Pick windows by length rather than position.
        for key in ["primary_window", "secondary_window"] {
            guard let w = limits[key] as? [String: Any], let pct = w["used_percent"] as? Double else { continue }
            let resets = (w["reset_at"] as? Double).map { Date(timeIntervalSince1970: $0) }
            let win = UsageWindow(usedPercent: pct, resetsAt: resets)
            let seconds = w["limit_window_seconds"] as? Double ?? 0
            if seconds >= 86_400 { usage.weekly = win } else { usage.fiveHour = win }
        }
        return usage
    }

    // MARK: Helpers

    private static func send(_ req: URLRequest) async throws -> [String: Any] {
        var req = req
        req.timeoutInterval = 20
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw FetchError.message(status == 401 ? "登入已失效（401）" : "伺服器回應 \(status)")
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FetchError.message("回應格式無法解析")
        }
        return obj
    }

    /// `/usr/bin/security` is already on the keychain item's access list, so this doesn't prompt.
    private static func runSecurity(_ args: [String]) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        p.arguments = args
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        try p.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw FetchError.message("找不到 Claude 登入資訊，請在 Claude App 打開 Code 分頁") }
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Handles "2026-11-02T09:00:00.448339+00:00" (microseconds trip up ISO8601DateFormatter).
    static func parseISODate(_ s: String) -> Date? {
        let trimmed = s.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        return ISO8601DateFormatter().date(from: trimmed)
    }
}
