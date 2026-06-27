import SwiftUI
import Foundation

struct ExerciseChartView: View {
    @EnvironmentObject var store: Store
    var exerciseName: String

    private var entries: [LogEntry] { store.history(for: exerciseName) }

    private var useWeight: Bool { entries.contains { ($0.weight ?? 0) > 0 } }

    private var values: [Double] {
        entries.map { useWeight ? ($0.weight ?? 0) : Double($0.reps) }
    }
    private var labels: [String] {
        entries.map { dateLabel($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if entries.isEmpty {
                    Text("No data yet for this exercise.")
                        .foregroundColor(Theme.muted)
                        .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(useWeight ? "Weight over time (lbs)" : "Reps over time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.muted)
                        MiniBarChart(values: values, labels: labels,
                                     unit: useWeight ? "lbs" : "reps")
                            .frame(height: 240)
                    }
                    .card()

                    HStack(spacing: 12) {
                        summaryCard("Sessions", "\(entries.count)")
                        summaryCard(useWeight ? "Max" : "Best",
                                    useWeight ? "\(Int(values.max() ?? 0)) lbs"
                                              : "\(Int(values.max() ?? 0)) reps")
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryCard(_ label: String, _ value: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.weight(.bold)).foregroundColor(Theme.green)
            Text(label).font(.caption).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .shadow(color: Theme.shadow, radius: 5, x: 0, y: 2)
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "M/d"; return f.string(from: d)
    }
}
