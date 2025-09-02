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

Coach Chat (Local LLM)

Simple chat UI.

On-device model with system prompt tuned to your goals.

Can reference today’s entry (your why, chosen swap) when replying.

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

LLM (choose 1 to start, keep interface swappable):

Option A — llama.cpp (Metal backend). Ship a small quantized model (e.g., 1.5–3B) as an in-app resource or downloadable asset.

Option B — MLC-LLM (TVM): iOS-friendly runtime with Metal acceleration and model packs.

Option C — System Intelligence (when available): If future iOS exposes sanctioned on-device models via API, you can add an adapter.

Create a LocalLLMService protocol so you can swap implementations without touching UI.

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

## 7) Coach Chat (Local LLM) – Interfaces

### Abstraction

protocol LocalLLMService {
    func generateReply(to messages: [LLMMessage], context: CoachContext) async throws -> String
}

struct LLMMessage: Identifiable, Codable {
    enum Role: String, Codable { case user, assistant, system }
    var id: UUID = UUID()
    var role: Role
    var content: String
    var timestamp: Date = .now
}

struct CoachContext: Codable {
    var todayWhy: String
    var todaySwap: String
    var commitTo: String
    var commitFrom: String
}

### System Prompt (first message)

You are a compassionate, pragmatic weight-loss coach. Focus on tiny, doable actions and pattern awareness.
Use the user’s daily context (why, chosen swap, commitment). Avoid shame. Offer one concrete next step.
Keep replies under 120 words unless asked.

### Mock Implementation (for development)

final class MockLLM: LocalLLMService {
    func generateReply(to messages: [LLMMessage], context: CoachContext) async throws -> String {
        let last = messages.last?.content ?? ""
        return "I hear you. Given your commitment to \(context.commitTo) instead of \(context.commitFrom), try one tiny step: drink water and set a 5‑minute timer before deciding. What feels doable right now about: \(last.prefix(80))…?"
    }
}

### Hooking Up a Real On‑Device Model

llama.cpp route

Add a dependency (static library or Swift Package) that exposes a simple predict(prompt: String) Metal-accelerated call.

Bundle a small quantized model (e.g., 2–4 GB can be too large; consider 1–2 GB or offer in‑app download after consent).

Stream tokens and surface partial text in the UI.

MLC-LLM route

Integrate its iOS runtime and select a compact model variant.

Use Metal for GPU acceleration on device; control context length/token limits to protect battery.

App Store note: if you download models post‑install, present clear consent and allow deletion in Settings.

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

## 10) Settings) Settings

iCloud Sync (SwiftData + CloudKit) toggle.

Model Management: choose installed model; show size; delete model.

Export: JSON export of entries; Import for restore.

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

Phase 0 (Day 1–2) - Project setup, SwiftData model, TodayView skeleton, local saves.

Phase 1 - Night Prep + Morning Focus + End-of-Day fully working. - Notifications for Night/Morning. - History list & detail.

Phase 2 - Quick Capture voice notes; optional transcription. - Widgets.

Phase 3 - Coach Chat using MockLLM → swap to real on-device model via llama.cpp or MLC‑LLM. - Settings: model management, iCloud sync.

## 12) Design Notes

Typography: large friendly headings; buttons that read like “actions” (verbs).

Color: soothing neutrals with one accent (e.g., teal) for primary actions.

Empty states with a single encouraging sentence.