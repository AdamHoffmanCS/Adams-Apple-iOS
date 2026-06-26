import SwiftUI

struct PickerItem: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var cat: String          // strength/cardio/flexibility/hiit/hyrox
    var sets: Int?
    var reps: String?
}

struct ExercisePickerView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var workoutID: UUID

    @State private var search = ""
    @State private var cat = "all"
    @State private var confirming: PickerItem?

    private let cats: [(key: String, label: String)] = [
        ("all", "All"), ("strength", "💪 Strength"), ("cardio", "🏃 Cardio"),
        ("flexibility", "🧘 Flex"), ("hiit", "⚡ HIIT"), ("hyrox", "🏆 Hyrox")
    ]

    private var items: [PickerItem] {
        var seen = Set<String>()
        var out: [PickerItem] = []
        for e in store.allExercises {
            let key = e.name.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            out.append(PickerItem(name: e.name, cat: e.pickerCategory,
                                  sets: e.suggestedSets, reps: e.suggestedReps))
        }
        for name in AppData.categoryExercises["hyrox"] ?? [] {
            let key = name.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            out.append(PickerItem(name: name, cat: "hyrox", sets: nil, reps: nil))
        }
        return out.filter { item in
            let catOK = cat == "all" || item.cat == cat
            let searchOK = search.isEmpty || item.name.localizedCaseInsensitiveContains(search)
            return catOK && searchOK
        }
        .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(cats.indices, id: \.self) { i in
                            let c = cats[i]
                            ChipButton(title: c.label, selected: cat == c.key) { cat = c.key }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                List(items) { item in
                    Button {
                        confirming = item
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).foregroundColor(Theme.text)
                                Text(item.cat.capitalized).font(.caption).foregroundColor(Theme.muted)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundColor(Theme.green)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search exercises")
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(item: $confirming) { item in
                ConfirmAddView(item: item) { sets, reps in
                    addToWorkout(item, sets: sets, reps: reps)
                }
                .presentationDetents([.height(280)])
            }
        }
    }

    private func addToWorkout(_ item: PickerItem, sets: Int?, reps: String?) {
        guard var w = store.workouts.first(where: { $0.id == workoutID }) else { return }
        w.exercises.append(ProgramExercise(name: item.name, sets: sets,
                                           reps: (reps?.isEmpty == false) ? reps : nil, notes: nil))
        store.update(w)
    }
}

struct ConfirmAddView: View {
    @Environment(\.dismiss) private var dismiss
    var item: PickerItem
    var onAdd: (Int?, String?) -> Void
    @State private var sets: String
    @State private var reps: String

    init(item: PickerItem, onAdd: @escaping (Int?, String?) -> Void) {
        self.item = item
        self.onAdd = onAdd
        _sets = State(initialValue: item.sets.map(String.init) ?? "")
        _reps = State(initialValue: item.reps ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(item.name) {
                    TextField("Sets (e.g. 3)", text: $sets).keyboardType(.numberPad)
                    TextField("Reps (e.g. 10 or 8-12)", text: $reps)
                }
            }
            .navigationTitle("Add to Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { onAdd(Int(sets), reps); dismiss() }
                }
            }
        }
    }
}
