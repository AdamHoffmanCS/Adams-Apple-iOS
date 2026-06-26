import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var exercise: DBExercise

    @State private var activeSheet: DetailSheet?
    @State private var showDeleteConfirm = false

    enum DetailSheet: Identifiable {
        case log(LogTarget)
        case addToProgram
        var id: String {
            switch self {
            case .log(let t): return t.id.uuidString
            case .addToProgram: return "addToProgram"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Badges
                HStack(spacing: 8) {
                    if let lvl = exercise.level { badge(lvl.capitalized, Theme.greenLight, Theme.greenDark) }
                    badge(exercise.category.capitalized, Theme.bg, Theme.text)
                }

                // Meta
                VStack(spacing: 0) {
                    metaRow("Equipment", exercise.equipment?.capitalized ?? "—")
                    Divider()
                    metaRow("Primary", exercise.primaryMuscles.joined(separator: ", ").capitalized.ifEmpty("—"))
                    Divider()
                    metaRow("Secondary", exercise.secondaryMuscles.joined(separator: ", ").capitalized.ifEmpty("—"))
                    if exercise.suggestedSets != nil || exercise.suggestedReps != nil {
                        Divider()
                        metaRow("Suggested", suggestedText)
                    }
                }
                .card(padding: 0)

                // YouTube
                if let yt = exercise.youtube, let url = URL(string: yt) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "play.rectangle.fill").foregroundColor(Theme.red)
                            Text("Watch on YouTube").font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .padding(14).background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border))
                    }
                    .foregroundColor(Theme.text)
                }

                // Instructions
                if !exercise.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to Perform").font(.title3.weight(.semibold))
                        ForEach(exercise.instructions.indices, id: \.self) { idx in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(idx + 1)").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                                    .frame(width: 22, height: 22).background(Theme.green).clipShape(Circle())
                                Text(exercise.instructions[idx]).font(.system(size: 15)).foregroundColor(Theme.text)
                            }
                        }
                    }
                    .card()
                }

                // Actions
                VStack(spacing: 10) {
                    Button("+ Add to Program") { activeSheet = .addToProgram }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Log Exercise") {
                        activeSheet = .log(LogTarget(name: exercise.name,
                                              sets: exercise.suggestedSets.map(String.init) ?? "",
                                              reps: (exercise.suggestedReps.flatMap { Int($0) } != nil) ? exercise.suggestedReps! : ""))
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    if exercise.isCustom {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .log(let t): LogExerciseSheet(name: t.name, sets: t.sets, reps: t.reps)
            case .addToProgram: AddToProgramSheet(exerciseName: exercise.name)
            }
        }
        .confirmationDialog("Delete \"\(exercise.name)\"?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteExercise(exercise); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var suggestedText: String {
        var parts: [String] = []
        if let s = exercise.suggestedSets { parts.append("\(s) sets") }
        if let r = exercise.suggestedReps, !r.isEmpty { parts.append("\(r) reps") }
        return parts.joined(separator: " × ").ifEmpty("—")
    }

    private func badge(_ text: String, _ bg: Color, _ fg: Color) -> some View {
        Text(text).font(.caption.weight(.semibold))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(bg).foregroundColor(fg).clipShape(Capsule())
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(Theme.muted)
            Spacer()
            Text(value).font(.system(size: 14, weight: .medium)).multilineTextAlignment(.trailing)
        }
        .padding(14)
    }
}

extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}
