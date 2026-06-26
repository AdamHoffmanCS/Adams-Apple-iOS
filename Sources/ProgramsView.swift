import SwiftUI

struct ProgramsView: View {
    @EnvironmentObject var store: Store
    private let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 14) {
                    ForEach(AppData.programCategories.indices, id: \.self) { i in
                        let cat = AppData.programCategories[i]
                        NavigationLink {
                            CategoryExercisesView(category: cat.key, title: cat.title)
                        } label: {
                            CategoryCard(icon: cat.icon, title: cat.title, subtitle: cat.subtitle,
                                         highlight: cat.key == "hyrox")
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        MyWorkoutsListView()
                    } label: {
                        CategoryCard(icon: "plus.circle.fill", title: "My Workouts",
                                     subtitle: "Build a custom routine", highlight: false, dashed: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Programs")
        }
    }
}

struct CategoryCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var highlight: Bool
    var dashed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(highlight ? .white : Theme.green)
            Text(title).font(.system(size: 17, weight: .bold))
                .foregroundColor(highlight ? .white : Theme.text)
            Text(subtitle).font(.system(size: 13))
                .foregroundColor(highlight ? .white.opacity(0.85) : Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .padding(16)
        .background(highlight ? AnyView(Theme.text) : AnyView(Theme.card))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .overlay {
            if dashed {
                RoundedRectangle(cornerRadius: Theme.radius)
                    .strokeBorder(Theme.green, style: StrokeStyle(lineWidth: 2, dash: [6]))
            }
        }
        .shadow(color: Theme.shadow, radius: 5, x: 0, y: 2)
    }
}

// MARK: - My Workouts list

struct MyWorkoutsListView: View {
    @EnvironmentObject var store: Store
    @State private var showCreate = false
    @State private var newName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Button { showCreate = true } label: {
                    Label("New Workout", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())

                if store.workouts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle").font(.largeTitle).foregroundColor(Theme.muted)
                        Text("No workouts yet.\nTap **New Workout** to build your first routine!")
                            .multilineTextAlignment(.center).foregroundColor(Theme.muted)
                    }
                    .padding(.top, 50)
                } else {
                    ForEach(store.workouts) { w in
                        NavigationLink {
                            ProgramDetailView(workoutID: w.id)
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.rectangle.fill").foregroundColor(Theme.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(w.name).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text)
                                    Text("\(w.exercises.count) exercise\(w.exercises.count == 1 ? "" : "s")")
                                        .font(.caption).foregroundColor(Theme.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(Theme.muted)
                            }
                            .padding(14)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Workout Builder")
        .navigationBarTitleDisplayMode(.inline)
        .alert("New Workout", isPresented: $showCreate) {
            TextField("e.g. Push Day, Leg Day", text: $newName)
            Button("Create") {
                let n = newName.trimmingCharacters(in: .whitespaces)
                guard !n.isEmpty else { return }
                _ = store.createWorkout(name: n)
                newName = ""
            }
            Button("Cancel", role: .cancel) { newName = "" }
        } message: {
            Text("Name your custom workout.")
        }
    }
}
