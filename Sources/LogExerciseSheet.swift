import SwiftUI

/// Identifiable payload so any row can present the log sheet via `.sheet(item:)`.
struct LogTarget: Identifiable {
    let id = UUID()
    var name: String
    var sets: String = ""
    var reps: String = ""
}

/// Modal for logging a set — reused by the Programs detail, the exercise
/// database, and the category exercise lists (mirrors the web Log modal).
struct LogExerciseSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State var name: String
    @State var sets: String
    @State var reps: String
    @State private var weight: String = ""

    init(name: String = "", sets: String = "", reps: String = "") {
        _name = State(initialValue: name)
        _sets = State(initialValue: sets)
        _reps = State(initialValue: reps)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise", text: $name)
                    TextField("Sets", text: $sets).keyboardType(.numberPad)
                    TextField("Reps", text: $reps).keyboardType(.numberPad)
                    TextField("Weight (lbs) — optional", text: $weight).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log It") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                                  || Int(sets) == nil || Int(reps) == nil)
                }
            }
        }
    }

    private func save() {
        let entry = LogEntry(
            exercise: name.trimmingCharacters(in: .whitespaces),
            sets: Int(sets) ?? 0,
            reps: Int(reps) ?? 0,
            weight: Double(weight)
        )
        store.addLog(entry)
        dismiss()
    }
}
