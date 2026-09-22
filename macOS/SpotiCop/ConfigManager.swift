// Config and execution manager for SpotiCop.
import Foundation
import AppKit

@MainActor
final class ConfigManager: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var capSize: String = "1GB"
    @Published var selectedDay: Int = 0
    @Published var scheduleTime: Date = defaultScheduleTime()
    @Published var logContent: String = ""
    @Published var patrolStatus: String = ""
    @Published var isPatrolling: Bool = false
    @Published var totalCacheSize: Int64 = 0

    let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    let presetCaps = ["500MB", "1GB", "2GB", "5GB"]

    var configFileURL: URL {
        let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
        let base = xdg.map { URL(fileURLWithPath: $0) } ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config")
        return base.appendingPathComponent("spoticop/config")
    }

    var logFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/spoticop.log")
    }

    var launchdPlistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.yesvus.spoticop.plist")
    }

    var cacheAURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/com.spotify.client/Data")
    }

    var cacheBURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Spotify/PersistentCache/Storage")
    }

    init() {
        loadConfig()
        refreshCacheSizes()
        loadLogs()
    }

    private static func defaultScheduleTime() -> Date {
        var comp = DateComponents()
        comp.hour = 4
        comp.minute = 0
        return Calendar.current.date(from: comp) ?? Date()
    }

    func loadConfig() {
        guard let data = try? String(contentsOf: configFileURL, encoding: .utf8) else { return }
        for line in data.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count == 2 else { continue }
            let key = parts[0]
            let value = parts[1]
            switch key {
            case "ENABLED":
                self.isEnabled = (value != "0" && value.lowercased() != "false")
            case "CAP":
                self.capSize = value
            case "DAY":
                if let idx = days.firstIndex(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
                    self.selectedDay = idx
                }
            case "TIME":
                let timeParts = value.split(separator: ":")
                if timeParts.count == 2, let h = Int(timeParts[0]), let m = Int(timeParts[1]) {
                    var comp = DateComponents()
                    comp.hour = h
                    comp.minute = m
                    if let d = Calendar.current.date(from: comp) {
                        self.scheduleTime = d
                    }
                }
            default:
                break
            }
        }
    }

    func saveConfig() {
        let comp = Calendar.current.dateComponents([.hour, .minute], from: scheduleTime)
        let hour = comp.hour ?? 4
        let minute = comp.minute ?? 0
        let timeStr = String(format: "%02d:%02d", hour, minute)
        let dayStr = days[selectedDay]

        let content = """
        # spoticop configuration
        ENABLED = \(isEnabled ? "1" : "0")
        CAP = \(capSize)
        DRY_RUN = 0
        LOG = \(logFileURL.path)
        DAY = \(dayStr)
        TIME = \(timeStr)
        """

        try? FileManager.default.createDirectory(at: configFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? content.write(to: configFileURL, atomically: true, encoding: .utf8)

        if isEnabled {
            updateLaunchdPlist(weekday: selectedDay, hour: hour, minute: minute)
        } else {
            disableLaunchd()
        }
    }

    func toggleMasterEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        saveConfig()
    }

    var capBytes: Int64 {
        parseSize(capSize)
    }

    func parseSize(_ str: String) -> Int64 {
        let cleaned = str.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var numStr = ""
        var unitStr = ""
        for char in cleaned {
            if (char >= "0" && char <= "9") || char == "." {
                numStr.append(char)
            } else {
                unitStr.append(char)
            }
        }
        guard let val = Double(numStr) else { return 1024 * 1024 * 1024 }
        let unit = unitStr.trimmingCharacters(in: .whitespaces)
        switch unit {
        case "KB", "K": return Int64(val * 1024)
        case "MB", "M": return Int64(val * 1024 * 1024)
        case "GB", "G", "": return Int64(val * 1024 * 1024 * 1024)
        case "TB", "T": return Int64(val * 1024 * 1024 * 1024 * 1024)
        default: return Int64(val * 1024 * 1024 * 1024)
        }
    }

    func formatBytes(_ bytes: Int64) -> String {
        if bytes >= 1024 * 1024 * 1024 * 1024 {
            return String(format: "%.2f TB", Double(bytes) / Double(1024 * 1024 * 1024 * 1024))
        } else if bytes >= 1024 * 1024 * 1024 {
            return String(format: "%.2f GB", Double(bytes) / Double(1024 * 1024 * 1024))
        } else if bytes >= 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / Double(1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return "\(bytes) B"
        }
    }

    var executablePath: String {
        if let bundled = Bundle.main.url(forResource: "spoticop", withExtension: nil)?.path, FileManager.default.fileExists(atPath: bundled) {
            return bundled
        }
        let userLocalBin = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin/spoticop").path
        if FileManager.default.fileExists(atPath: userLocalBin) {
            return userLocalBin
        }
        let globalBin = "/usr/local/bin/spoticop"
        if FileManager.default.fileExists(atPath: globalBin) {
            return globalBin
        }
        return userLocalBin
    }

    private func disableLaunchd() {
        let plistURL = launchdPlistURL
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["unload", plistURL.path]
        try? task.run()
        task.waitUntilExit()
    }

    private func updateLaunchdPlist(weekday: Int, hour: Int, minute: Int) {
        let plistURL = launchdPlistURL
        try? FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let execPath = executablePath

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.yesvus.spoticop</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(execPath)</string>
            </array>
            <key>StartCalendarInterval</key>
            <dict>
                <key>Weekday</key>
                <integer>\(weekday)</integer>
                <key>Hour</key>
                <integer>\(hour)</integer>
                <key>Minute</key>
                <integer>\(minute)</integer>
            </dict>
            <key>StandardOutPath</key>
            <string>\(logFileURL.path)</string>
            <key>StandardErrorPath</key>
            <string>\(logFileURL.path)</string>
        </dict>
        </plist>
        """

        try? plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["unload", plistURL.path]
        try? task.run()
        task.waitUntilExit()

        let reload = Process()
        reload.launchPath = "/bin/launchctl"
        reload.arguments = ["load", plistURL.path]
        try? reload.run()
        reload.waitUntilExit()
    }

    func refreshCacheSizes() {
        let urlA = self.cacheAURL
        let urlB = self.cacheBURL
        Task.detached {
            let sA = Self.calcDirSize(url: urlA)
            let sB = Self.calcDirSize(url: urlB)

            await MainActor.run {
                self.totalCacheSize = sA + sB
            }
        }
    }

    nonisolated private static func calcDirSize(url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsPackageDescendants]
        ) else { return 0 }
        
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let res = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  res.isRegularFile == true,
                  let size = res.fileSize else { continue }
            total += Int64(size)
        }
        return total
    }

    func loadLogs() {
        if let data = try? String(contentsOf: logFileURL, encoding: .utf8) {
            let lines = data.components(separatedBy: .newlines).filter { !$0.isEmpty }
            self.logContent = lines.suffix(40).joined(separator: "\n")
        } else {
            self.logContent = ""
        }
    }

    func clearLogs() {
        try? "".write(to: logFileURL, atomically: true, encoding: .utf8)
        loadLogs()
    }

    func runPatrol() {
        isPatrolling = true
        patrolStatus = ""
        saveConfig()

        let execPath = executablePath
        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: execPath)
            process.arguments = []

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try? process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            await MainActor.run {
                self.isPatrolling = false
                self.patrolStatus = output.components(separatedBy: .newlines).first ?? "Completed"
                self.loadLogs()
                self.refreshCacheSizes()
            }
        }
    }
}
