//
//  EveningPrepManager.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct EveningPrepManager: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var customItemText = ""
    @State private var showingAddCustomItem = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Default Prep Items") {
                    ForEach(EveningPrepItem.createDefaultItems()) { item in
                        HStack {
                            Toggle(isOn: .constant(item.isEnabled)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.text)
                                        .font(.body)
                                    if item.isDefault {
                                        Text("Built-in")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .onChange(of: item.isEnabled) { _, newValue in
                                // Update the item in the database
                                item.isEnabled = newValue
                                try? context.save()
                            }
                            
                            if !item.isDefault || item.text.contains("water bottle") {
                                // Don't allow deletion of water bottle
                                Spacer()
                            } else {
                                Button(action: {
                                    item.isEnabled = false
                                    try? context.save()
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Custom Items") {
                    ForEach(customItems, id: \.self) { customItem in
                        HStack {
                            Text(customItem)
                                .font(.body)
                            Spacer()
                            Button(action: {
                                removeCustomItem(customItem)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onDelete(perform: deleteCustomItems)
                    
                    Button(action: { showingAddCustomItem = true }) {
                        Label("Add Custom Item", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Evening Prep Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddCustomItem) {
                AddCustomPrepItemView { newItem in
                    addCustomItem(newItem)
                }
            }
        }
    }
    
    private var customItems: [String] {
        // This would come from the current DailyEntry or a global setting
        // For now, return empty array
        return []
    }
    
    private func addCustomItem(_ item: String) {
        // Add to current DailyEntry or global settings
        customItemText = ""
    }
    
    private func removeCustomItem(_ item: String) {
        // Remove from current DailyEntry or global settings
    }
    
    private func deleteCustomItems(offsets: IndexSet) {
        // Remove multiple custom items
    }
}

struct AddCustomPrepItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var customItemText = ""
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("What would you like to add to your evening prep routine?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                TextField("e.g., Set out workout clothes", text: $customItemText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .background(colorScheme == .dark ? Color.darkTextInputBackground : Color.clear)
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Custom Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if !customItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onAdd(customItemText.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                    }
                    .disabled(customItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    EveningPrepManager()
}
