//
//  LabelManager.swift
//  LootsDisplay
//
//  Created by Nat on 1/6/26.
//


import Foundation

class LabelManager: ObservableObject {
    static let shared = LabelManager()
    private let historyKey = "recent_labels_history"
    private let maxHistory = 3
    
    @Published var recentLabels: [String] = []
    
    init() {
        loadHistory()
    }
    
    /// Adds a label to history. Moves it to the front if it already exists.
    func saveLabelToHistory(_ label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Remove duplicate if it exists, then insert at start
        var currentHistory = recentLabels.filter { $0.lowercased() != trimmed.lowercased() }
        currentHistory.insert(trimmed, at: 0)
        
         let updatedHistory = Array(currentHistory.prefix(maxHistory))
        
        // Save and Update UI
        //Persistent data via UserDefaults
        UserDefaults.standard.set(updatedHistory, forKey: historyKey)
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
