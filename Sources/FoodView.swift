import SwiftUI

struct FoodView: View {
    @EnvironmentObject var store: Store
    @State private var showAddFood = false
    @State private var showGoals = false
    @State private var showDayDetail: DayFoodLog? = nil
    @State private var editingNote = false
    @State private var noteText = ""

    private var todayLog: DayFoodLog { store.dayLog(for: Date()) }

    private var totals: (cal: Double, protein: Double, fat: Double, carbs: Double) {
        let entries = todayLog.entries
        return (
            entries.reduce(0) { $0 + $1.calories },
            entries.reduce(0) { $0 + $1.protein },
            entries.reduce(0) { $0 + $1.fat },
            entries.reduce(0) { $0 + $1.carbs }
        )
    }

    private var pastLogs: [DayFoodLog] {
        let today = Calendar.current.startOfDay(for: Date())
        return store.foodLogs.filter { Calendar.current.startOfDay(for: $0.day) < today }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    calorieRingCard
                    macroBreakdownCard
                    todayMealsCard
                    dayNoteCard
                    if !pastLogs.isEmpty { historyCard }
                    attributionFooter
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showGoals = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Theme.green)
                    }
                }
            }
            .navigationDestination(item: $showDayDetail) { log in
                FoodDayDetailView(log: log)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodEntrySheet { entry in
                store.addFoodEntry(entry, for: Date())
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showGoals) {
            FoodGoalsSheet()
                .environmentObject(store)
        }
    }

    // MARK: - Calorie Ring

    private var calorieRingCard: some View {
        let t = totals
        let goal = store.foodGoals.calories
        let progress = goal > 0 ? min(t.cal / goal, 1.0) : 0

        return VStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: progress,
                             color: calorieRingColor(progress),
                             lineWidth: 14)
                    .frame(width: 220, height: 220)
                VStack(spacing: 4) {
                    Text("\(Int(t.cal))")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("of \(Int(goal)) kcal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 0) {
                macroChip("Protein", t.protein, "g", Color(hex: "#5C9EFF"))
                Divider().frame(height: 32).background(Theme.border)
                macroChip("Fat", t.fat, "g", Color(hex: "#FF9F43"))
                Divider().frame(height: 32).background(Theme.border)
                macroChip("Carbs", t.carbs, "g", Color(hex: "#FF6B6B"))
            }
            .padding(.horizontal, 4)

            Button("Add Food") { showAddFood = true }
                .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .card(padding: 24)
    }

    private func macroChip(_ label: String, _ value: Double, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased()).font(.system(size: 10)).foregroundColor(Theme.muted)
            Text("\(Int(value))\(unit)")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Macro Breakdown Bars

    private var macroBreakdownCard: some View {
        let t = totals
        let g = store.foodGoals
        return VStack(alignment: .leading, spacing: 14) {
            Text("Macros").font(.title3.weight(.semibold))
            macroBar("Protein", t.protein, g.protein, Color(hex: "#5C9EFF"))
            macroBar("Fat",     t.fat,     g.fat,     Color(hex: "#FF9F43"))
            macroBar("Carbs",   t.carbs,   g.carbs,   Color(hex: "#FF6B6B"))
        }
        .card()
    }

    private func macroBar(_ label: String, _ value: Double, _ goal: Double, _ color: Color) -> some View {
        let pct = goal > 0 ? min(value / goal, 1.0) : 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(Int(value))g / \(Int(goal))g")
                    .font(.caption).foregroundColor(Theme.muted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.border)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * pct, height: 8)
                        .animation(.easeOut(duration: 0.6), value: pct)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Today's meals

    private var todayMealsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Meals").font(.title3.weight(.semibold))
                Spacer()
                Text(Date(), style: .date)
                    .font(.caption).foregroundColor(Theme.muted)
            }
            if todayLog.entries.isEmpty {
                Text("No food logged yet — tap Add Food to start.")
                    .font(.subheadline).foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                let grouped = Dictionary(grouping: todayLog.entries, by: \.mealType)
                ForEach(MealType.allCases, id: \.self) { meal in
                    if let entries = grouped[meal], !entries.isEmpty {
                        mealGroup(meal, entries: entries, day: Date())
                    }
                }
            }
        }
        .card()
    }

    private func mealGroup(_ meal: MealType, entries: [FoodEntry], day: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.muted)
                .padding(.top, 4)
            ForEach(entries) { entry in
                foodEntryRow(entry, day: day)
            }
        }
    }

    private func foodEntryRow(_ entry: FoodEntry, day: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text("\(store.formatWeight(entry.grams))  ·  P \(Int(entry.protein))g  F \(Int(entry.fat))g  C \(Int(entry.carbs))g")
                    .font(.caption).foregroundColor(Theme.muted)
            }
            Spacer()
            Text("\(Int(entry.calories)) kcal")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.green)
        }
        .padding(10)
        .background(Theme.inset)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.deleteFoodEntry(entry, for: day)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Day note

    private var dayNoteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Note").font(.title3.weight(.semibold))
                Spacer()
                Button(todayLog.note.isEmpty ? "Add" : "Edit") {
                    noteText = todayLog.note
                    editingNote = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.green)
            }
            if todayLog.note.isEmpty {
                Text("Add notes about how you feel, what you ate, cravings, energy levels…")
                    .font(.subheadline).foregroundColor(Theme.muted)
            } else {
                Text(todayLog.note)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.text)
            }
        }
        .card()
        .sheet(isPresented: $editingNote) {
            NoteEditorSheet(title: "Today's Food Note", note: $noteText) {
                store.updateDayNote(noteText, for: Date())
            }
        }
    }

    // MARK: - History

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("History").font(.title3.weight(.semibold))
            ForEach(pastLogs.prefix(7)) { log in
                Button {
                    showDayDetail = log
                } label: {
                    pastLogRow(log)
                }
                .buttonStyle(.plain)
            }
            if pastLogs.count > 7 {
                NavigationLink {
                    FoodFullHistoryView()
                        .environmentObject(store)
                } label: {
                    HStack {
                        Text("See All History")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.green)
                        Spacer()
                        Text("\(pastLogs.count) days").font(.caption).foregroundColor(Theme.muted)
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(Theme.muted)
                    }
                    .padding(12)
                    .background(Theme.inset)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .card()
    }

    private static let dayFormatter: DateFormatter = {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none
        return df
    }()

    private func pastLogRow(_ log: DayFoodLog) -> some View {
        let cal = log.entries.reduce(0.0) { $0 + $1.calories }
        let df = Self.dayFormatter
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(df.string(from: log.day))
                    .font(.system(size: 15, weight: .semibold))
                Text("\(log.entries.count) items logged")
                    .font(.caption).foregroundColor(Theme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(cal)) kcal")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.green)
                Image(systemName: "chevron.right")
                    .font(.caption2).foregroundColor(Theme.muted)
            }
        }
        .padding(12)
        .background(Theme.inset)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Attribution footer

    private var attributionFooter: some View {
        Text("Food data from Open Food Facts (world.openfoodfacts.org) — Open Database License (ODbL v1.0).")
            .font(.system(size: 11))
            .foregroundColor(Theme.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }
}

// MARK: - Color helper

private func calorieRingColor(_ progress: Double) -> Color {
    if progress < 0.5 { return Color(hex: "#5C9EFF") }
    if progress < 0.85 { return Theme.green }
    if progress < 1.0  { return Color(hex: "#FF9F43") }
    return Color(hex: "#FF5252")
}

// MARK: - Note editor sheet (reusable)

struct NoteEditorSheet: View {
    var title: String
    @Binding var note: String
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $note)
                    .frame(minHeight: 180)
                    .padding(12)
                    .background(Theme.inset)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Spacer()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(); dismiss() }
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Theme.green)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
            }
        }
    }
}
