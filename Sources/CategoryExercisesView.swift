import SwiftUI

struct CategoryExercisesView: View {
    @EnvironmentObject var store: Store
    var category: String
    var title: String

    @State private var activeSheet: CatSheet?

    enum CatSheet: Identifiable {
        case log(LogTarget)
        case targets
        var id: String {
            switch self {
            case .log(let t): return t.id.uuidString
            case .targets: return "targets"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if category == "hyrox" {
                    hyroxContent
                } else {
                    ForEach(AppData.categoryExercises[category] ?? [], id: \.self) { name in
                        exerciseRow(name: name, note: nil)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("\(title) Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if category == "hyrox" {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { activeSheet = .targets } label: { Label("Targets", systemImage: "gearshape") }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .log(let t): LogExerciseSheet(name: t.name, sets: t.sets, reps: t.reps)
            case .targets: HyroxSettingsView()
            }
        }
    }

    @ViewBuilder private var hyroxContent: some View {
        HStack {
            Text("🏁 Race Stations").font(.headline)
            Text("Official Order").font(.caption2).padding(.horizontal, 8).padding(.vertical, 3)
                .background(Theme.greenLight).foregroundColor(Theme.greenDark).clipShape(Capsule())
        }
        .padding(.bottom, 2)
        ForEach(Array(AppData.hyroxStations.enumerated()), id: \.offset) { idx, station in
            exerciseRow(name: station.name, note: store.hyroxNote(for: station.name), number: idx + 1)
        }

        Text("🏋️ Training Exercises").font(.headline).padding(.top, 12)
        ForEach(AppData.hyroxTraining, id: \.self) { name in
            exerciseRow(name: name, note: nil)
        }
    }

    private func exerciseRow(name: String, note: String?, number: Int? = nil) -> some View {
        HStack(spacing: 10) {
            if let number = number {
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    .frame(width: 24, height: 24).background(Theme.green).clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 15, weight: .medium))
                if let note = note, !note.isEmpty {
                    Text(note).font(.caption).foregroundColor(Theme.greenDark)
                }
            }
            Spacer()
            if store.hasHistory(name) {
                NavigationLink {
                    ExerciseChartView(exerciseName: name)
                } label: {
                    Image(systemName: "chart.bar.fill").font(.system(size: 14))
                        .padding(7).background(Theme.bg).clipShape(RoundedRectangle(cornerRadius: 6))
                        .foregroundColor(Theme.text)
                }
                .buttonStyle(.plain)
            }
            Button("+ Log") { activeSheet = .log(LogTarget(name: name)) }
                .font(.system(size: 14, weight: .semibold))
                .padding(.vertical, 6).padding(.horizontal, 14)
                .background(Theme.greenLight).foregroundColor(Theme.greenDark)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border))
    }
}
