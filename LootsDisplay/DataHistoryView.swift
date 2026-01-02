import SwiftUI

struct DataHistoryView: View {
    @ObservedObject var sensors: SensorManager
    // 1. Track which items are selected by their ID
    @State private var selectedSessionIDs = Set<UUID>()
    // 2. Track whether the list is in "Edit" (Select) mode
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        // 3. Pass the selection set to the List
        List(selection: $selectedSessionIDs) {
            Section(header: Text("Recorded Samples")) {
                if sensors.sessions.isEmpty {
                    Text("No sessions found").foregroundColor(.secondary)
                } else {
                    ForEach(sensors.sessions) { session in
                        SessionRowView(session: session, sensors: sensors)
                            // 4. Tag each row with its ID so the List knows what is being selected
                            .tag(session.id)
                    }
                    .onDelete(perform: editMode == .inactive ? { offsets in sensors.deleteSession(at: offsets) } : nil)
                }
            }
        }
        .navigationTitle("History")
        // 5. Sync the environment's editMode with our local state
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // 6. Toggle button that switches between "Select" and "Done"
                Button(editMode == .active ? "Done" : "Select") {
                    withAnimation {
                        if editMode == .active {
                            editMode = .inactive
                            selectedSessionIDs.removeAll() // Clear selection when finished
                        } else {
                            editMode = .active
                        }
                    }
                }
            }
            // Bottom Bar
            ToolbarItemGroup(placement: .bottomBar) {
                if editMode == .active {
                    renderBottomBarButtons()
                }
            }
            
        }
        .toolbar(editMode == .active ? .visible : .hidden, for: .bottomBar)
        .toolbarBackground(.visible, for: .bottomBar)
        .toolbarBackground(Color(UIColor.systemBackground), for: .bottomBar)
        .alert(sensors.alertTitle, isPresented: $sensors.showAlert) {
            Button("OK", role: .cancel) { sensors.showAlert = false }
        }
    }
    
    private func deleteSelected() {
        sensors.sessions.removeAll { session in
            if selectedSessionIDs.contains(session.id) {
                LocalFileManager.deleteSession(id: session.id)
                return true
            }
            return false
        }
        selectedSessionIDs.removeAll()
        editMode = .inactive
    }

    
    
    private func bulkSaveCSV() {
        let selectedSessions = sensors.sessions.filter { selectedSessionIDs.contains($0.id) }
        guard !selectedSessions.isEmpty else { return }

        // If only one is selected, just use the normal save
        if selectedSessions.count == 1 {
            sensors.saveSessionAsCSV(selectedSessions[0])
            return
        }

        sensors.saveSessionsAsCSV(selectedSessions)
    }

    private func bulkExportJSON() {
        if let firstID = selectedSessionIDs.first,
           let session = sensors.sessions.first(where: { $0.id == firstID }) {
            NetworkManager.exportSession(session) { _, msg in
                sensors.alertTitle = msg
                sensors.showAlert = true
            }
        }
    }
    
    @ViewBuilder
    private func renderBottomBarButtons() -> some View {
        // Bottom Left: Trash
        Button(role: .destructive) {
            deleteSelected()
        } label: {
            Image(systemName: "trash")
                .font(.title3) // Makes the icon larger
        }
        .disabled(selectedSessionIDs.isEmpty)

        Spacer()

        // Count Text
        Text(selectedSessionIDs.isEmpty ? "Select Samples" : "\(selectedSessionIDs.count) Selected")
            .font(.headline)
            .foregroundColor(.primary)
            .transition(.scale.combined(with: .opacity))

        Spacer()

        // Bottom Right: More Menu (...)
        Menu {
            Button {
                bulkSaveCSV() // Our CSV logic
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            
//            Button {
//                bulkExportJSON() // Our JSON logic
//            } label: {
//                Label("Export JSON", systemImage: "curlybraces")
//            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3) // Makes the icon larger
        }
        .disabled(selectedSessionIDs.isEmpty)
    }
}

struct SessionRowView: View {
    let session: RecordingSession
    @ObservedObject var sensors: SensorManager
    // Access the current edit mode from the environment
    @Environment(\.editMode) private var editMode

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.title)
                    .font(.headline)
                Text("\(session.frames.count) frames captured")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Only show the Menu and NavigationLink if NOT in selection mode
            if editMode?.wrappedValue == .inactive {
                Menu {
                    Button(action: {
                        sensors.saveSessionAsCSV(session)
                    }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
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
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        // Ensure that tapping the row goes to the graph ONLY when not selecting
        .background(
            NavigationLink("", destination: SensorGraphView(session: session))
                .opacity(0)
        )
    }
}
