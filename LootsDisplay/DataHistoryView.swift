import SwiftUI

struct DataHistoryView: View {
    @ObservedObject var sensors: SensorManager
    //items are selected by their ID
    @State private var selectedSessionIDs = Set<UUID>()
    //selection mode
    @State private var editMode: EditMode = .inactive
    
    //label
    @State private var showingLabelAlert = false
    @State private var tempLabelText = ""
    @State private var sessionsToLabel: [RecordingSession] = []
    private let maxLabelLength = 15
    private let illegalCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
    
    var body: some View {
        VStack(spacing: 0) {
            historyList
        }
        .navigationTitle("History")
        .environment(\.editMode, $editMode)
        .toolbar {
            topToolbarItems
            bottomToolbarItems
        }
        .toolbar(editMode == .active ? .visible : .hidden, for: .bottomBar)
        .toolbarBackground(.visible, for: .bottomBar)
        .toolbarBackground(Color(UIColor.systemBackground), for: .bottomBar)
        // Extracted Alerts
        .alert(sensors.alertTitle, isPresented: $sensors.showAlert) {
            Button("OK", role: .cancel) { sensors.showAlert = false }
        }
        .alert("Add Label", isPresented: $showingLabelAlert) {
            labelAlertContent
        }
        .onChange(of: tempLabelText) { newValue in
            // Strip illegal characters
            let filtered = newValue.components(separatedBy: illegalCharacters).joined()
            
            // length limit
            if filtered.count > maxLabelLength {
                tempLabelText = String(filtered.prefix(maxLabelLength))
            } else if filtered != newValue {
                //Update only if character removed
                tempLabelText = filtered
            }
        }
        
    }

    private var historyList: some View {
        List(selection: $selectedSessionIDs) {
            Section(header: Text("Recorded Samples")) {
                if sensors.sessions.isEmpty {
                    Text("No sessions found").foregroundColor(.secondary)
                } else {
                    ForEach(sensors.sessions) { session in
                        // Make sure you updated SessionRowView to accept these bindings!
                        SessionRowView(
                            session: session,
                            sensors: sensors,
                            sessionsToLabel: $sessionsToLabel,
                            showingLabelAlert: $showingLabelAlert
                        )
                        .tag(session.id)
                    }
                    .onDelete(perform: editMode == .inactive ? { sensors.deleteSession(at: $0) } : nil)
                }
            }
        }
    }

    @ViewBuilder
    private var labelAlertContent: some View {
        TextField("e.g., Bench Press Set 1", text: $tempLabelText)
        Button("Apply") {
            for session in sessionsToLabel {
                sensors.applyLabelToSession(id: session.id, label: tempLabelText)
            }
            tempLabelText = ""
            sessionsToLabel = []
        }
        Button("Cancel", role: .cancel) {
            tempLabelText = ""
            sessionsToLabel = []
        }
    }

    @ToolbarContentBuilder
    private var topToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(editMode == .active ? "Done" : "Select") {
                withAnimation {
                    if editMode == .active {
                        editMode = .inactive
                        selectedSessionIDs.removeAll()
                    } else {
                        editMode = .active
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var bottomToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            if editMode == .active {
                renderBottomBarButtons()
            }
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
            Button {
                sessionsToLabel = sensors.sessions.filter { selectedSessionIDs.contains($0.id) }
                showingLabelAlert = true
            } label: {
                Label("Label", systemImage: "tag.stack")
            }
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
    @Environment(\.editMode) private var editMode
    @Binding var sessionsToLabel: [RecordingSession]
    @Binding var showingLabelAlert: Bool

    // Efficiently find the first label assigned to this session
    private var sessionLabel: String? {
        session.frames.first(where: { $0.label != nil && !$0.label!.isEmpty })?.label
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Main Header Row: Date Title + Label Tag
                HStack(alignment: .center, spacing: 8) {
                    Text(session.title)
                        .font(.system(.headline)) // Monospaced keeps dates aligned
                        .lineLimit(1)
                    
                    if let label = sessionLabel {
                        labelTag(label)
                    }
                }
                
                // Subheadline
                Text("\(session.frames.count) frames captured")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Interaction logic (Menu and Chevron)
            if editMode?.wrappedValue == .inactive {
                rowActionMenu
                
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

    // Extracted the tag UI for better readability
    @ViewBuilder
    private func labelTag(_ text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "tag.fill")
                .font(.system(size: 8))
            Text(text.uppercased())
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.blue))
        .fixedSize() // Prevents the tag from squishing
    }
    
    // Extracted Menu
    private var rowActionMenu: some View {
        Menu {
            Button {
                sensors.saveSessionAsCSV(session)
            } label: {
                Label("Save CSV", systemImage: "square.and.arrow.down")
            }
            
            Button {
                sessionsToLabel = [session]
                showingLabelAlert = true
            } label: {
                Label("Label", systemImage: "tag")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundColor(.blue)
                .padding(8)
        }
    }
}
