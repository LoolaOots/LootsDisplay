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
                Text("paywall.title")
                    .font(.title2).bold()
            }
            .padding(.top, 40)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "sensor.fill", text: "paywall.feature.bluetooth")
                FeatureRow(icon: "chart.bar.doc.horizontal", text: "paywall.feature.storage")
                FeatureRow(icon: "timer", text: "paywall.feature.duration")
                FeatureRow(icon: "clock.arrow.trianglehead.counterclockwise.rotate.90", text: "paywall.feature.trial")
            }
            .padding(.horizontal, 32)

            Text(String(format: String(localized: "paywall.pricing"), store.products.first?.displayPrice ?? ""))
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
                        Text(String(format: String(localized: "paywall.btn.start_trial"), product.displayPrice, subscriptionPeriod(product)))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    Button("paywall.btn.restore") {
                        Task { await store.restorePurchases() }
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
            } else {
                Text("paywall.error.no_subscription")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                Link("paywall.terms_of_use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("paywall.privacy_policy", destination: URL(string: "https://www.termsfeed.com/live/f59fb290-55f8-48f1-ad37-e69d46d93c27")!)
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
        case .month: return String(localized: "paywall.period.month")
        case .year:  return String(localized: "paywall.period.year")
        case .week:  return String(localized: "paywall.period.week")
        default:     return String(localized: "paywall.period.default")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: LocalizedStringKey
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
