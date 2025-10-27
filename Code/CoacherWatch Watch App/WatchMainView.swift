//
//  WatchMainView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI

struct WatchMainView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // I Need Help button
                NavigationLink(destination: NeedHelpWatchView()) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 24))
                        Text("I Need Help")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // I Did It button
                NavigationLink(destination: IDidItWatchView()) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                        Text("I Did It")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // Urge Timer button
                NavigationLink(destination: UrgeTimerView()) {
                    HStack {
                        Image(systemName: "timer")
                            .font(.system(size: 24))
                        Text("Urge Timer")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
}

#Preview {
    WatchMainView()
}
