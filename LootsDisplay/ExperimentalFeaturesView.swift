//
//  ExperimentalFeaturesView.swift
//  LootsDisplay
//
//  Created by Nat on 1/2/26.
//

import SwiftUI

struct ExperimentalFeaturesView: View {
    var body: some View {
        List {
            Section(header: Text("Connectivity")) {
                NavigationLink(destination: BluetoothDeviceView()) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.blue)
                        Text("Bluetooth")
                    }
                }
            }
        }
        .navigationTitle("Experimental")
    }
}
