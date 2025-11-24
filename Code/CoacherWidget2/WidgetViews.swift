//
//  WidgetViews.swift
//  CoacherWidget
//
//  Created by Rebecca Clarke on 8/30/25.
//

import WidgetKit
import SwiftUI

extension String {
    func lowercasedFirstLetter() -> String {
        guard !isEmpty else { return self }
        return String(prefix(1).lowercased()) + String(dropFirst())
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: CoacherTimelineEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with leaf icon, prompt and sunshine icon
            HStack {
                Link(destination: URL(string: "coacher://morningfocus")!) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
                .accessibilityLabel("Open Lighter app")
                .accessibilityHint("Opens Lighter app to today view")
                
                Text(entry.encouragingPrompt)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(Color.widgetText)
                
                Spacer()
                
                if !entry.morningFocusCompleted {
                    Link(destination: URL(string: "coacher://morningfocus")!) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                    }
                    .accessibilityLabel("Start morning focus")
                    .accessibilityHint("Opens morning focus in Lighter app")
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 6) {
                Link(destination: URL(string: "coacher://needhelp")!) {
                    Text("I Need Help")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
                .accessibilityLabel("I Need Help")
                .accessibilityHint("Opens help options in Lighter app")
                
                Link(destination: URL(string: "coacher://success")!) {
                    Text("I Did Great!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(6)
                }
                .accessibilityLabel("I Did Great")
                .accessibilityHint("Opens success capture in Lighter app")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: CoacherTimelineEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with leaf icon, prompt and sunshine icon
            HStack {
                Link(destination: URL(string: "coacher://morningfocus")!) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                
                Text(entry.encouragingPrompt)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(Color.widgetText)
                
                Spacer()
                
                if !entry.morningFocusCompleted {
                    Link(destination: URL(string: "coacher://morningfocus")!) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons side by side
            HStack(spacing: 12) {
                Link(destination: URL(string: "coacher://needhelp")!) {
                    Text("I Need Help")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Link(destination: URL(string: "coacher://success")!) {
                    Text("I Did Great!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: CoacherTimelineEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Top header with leaf icon and sunshine icon
            HStack {
                Link(destination: URL(string: "coacher://morningfocus")!) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if !entry.morningFocusCompleted {
                    Link(destination: URL(string: "coacher://morningfocus")!) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            if entry.morningFocusCompleted {
                // Show morning summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Morning Focus")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.widgetText)
                    
                    if !entry.morningWhy.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Why This Matters:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.widgetSecondaryText)
                            
                            Text("I want to " + entry.morningWhy.lowercasedFirstLetter())
                                .font(.caption)
                                .foregroundColor(Color.widgetText)
                                .lineLimit(2)
                        }
                    }
                    
                    if !entry.morningIdentity.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I am someone who:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.widgetSecondaryText)
                            
                            Text(entry.morningIdentity)
                                .font(.caption)
                                .foregroundColor(Color.widgetText)
                                .lineLimit(2)
                        }
                    }
                    
                    if !entry.morningFocus.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Focus:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.widgetSecondaryText)
                            
                            Text(entry.morningFocus)
                                .font(.caption)
                                .foregroundColor(Color.widgetText)
                                .lineLimit(2)
                        }
                    }
                    
                    if !entry.morningStressResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("If Stressed:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.widgetSecondaryText)
                            
                            Text(entry.morningStressResponse)
                                .font(.caption)
                                .foregroundColor(Color.widgetText)
                                .lineLimit(2)
                        }
                    }
                }
            } else {
                // Show morning focus prompt
                VStack(spacing: 8) {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Start Your Morning Focus")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.widgetText)
                        
                        Text("Tap to set your intention for the day")
                            .font(.caption)
                            .foregroundColor(Color.widgetSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    Link(destination: URL(string: "coacher://morningfocus")!) {
                        Text("Start Morning Focus")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons at bottom
            HStack(spacing: 12) {
                Link(destination: URL(string: "coacher://needhelp")!) {
                    Text("I Need Help")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Link(destination: URL(string: "coacher://success")!) {
                    Text("I Did Great!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

