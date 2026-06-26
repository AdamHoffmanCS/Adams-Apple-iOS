import SwiftUI

struct ExerciseDBView: View {
    @EnvironmentObject var store: Store
    @State private var search = ""
    @State private var filter = "all"
    @State private var showAdd = false

    private var results: [DBExercise] {
        store.allExercises.filter { e in
            let f: Bool
            switch filter {
            case "all":    f = true
            case "cardio": f = e.category.lowercased() == "cardio"
            default:       f = e.primaryMuscles.contains { $0.lowercased().contains(filter) }
            }
            let s = search.isEmpty || e.name.localizedCaseInsensitiveContains(search)
            return f && s
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AppData.dbFilters.indices, id: \.self) { i in
                            let f = AppData.dbFilters[i]
                            ChipButton(title: f.label, selected: filter == f.key) { filter = f.key }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }

                List {
                    ForEach(results) { ex in
                        NavigationLink {
                            ExerciseDetailView(exercise: ex)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name).foregroundColor(Theme.text)
                                    Text(subtitle(ex)).font(.caption).foregroundColor(Theme.muted)
                                }
                                Spacer()
                                if ex.isCustom {
                                    Text("Custom").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Theme.greenLight).foregroundColor(Theme.greenDark).clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if results.isEmpty {
                        Text("No exercises found — try a different search or filter.")
                            .foregroundColor(Theme.muted).padding()
                    }
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search 800+ exercises")
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: { Label("Add", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddCustomExerciseView() }
            .task { await store.fetchRemoteDB() }
        }
    }

    private func subtitle(_ e: DBExercise) -> String {
        var parts: [String] = []
        if let eq = e.equipment, !eq.isEmpty { parts.append(eq) }
        if let p = e.primaryMuscles.first { parts.append(p) }
        return parts.joined(separator: " · ").capitalized
    }
}
