//
//  DataHistoryView.swift
//  LootsDisplay
//
//  Created by Nat on 12/28/25.
//

import SwiftUI

struct DataHistoryView: View {
    @ObservedObject var sensors: SensorManager
    
    var body: some View {
        List {
            Section(header: Text("Recent Recordings")) {
                if sensors.sessions.isEmpty {
                    Text("No data recorded yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sensors.sessions) { session in
                        VStack(alignment: .leading) {
                            Text(session.title) // Title is the Start Time
                                .font(.headline)
                            Text("\(session.frames.count) data points captured")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("History")
        // The back button is automatically added by NavigationView
    }
}
