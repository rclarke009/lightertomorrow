# Widget Setup Instructions

## Xcode Configuration Required

### 1. Add Widget Extension Target
1. In Xcode, go to File → New → Target
2. Select "Widget Extension" 
3. Name it "CoacherWidget"
4. Make sure "Include Configuration Intent" is checked
5. Click "Finish" and "Activate" when prompted

### 2. Add App Group Capability
1. Select the main app target in Xcode
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" and add "App Groups"
4. Add group: `group.com.coacher.shared`
5. Repeat for the CoacherWidget target

### 3. Configure URL Scheme
1. Select the main app target in Xcode
2. Go to "Info" tab
3. Expand "URL Types" section
4. Click "+" to add a new URL Type
5. Set:
   - Identifier: `coacher`
   - URL Schemes: `coacher`
   - Role: `Editor`

### 4. Update Widget Files
Replace the generated widget files with the ones in the `CoacherWidget/` directory:
- `CoacherWidget.swift`
- `WidgetEntry.swift` 
- `CoacherTimelineProvider.swift`
- `WidgetViews.swift`

### 5. Configure Shared SwiftData Container
Update the model container in both `CoacherApp.swift` and the widget to use the shared App Group container:

```swift
.modelContainer(for: [DailyEntry.self, Achievement.self, LLMMessage.self, CravingNote.self, SuccessNote.self, EveningPrepItem.self, UserSettings.self, AudioRecording.self, EmotionalTakeoverNote.self, HabitHelperNote.self], inMemory: false)
```

### 6. Test Widget
1. Build and run the app
2. Long press on home screen
3. Tap "+" to add widgets
4. Search for "Coacher"
5. Add small, medium, and large widgets
6. Test button taps and deep linking

## Widget Features

### Small Widget (2x2)
- Encouraging prompt at top
- Sunshine icon (☀️) in upper right if morning focus not completed
- Two stacked buttons: "I Need Help" and "I Did Great!"

### Medium Widget (4x2)  
- Encouraging prompt at top
- Sunshine icon (☀️) in upper right if morning focus not completed
- Two side-by-side buttons: "I Need Help" and "I Did Great!"

### Large Widget (4x4)
- If morning focus completed: Shows full morning summary with all sections
- If morning focus not completed: Shows prompt to start morning focus with sunshine icon
- Action buttons at bottom: "I Need Help" and "I Did Great!"

## Deep Links
- `coacher://needhelp` → Opens NeedHelpView
- `coacher://success` → Opens SuccessCaptureView  
- `coacher://morningfocus` → Switches to Today tab

## Next Steps
1. Set up shared SwiftData container for real data access
2. Test with actual user data
3. Fine-tune widget appearance and behavior
4. Add to App Store submission
