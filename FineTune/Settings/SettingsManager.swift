// FineTune/Settings/SettingsManager.swift
import Foundation
import os

@Observable
@MainActor
final class SettingsManager {
    private var settings: Settings
    private var saveTask: Task<Void, Never>?
    private let settingsURL: URL
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FineTune", category: "SettingsManager")

    struct Settings: Codable {
        var version: Int = 1
        var appVolumes: [String: Float] = [:]
    }

    init(directory: URL? = nil) {
        let baseDir = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("FineTune")
        self.settingsURL = baseDir.appendingPathComponent("settings.json")
        self.settings = Settings()
        loadFromDisk()
    }

    func getVolume(for identifier: String) -> Float? {
        settings.appVolumes[identifier]
    }

    func setVolume(for identifier: String, to volume: Float) {
        settings.appVolumes[identifier] = volume
        scheduleSave()
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else { return }

        do {
            let data = try Data(contentsOf: settingsURL)
            settings = try JSONDecoder().decode(Settings.self, from: data)
            logger.debug("Loaded settings with \(self.settings.appVolumes.count) app volumes")
        } catch {
            logger.error("Failed to load settings: \(error.localizedDescription)")
            settings = Settings()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            writeToDisk()
        }
    }

    private func writeToDisk() {
        do {
            let directory = settingsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let data = try JSONEncoder().encode(settings)
            try data.write(to: settingsURL, options: .atomic)

            logger.debug("Saved settings")
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
        }
    }
}
