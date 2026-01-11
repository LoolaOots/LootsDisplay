//
//  CSVManager.swift
//  LootsDisplay
//
//  Created by Nat on 1/5/26.
//


import Foundation
import UIKit

struct CSVManager {
    
    /// Exports multiple sessions
    static func exportSessionsAsCSV(_ selectedSessions: [RecordingSession]) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("BulkExport_\(UUID().uuidString.prefix(6))")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            for session in selectedSessions {
                let csvString = generateCSVString(for: session)
                
                let fileName = fileName(for: session)
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            
            share(items: [tempDir])
            
        } catch {
            print("Bulk save failed: \(error)")
        }
    }
    
    /// Exports a single session
    static func exportSingleSessionAsCSV(_ session: RecordingSession) {
        let csvString = generateCSVString(for: session)
        
        let fileName = fileName(for: session)
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            share(items: [path])
        } catch {
            print("Failed to create CSV: \(error)")
        }
    }
    
    static func fileName(for session: RecordingSession) -> String {
            let firstLabel = session.frames.first(where: { $0.label != nil && !$0.label!.isEmpty })?.label
            let cleanLabel = firstLabel?.replacingOccurrences(of: " ", with: "_") ?? "SensorLog"
            
            let fileDateFormatter = DateFormatter()
            fileDateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let dateString = fileDateFormatter.string(from: session.startTime)
            
            //Unique ID
            let uniqueID = session.id.uuidString.prefix(4)
            
            return "\(cleanLabel)_\(dateString)_\(uniqueID).csv"
        }

    /// Converts a RecordingSession into a raw CSV String
    static func generateCSVString(for session: RecordingSession) -> String {
        var csvString = "Timestamp,Label,Pitch,Roll,Yaw,Latitude,Longitude,Pressure,Heading,Speed,AccelX,AccelY,AccelZ,GForceX,GForceY,GForceZ,GyroX,GyroY,GyroZ,MagX,MagY,MagZ\n"
        let isoFormatter = ISO8601DateFormatter()
        
        for frame in session.frames {
            let row = [
                isoFormatter.string(from: frame.timestamp),
                "\(frame.label ?? "")",
                "\(frame.pitch)", "\(frame.roll)", "\(frame.yaw)",
                "\(frame.latitude)", "\(frame.longitude)", "\(frame.pressure)",
                "\(frame.heading)", "\(frame.speed)",
                "\(frame.accelX)", "\(frame.accelY)", "\(frame.accelZ)",
                "\(frame.gForceX)", "\(frame.gForceY)", "\(frame.gForceZ)",
                "\(frame.gyroX)", "\(frame.gyroY)", "\(frame.gyroZ)",
                "\(frame.magX)", "\(frame.magY)", "\(frame.magZ)"
            ].joined(separator: ",")
            csvString.append(row + "\n")
        }
        return csvString
    }
    
    /// Helper to present the iOS Share Sheet
    private static func share(items: [Any]) {
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}
