import SwiftUI

struct ProgramDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var workoutID: UUID

    @State private var activeSheet: ProgramSheet?
    @State private var showDeleteConfirm = false

    enum ProgramSheet: Identifiable {
        case picker
        case log(LogTarget)
        var id: String {
            switch self {
            case .picker: return "picker"
            case .log(let t): return t.id.uuidString
            }
        }
    }

    private var workout: SavedWorkout? { store.workouts.first { $0.id == workoutID } }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Button { activeSheet = .picker } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())

                if let w = workout {
                    if w.exercises.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "dumbbell").font(.largeTitle).foregroundColor(Theme.muted)
                            Text("No exercises yet.\nTap **Add Exercise** to build this workout!")
                                .multilineTextAlignment(.center).foregroundColor(Theme.muted)
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(w.exercises) { ex in
                            ProgramExerciseRow(
                                ex: ex,
                                hasHistory: store.hasHistory(ex.name),
                                onLog: { activeSheet = .log(LogTarget(
                                    name: ex.name,
                                    sets: ex.sets.map(String.init) ?? "",
                                    reps: (ex.reps.flatMap { Int($0) } != nil) ? ex.reps! : "")) },
                                onRemove: { remove(ex) }
                            )
                        }
                    }

                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete Program", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(workout?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .picker:
                ExercisePickerView(workoutID: workoutID)
            case .log(let t):
                LogExerciseSheet(name: t.name, sets: t.sets, reps: t.reps)
            }
        }
        .confirmationDialog("Delete this program? This cannot be undone.",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let w = workout { store.deleteWorkout(w) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func remove(_ ex: ProgramExercise) {
        guard var w = workout else { return }
        w.exercises.removeAll { $0.id == ex.id }
        store.update(w)
    }
}

struct ProgramExerciseRow: View {
    @EnvironmentObject var store: Store
    var ex: ProgramExercise
    var hasHistory: Bool
    var onLog: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(ex.name).font(.system(size: 16, weight: .semibold))
                if let meta = metaText {
                    Text(meta).font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.greenDark)
                }
                if let notes = ex.notes, !notes.isEmpty {
                    Text(notes).font(.system(size: 13)).foregroundColor(Theme.muted)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                if hasHistory {
                    NavigationLink {
                        ExerciseChartView(exerciseName: ex.name)
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .padding(7).background(Theme.inset).clipShape(RoundedRectangle(cornerRadius: 6))
                            .foregroundColor(Theme.text)
                    }
                    .buttonStyle(.plain)
                }
                Button("+ Log", action: onLog)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.vertical, 6).padding(.horizontal, 14)
                    .background(Theme.greenLight).foregroundColor(Theme.greenDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Button(action: onRemove) {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.muted)
                }
            }
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border))
    }

    private var metaText: String? {
        var parts: [String] = []
        if let s = ex.sets { parts.append("\(s) sets") }
        if let r = ex.reps, !r.isEmpty { parts.append("\(r) reps") }
        return parts.isEmpty ? nil : parts.joined(separator: " × ")
    }
}
