# Weight Loss Coach – SwiftUI App Plan Part A

A private-by-default iPhone app to guide daily weight-loss habits and let you talk to an on‑device coach.

## 1) Product Goals

Make the next healthy choice easy with tiny, repeatable actions.

Capture voice/text reflections securely on device.

Offer a conversational coach using a local LLM (no cloud required).

Keep the UI calm, fast, and low-friction (≤30 seconds to log a day).

## 2) MVP Feature Set

Night Prep / Morning Focus Worksheet

Pre-fill checklist + text fields exactly from your template.

Single screen for Night Prep; single screen for Morning Focus.

Optional End-of-Day check-in.

Daily Entries & Streaks

One entry per date (editable throughout the day).

Streak count based on any logged action.

Quick Capture

Large button: “I’m craving / I’m stressed” → opens a 20-second voice note + prompt to choose a swap.

Coach Chat (Hybrid AI)

Simple chat UI with seamless mode switching.

**Online Mode:** GPT-4o with advanced reasoning and multimodal support
**Private Mode:** Apple Foundation Models with complete privacy

Both modes use system prompts tuned to weight loss coaching goals.

Can reference today's entry (your why, chosen swap) when replying.

Includes comprehensive disclaimers: "This isn't medical advice—consult professionals for mental health/nutrition."

Reminders & Widgets

Night Prep reminder (9:00 PM default), Morning Focus (8:00 AM default).

Lock Screen/Home Screen widgets: “Log Night Prep”, “Start Morning Focus”, “Talk to Coach”.

Privacy

Everything stored locally (SwiftData). Optional iCloud sync (off by default).

On-device speech recognition where supported.

## 3) Architecture Overview

UI: SwiftUI

Persistence: SwiftData (iOS 17+) or Core Data fallback if needed.

Speech: SFSpeechRecognizer with supportsOnDeviceRecognition == true when available; otherwise standard path.

AI Coach Implementation (Hybrid Approach):

**Online Option — GPT-4o via OpenAI API:**
- Scalable, powerful conversations with real-time responses
- Supports multimodal input (text + images for meal analysis)
- Advanced reasoning for complex coaching scenarios
- Requires internet connection and API key
- Privacy consideration: Data sent to OpenAI servers

**Private Option — Apple Foundation Models (iOS 18+):**
- On-device processing via Neural Engine
- Complete privacy - no data leaves device
- Works offline without internet connection
- Optimized for iPhone 15 Pro+ devices
- Uses Core ML and FoundationModels framework

**Implementation Strategy:**
- Provide both options in Settings with easy switching
- Default to private mode for privacy-first users
- Allow fallback to online mode for complex queries
- Create a unified LLMService protocol for seamless switching
- Include comprehensive privacy disclaimers and user consent

## 4) Data Model (SwiftData)

import SwiftData
import Foundation

@Model
final class DailyEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date = .now

    // Night Prep
    var stickyNotes: Bool = false
    var preppedProduce: Bool = false
    var waterReady: Bool = false
    var breakfastPrepped: Bool = false
    var nightOther: String = ""

    // Morning Focus
    var myWhy: String = ""
    var challenge: Challenge = .none
    var challengeOther: String = ""
    var chosenSwap: String = ""
    var commitFrom: String = ""   // instead of ___
    var commitTo: String = ""     // Today I will ___ instead of ___

    // End of Day
    var followedSwap: Bool? = nil
    var feelAboutIt: String = ""
    var whatGotInTheWay: String = ""

    // Voice notes (file URLs in app sandbox)
    var voiceNotes: [URL] = []

    init() {}
}

enum Challenge: String, Codable, CaseIterable, Identifiable {
    case none, skippingMeals, lateNightSnacking, sugaryDrinks, onTheGo, emotionalEating, other
    var id: String { rawValue }
}

If you prefer Core Data, mirror the same fields in an NSManagedObject subclass.

## 5) UI Map

Tab 1: Today

Night Prep (toggle checklist + free text)

Morning Focus (why, choose challenge, choose swap, commit)

End-of-Day Check-In

Big button: “Quick Capture” (voice/text)

Tab 2: Coach

Chat interface; messages persisted locally.

Tab 3: History

Calendar list of entries; tap to view/edit.

Tab 4: Settings

Reminders, iCloud sync toggle, export/import, model selection/size.

## 5.1 Unified SectionCard Component

A refactored SectionCard design removes the visual gaps between header and body. It renders the header + body as one seamless card, supports collapse, dimming, optional status pill, and a collapsed preview line. Inner section views (NightPrepSection, MorningFocusSection, etc.) should not render their own outer backgrounds; they provide only field-level UI, so SectionCard is the single card wrapper.

### Features

Header strip (accent color) + body content share one rounded rectangle.

Collapsed Preview: one-line summary when collapsed.

Status pill: right‑aligned, e.g. “Saved / Incomplete”.

Dimmed overlay for past sections.

Example usage:

SectionCard(
  title: "Morning Focus (Today)",
  icon: "sun.max.fill",
  accent: .blue,
  collapsed: $morningCollapsed,
  status: morningComplete ? "Saved" : "Incomplete"
) {
  MorningFocusSection(entry: $entry)
}

## 5.2 Timeline Scrolling History

Concept: Make Today the default focus in the center, but allow scrolling up for history (yesterday, the day before, etc.) and scrolling down only for tonight (End‑of‑Day Check‑In and Prep Tonight). This creates a vertical timeline experience without future placeholders.

### Behavior

Scroll Up: show exactly 7 past days above Today.

Today (anchor): on open, scrolls into view and shows:

Last Night’s Prep (collapsed, dimmed, no preview text)

Morning Focus (expanded)

End‑of‑Day Check‑In (collapsed until evening)

Prep Tonight (collapsed until evening)

Scroll Down: tonight only → End‑of‑Day Check‑In + Prep Tonight.

### Implementation Notes

Use ScrollViewReader + LazyVStack with day buckets for performance.

Provide a floating Jump to Today button.

Day labels: “Today” for the current bucket; bold black date (e.g., Fri • Aug 30) for each of the 7 past days.

Collapsed cards show no preview line and no status pills per spec.

## 5.3 Timeline Clarifications (Final)

### Historical Scroll

Show 7 past days above Today.

Past days: collapsed + dimmed cards (Last Night’s Prep + Morning Focus).

Label each with a bold black date (e.g., “Fri • Aug 30”).

Today shows as “Today” in header.

### Future Scroll

Only tonight’s End‑of‑Day Check‑In + Prep Tonight.

