import SwiftUI

// MARK: - Day detail

struct FoodDayDetailView: View {
    var log: DayFoodLog
    @EnvironmentObject var store: Store
    @State private var editingNote = false
    @State private var noteText = ""

    private var liveLog: DayFoodLog { store.dayLog(for: log.day) }

    private var totals: (cal: Double, p: Double, f: Double, c: Double) {
        let e = liveLog.entries
        return (e.reduce(0){$0+$1.calories}, e.reduce(0){$0+$1.protein},
                e.reduce(0){$0+$1.fat},      e.reduce(0){$0+$1.carbs})
    }

    private let df: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .full; f.timeStyle = .none; return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryCard
                mealsCard
                noteCard
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(df.string(from: log.day))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editingNote) {
            NoteEditorSheet(title: "Day Note", note: $noteText) {
                store.updateDayNote(noteText, for: log.day)
            }
        }
    }

    private var summaryCard: some View {
        let t = totals
        let g = store.foodGoals
        return VStack(spacing: 12) {
            HStack(spacing: 0) {
                summaryCol("Calories", "\(Int(t.cal))", "/ \(Int(g.calories))", Theme.green)
                summaryCol("Protein",  "\(Int(t.p))g",  "/ \(Int(g.protein))g",  Color(hex: "#5C9EFF"))
                summaryCol("Fat",      "\(Int(t.f))g",  "/ \(Int(g.fat))g",      Color(hex: "#FF9F43"))
                summaryCol("Carbs",    "\(Int(t.c))g",  "/ \(Int(g.carbs))g",    Color(hex: "#FF6B6B"))
            }
        }
        .card()
    }

    private func summaryCol(_ label: String, _ val: String, _ sub: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10)).foregroundColor(Theme.muted)
            Text(val).font(.system(size: 17, weight: .bold)).foregroundColor(color)
            Text(sub).font(.system(size: 10)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var mealsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Meals").font(.title3.weight(.semibold))
            if liveLog.entries.isEmpty {
                Text("Nothing logged this day.")
                    .font(.subheadline).foregroundColor(Theme.muted)
            } else {
                let grouped = Dictionary(grouping: liveLog.entries, by: \.mealType)
                ForEach(MealType.allCases, id: \.self) { meal in
                    if let entries = grouped[meal], !entries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(meal.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.muted)
                            ForEach(entries) { entry in
                                entryRow(entry)
                            }
                        }
                    }
                }
            }
        }
        .card()
    }

    private func entryRow(_ entry: FoodEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                Text("\(store.formatWeight(entry.grams))  ·  P \(Int(entry.protein))g  F \(Int(entry.fat))g  C \(Int(entry.carbs))g")
                    .font(.caption).foregroundColor(Theme.muted)
            }
            Spacer()
            Text("\(Int(entry.calories)) kcal")
                .font(.system(size: 13, weight: .bold)).foregroundColor(Theme.green)
        }
        .padding(10)
        .background(Theme.inset)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.deleteFoodEntry(entry, for: log.day)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Note").font(.title3.weight(.semibold))
                Spacer()
                Button(liveLog.note.isEmpty ? "Add" : "Edit") {
                    noteText = liveLog.note
                    editingNote = true
                }
                .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.green)
            }
            if liveLog.note.isEmpty {
                Text("No note for this day.")
                    .font(.subheadline).foregroundColor(Theme.muted)
            } else {
                Text(liveLog.note).font(.system(size: 14))
            }
        }
        .card()
    }
}

// MARK: - Full history list

struct FoodFullHistoryView: View {
    @EnvironmentObject var store: Store
    @State private var showDetail: DayFoodLog? = nil

    private var pastLogs: [DayFoodLog] {
        let today = Calendar.current.startOfDay(for: Date())
        return store.foodLogs.filter { Calendar.current.startOfDay(for: $0.day) < today }
    }

    private let df: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(pastLogs) { log in
                    Button {
                        showDetail = log
                    } label: {
                        historyRow(log)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Food History")
        .navigationDestination(item: $showDetail) { log in
            FoodDayDetailView(log: log).environmentObject(store)
        }
    }

    private func historyRow(_ log: DayFoodLog) -> some View {
        let cal = log.entries.reduce(0.0) { $0 + $1.calories }
        let prot = log.entries.reduce(0.0) { $0 + $1.protein }
        let fat  = log.entries.reduce(0.0) { $0 + $1.fat }
        let carbs = log.entries.reduce(0.0) { $0 + $1.carbs }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(df.string(from: log.day))
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(Int(cal)) kcal")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.green)
                Image(systemName: "chevron.right").font(.caption).foregroundColor(Theme.muted)
            }
            HStack(spacing: 16) {
                macroTag("P", prot, Color(hex: "#5C9EFF"))
                macroTag("F", fat,  Color(hex: "#FF9F43"))
                macroTag("C", carbs, Color(hex: "#FF6B6B"))
                Spacer()
                Text("\(log.entries.count) items")
                    .font(.caption).foregroundColor(Theme.muted)
            }
            if !log.note.isEmpty {
                Text(log.note)
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
    }

    private func macroTag(_ label: String, _ val: Double, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.caption).foregroundColor(Theme.muted)
            Text("\(Int(val))g").font(.caption.weight(.bold)).foregroundColor(color)
        }
    }
}

// MARK: - Goals sheet

struct FoodGoalsSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var calories: String = ""
    @State private var protein:  String = ""
    @State private var fat:      String = ""
    @State private var carbs:    String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Unit Preference").font(.title3.weight(.semibold))
                        Text("Choose the unit used when logging food amounts.")
                            .font(.subheadline).foregroundColor(Theme.muted)
                        Picker("Unit", selection: $store.weightUnit) {
                            ForEach(WeightUnit.allCases, id: \.self) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Daily Targets").font(.title3.weight(.semibold))
                        Text("Set your daily nutrition goals. These are used for the calorie ring and macro bars.")
                            .font(.subheadline).foregroundColor(Theme.muted)

                        goalField("Daily Calories", "kcal", $calories)
                        goalField("Protein",        "g",    $protein)
                        goalField("Fat",            "g",    $fat)
                        goalField("Carbohydrates",  "g",    $carbs)
                    }
                    .card()
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                calories = "\(Int(store.foodGoals.calories))"
                protein  = "\(Int(store.foodGoals.protein))"
                fat      = "\(Int(store.foodGoals.fat))"
                carbs    = "\(Int(store.foodGoals.carbs))"
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(); dismiss() }
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Theme.green)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
            }
        }
    }

    private func goalField(_ label: String, _ unit: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label) (\(unit))").font(.caption).foregroundColor(Theme.muted)
            TextField("0", text: binding)
                .keyboardType(.numberPad)
                .padding(10)
                .background(Theme.inset)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
        }
    }

    private func save() {
        store.foodGoals = FoodGoals(
            calories: Double(calories) ?? store.foodGoals.calories,
            protein:  Double(protein)  ?? store.foodGoals.protein,
            fat:      Double(fat)      ?? store.foodGoals.fat,
            carbs:    Double(carbs)    ?? store.foodGoals.carbs
        )
    }
}
