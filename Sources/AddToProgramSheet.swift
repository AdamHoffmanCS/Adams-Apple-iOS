import SwiftUI

struct AddToProgramSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var exerciseName: String

    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                if store.workouts.isEmpty {
                    Text("No programs yet. Create one below.").foregroundColor(Theme.muted)
                } else {
                    Section("Add \"\(exerciseName)\" to") {
                        ForEach(store.workouts) { w in
                            Button {
                                add(to: w)
                            } label: {
                                HStack {
                                    Text(w.name).foregroundColor(Theme.text)
                                    Spacer()
                                    Text("\(w.exercises.count)").foregroundColor(Theme.muted)
                                    Image(systemName: "plus.circle.fill").foregroundColor(Theme.green)
                                }
                            }
                        }
                    }
                }
                Section("New program") {
                    HStack {
                        TextField("Program name", text: $newName)
                        Button("Create") {
                            let n = newName.trimmingCharacters(in: .whitespaces)
                            guard !n.isEmpty else { return }
                            var w = store.createWorkout(name: n)
                            w.exercises.append(ProgramExercise(name: exerciseName))
                            store.update(w)
                            dismiss()
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Add to Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func add(to workout: SavedWorkout) {
        var w = workout
        w.exercises.append(ProgramExercise(name: exerciseName))
        store.update(w)
        dismiss()
    }
}
