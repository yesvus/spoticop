// SpotiCop settings views.
import SwiftUI
import AppKit

// MARK: - General Tab
struct GeneralTabView: View {
    @ObservedObject var config: ConfigManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Master Toggle
            HStack(alignment: .center) {
                Text("Enable SpotiCop")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { config.isEnabled },
                    set: { config.toggleMasterEnabled($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            Text("SpotiCop stays enabled after you quit the app")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Divider()

            // Cache Limit
            HStack {
                Text("Cache Limit:")
                    .font(.system(size: 13))
                Spacer()
                Picker("", selection: Binding(
                    get: { config.capSize },
                    set: {
                        config.capSize = $0
                        config.saveConfig()
                    }
                )) {
                    ForEach(config.presetCaps, id: \.self) { preset in
                        Text(preset).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            // Current Usage
            HStack {
                Text("Current Cache:")
                    .font(.system(size: 13))
                Spacer()
                Text(config.formatBytes(config.totalCacheSize))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Patrol Action
            HStack(spacing: 10) {
                Button(action: {
                    config.runPatrol()
                }) {
                    HStack(spacing: 6) {
                        if config.isPatrolling {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(config.isPatrolling ? "Patrolling..." : "Patrol Now")
                    }
                }
                .disabled(config.isPatrolling)

                if !config.patrolStatus.isEmpty {
                    Text(config.patrolStatus)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .frame(width: 420)
    }
}

// MARK: - Schedule Tab
struct ScheduleTabView: View {
    @ObservedObject var config: ConfigManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Patrol Day:")
                    .font(.system(size: 13))
                Spacer()
                Picker("", selection: Binding(
                    get: { config.selectedDay },
                    set: {
                        config.selectedDay = $0
                        config.saveConfig()
                    }
                )) {
                    ForEach(0..<config.days.count, id: \.self) { idx in
                        Text(config.days[idx]).tag(idx)
                    }
                }
                .frame(width: 140)
            }

            HStack {
                Text("Patrol Time:")
                    .font(.system(size: 13))
                Spacer()
                DatePicker("", selection: Binding(
                    get: { config.scheduleTime },
                    set: {
                        config.scheduleTime = $0
                        config.saveConfig()
                    }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }

            Divider()

            HStack {
                Button("Save Schedule") {
                    config.saveConfig()
                }
                Spacer()
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .frame(width: 420)
    }
}

// MARK: - Activity Tab
struct ActivityTabView: View {
    @ObservedObject var config: ConfigManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.vertical) {
                Text(config.logContent.isEmpty ? "No logs recorded." : config.logContent)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(8)
            }
            .frame(height: 180)
            .background(Color(NSColor.textBackgroundColor))
            .border(Color(NSColor.separatorColor).opacity(0.5), width: 1)

            HStack(spacing: 8) {
                Button("Refresh") {
                    config.loadLogs()
                }
                Button("Clear") {
                    config.clearLogs()
                }
                Spacer()
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .frame(width: 420)
    }
}

// MARK: - About Tab
struct AboutTabView: View {
    @ObservedObject var config: ConfigManager

    var body: some View {
        VStack(spacing: 8) {
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
            } else {
                Image(systemName: "shield.lefthalf.filled")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.accentColor)
            }

            Text("SpotiCop")
                .font(.system(size: 15, weight: .bold))

            Text("Version 0.1.0")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text("Created by yesvus")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 4)

            HStack(spacing: 24) {
                Button(action: {
                    if let url = URL(string: "https://github.com/yesvus/spoticop") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.branch")
                        Text("Check It Out on GitHub")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                Button(action: {
                    let path = config.cacheAURL.path
                    if FileManager.default.fileExists(atPath: path) {
                        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                    } else {
                        let parent = config.cacheAURL.deletingLastPathComponent().path
                        NSWorkspace.shared.selectFile(parent, inFileViewerRootedAtPath: "")
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text("Reveal Cache")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .frame(width: 420)
    }
}
