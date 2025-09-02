# Weight Loss Coach – SwiftUI App Plan Part B

Celebration/Encouragement

I love this plan. Here’s a clean way to structure it so it feels meaningful without being noisy:

Celebration strategy

Nightly swap (most days):
Show a small, satisfying plant sprout animation next to the encouragement text (no dimming). The stem “grows” in, leaves fade/scale in, and gently sway—a living, calming signal of habit growth.

Milestones only (3-day, 7-day, etc.):
Trigger the big overlay with dimming + “ring/spark” perimeter to make it feel special and rare.

Difficulty & performance

Plant sprout animation: Easy-medium. Fully native SwiftUI (no assets needed). Animates a Path (stem trim) + two leaves with a subtle sway. CPU/GPU friendly and respects Reduce Motion (sway off).

Streak gating: Easy. A tiny AppStorage + date check to increment/reset streak and fire the overlay only on selected milestones.

What I built for you (in the canvas)

Nightly Swap – Plant Sprout Mini-Celebration (SwiftUI) + Streak Gating

Component: SwapMiniCelebration

Includes: animated plant (growth + leaf sway), randomized encouragement phrase, streak counter text, and helper StreakManager using UserDefaults.

Call mini.onSwapLogged() right after you persist the swap to update streak + replay the plant.

Triggers the big overlay only on 3, 7, 14, 30 (you can change these).

Perimeter Spark Celebration Overlay (SwiftUI)

Full-screen dim + center card; traveling ember spark traces the edge and auto-dismisses; has calm/playfulstyles and haptics; respects Reduce Motion.

These two pieces snap together: the mini plant runs nightly; the overlay pops only at milestones.

Quick wiring example

@State private var mini = SwapMiniCelebration()

Button("I did my swap") {

// 1) save swap to your model/store

// 2) update UI feedback

mini.onSwapLogged()

}

## 13) Inspirational Advice & Onboarding

### Daily Inspirational Advice

Show a short one‑sentence encouragement once per day when the user opens Today.

Examples: “You don’t have to eat perfectly, just make one healthier choice.”, “Water first — let the craving wait 5 minutes.”, “Every prep you do tonight is a gift for your tomorrow self.”

Implementation: cycle through a small local array of phrases by date hash.

Settings toggle: Daily Inspiration On/Off (default: On).

### Onboarding

Keep minimal: the app should feel usable immediately.

First launch modal (1 screen): explains the core loop (Morning Focus + Night Prep). Button to “Start My First Morning Focus.” Skip option to go straight in.

Optional Tutorial (3 swipes): Morning Focus, I Need Help, Night Prep. Ends with “Got it.”

Settings: Replay Tutorial option.

Optional inspirational mini‑lesson after first Morning Focus: short paragraph, can be dismissed or snoozed.

Encouragement Notes & Celebration Flow

### Celebration Flow (Playful Style)

Button Press: User taps “I did my swap.” Button glows/pulses.

Sparkly Ring Animation: Circle of light radiates, sparkles trail, ~1 second.

Confetti Sprinkle: A handful of colorful pieces drift down (lightweight, ~1 second).

Encouragement Text: Randomized 1–line phrases fade in for 2–3 seconds:

🌱 “One healthier choice, done.”

🌟 “That swap makes you stronger.”

🎈 “Small steps, big wins.”

Progress Nudge (optional): If tracking streaks, a banner: “Swap streak: 3 days in a row!”

Visual Tone: Bright colors (sky blue, teal, green), smooth ease animations, ~3s duration total.

### Celebration Flow (Calm Style)

Button Press: Button softly glows.

Sparkle Ripple: Subtle circle ripple with twinkles, ~1s.

Encouragement Text: Minimalist line under the button, 2s:

“Swap complete. 🌿”

“Nice choice.”

“You’re building momentum.”

Progress Nudge (optional): Tiny glowing dot or subtle progress ring increment.

Visual Tone: Calming blues/greens, slower easing, ~2s total.

### Celebration Style Options

🎉 Playful: Sparkly ring + confetti + encouraging phrase.

✨ Calm: Glow ripple + sparkles + gentle phrase.

🚫 Off: No animation, just a checkmark ✅ or quiet confirmation text.

Implementation - Default: Calm. - Settings: segmented control or dropdown with small preview animations. - User’s choice persists.