No “coming soon” placeholders beyond that.

### Collapsed Previews & Status

Collapsed previews: none.

Status pills: none.

SectionCard: header + body share same background (single seamless card).

### Layout Structure

Use LazyVStack + ScrollViewReader with day buckets.

Past days: -1 to -7 offsets.

Today: offset 0.

Tonight bucket follows Today.

Floating “Jump to Today” button optional.

### Sample Bucket Behavior

Past (-1..-7): show bold date, two collapsed SectionCards (Last Night’s Prep, Morning Focus).

Today (0): show “Today”, Last Night’s Prep (collapsed), Morning Focus (expanded).

Tonight: header “Tonight” with End‑of‑Day Check‑In and Prep Tonight expanded.

## 6) SwiftUI Screens

### 6.0 Timeline Decisions (Final)

Past history: 7 days above Today.

Future: only tonight (End‑of‑Day + Prep Tonight). No “coming soon” placeholders.

Collapsed previews: none.

Status pills: none.

SectionCard styling: header and body share the same background (one seamless card).

Lists: LazyVStack + ScrollViewReader.

Day labels: Today, and bold black date for past days.

### 6.1 Timeline Scaffold (Code Sketch)

enum DayKey: Hashable { case day(Int) } // -1..-7 past, 0 today

struct TimelineScreen: View {
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach((1...7).reversed(), id: \.self) { back in
                        DayBucket(offset: -back).id(DayKey.day(-back))
                    }
                    DayBucket(offset: 0).id(DayKey.day(0))
                    TonightBucket() // tonight only
                }
                .padding(.horizontal)
            }
            .onAppear { proxy.scrollTo(DayKey.day(0), anchor: .center) }
        }
    }
}

struct DayBucket: View {
    let offset: Int // -1..-7 past, 0 today
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if offset == 0 {
                Text("Today").font(.title3.weight(.semibold))
            } else {
                Text(formattedDate(for: offset))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            if offset < 0 {
                SectionCard(title: "Last Night’s Prep", icon: "moon.stars.fill",
                            accent: .purple, collapsed: .constant(true), dimmed: true) { }
                SectionCard(title: "Morning Focus", icon: "sun.max.fill",
                            accent: .blue, collapsed: .constant(true), dimmed: true) { }
            } else {
                SectionCard(title: "Last Night’s Prep (for Today)", icon: "moon.stars.fill",
                            accent: .purple, collapsed: .constant(true), dimmed: true) { }
                SectionCard(title: "Morning Focus (Today)", icon: "sun.max.fill",
                            accent: .blue, collapsed: .constant(false)) {
                    MorningFocusSection(entry: .constant(DailyEntry()))
                }
            }
        }
    }

    private func formattedDate(for offset: Int) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offset, to: Date())!
        let f = DateFormatter(); f.dateFormat = "EEE • MMM d"
        return f.string(from: date)
    }
}

struct TonightBucket: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tonight").font(.title3.weight(.semibold))
            SectionCard(title: "End-of-Day Check-In", icon: "checkmark.seal.fill",
                        accent: .teal, collapsed: .constant(false)) {
                EndOfDaySection(entry: .constant(DailyEntry()))
            }
            SectionCard(title: "Prep Tonight (for Tomorrow)", icon: "calendar.badge.clock",
                        accent: .purple, collapsed: .constant(false)) {
                NightPrepSection(entry: .constant(DailyEntry()))
            }
        }
        .padding(.bottom, 24)
    }
}

Note: SectionCard is the unified, gapless wrapper; inner sections should not add outer card backgrounds. (Skeletons)

### “I Need Help” Flow (Quick Capture replacement)

Instead of a generic Quick Capture, the user taps I Need Help. This presents a sheet with craving/stress categories, each leading to tailored mini-coach options.

#### Flow

Button: Large button in TodayView → “I Need Help”.

Step 1: Choose Category (Stress/Emotional, Habit/Automatic, Physical/Biological, Other/Not Sure).

Step 2: Mini-Coach Session per category:

Stress/Emotional: offer 2‑minute grounding, quick journal, or audio clip.

Habit/Automatic: suggest swaps (gum, water, short walk) and ask if it’s time/place trigger.

Physical/Biological: suggest water, protein snack, short stretch, or check last balanced meal.

Other: fallback voice/text note.

Step 3: Save tagged entry (cravingType) plus optional voice/text capture.

Coach Integration: Saved entries are tagged; coach can later reference patterns (e.g., “Most of your captures were Stress cravings this week…”).

#### Data Model Update

By default, craving captures are immediately transcribed to text on‑device. The transcript is shown for quick verification/edit, then saved as text only. Audio is discarded unless the user explicitly enables “Keep Audio” in Settings. This keeps the flow lightweight and searchable while still allowing a voice-first capture.

enum CravingType: String, Codable, CaseIterable, Identifiable {
    case stress, habit, physical, other
    var id: String { rawValue }
}

