import SwiftUI

struct AddCustomExerciseView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "strength"
    @State private var sets = ""
    @State private var reps = ""
    @State private var muscles = ""
    @State private var equipment = ""
    @State private var youtube = ""
    @State private var notes = ""

    private let categories: [(value: String, label: String)] = [
        ("strength", "Strength"), ("cardio", "Cardio"),
        ("stretching", "Flexibility"), ("plyometrics", "Plyometrics / HIIT")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name (e.g. Bulgarian Split Squat)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(categories.indices, id: \.self) { i in
                            Text(categories[i].label).tag(categories[i].value)
                        }
                    }
                }
                Section("Suggested (optional)") {
                    TextField("Sets (e.g. 3)", text: $sets).keyboardType(.numberPad)
                    TextField("Reps (e.g. 8-12)", text: $reps)
                }
                Section("Details (optional)") {
                    TextField("Primary muscles (comma separated)", text: $muscles)
                    TextField("Equipment", text: $equipment)
                    TextField("YouTube link", text: $youtube).keyboardType(.URL).autocapitalization(.none)
                }
                Section("Description / Key Points") {
                    TextField("One key point per line…", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("Add Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let instructions = notes
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let ex = DBExercise(
            id: "custom_\(Int(Date().timeIntervalSince1970 * 1000))",
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            level: nil,
            equipment: equipment.isEmpty ? nil : equipment,
            primaryMuscles: muscles.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty },
            secondaryMuscles: [],
            instructions: instructions,
            suggestedSets: Int(sets),
            suggestedReps: reps.isEmpty ? nil : reps,
            youtube: youtube.isEmpty ? nil : youtube,
            isCustom: true
        )
        store.addCustomExercise(ex)
        dismiss()
    }
}