Stretch Ideas (Later)

Tie‑ins with Apple Health: weight, steps (read-only with consent) → trend nudges.

On‑device intent detection (classify “craving”, “stress”, “boredom”).

PDF export of weekly reflections.

“Emergency plan” button that surfaces your top 3 swaps and a 90‑second calming audio.

## 14) Next Steps (Concrete)

Create Xcode project (iOS 17+), add SwiftData model from §4.

Build TodayView from §6 and verify save/load for current day.

Add two local notifications for Night Prep and Morning Focus.

Implement MockLLM and chat UI scaffold; confirm interface.

Choose model path (llama.cpp or MLC‑LLM) and budget app size.

Add voice capture with file storage; add optional transcription.

When you’re ready, we can drop in a real LLM adapter—your UI won’t have to change.

## 9.1 Deep‑Link Routing & Navigation Hooks

### Router

final class AppRouter: ObservableObject {
    enum Destination { case none, prepTonight, reviewPrep, needHelp }
    @Published var dest: Destination = .none
}

### App Entry

@main
struct WLCoachApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .onOpenURL { url in handle(url: url) }
        }
    }
}

extension WLCoachApp {
    func handle(url: URL) {
        switch url.host {
        case "prepTonight": router.dest = .prepTonight
        case "reviewPrep": router.dest = .reviewPrep
        case "needHelp": router.dest = .needHelp
        default: break
        }
    }
}

### Notification Response → Deep Link

func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    let dest = (response.notification.request.content.userInfo["dest"] as? String) ?? ""
    if let url = URL(string: "wlcoach://\(dest)") {
        await MainActor.run { UIApplication.shared.open(url) }
    }
}

### RootView with Tab Navigation

struct RootView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        TabView {
            TodayRoot()
                .tabItem { Label("Today", systemImage: "sun.max") }
            CoachView()
                .tabItem { Label("Coach", systemImage: "message") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

### TodayRoot with Scroll Targets

enum TodayAnchor: Hashable { case nightPrep, morningFocus, endOfDay }

struct TodayRoot: View {
    @EnvironmentObject var router: AppRouter
    @State private var showNeedHelp = false
    @State private var entry = DailyEntry()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group { NightPrepSection(entry: $entry) }.id(TodayAnchor.nightPrep)
                Divider()
                Group { MorningFocusSection(entry: $entry) }.id(TodayAnchor.morningFocus)
                Divider()
                Group { EndOfDaySection(entry: $entry) }.id(TodayAnchor.endOfDay)
            }
            .onReceive(router.$dest) { dest in
                guard dest != .none else { return }
                withAnimation(.easeInOut) {
                    switch dest {
                    case .prepTonight:
                        proxy.scrollTo(TodayAnchor.nightPrep, anchor: .top)
                    case .reviewPrep:
                        proxy.scrollTo(TodayAnchor.morningFocus, anchor: .top)
                    case .needHelp:
                        showNeedHelp = true
                    case .none: break
                    }
                }
                DispatchQueue.main.async { router.dest = .none }
            }
            .sheet(isPresented: $showNeedHelp) { NeedHelpView() }
            .navigationTitle("Today")
        }
    }
}

### Morning Summary Banner (nice‑to‑have)

Show a small banner at the top of Morning Focus when opened via Review Prep.

struct MorningSummaryBanner: View {
    let prepItems: [String]
    var body: some View {
        if !prepItems.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("From last night:").font(.caption).bold()
                ForEach(prepItems, id: \.self) { Text("• \($0)") }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemBackground)))
        }
    }
}

mini // place this next to your nightly encouragement text

Optional extras (say the word if you want them)

Confetti sprinkle only on milestones (already supported by the overlay; easy to toggle).

“Plant grows taller” meta-progress: very subtle bias the stem curve height to streak (visualizes long-term growth).

Sound or haptics settings: soft success haptic on nightly; fuller success on milestones; auto-respect Reduce Motion.

Theme tie-in: color the leaves with your brand greens/teals; add a tiny dew-sparkle when the sway reverses for a micro-delight.

If you want, I can swap the leaf shape to something more stylized (e.g., rounded teardrops), or turn the sprout into a small potted sapling that gets a new leaf at certain totals (e.g., every 5 swaps).