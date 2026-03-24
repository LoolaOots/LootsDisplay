import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var store = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "sensor.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.blue)
                Text("Unlock Premium Sensor Features")
                    .font(.title2).bold()
            }
            .padding(.top, 40)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "sensor.fill", text: "Connect WitMotion901 Series Bluetooth Sensor")
                FeatureRow(icon: "chart.bar.doc.horizontal", text: "More Storage: up to 30 recordings")
                FeatureRow(icon: "timer", text: "Longer Recordings: up to 3 minutes")
                FeatureRow(icon: "clock.arrow.trianglehead.counterclockwise.rotate.90", text: "7-day free trial, cancel anytime")
            }
            .padding(.horizontal, 32)
            
            Text("Monthly subscription • \(store.products.first?.displayPrice ?? "")/month")
                .font(.footnote)
                .foregroundColor(.secondary)

            Spacer()

            if store.isLoading {
                ProgressView()
            } else if let product = store.products.first {
                VStack(spacing: 12) {
                    Button {
                        Task { try? await store.purchase() }
                    } label: {
                        Text("Start Free Trial - then \(product.displayPrice)/\(subscriptionPeriod(product))")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    Button("Restore Purchases") {
                        Task { await store.restorePurchases() }
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
            } else {
                Text("Unable to load subscription options.\nCheck your connection.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Privacy Policy", destination: URL(string: "https://www.termsfeed.com/live/f59fb290-55f8-48f1-ad37-e69d46d93c27")!)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 24)
        }
        .onChange(of: store.isProUnlocked) { unlocked in
            if unlocked { dismiss() }
        }
    }

    private func subscriptionPeriod(_ product: Product) -> String {
        switch product.subscription?.subscriptionPeriod.unit {
        case .month: return "mo"
        case .year: return "yr"
        case .week: return "wk"
        default: return "period"
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
