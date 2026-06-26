import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timer: TimerModel
    @Environment(\.dismiss) private var dismiss

    private let presets: [(label: String, secs: Int)] =
        [("30s", 30), ("1m", 60), ("1:30", 90), ("2m", 120), ("5m", 300), ("10m", 600)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Mode switch
                    Picker("", selection: Binding(
                        get: { timer.mode },
                        set: { timer.setMode($0) })) {
                        Text("Stopwatch").tag(TimerModel.Mode.stopwatch)
                        Text("Countdown").tag(TimerModel.Mode.countdown)
                    }
                    .pickerStyle(.segmented)

                    // Ring + time
                    ZStack {
                        ProgressRing(progress: timer.progress,
                                     color: timer.mode == .countdown && timer.cdRemaining <= 10
                                            ? Theme.red : Theme.green,
                                     lineWidth: 10)
                            .frame(width: 200, height: 200)
                        VStack(spacing: 4) {
                            Text(timer.display)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text(timer.isRunning ? "running" : "ready")
                                .font(.caption).foregroundColor(Theme.muted)
                        }
                    }
                    .padding(.top, 8)

                    // Countdown presets
                    if timer.mode == .countdown {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            ForEach(presets, id: \.label) { p in
                                Button(p.label) { timer.setCountdown(seconds: p.secs) }
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(timer.cdTotal == p.secs ? Theme.green : Theme.greenLight.opacity(0.5))
                                    .foregroundColor(timer.cdTotal == p.secs ? .white : Theme.greenDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    // Controls
                    HStack(spacing: 16) {
                        Button { timer.reset() } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .semibold))
                                .frame(width: 56, height: 56)
                                .background(Theme.bg).foregroundColor(Theme.text)
                                .clipShape(Circle())
                        }
                        Button { timer.toggle() } label: {
                            Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .bold))
                                .frame(width: 72, height: 72)
                                .background(Theme.green).foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }

                    // Stopwatch rounds
                    if timer.mode == .stopwatch {
                        Button { timer.roundComplete() } label: {
                            Label("Round Complete", systemImage: "bell.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(!timer.isRunning)

                        if !timer.rounds.isEmpty {
                            VStack(spacing: 6) {
                                ForEach(timer.rounds, id: \.num) { r in
                                    HStack {
                                        Text("Round \(r.num)").font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(TimerModel.format(r.duration)).monospacedDigit()
                                            .foregroundColor(Theme.muted)
                                    }
                                    .padding(.vertical, 8).padding(.horizontal, 12)
                                    .background(Theme.bg).clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
