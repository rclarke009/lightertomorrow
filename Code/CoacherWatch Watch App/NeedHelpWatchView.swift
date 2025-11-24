//
//  NeedHelpWatchView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import WatchConnectivity

struct NeedHelpWatchView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Three Breaths button
            NavigationLink(destination: ThreeBreathsView()) {
                VStack(spacing: 8) {
                    Image(systemName: "wind")
                        .font(.system(size: 24))
                    Text("Three Breaths")
                        .font(.system(size: 16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Record Struggle button
            NavigationLink(destination: RecordStruggleView()) {
                VStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                    Text("Record Struggle")
                        .font(.system(size: 16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                    .background(Color(red: 0.192, green: 0.651, blue: 0.251))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }
}

#Preview {
    NavigationStack {
        NeedHelpWatchView()
    }
}
