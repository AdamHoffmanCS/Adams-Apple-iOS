import SwiftUI
import Foundation

struct DashboardView: View {
    @EnvironmentObject var store: Store
    @State private var quickEntry: QuickEntry?

    enum QuickEntry: Identifiable {
        case weight, bodyFat
        var id: Int { self == .weight ? 0 : 1 }
    }

    private var latestWeight: MetricEntry? {
        store.weights.sorted { $0.date > $1.date }.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Welcome back, Adam 💪")
                        .font(.system(size: 28, weight: .bold))

                    HStack(spacing: 12) {
                        StatCard(value: "\(store.log.count)", label: "Workouts Logged")
                        StatCard(value: "\(store.streak)", label: "Day Streak 🔥")
                        StatCard(value: latestWeight.map { store.fmtNum($0.value) } ?? "—",
                                 label: "Weight (lbs)")
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Start").font(.title3.weight(.semibold))
                        Button("Start a Workout") { store.selectedTab = 1 }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Quick Log").font(.title3.weight(.semibold))
                        Text(latestWeight.map { "Last weight: \(store.fmtNum($0.value)) lbs · \(dateStr($0.date))" }
                                ?? "Track your weight and body fat over time.")
                            .font(.subheadline).foregroundColor(Theme.muted)
                        HStack(spacing: 12) {
                            Button { quickEntry = .weight } label: {
                                Label("Log Weight", systemImage: "scalemass.fill")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            Button { quickEntry = .bodyFat } label: {
                                Label("Log Body Fat", systemImage: "percent")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        Button("View all progress") { store.selectedTab = 4 }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.greenDark)
                    }
                    .card()

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("🍎 Adams Apple")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $quickEntry) { entry in
                switch entry {
                case .weight:
                    AddSingleValueSheet(title: "Weight", unit: "lbs") { d, v in
                        store.weights.append(MetricEntry(date: d, value: v))
                    }
                case .bodyFat:
                    AddSingleValueSheet(title: "Body Fat", unit: "%") { d, v in
                        store.bodyFat.append(MetricEntry(date: d, value: v))
                    }
                }
            }
        }
    }

    private func dateStr(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: d)
    }
}

struct StatCard: View {
    var value: String
    var label: String
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Theme.green)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20).padding(.horizontal, 8)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
    }
}
