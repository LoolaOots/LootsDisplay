import Foundation

struct LocalFileManager {
    static let folderName = "SensorRecordings"

    //folder path where data is saved
    private static func getFolderURL() -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
    }

    //create if folder path doesnt exist
    static func setupFolder() {
        guard let url = getFolderURL() else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    //save
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
                guard fileURL.pathExtension == "json" else { return nil }
                guard let data = try? Data(contentsOf: fileURL) else { return nil }
                return try? JSONDecoder().decode(RecordingSession.self, from: data)
            }.sorted(by: { $0.startTime > $1.startTime })
        } catch {
            return []
        }
    }

    //delete
    static func deleteSession(id: UUID) {
        guard let folderURL = getFolderURL() else { return }
        try? FileManager.default.removeItem(at: folderURL.appendingPathComponent("\(id).json"))
        try? FileManager.default.removeItem(at: folderURL.appendingPathComponent("\(id).mov"))
    }

    //video file location for a session, if one was attached
    static func videoURL(for sessionId: UUID) -> URL? {
        guard let url = getFolderURL()?.appendingPathComponent("\(sessionId).mov") else { return nil }
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    //moves a temp video file into the recordings folder, named to match the session, and stamps the session's videoFileName
    @discardableResult
    static func attachVideo(from tempURL: URL, toSessionId sessionId: UUID) -> String? {
        guard let folderURL = getFolderURL() else { return nil }
        let fileName = "\(sessionId).mov"
        let destinationURL = folderURL.appendingPathComponent(fileName)
        do {
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        } catch {
            print("Error attaching video to session \(sessionId): \(error)")
            return nil
        }

        var sessions = loadSessions()
        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[index].videoFileName = fileName
            saveSession(sessions[index])
        }
        return fileName
    }
}
