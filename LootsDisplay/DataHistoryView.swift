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
                        SessionRowView(session: session, sensors: sensors)
                    }
                    .onDelete(perform: sensors.deleteSession)
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !sensors.sessions.isEmpty {
                    Button(role: .destructive) {
                        sensors.deleteAllSessions()
                    } label: {
                        Text("Delete All")
                    }
                }
            }
        }
        .alert(sensors.alertTitle, isPresented: $sensors.showAlert) {
            Button("OK", role: .cancel) { sensors.showAlert = false }
        }
    }
}

struct SessionRowView: View {
    let session: RecordingSession
    @ObservedObject var sensors: SensorManager
    
    var body: some View {
        HStack {
            NavigationLink(destination: SensorGraphView(session: session)) {
                VStack(alignment: .leading) {
                    Text(session.title)
                        .font(.headline)
                    Text("\(session.frames.count) frames captured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            
            Spacer()
            
            Menu {
                Button(action: {
                    NetworkManager.exportSession(session) { success, message in
                        DispatchQueue.main.async {
                            sensors.alertTitle = message
                            sensors.showAlert = true
                        }
                    }
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(8)
            }
            
//            Menu {
//                Button(action: {
//                    sensors.exportSession(session)
//                }) {
//                    Label("Export", systemImage: "square.and.arrow.up")
//                }
//            } label: {
//                Image(systemName: "ellipsis.circle")
//                    .font(.title2)
//                    .foregroundColor(.blue)
//                    .padding(8)
//            }
        }
        .padding(.vertical, 4)
    }
}
