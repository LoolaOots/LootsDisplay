import SwiftUI

struct DataHistoryView: View {
    @ObservedObject var sensors: SensorManager
    
    var body: some View {
        List {
            Section(header: Text("Recorded Samples")) {
                if sensors.sessions.isEmpty {
                    Text("No sessions found").foregroundColor(.secondary)
                } else {
                    ForEach(sensors.sessions) { session in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(session.title)
                                    .font(.headline)
                                Text("\(session.frames.count) frames captured")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Menu {
                                Button(action: {
                                    sensors.exportSession(session)
                                }) {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .padding(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("History")
        .alert(sensors.alertTitle, isPresented: $sensors.showAlert) {
            Button("OK", role: .cancel) {
                sensors.showAlert = false
            }
        }
    }
}
