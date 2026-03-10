import SwiftUI

@main
struct LootsDisplayApp: App {
    @StateObject var store = SubscriptionManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
