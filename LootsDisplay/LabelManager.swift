import Foundation

class LabelManager: ObservableObject {
    static let shared = LabelManager()
    private let historyKey = "recent_labels_history"
    private let maxHistory = 3
    
    @Published var recentLabels: [String] = []
    
    init() {
        loadHistory()
    }
    
    //Add label to history and filter duplicates
    func saveLabelToHistory(_ label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        //remove duplicates
        var currentHistory = recentLabels.filter { $0.lowercased() != trimmed.lowercased() }
        currentHistory.insert(trimmed, at: 0) //insert at beginning
        
         let updatedHistory = Array(currentHistory.prefix(maxHistory))
        
        //Save and update UI
        UserDefaults.standard.set(updatedHistory, forKey: historyKey) //Persistent data via UserDefaults
        DispatchQueue.main.async {
            self.recentLabels = updatedHistory
        }
    }
    
    private func loadHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: historyKey) {
            self.recentLabels = saved
        }
    }
}
