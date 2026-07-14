import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct DashboardView: View {
    @EnvironmentObject var store: Store
    @State private var quickEntry: QuickEntry?
    @State private var exportURL: URL?
    @State private var showExport = false
    @State private var showImporter = false
    @State private var pendingImportURL: URL?
    @State private var showImportConfirm = false
    @State private var importError: String?

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

                    HStack(spacing: 12) {
                        fastingCard
                        nutritionCard
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            if let url = try? store.exportAllData() {
                                exportURL = url
                                showExport = true
                            }
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            showImporter = true
                        } label: {
                            Label("Import Data…", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.green)
                    }
                    .accessibilityLabel("Backup Data")
                }
            }
            .sheet(isPresented: $showExport) {
                if let url = exportURL {
                    ActivityShareSheet(items: [url])
                        .presentationDetents([.medium, .large])
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    pendingImportURL = url
                    showImportConfirm = true
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
            .confirmationDialog(
                "Replace all data on this device with the contents of this backup? This can't be undone.",
                isPresented: $showImportConfirm,
                titleVisibility: .visible
            ) {
                Button("Import & Replace", role: .destructive) {
                    guard let url = pendingImportURL else { return }
                    do {
                        try store.importAllData(from: url)
                    } catch {
                        importError = error.localizedDescription
                    }
                    pendingImportURL = nil
                }
                Button("Cancel", role: .cancel) { pendingImportURL = nil }
            }
            .alert("Import Failed", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
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

    // MARK: - Fasting countdown card

    private var fastingCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let (display, sub, active) = fastingInfo(at: context.date)
            Button { store.selectedTab = 3 } label: {
                VStack(spacing: 6) {
                    Text("Fasting")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.muted)
                    Text(display)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(active ? Theme.green : Theme.muted)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20).padding(.horizontal, 8)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    private func fastingInfo(at date: Date) -> (display: String, sub: String, active: Bool) {
        guard let state = store.fastState else {
            return (store.fastConfig.label, "not fasting", false)
        }
        let end = state.start.addingTimeInterval(store.fastConfig.hours * 3600)
        let remaining = end.timeIntervalSince(date)
        if remaining > 0 {
            return (TimerModel.format(Int(remaining)), "remaining", true)
        } else {
            return ("00:00:00", "window open", true)
        }
    }

    // MARK: - Nutrition card

    private var nutritionCard: some View {
        let todayEntries = store.dayLog(for: Date()).entries
        let cal     = todayEntries.reduce(0.0) { $0 + $1.calories }
        let protein = todayEntries.reduce(0.0) { $0 + $1.protein }
        let fat     = todayEntries.reduce(0.0) { $0 + $1.fat }
        let carbs   = todayEntries.reduce(0.0) { $0 + $1.carbs }
        let goal    = store.foodGoals.calories

        return Button { store.selectedTab = 2 } label: {
            VStack(spacing: 6) {
                Text("Nutrition")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.muted)
                Text("\(Int(cal))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(cal > 0 ? Theme.green : Theme.muted)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("kcal")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
                if cal > 0 {
                    Text("P \(Int(protein))g · F \(Int(fat))g · C \(Int(carbs))g")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                } else {
                    Text("of \(Int(goal)) kcal goal")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.muted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20).padding(.horizontal, 8)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