@Model
final class CravingNote {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date = .now
    var type: CravingType = .other
    var text: String = ""   // transcript (user can edit before saving)
    var keptAudio: Bool = false // true only if user opts to retain audio
}
```swift
enum CravingType: String, Codable, CaseIterable, Identifiable {
    case stress, habit, physical, other
    var id: String { rawValue }
}

extension DailyEntry {
    var cravingNotes: [CravingNote] = []
}

@Model
final class CravingNote {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date = .now
    var type: CravingType = .other
    var text: String = ""
    var audioURL: URL? = nil
}

#### UI Example

struct NeedHelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selection: CravingType? = nil

    var body: some View {
        NavigationStack {
            List {
                Button("Stress / Emotional") { selection = .stress }
                Button("Habit / Automatic") { selection = .habit }
                Button("Physical / Biological") { selection = .physical }
                Button("Other / Not Sure") { selection = .other }
            }
            .navigationTitle("I Need Help")
            .sheet(item: $selection) { type in
                MiniCoachView(type: type)
            }
        }
    }
}

### TodayView

Time‑aware layout (midnight–6 PM vs. 6 PM–midnight) - 00:00–17:59 (Day Phase): - Show Last Night’s Prep (for Today) at the top, but collapsed + dimmed by default. - Show Morning Focus (Today) expanded and primary. - Hide End‑of‑Day by default (still accessible via anchor or disclosure). - 18:00–23:59 (Evening Phase): - Show Morning Focus (Today) collapsed + dimmed (already used). - Show End‑of‑Day Check‑In expanded. - Show Prep Tonight (for Tomorrow) expanded below check‑in.

Collapsible Card Style Use a shared card that supports collapsed and dimmed flags with a chevron disclosure.

struct Card<Content: View>: View {
    let title: String
    @Binding var collapsed: Bool
    var dimmed: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { collapsed.toggle() } }

            if !collapsed { content.transition(.opacity.combined(with: .move(edge: .top))) }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(dimmed ? 0.04 : 0))
        )
    }
}

Phase Logic & Ordering

enum DayPhase { case day, evening }

func currentPhase(now: Date = Date()) -> DayPhase {
    let hour = Calendar.current.component(.hour, from: now)
    return hour < 18 ? .day : .evening
}

Composed Today Screen

struct TodayRoot: View {
    @State private var entry = DailyEntry()
    @State private var nightCollapsed = true
    @State private var morningCollapsed = false
    @State private var endCollapsed = true
    @State private var prepTonightCollapsed = false

    var body: some View {
        let phase = currentPhase()
        ScrollView {
            if phase == .day {
                Card(title: "Last Night’s Prep (for Today)", collapsed: $nightCollapsed, dimmed: true) {
                    NightPrepSection(entry: $entry)
                }
                Card(title: "Morning Focus (Today)", collapsed: $morningCollapsed) {
                    MorningFocusSection(entry: $entry)
                }
                Card(title: "End‑of‑Day Check‑In", collapsed: $endCollapsed) {
                    EndOfDaySection(entry: $entry)
                }
            } else {
                Card(title: "Morning Focus (Today)", collapsed: $morningCollapsed, dimmed: true) {
                    MorningFocusSection(entry: $entry)
                }
                Card(title: "End‑of‑Day Check‑In", collapsed: $endCollapsed) {
                    EndOfDaySection(entry: $entry)
                }
                Card(title: "Prep Tonight (for Tomorrow)", collapsed: $prepTonightCollapsed) {
                    NightPrepSection(entry: $entry)
                }
            }
        }
        .onAppear { configureDefaultCollapses(for: currentPhase()) }
    }

    private func configureDefaultCollapses(for phase: DayPhase) {
        switch phase {
        case .day:
            nightCollapsed = true
            morningCollapsed = false
            endCollapsed = true
            prepTonightCollapsed = false
        case .evening:
            nightCollapsed = true // implicitly last night; not shown directly in evening layout
            morningCollapsed = true
            endCollapsed = false
            prepTonightCollapsed = false
        }
    }
}

Notes - The Night Prep section is reused for “last night” (read‑only feel) vs. “prep tonight” (editable). Consider an editable flag if you want to prevent changes to last night’s values. - The I Need Help button remains visible in both phases. - Reminders (from §9) align with this: Morning → Review, Evening → Prep Tonight.

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]

    @State private var entry: DailyEntry = DailyEntry()

    var body: some View {
        ScrollView {
            NightPrepSection(entry: $entry)
            Divider().padding(.vertical)
            MorningFocusSection(entry: $entry)
            Divider().padding(.vertical)
            EndOfDaySection(entry: $entry)

            Button(action: quickCapture) {
                Label("Quick Capture", systemImage: "mic.circle.fill")
                    .font(.title2)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .navigationTitle("Today")
        .onAppear { loadOrCreateToday() }
        .toolbar { SaveButton(entry: entry) }
    }

    private func loadOrCreateToday() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        if let existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            entry = existing
        } else {
            entry = DailyEntry()
            entry.date = startOfDay
            context.insert(entry)
            try? context.save()
        }
    }

    private func quickCapture() {
        // present a sheet with voice/text capture
    }
}

### Night Prep Sections

Two distinct instances: - Last Night’s Prep (for Today): Shown from midnight to 6 PM. Read‑only by default, collapsed + dimmed (faded purple). Expandable if user wants to review or edit. - Prep Tonight (for Tomorrow): Shown from 6 PM to midnight. Editable, styled as active (blue). Contains the same checklist/fields as Night Prep.

Customization: - Users can manage their Night Prep items: - Add custom prep tasks. - Delete or hide defaults (except 2–3 core items that remain). - Order tasks (drag‑reorder optional stretch feature).

Styling Rules: - Light mode: Active = cheerful blue background; Past = faded purple overlay. - Dark mode: Active = dark blue card; Past = faded purple overlay.

Example Info for Night Prep Customization UI:

struct PrepItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var isDefault: Bool = false // core items flagged
    var active: Bool = true
}

@Model
final class NightPrepConfig {
    @Attribute(.unique) var id: UUID = UUID()
    var items: [PrepItem] = []
}

### Morning Focus Section Enhancements

“My Why” Example/Help: Provide a small info button next to the My Why field. Tapping shows either:

A worksheet screen with examples (e.g., “I want energy to play with my kids.”, “I want to feel confident in my clothes.”).

Or a modal with prompts: “Think of one sentence that motivates you personally. It should be about how your life feels, not just weight numbers.”

Implementation sketch:

HStack {
    Text("Step 1 – My Why (2 minutes)").bold()
    Spacer()
    Button(action: { showWhyHelp = true }) { Image(systemName: "info.circle") }
}
.sheet(isPresented: $showWhyHelp) { WhyHelpView() }

UI Label Logic: - Morning hours → display as “Last Night’s Prep (for Today)” - Evening hours → display as “Prep Tonight (for Tomorrow)”

This helps users understand whether they’re reviewing the prep they already did or filling it in for tomorrow.

struct NightPrepSection: View {
    @Binding var entry: DailyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Night Prep (5 minutes)")
                .font(.title3).bold()
            Toggle("Put sticky notes where I usually grab the less-healthy choice", isOn: $entry.stickyNotes)
            Toggle("Wash/cut veggies or fruit and place them at eye level", isOn: $entry.preppedProduce)
            Toggle("Put water bottle in fridge or by my bed", isOn: $entry.waterReady)
            Toggle("Prep quick breakfast/snack", isOn: $entry.breakfastPrepped)
            TextField("Other…", text: $entry.nightOther)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

### Morning Focus Section

struct MorningFocusSection: View {
    @Binding var entry: DailyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Morning Focus (10 minutes)").font(.title3).bold()

            // Step 1 – My Why
            Text("Step 1 – My Why (2 minutes)").bold()
            TextEditor(text: $entry.myWhy).frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            // Step 2 – Identify a Challenge
            Text("Step 2 – Identify a Challenge (3 minutes)").bold()
            Picker("Challenge", selection: $entry.challenge) {
                Text("Select…").tag(Challenge.none)
                Text("Skipping meals").tag(Challenge.skippingMeals)
                Text("Late-night snacking").tag(Challenge.lateNightSnacking)
                Text("Sugary drinks").tag(Challenge.sugaryDrinks)
                Text("Eating on the go / fast food").tag(Challenge.onTheGo)
                Text("Emotional eating").tag(Challenge.emotionalEating)
                Text("Other").tag(Challenge.other)
            }.pickerStyle(.menu)

            if entry.challenge == .other {
                TextField("Describe the challenge…", text: $entry.challengeOther)
                    .textFieldStyle(.roundedBorder)
            }

            // Step 3 – Choose My Swap
            Text("Step 3 – Choose My Swap (3 minutes)").bold()
            TextField("What healthier choice will I do instead?", text: $entry.chosenSwap)
                .textFieldStyle(.roundedBorder)

            // Step 4 – Commit
            Text("Step 4 – Commit (2 minutes)").bold()
            Text("Today I will … instead of …").font(.subheadline).foregroundStyle(.secondary)
            HStack {
                TextField("do this…", text: $entry.commitTo)
                Text("instead of")
                TextField("not this…", text: $entry.commitFrom)
            }
            .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

### End-of-Day Section

struct EndOfDaySection: View {
    @Binding var entry: DailyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("End-of-Day Check-In (Optional)").font(.title3).bold()
            Toggle("I followed my swap", isOn: Binding(
                get: { entry.followedSwap ?? false },
                set: { entry.followedSwap = $0 }
            ))
            TextField("If yes, how do I feel about it?", text: $entry.feelAboutIt)
                .textFieldStyle(.roundedBorder)
            TextField("If no, what got in the way?", text: $entry.whatGotInTheWay)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

## 7) Coach Chat (Hybrid AI) – Interfaces

### Abstraction

protocol LLMService {
    var isOnlineMode: Bool { get }
    func generateReply(to messages: [LLMMessage], context: CoachContext) async throws -> String
    func switchMode() async
}

struct LLMMessage: Identifiable, Codable {
    enum Role: String, Codable { case user, assistant, system }
    var id: UUID = UUID()
    var role: Role
    var content: String
    var timestamp: Date = .now
    var includesImage: Bool = false
}

struct CoachContext: Codable {
    var todayWhy: String
    var todaySwap: String
    var commitTo: String
    var commitFrom: String
    var currentStreak: Int = 0
    var daysThisWeek: Int = 0
}

### System Prompt (Both Modes)

You are a compassionate, pragmatic weight-loss coach. Focus on sustainable healthy decisions, addressing mental health triggers (anxiety-driven snacking) and bad habits using CBT-inspired techniques. Include basic nutrition guidance but prioritize mindset and emotional support. Use the user's daily context (why, chosen swap, commitment). Avoid shame. Offer one concrete next step. Keep replies under 200 words unless asked. End with an engaging question.

### Online Implementation (GPT-4o)

final class OnlineCoachingService: LLMService {
    var isOnlineMode: Bool = true
    private let openAI: OpenAI.Client
    
    func generateReply(to messages: [LLMMessage], context: CoachContext) async throws -> String {
        let systemPrompt = createSystemPrompt(context: context)
        let chatMessages = [ChatMessage.role(.system, content: .string(systemPrompt))] + 
                          messages.map { ChatMessage.role(.user, content: .string($0.content)) }
        
        let query = ChatQuery(model: .gpt4_o, messages: chatMessages)
        let result = try await openAI.chats(query: query)
        return result.choices.first?.message.content ?? "Sorry, please try again."
    }
    
    func switchMode() async {
        // Switch to private mode implementation
    }
}

### Private Implementation (Apple Foundation Models)

final class PrivateCoachingService: LLMService {
    var isOnlineMode: Bool = false
    private let model: LanguageModel
    
    func generateReply(to messages: [LLMMessage], context: CoachContext) async throws -> String {
        let systemPrompt = createSystemPrompt(context: context)
        let conversation = messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")
        
        let prompt = """
        \(systemPrompt)
        
        Conversation:
        \(conversation)
        
        Coach:
        """
        
        let session = model.startSession()
        let request = GenerateTextRequest(
            prompt: prompt,
            options: GenerateTextOptions(maxTokens: 300, temperature: 0.7)
        )
        
        let response = try await session.generateText(request)
        return response.content.text ?? "Sorry, please try again."
    }
    
    func switchMode() async {
        // Switch to online mode implementation
    }
}

### Hybrid Manager

final class HybridLLMManager: ObservableObject, LLMService {
    @Published var isOnlineMode: Bool = false
    @AppStorage("preferOnlineAI") private var preferOnlineAI = false
    
    private let onlineService = OnlineCoachingService()
    private let privateService = PrivateCoachingService()
    
    var currentService: LLMService {
        isOnlineMode ? onlineService : privateService
    }
    
    func generateReply(to messages: [LLMMessage], context: CoachContext) async throws -> String {
        return try await currentService.generateReply(to: messages, context: context)
    }
    
    func switchMode() async {
        await MainActor.run {
            isOnlineMode.toggle()
            preferOnlineAI = isOnlineMode
        }
    }
}

## 8) Speech – Private Voice Notes

Use AVAudioSession + AVAudioRecorder for raw voice notes stored locally.

For transcription, use SFSpeechRecognizer:

Check supportsOnDeviceRecognition and prefer on‑device if available/locale supported.

Provide a toggle in Settings: “Transcribe voice notes automatically”.

func requestSpeechAuth() async throws {
    let status = await SFSpeechRecognizer.authorizationStatus()
    if status != .authorized { _ = await SFSpeechRecognizer.requestAuthorization() }
}

## 9) Notifications & Widgets

Dynamic, time-aware reminders

Evening (e.g., 9:00 PM): Title “Prep Tonight (for Tomorrow)” → deep link to Night Prep section in edit mode.

Morning (e.g., 8:00 AM): Title “Review Your Prep” → deep link to Morning Focus with a quick summary of last night’s items.

Optional Midday Nudge (configurable): “I Need Help” quick action (opens Need Help sheet directly).

Widgets: Activity summarizer + quick actions. Deep link to Today/Coach via widgetURL.

Reminder Scheduling Sketch

struct ReminderTimes: Codable {
    var eveningHour: Int = 21  // 9 PM
    var morningHour: Int = 8   // 8 AM
    var middayHour: Int? = nil // optional
}

enum ReminderDestination: String { case prepTonight, reviewPrep, needHelp }

func scheduleDailyReminders(times: ReminderTimes) async throws {
    let center = UNUserNotificationCenter.current()
    try await center.requestAuthorization(options: [.alert, .sound, .badge])

    // Evening – Prep Tonight
    let evening = UNMutableNotificationContent()
    evening.title = "Prep Tonight (for Tomorrow)"
    evening.body = "30 seconds now makes tomorrow easier."
    evening.userInfo = ["dest": ReminderDestination.prepTonight.rawValue]
    let eveningTrigger = dateTrigger(hour: times.eveningHour)
    let eveningReq = UNNotificationRequest(identifier: "evening_prep", content: evening, trigger: eveningTrigger)

    // Morning – Review Prep
    let morning = UNMutableNotificationContent()
    morning.title = "Review Your Prep"
    morning.body = "Glance at your Why + Swap before the day gets busy."
    morning.userInfo = ["dest": ReminderDestination.reviewPrep.rawValue]
    let morningTrigger = dateTrigger(hour: times.morningHour)
    let morningReq = UNNotificationRequest(identifier: "morning_review", content: morning, trigger: morningTrigger)

    // Optional Midday – I Need Help
    var requests: [UNNotificationRequest] = [eveningReq, morningReq]
    if let midday = times.middayHour {
        let content = UNMutableNotificationContent()
        content.title = "I Need Help"
        content.body = "Need a quick assist? Open the mini‑coach."
        content.userInfo = ["dest": ReminderDestination.needHelp.rawValue]
        let trig = dateTrigger(hour: midday)
        requests.append(UNNotificationRequest(identifier: "midday_help", content: content, trigger: trig))
    }

    try await center.removeAllPendingNotificationRequests()
    for r in requests { try await center.add(r) }
}

private func dateTrigger(hour: Int) -> UNCalendarNotificationTrigger {
    var comps = DateComponents()
    comps.hour = hour
    return UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
}

Deep Links / Navigation Hooks In @main App scene, handle notification response routing:

@main
struct WeightLossCoachApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navState = NavigationState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(navState)
                .onOpenURL { url in navState.handleDeepLink(url) }
        }
    }
}

final class NavigationState: ObservableObject {
    enum Destination { case todayPrepTonight, todayReviewPrep, needHelp }
    @Published var destination: Destination? = nil

    func handleDeepLink(_ url: URL) {
        switch url.host {
        case "prepTonight": destination = .todayPrepTonight
        case "reviewPrep": destination = .todayReviewPrep
        case "needHelp": destination = .needHelp
        default: break
        }
    }
}

Then in TodayView:

struct TodayView: View {
    @EnvironmentObject var navState: NavigationState
    // existing @State entry etc.

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                NightPrepSection(entry: $entry)
                    .id("nightPrep")
                Divider()
                MorningFocusSection(entry: $entry)
                    .id("morningFocus")
                Divider()
                EndOfDaySection(entry: $entry)
            }
            .onChange(of: navState.destination) { dest in
                switch dest {
                case .todayPrepTonight: withAnimation { proxy.scrollTo("nightPrep", anchor: .top) }
                case .todayReviewPrep: withAnimation { proxy.scrollTo("morningFocus", anchor: .top) }
                case .needHelp: showingNeedHelp = true
                default: break
                }
            }
        }
    }

    @State private var showingNeedHelp = false
}

This ensures tapping a reminder routes the user straight to the right section (or opens Need Help sheet).

## 10) Settings

### AI Coach Configuration
- **AI Mode Selection:** Toggle between Online (GPT-4o) and Private (Apple Foundation Models)
- **Privacy Controls:** Clear chat history when switching modes
- **API Key Management:** Secure storage for OpenAI API key (Online mode only)
- **Model Status:** Display current AI mode and connection status
- **Fallback Behavior:** Auto-switch to private mode if online unavailable

### Data & Privacy
- **iCloud Sync:** SwiftData + CloudKit toggle (off by default for privacy)
- **Data Export:** JSON export of entries for backup/restore
- **Chat History:** Option to keep or auto-delete conversation history
- **Privacy Disclaimers:** Clear information about data handling per mode

### Notifications & Reminders
- **Reminder Times:** Customize evening prep and morning focus notifications
- **Notification Content:** Preview and customize reminder messages
- **Deep Link Testing:** Test notification routing to specific app sections

## 12) Gamification & Motivation

Why: Positive reinforcement and small rewards increase user retention and habit adherence (streaks/rewards often boost engagement materially). Keep it optional and kind.

### Features

Mini‑Milestones: Badges/celebrations for 3‑day, 7‑day, 14‑day, 30‑day streaks; also first week of Morning Focus completed.

Lightweight Confetti: Small celebration overlay when a milestone is hit. (Keep it subtle; user can disable in Settings.)

Progress Visualization: Weekly completion ring + streak heatmap in History.

Positive Nudges in Coach: The coach can read streak/weekly progress and add one encouraging sentence.

### Data Model

@Model
final class Achievement {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var dateEarned: Date
    var type: String // e.g., "streak", "consistency", "first_week"
    var details: String

    init(name: String, dateEarned: Date = .now, type: String, details: String = "") {
        self.name = name
        self.dateEarned = dateEarned
        self.type = type
        self.details = details
    }
}

### Streak Heatmap (History)

struct StreakHeatmap: View {
    let entryDates: Set<Date> // normalized to startOfDay
    let weeksToShow: Int = 12

    private var weeks: [[Date]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Build an array of weeks (Sun..Sat or Mon..Sun per locale)
        var result: [[Date]] = []
        let weekday = cal.component(.weekday, from: today)
        let startOfThisWeek = cal.date(byAdding: .day, value: -(weekday-1), to: today) ?? today
        for w in 0..<weeksToShow {
            let start = cal.date(byAdding: .day, value: -(w*7), to: startOfThisWeek)!
            let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
            result.append(days)
        }
        return result.reversed()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Streaks")
                .font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(weeks, id: \.self) { week in
                    GridRow {
                        ForEach(week, id: \.self) { day in
                            let hit = entryDates.contains(Calendar.current.startOfDay(for: day))
                            Rectangle()
                                .fill(hit ? Color.teal : Color.gray.opacity(0.2))
                                .frame(width: 12, height: 12)
                                .cornerRadius(3)
                                .accessibilityLabel(Text(hit ? "Completed" : "Not completed"))
                        }
                    }
                }
            }
        }
    }
}

### Weekly Completion Ring (Today/History)

Compute fraction of the last 7 days with any logged action.

Display with Circle().trim(from: 0, to: progress) and a small label.

### Coach Nudges Integration

Add streak context to the CoachContext and inject one encouraging sentence when thresholds are met.

struct CoachContext: Codable {
    var todayWhy: String
    var todaySwap: String
    var commitTo: String
    var commitFrom: String
    var currentStreak: Int
    var daysThisWeek: Int
}

extension LocalLLMService {
    func nudge(for context: CoachContext) -> String? {
        if context.currentStreak == 7 { return "Seven days in a row—amazing consistency!" }
        if context.daysThisWeek >= 5 { return "You’ve showed up on 5 days this week—your future self feels this." }
        return nil
    }
}

### Settings

Toggle: Show celebrations (on by default).

Toggle: Show streak widgets.

Button: Reset achievements (with confirm).

## 11) Phased Build Plan

**Phase 0 (Day 1–2)** - Project setup, SwiftData model, TodayView skeleton, local saves.

**Phase 1** - Night Prep + Morning Focus + End-of-Day fully working. - Notifications for Night/Morning. - History list & detail.

**Phase 2** - Quick Capture voice notes; optional transcription. - Widgets.

**Phase 3** - AI Coach Implementation:
  - Start with Private mode (Apple Foundation Models) for privacy-first approach
  - Add Online mode (GPT-4o) with secure API key management
  - Implement hybrid switching with seamless mode transitions
  - Add comprehensive privacy disclaimers and user consent flows

**Phase 4** - Advanced AI Features:
  - Multimodal support (image analysis for meal logging)
  - Advanced coaching prompts with CBT techniques
  - Context-aware responses using daily entry data
  - Settings: AI mode management, privacy controls, iCloud sync

## 12) Design Notes

Typography: large friendly headings; buttons that read like “actions” (verbs).

Color: soothing neutrals with one accent (e.g., teal) for primary actions.

Empty states with a single encouraging sentence.


Revising Morning Focus and Evening Check in --
1. Lower the "activation energy" for healthy actions
Why: Under stress, the brain seeks the fastest dopamine hit. High-effort healthy actions get skipped.How to apply:
Make the healthy swap visible and frictionless. Pre-portion snacks (like cut veggies or boiled eggs) and keep them front and center. Hide or move trigger foods out of immediate reach.
Micro-movements count. Instead of aiming for a full workout, aim for 2–3 minutes of movement when you feel an urge. Huberman often talks about “behavioral momentum”—once you start small, your brain often wants to keep going.

2. Break the stress → binge loop with fast nervous system resets
Why: Stress increases cortisol, which triggers cravings and lowers self-control.Techniques from Huberman and others:
Physiological sigh (Huberman): Two short inhales through the nose, followed by a long, slow exhale through the mouth. Do 2–3 rounds. This lowers stress quickly.
Cold water face splash: Activates the dive reflex and calms your heart rate. Just 30 seconds can reset your emotional state.
Name the urge: Label your feeling out loud or in writing: “I’m feeling anxious and wanting comfort.” Naming emotions reduces their intensity.
You can pair these resets with your app’s prompts—for example, make a quick sighing breath a mandatory step before writing your “why” each morning.

3. Build “urge surfing” skills
Why: Cravings come in waves and often peak for only ~10–15 minutes.How:
Picture the urge as an ocean wave rising and falling.
Instead of fighting it, ride it out—set a timer for 10 minutes and do something else (walk, shower, dance, text a friend).
When the timer ends, you can still choose the food, but often the wave will have passed.This is a classic mindfulness-based CBT tool and fits well into your journaling structure.

4. Strengthen your “self-identity” around health
Why: Habits stick better when they’re tied to identity (“I am someone who cares for my body”) rather than outcomes (“I want to lose weight”).Ideas:
Rewrite your “why” in identity terms. Instead of “I want to fit my ring,” try “I am reclaiming my body’s strength and comfort.”
Record a 1-minute voice memo each morning reading your why. Hearing your own voice makes it more emotionally sticky.

5. Address underlying emotional triggers gently
Because you mentioned childhood issues and past relationship pain, it’s likely that food has long served as an emotional anesthetic. That’s normal—but it means logic alone won’t stop the pattern. A few solo-friendly ways to begin gently shifting this:
Journaling in parts: Write as if the part of you who wants comfort food is a younger version of you. What is she afraid of? What does she need? Then answer her from your adult self. This can reduce the “fight” and build internal safety.
Self-compassion microphrases: Kristen Neff’s research shows that saying something like “This is hard, but I’m not alone. I can be kind to myself right now” reduces shame, which often fuels the binge cycle.

6. Create “if/then” plans for stress spikes
Why: Pre-deciding actions prevents willpower drain.Examples you can script into your app:
If I feel the urge to stress-eat, then I will do 3 physiological sighs and dance for 1 song.
If I still want the food, then I will eat it mindfully on a plate, without multitasking.
Even if you still end up eating it, you’ve broken the autopilot pattern—and that’s progress.

7. Build streaks of tiny wins (dopamine layering)
Huberman talks about “reward prediction error”—your brain gives a dopamine burst when you surprise it with success.
Use your app to give yourself a micro-reward for doing the process (writing your why, doing your swap) regardless of outcome.
Track streaks visually, even if they’re just “I showed up.” Progress, not perfection, rewires behavior.

Final Thought
Right now, you’re trying to rebuild trust with yourself—emotionally and physically. That trust is built not from “never slipping,” but from showing yourself that you always come back. Each time you notice the pattern and re-engage the next day, you’re strengthening the neural path toward resilience.

If you want, I can also help you adjust your app’s daily prompts so they better trigger these neuroscience-backed tools (like adding “physiological sigh” or “urge surfing” check-ins).







ChatGPT said:
Perfect — let’s build on the app you’ve already created and make its daily prompts work with your brain’s wiring, so it helps interrupt the stress → binge loop instead of relying only on willpower.
We’ll keep the flow very short so it feels light and doable even on chaotic days.

Revised Daily Prompt Structure
Morning Check-In
Goal: prime your nervous system for calm + align with your identity
Reset Your State to Calm (1 minute)
Do 2–3 physiological sighs (double inhale through nose, long slow exhale through mouth).
Optional: cold water splash to face.
Reconnect With Your Identity-Based “Why”
Write 1–2 sentences that start with:
“I am someone who…” (identity)
“Today I will care for myself by…” (action)
(Example: “I am someone who builds strength and calm in my body. Today I will care for myself by moving gently and feeding my body what it needs.”)
Plan a Healthy Swap
Pick one common stress-trigger food and name your swap for the day.
Keep it visible/ready (lower friction).
Set Your “If/Then” Script
Plan for the moment a craving will hit.
Write: “If I get stressed, then I will _________.”
Suggestions: dance for 1 song, do 3 sighs, drink water, walk 5 mins.

Evening Check-In
Goal: build learning loops + self-trust
Log What Happened (Neutral, No Judgment)
Did I use my healthy swap?
If not, what got in the way? (e.g. stress, tired, felt lonely, forgot)
Surf the Urge Reflection
Did I ride out any cravings today? How did that feel?
(Even noticing the urge is progress.)
Prep One Small Win for Tomorrow
Set out your swap food, workout clothes, or write your “if/then” for tomorrow.
Mark your “I showed up” streak (dopamine hit even if not perfect).
Compassion Phrase
End with: “This is hard, and I’m not alone. I can be kind to myself as I grow.”

Optional: Once a Week (Reflection Sunday?)
Quick journaling as the “younger part” of you who wants comfort food.
Let her voice her fears, then write back from your adult self.
This gently untangles the old emotional wiring that drives binge behavior.

Why this works
Front-load calm so stress doesn’t hijack your brain (Huberman’s state-first approach)
Identity-based habits create longer-lasting motivation
If/then plans and urge surfing reduce decision fatigue
Compassion + streaks rebuild self-trust, which is the foundation of all behavior change

If you want, I can mock up the exact wording for your app’s on-screen prompts (like the actual text it shows you morning and night so it’s easy to tap through).
Would you like me to do that next?


Excellent — let’s make the actual screen text short, warm, and fast to use so it won’t feel like “another chore.”We’ll make two flows: Morning and Evening check-ins.

🕗 Morning Check-In Prompts
Goal: Calm your body → reconnect with your identity → prep your day
Screen 1 — Reset Your State
Take 3 slow breaths.Two quick inhales through your nose, one long slow exhale through your mouth.
[Done]
Screen 2 — Reconnect With Your Why
Complete this sentence:“I am someone who…”(Example: “I am someone who builds strength and calm in my body.”)
[Text box]
Screen 3 — Choose Today’s Act of Care
Complete this sentence:“Today I will care for myself by…”(Example: “choosing veggies with lunch”)
[Text box]
Screen 4 — Plan Your Healthy Swap
Pick one food or habit to swap today.Old habit: ________My swap: ________
[Text boxes]
Screen 5 — Plan for Stress Moments
If stress hits, what will you do first?If I feel stressed, then I will…(Examples: dance 1 song, walk 5 min, 3 slow breaths)
[Text box]

🌙 Evening Check-In Prompts
Goal: Learn from the day → prep for tomorrow → build self-trust
Screen 1 — Reflect on Today
Did you use your swap today?
[Yes / No]
If not, what got in the way?[Text box]
Screen 2 — Notice Urges
Did you notice any cravings?How did you respond?
[Text box]
Screen 3 — Prep One Small Win for Tomorrow
What’s one thing you can set up now to help Future You?(Example: set out workout clothes, prep swap food)
[Text box]
Screen 4 — Self-Compassion Note
End the day with kindness.
“This is hard, and I’m not alone. I can be kind to myself as I grow.”
[Mark day complete] ✅

Optional Features You Could Add Later
A “streak” counter that counts days you showed up, not days you were perfect
A “play calming breath” button to play an audio cue for 3 physiological sighs
A “voice memo” button on the Morning Why screen so you can speak it out loud

If you’d like, I can also design the database structure or SwiftUI data model to store these daily answers and streaks.
Do you want me to do that next?




How to Build This Into Your App
We could replace the “Healthy Swap” screen with this wording:
“If I feel stressed or want comfort today, I will…”(Choose one quick action that brings relief or energy — breath, music, warm drink, walk, etc.)
[Text box](Optional: After that, if I still want a snack, I’ll have ________.)
This lets your brain see it as “I’m caring for myself” instead of “I’m being restricted” — which is far less likely to trigger rebellion or rebound eating.

If you want, I can help you rebuild the full morning prompt flow with this new approach (removing the old “swap” and replacing it with “care action + optional snack”).
Would you like me to do that next?


yes please

ChatGPT said:
Perfect — let’s rewrite your morning check-in flow so it no longer makes the old “problem foods” the main focus.
Instead, it will guide you to:
Calm your nervous system first (so cravings start lower)
Reconnect with your identity and goals
Plan a “care action” for when stress hits (with an optional supportive snack afterward)
This helps your brain see the whole day as self-care, not restriction — which greatly reduces rebound eating.

🌞 Revised Morning Check-In Prompts
Screen 1 — Reset Your State
Take 3 slow breaths.Two quick inhales through your nose, one long slow exhale through your mouth.
[Done]

Screen 2 — Reconnect With Your Identity
Complete this sentence:“I am someone who…”(Example: “I am someone who builds calm and strength in my body.”)
[Text box]

Screen 3 — Set Today’s Focus
Complete this sentence:“Today I will care for myself by…”(Example: “moving gently and pausing to breathe before meals”)
[Text box]

Screen 4 — Plan Your Stress Response
When stress or cravings hit, what will you do to give your body relief or energy?
If I feel stressed or want comfort, I will…(Examples: dance to one song, wrap in a blanket and do 3 breaths, go stand in the sun for 3 minutes, sway/rock, take a warm shower)
[Text box]
Optional add-on line (for food support):
(If I still want something to eat afterward, I’ll have __________.)
[Text box]

Screen 5 — Finish With a Quick Visual
Picture yourself doing your care action calmly.
Take one more slow breath.
[Start My Day] ✅

Why This Change Works
Removes the “forbidden food” spotlight that often triggers rebounds
Gives your nervous system relief first, so cravings don’t feel urgent
Lets your brain expect soothing, not punishment from you — which builds self-trust

If you want, I can next help you revise your evening check-in to match this new “care-first” approach (instead of focusing on whether you avoided a food).
Would you like me to do that?


Excellent — let’s make your evening check-in match the same care-first mindset as your new morning flow.
Instead of judging “did I eat the bad thing,” it will help you:
Reflect gently and notice patterns
Celebrate showing up (even if not “perfect”)
Prep small wins for tomorrow
End the day feeling safe, not ashamed — so your nervous system wants to keep trying

🌙 Revised Evening Check-In Prompts
Screen 1 — Celebrate Showing Up
You showed up today. That matters.
Did you do your care action at least once today?
[Yes / No]
(Even noticing your stress counts as a win.)

Screen 2 — Gentle Reflection
What helped you feel calm or cared for today?
[Text box]
Was there a moment you felt pulled toward comfort eating?What was happening inside or around you?
[Text box]
(This builds awareness without shame — awareness is what creates change.)

Screen 3 — Prep a Small Win for Tomorrow
What’s one small thing you can set up for Future You?(Examples: prep a snack, lay out walking shoes, write a kind note)
[Text box]

Screen 4 — End With Self-Compassion
Read this to yourself:
“This is hard, and I’m not alone. I can be kind to myself as I grow.”
[Mark Day Complete] ✅

Why This Helps
Makes the app a safe place, not a report card
Strengthens the brain’s self-trust loop (“I notice, I learn, I try again”)
Leaves you feeling hopeful at night, which lowers stress hormones and makes cravings weaker the next day


here’s a clear, drop-in map of where to use checkboxes vs buttons, plus when to fire celebrations—aligned to your new “care-first” flow and your existing CelebrationManager.
UI rules of thumb (so it stays consistent)
Checkboxes (or a Toggle): for lists of items that can be done in any order (e.g., your “Prep a Small Win” checklist).
Segmented control: when the user must pick one of a few options (e.g., “Just Talk / Ask the Coach”).
Buttons (“Done”, “Start”, “Save”): for one-shot actions (breathing, tapping consent, finishing a flow).
Radio buttons (or a single-select list): pick exactly one from a longer list.
Avoid checkboxes on single-action screens—use a Done button instead.

Morning flow (with inputs + micro-celebrations)
Screen 1 — Reset Your State
UI: “Start” button → brief on-screen guide (or 15–30s timer), then “Done” button.
No checkbox here. It’s a single action.
Celebrate: tiny burst (haptic + subtle confetti) the first time each day they tap Done.
Screen 2 — Reconnect With Your Identity
UI: 1 text field (“I am someone who…”) + Save button.
Celebrate: none by default; tiny burst if it’s their 3-day streak completing this screen.
Screen 3 — Today’s Focus (“I will care for myself by…”)
UI: text field + Save button. Optionally show smart suggestions chips.
Celebrate: tiny burst if they completed both identity + focus in the same morning.
Screen 4 — Plan Your Stress Response
UI: text field (“If I feel stressed… I will…”) + optional snack field + Save.
Celebrate: medium confetti the first time ever they define a stress response, and tiny on the first entry each day thereafter.
Screen 5 — Finish With a Visual
UI: Start My Day button (completes Morning Check-In).
Celebrate: medium confetti for completing the whole morning flow; upgrade to big on notable streaks (7, 14, 30 days showed-up).

Evening flow
Screen 1 — Celebrate Showing Up
UI: Yes / No buttons for “Did you do your care action at least once?”
If Yes → medium confetti (first 3 evenings) then tiny.
If No → no confetti; show warm validation.
Screen 2 — Gentle Reflection
UI: two text boxes (“What helped you feel calm?” and “What pulled you toward comfort eating?”) + Save.
Celebrate: none (keep it calm).
Screen 3 — Prep a Small Win for Tomorrow
UI: Checklist with checkboxes from your Prep Library (today’s defaults appear pre-listed).
Each item shows a tri-state control (Done / Partly / Skip).
Celebrate: tiny per item when set to Done; medium if they mark ≥2 preps Done in one evening; big when they hit a new “weekly consistency” badge (e.g., 5 nights in a week with ≥1 Done).
Screen 4 — Self-Compassion Note
UI: static phrase + Mark Day Complete button.
Celebrate: medium if they completed any one of: (a) care action Yes, (b) at least one Prep = Done, (c) entire evening flow.
If none of the above, no confetti—just a gentle checkmark + haptic.

Prep Library & Today Checklist (where checkboxes live)
Prep Library View: no checkboxes; it’s management only (text fields, toggles, archive menu).
Today Checklist View: each prep row shows a tri-state picker (Done / Partly / Skip). That’s your checkbox equivalent.
Celebrations here (as above): tiny per Done, medium for multi-Done, big for “weekly consistency” badges.

Celebration tiers & rate limits (to keep it special)
Tiny: soft haptic + emoji/particle pop near the button (no screen takeover).
Triggers: Morning breath Done, identity+focus saved, daily stress-response saved, each Prep marked Done, first consent to try plan in a chat episode.
Medium: mini-confetti burst (1.0–1.5s), subtle sound (if enabled).
Triggers: complete morning flow; evening “care action = Yes”; ≥2 preps Done; day complete with at least one success.
Big: screen confetti (1.5–2.0s) + celebratory banner.
Triggers: streak milestones (7/14/30 days showed-up), first stress-response ever, weekly consistency badge.
Rate-limit: max 1 medium and 1 big per session (morning or evening). Collapse extras to tiny.

Here’s an example of warm validation you could use in your End-of-Day flow when the user taps No on “Did you do your care action at least once today?”

Warm validation text samples:
“That’s okay—showing up here still counts. 🌱”
“Not every day goes as planned, but you’re still learning what you need.”
“It makes sense today felt tough. You’re not alone in that.”
“Even noticing that urge or stress matters. Tomorrow’s a fresh start.”
“Showing up here still matters.”
“Not every day is smooth, and that’s okay.”
“Even noticing today’s challenge is progress.”
“You don’t have to be perfect to keep going.”
“Every step back is also a chance to learn.”
“This was a tough day, but you’re not alone.”
“You deserve kindness, especially when it feels hard.”
“Caring for yourself includes patience on days like this.”
“It’s okay to rest. Tomorrow is a reset.”
“Struggling doesn’t erase your effort.”
“Tomorrow is a fresh page.”
“Even small attempts today set up tomorrow.”
“Your future self is grateful you checked in.”
“Each day is practice, not a test.”
“Momentum comes from showing up, not perfection.”

here’s a companion pool of mini-celebration lines you can show when the user taps Yes on “Did you do your care action at least once today?”
These are short, upbeat, and designed to pair with your subtle haptics/confetti.
🎉 Simple Wins
“You did it — that counts.”
“A care action, done. 🌱”
“Tiny steps, real progress.”
“That’s a win worth noticing.”
“Consistency beats perfection.”
💪 Identity-Based Nudges
“You’re showing up as someone who cares for themselves.”
“Every small act reinforces your new identity.”
“This is how resilience is built.”
“Proof you can keep promises to yourself.”
“One step today = momentum tomorrow.”
🌞 Encouraging Energy
“Future you is already thankful.”
“You’ve planted another seed.”
“This is how streaks start.”
“Your effort is adding up.”
“Today you showed yourself you can.”
