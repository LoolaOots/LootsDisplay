//
//  PaywallView.swift
//  LootsDisplay
//
//  Created by Nat on 3/9/26.
//


import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var store = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "sensor.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.blue)
                Text("Unlock Pro Sensor Features")
                    .font(.title2).bold()
                Text("Connect and monitor your WitMotion sensor with a Pro subscription. WitMotion901 series sensors supported.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "sensor.fill", text: "Connect WitMotion Bluetooth Sensor")
                FeatureRow(icon: "chart.bar.doc.horizontal", text: "Store up to 30 recordings (versus the free 10)")
                FeatureRow(icon: "clock.arrow.trianglehead.counterclockwise.rotate.90", text: "7-day free trial, cancel anytime")
            }
            .padding(.horizontal, 32)

            Spacer()

            // Purchase button
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

            // Legal
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://yourapp.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 24)
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
