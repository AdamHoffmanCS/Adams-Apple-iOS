import SwiftUI
import Foundation

struct FastingView: View {
    @EnvironmentObject var store: Store
    @State private var customHours: String = ""

    private let presets: [(label: String, fast: Double, eat: Double)] = [
        ("14:10", 14, 10), ("16:8", 16, 8), ("18:6", 18, 6), ("20:4", 20, 4), ("OMAD", 23, 1)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    countdownCard
                    windowSection
                    protocolGuide
                    benefits
                    tipsAndSafety
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Fasting")
        }
    }

    private var isActive: Bool { store.fastState != nil }
    private var totalSeconds: Double { store.fastConfig.hours * 3600 }

    // MARK: - Countdown card

    private var countdownCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let info = fastInfo(at: context.date)
            VStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: info.progress,
                                 color: fastingRingColor(info.progress),
                                 lineWidth: 14)
                        .frame(width: 220, height: 220)
                    VStack(spacing: 4) {
                        Text(info.displayTime)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(info.subLabel.uppercased())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.muted)
                    }
                }

                Text(info.status)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.center)

                HStack(spacing: 36) {
                    timeBlock("Started", info.startedText)
                    timeBlock("Eating window", info.windowText)
                }

                if isActive {
                    Button("End Fast") { endFast(info: info) }
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Start Fast") { startFast() }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
        }
        .card(padding: 24)
    }

    // MARK: - Window customizer

    private var windowSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Fasting Window").font(.title3.weight(.semibold))
            Text("Pick a protocol, or set a custom length below.")
                .font(.subheadline).foregroundColor(Theme.muted)

            HStack(spacing: 10) {
                ForEach(presets.indices, id: \.self) { i in
                    presetButton(presets[i])
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Custom fast length (hours)").font(.caption).foregroundColor(Theme.muted)
                HStack(spacing: 10) {
                    TextField("16", text: $customHours)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .background(Theme.inset)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                    Button("Set") { setCustom() }
                        .font(.system(size: 15, weight: .bold))
                        .padding(.vertical, 10).padding(.horizontal, 22)
                        .background(Theme.green).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .disabled(isActive)
                        .opacity(isActive ? 0.5 : 1)
                }
            }
            if isActive {
                Text("End your current fast to change protocol.")
                    .font(.caption).foregroundColor(Theme.muted)
            }
        }
        .card()
    }

    private func presetButton(_ p: (label: String, fast: Double, eat: Double)) -> some View {
        let selected = store.fastConfig.hours == p.fast
        return Button(p.label) { selectPreset(p) }
            .font(.system(size: 14, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? Theme.green : Theme.card)
            .foregroundColor(selected ? .white : Theme.text)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Theme.green : Theme.border, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(isActive ? 0.5 : 1)
            .disabled(isActive)
    }

    private func timeBlock(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased()).font(.system(size: 11)).foregroundColor(Theme.muted)
            Text(value).font(.system(size: 16, weight: .semibold))
        }
    }

    // MARK: - Info content

    private var protocolGuide: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Which window should I pick?").font(.title3.weight(.semibold))
            Text("Match the protocol to your goal and experience level.")
                .font(.subheadline).foregroundColor(Theme.muted).padding(.bottom, 4)
            protoRow("14:10 — Gentle start",
                     "Easiest on-ramp. Great for beginners or shift workers: stop late-night snacking and push breakfast a little later.")
            protoRow("16:8 — The default",
                     "The best balance of results and sustainability for fat loss and blood-sugar control. Most people eat roughly noon–8pm.")
            protoRow("18:6 — Step it up",
                     "Faster fat loss once 16:8 feels routine. A tighter window — keep hitting your protein and calorie targets.")
            protoRow("20:4 — Warrior",
                     "Advanced. One large meal plus a small snack. Strong appetite control, but harder to eat enough quality food.")
            protoRow("OMAD — One meal a day",
                     "Maximum simplicity and the longest daily repair window, but hardest to get adequate nutrition. Best used occasionally.")
        }
        .card()
    }

    private func protoRow(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 15, weight: .semibold))
            Text(body).font(.system(size: 14)).foregroundColor(Theme.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When fasting helps").font(.title3.weight(.semibold))
            Text("Evidence-based reasons people fast.")
                .font(.subheadline).foregroundColor(Theme.muted).padding(.bottom, 4)
            disclosure("Fat loss & body composition",
                       "A shorter eating window naturally trims daily calories for most people and lowers insulin, making stored fat easier to access. Pair it with strength training and enough protein to preserve muscle.")
            disclosure("Blood sugar & metabolic health",
                       "Extended time without food keeps insulin low and can improve fasting glucose and insulin sensitivity over time.")
            disclosure("Cellular repair (autophagy)",
                       "After roughly 16+ hours without food the body ramps up autophagy, its process for clearing out and recycling damaged cell components. Longer fasts deepen this effect.")
            disclosure("Simplicity & focus",
                       "Fewer meals means fewer decisions and steadier energy. Many people report sharper focus in the fasted state once adapted.")
            disclosure("Heart-health markers",
                       "Some studies show improvements in blood pressure, triglycerides, and LDL cholesterol — results vary and depend on what you eat in your window.")
        }
        .card()
    }

    private func disclosure(_ title: String, _ body: String) -> some View {
        DisclosureGroup {
            Text(body).font(.system(size: 14)).foregroundColor(Theme.text)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
        } label: {
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
        }
        .tint(Theme.green)
        .padding(.vertical, 10).padding(.horizontal, 14)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
    }

    private var tipsAndSafety: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Make it stick").font(.title3.weight(.semibold))
            Text("Water, black coffee, and plain tea are fine during the fast and blunt hunger. Front-load protein when you break the fast, don't \"make up\" calories by overeating, and ease in by pushing breakfast later in 30-minute steps.")
                .font(.system(size: 14)).foregroundColor(Theme.muted)
            Text("A quick note: Fasting isn't right for everyone. Get medical guidance first if you're pregnant or breastfeeding, under 18, underweight, have a history of disordered eating, or have diabetes or take blood-sugar or blood-pressure medication. Stay hydrated, keep electrolytes up, and break your fast if you feel unwell. This is general information, not medical advice.")
                .font(.system(size: 13))
                .padding(14)
                .background(Theme.redLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    // MARK: - Logic

    struct FastInfo {
        var progress: Double
        var displayTime: String
        var subLabel: String
        var status: String
        var startedText: String
        var windowText: String
        var complete: Bool
    }

    private func fastInfo(at date: Date) -> FastInfo {
        guard let state = store.fastState else {
            return FastInfo(progress: 0,
                            displayTime: TimerModel.format(Int(totalSeconds)),
                            subLabel: "fasting window",
                            status: "Ready to start your \(store.fastConfig.label) fast",
                            startedText: "—", windowText: "—", complete: false)
        }
        let start = state.start
        let end = start.addingTimeInterval(totalSeconds)
        let elapsed = date.timeIntervalSince(start)
        let remaining = end.timeIntervalSince(date)
        let progress = max(0, min(1, elapsed / totalSeconds))
        let tf = DateFormatter(); tf.dateFormat = "h:mm a"
        if remaining > 0 {
            return FastInfo(progress: progress,
                            displayTime: TimerModel.format(Int(remaining)),
                            subLabel: "until eating window",
                            status: "Fasting — \(Int(progress * 100))% there. Keep going! 💪",
                            startedText: tf.string(from: start),
                            windowText: tf.string(from: end), complete: false)
        } else {
            return FastInfo(progress: 1,
                            displayTime: "00:00:00",
                            subLabel: "eating window open",
                            status: "🎉 Eating window open — well done!",
                            startedText: tf.string(from: start),
                            windowText: tf.string(from: end), complete: true)
        }
    }

    private func startFast() { store.fastState = FastState(start: Date()) }

    private func endFast(info: FastInfo) {
        store.fastState = nil
    }

    private func selectPreset(_ p: (label: String, fast: Double, eat: Double)) {
        guard !isActive else { return }
        store.fastConfig = FastConfig(hours: p.fast, eat: p.eat)
    }

    private func setCustom() {
        guard !isActive, let h = Double(customHours), h >= 1, h <= 48 else { return }
        store.fastConfig = FastConfig(hours: h, eat: h < 24 ? (24 - h) : nil)
        customHours = ""
    }
}
