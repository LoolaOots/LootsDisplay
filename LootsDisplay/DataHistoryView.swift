import SwiftUI

struct DataHistoryView: View {
    @ObservedObject var sensors: SensorManager
    @State private var selectedSessionIDs = Set<UUID>()
    @State private var editMode: EditMode = .inactive
    
    @State private var showingLabelAlert = false
    @State private var tempLabelText = ""
    @State private var sessionsToLabel: [RecordingSession] = []
    private let maxLabelLength = 15
    private let illegalCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
    @StateObject private var labelManager = LabelManager.shared
    
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
            let filtered = newValue.components(separatedBy: illegalCharacters).joined()
            if filtered.count > maxLabelLength {
                tempLabelText = String(filtered.prefix(maxLabelLength))
            } else if filtered != newValue {
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
        if selectedSessions.count == 1 {
            CSVManager.exportSingleSessionAsCSV(selectedSessions[0])
            return
        }
        CSVManager.exportSessionsAsCSV(selectedSessions)
    }
    
    @ViewBuilder
    private func renderBottomBarButtons() -> some View {
        Button(role: .destructive) {
            deleteSelected()
        } label: {
            Image(systemName: "trash")
                .font(.title3)
        }
        .tint(.red)
        .disabled(selectedSessionIDs.isEmpty)

        Spacer()

        Text(selectedSessionIDs.isEmpty ? "Select Samples" : "\(selectedSessionIDs.count) Selected")
            .font(.headline)
            .foregroundColor(.primary)
            .transition(.scale.combined(with: .opacity))

        Spacer()

        //... menu multi selection
        Menu {
            Button {
                bulkSaveCSV()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            Button {
                sessionsToLabel = sensors.sessions.filter { selectedSessionIDs.contains($0.id) }
                showingLabelAlert = true
            } label: {
                Label("Label", systemImage: "tag")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
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

    @State private var showingActionSheet = false

    private var sessionLabel: String? {
        session.frames.first(where: { $0.label != nil && !$0.label!.isEmpty })?.label
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(session.title)
                        .font(.system(.headline))
                        .lineLimit(1)
                    
                    if let label = sessionLabel {
                        labelTag(label)
                    }
                }
                
                Text("\(session.frames.count) frames captured")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if editMode?.wrappedValue == .inactive {
                //... menu single selection
                Button {
                    showingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingActionSheet) {
                    VStack(spacing: 0) {
                        Button {
                            CSVManager.exportSingleSessionAsCSV(session)
                            showingActionSheet = false
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                                Spacer()
                            }
                            .padding()
                        }
                        Button {
                            sessionsToLabel = [session]
                            showingLabelAlert = true
                            showingActionSheet = false
                        } label: {
                            HStack {
                                Image(systemName: "tag")
                                Text("Label")
                                Spacer()
                            }
                            .padding()
                        }
                        Button(role: .destructive) {
                            if let index = sensors.sessions.firstIndex(where: { $0.id == session.id }) {
                                sensors.deleteSession(at: IndexSet(integer: index))
                            }
                            showingActionSheet = false
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .frame(minWidth: 180)
                    .padding(.horizontal, 8)
                    .presentationCompactAdaptation(.popover)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .background(
            NavigationLink("", destination: SensorGraphView(session: session))
                .opacity(0)
        )
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
        .fixedSize()
    }
}
