import SwiftUI

struct DataHistoryView: View {
    @ObservedObject var sensors: SensorManager
    //items are selected by their ID
    @State private var selectedSessionIDs = Set<UUID>()
    //selection mode
    @State private var editMode: EditMode = .inactive
    //... menu
    @State private var selectedSession: RecordingSession? = nil
    
    //label
    @State private var showingLabelAlert = false
    @State private var tempLabelText = ""
    @State private var sessionsToLabel: [RecordingSession] = []
    private let maxLabelLength = 15
    private let illegalCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
    @StateObject private var labelManager = LabelManager.shared
    
    var body: some View {
        NavigationLink(
            destination: Group {
                if let session = selectedSession {
                    SensorGraphView(session: session)
                }
            },
            isActive: Binding(
                get: { selectedSession != nil },
                set: { if !$0 { selectedSession = nil } }
            )
        ) { EmptyView() }
        
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
        .sheet(isPresented: $showingLabelAlert, onDismiss: {
            tempLabelText = ""
            sessionsToLabel = []
        }) {
            LabelEntrySheet(
                sensors: sensors,
                tempLabelText: $tempLabelText,
                sessionsToLabel: sessionsToLabel
            )
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
                        SessionRowView(
                            session: session,
                            
                            selectedSession: $selectedSession,
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
        VStack(alignment: .leading, spacing: 10) {
            TextField("e.g., Bench Press Set 1", text: $tempLabelText)
                .textFieldStyle(.roundedBorder)

            if !labelManager.recentLabels.isEmpty {
                Text("Recent Labels")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(labelManager.recentLabels, id: \.self) { label in
                    Button(action: {
                        tempLabelText = label
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text(label)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        
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
            CSVManager.exportSingleSessionAsCSV(selectedSessions[0])
            return
        }

        CSVManager.exportSessionsAsCSV(selectedSessions)
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
        .tint(.red)
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
    @Binding var selectedSession: RecordingSession?
    @Binding var sessionsToLabel: [RecordingSession]
    @Binding var showingLabelAlert: Bool
    
    // Efficiently find the first label assigned to this session
    private var sessionLabel: String? {
        session.frames.first(where: { $0.label != nil && !$0.label!.isEmpty })?.label
    }
    
    var body: some View {
        // We use a plain Button for the whole row to force iOS to treat it
        // as a single interactive element, then we "intercept" the menu tap.
        HStack {
            // Content Area
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(session.title).font(.headline).lineLimit(1)
                    if let label = sessionLabel { labelTag(label) }
                }
                Text("\(session.frames.count) frames captured")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // This allows us to tap the text area to navigate
            .onTapGesture {
                selectedSession = session
            }

            Spacer()

            // The Menu
            // We use a ContextMenu-style Menu but with a very specific style
            Menu {
                Button { CSVManager.exportSingleSessionAsCSV(session) } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
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
                    .padding(12)
                    .background(Color.white.opacity(0.001))
            }
            // CRITICAL: Tells the List "don't manage this button's tap"
            .buttonStyle(PlainButtonStyle())
            .highPriorityGesture(TapGesture())
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
    
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
}

struct SessionRowViewx: View {
    let session: RecordingSession
    @ObservedObject var sensors: SensorManager
    @Environment(\.editMode) private var editMode
    @Binding var selectedSession: RecordingSession?
    @Binding var sessionsToLabel: [RecordingSession]
    @Binding var showingLabelAlert: Bool

    // Efficiently find the first label assigned to this session
    private var sessionLabel: String? {
        session.frames.first(where: { $0.label != nil && !$0.label!.isEmpty })?.label
    }
    
    

    var body: some View {
            HStack {
                // LEFT SIDE: The Info (Tapping this navigates)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(session.title)
                            .font(.system(.headline))
                        if let label = sessionLabel { labelTag(label) }
                    }
                    Text("\(session.frames.count) frames captured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    // MANUALLY TRIGGER NAVIGATION
                    self.selectedSession = session
                }

                Spacer()

                // RIGHT SIDE: The Menu (Tapping this opens menu)
                if editMode?.wrappedValue == .inactive {
                    rowActionMenu
                        .buttonStyle(BorderlessButtonStyle())
                        .onTapGesture { } // Stops tap from reaching the row logic
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }

    // tag UI
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
    
    //... menu
    @ViewBuilder
    private var rowActionMenu: some View {
        Menu {
            Button {
                CSVManager.exportSingleSessionAsCSV(session)
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            
            Button {
                sessionsToLabel = [session]
                showingLabelAlert = true
            } label: {
                Label("Label", systemImage: "tag")
            }
            
            Button(role: .destructive) {
                if let index = sensors.sessions.firstIndex(where: { $0.id == session.id }) {
                    sensors.deleteSession(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundColor(.blue)
                .padding(8)
        }
    }
}
