//
//  LabelEntrySheet.swift
//  LootsDisplay
//
//  Created by Nat on 1/6/26.
//


import SwiftUI

struct LabelEntrySheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var sensors: SensorManager
    @StateObject private var labelManager = LabelManager.shared
    
    @Binding var tempLabelText: String
    let sessionsToLabel: [RecordingSession]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("New Label")) {
                    TextField("e.g., Bench Press Set 1", text: $tempLabelText)
                        .submitLabel(.done)
                }
                
                if !labelManager.recentLabels.isEmpty {
                    Section(header: Text("Recent Labels")) {
                        ForEach(labelManager.recentLabels, id: \.self) { label in
                            Button {
                                tempLabelText = label
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.secondary)
                                    Text(label)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if tempLabelText == label {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        for session in sessionsToLabel {
                            sensors.applyLabelToSession(id: session.id, label: tempLabelText)
                        }
                        dismiss()
                    }
                    .disabled(tempLabelText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large]) // Makes it a half-height sheet
    }
}