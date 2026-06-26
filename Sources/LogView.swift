import SwiftUI

struct LogView: View {
    @EnvironmentObject var store: Store
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if store.log.isEmpty {
                        Text("No workouts logged yet. Go crush it! 💥")
                            .foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 60)
                    } else {
                        ForEach(store.log) { entry in
                            NavigationLink {
                                ExerciseChartView(exerciseName: entry.exercise)
                            } label: {
                                LogRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }

                        Button("Clear Log") { showClearConfirm = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("My Workout Log")
            .confirmationDialog("Clear your entire workout log? This cannot be undone.",
                                isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear Log", role: .destructive) { store.clearLog() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct LogRow: View {
    var entry: LogEntry
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.exercise).font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                Text(metaText).font(.system(size: 14)).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(dateStr).font(.caption).foregroundColor(Theme.muted)
                Text(timeStr).font(.caption).foregroundColor(Theme.muted)
            }
            Image(systemName: "chart.bar.fill")
                .font(.caption).foregroundColor(Theme.green).padding(.leading, 6)
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 1))
    }

    private var metaText: String {
        var s = "\(entry.sets) sets × \(entry.reps) reps"
        if let w = entry.weight, w > 0 { s += " · \(formatWeight(w)) lbs" }
        return s
    }
    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(w)) : String(format: "%.1f", w)
    }
    private var dateStr: String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: entry.date)
    }
    private var timeStr: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: entry.date)
    }
}
