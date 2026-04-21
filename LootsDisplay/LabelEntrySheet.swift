import SwiftUI

//Enter in label sheet for data history view
struct LabelEntrySheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var sensors: SensorManager
    @StateObject private var labelManager = LabelManager.shared
    
    @Binding var tempLabelText: String
    let sessionsToLabel: [RecordingSession]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("section.new_label")) {
                    TextField("label.placeholder", text: $tempLabelText)
                        .submitLabel(.done)
                }
                
                if !labelManager.recentLabels.isEmpty {
                    Section(header: Text("section.recent_labels")) {
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
            .navigationTitle("nav.add_label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("btn.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("btn.apply") {
                        for session in sessionsToLabel {
                            sensors.applyLabelToSession(id: session.id, label: tempLabelText)
                        }
                        dismiss()
                    }
                    .disabled(tempLabelText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
