//
//  LocalFileManager.swift
//  LootsDisplay
//
//  Created by Nat on 12/29/25.
//


import Foundation

struct LocalFileManager {
    static let folderName = "SensorRecordings"
    
    // Gets the path to the folder where we save data
    private static func getFolderURL() -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
    }
    
    // Create the folder if it doesn't exist
    static func setupFolder() {
        guard let url = getFolderURL() else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    static func saveSession(_ session: RecordingSession) {
        guard let url = getFolderURL()?.appendingPathComponent("\(session.id).json") else { return }
        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: url)
        } catch {
            print("Error saving to disk: \(error)")
        }
    }
    
    //Persistent data via JSON
    static func loadSessions() -> [RecordingSession] {
        guard let url = getFolderURL() else { return [] }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return files.compactMap { fileURL in
                guard let data = try? Data(contentsOf: fileURL) else { return nil }
                return try? JSONDecoder().decode(RecordingSession.self, from: data)
            }.sorted(by: { $0.startTime > $1.startTime })
        } catch {
            return []
        }
    }
    
    static func deleteSession(id: UUID) {
        guard let url = getFolderURL()?.appendingPathComponent("\(id).json") else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
