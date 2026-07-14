import Foundation
import SwiftUI
import WidgetKit

private let appGroupID = "group.com.adamhoffman.adamsapple"

@MainActor
final class Store: ObservableObject {

    // Persisted state (mirrors the web app's localStorage keys)
    @Published var log: [LogEntry] = []                     { didSet { persist(log, "adamsAppleLog") } }
    @Published var workouts: [SavedWorkout] = []            { didSet { persist(workouts, "adamsAppleWorkouts") } }
    @Published var customExercises: [DBExercise] = []       { didSet { persist(customExercises, "adamsAppleCustomEx") } }
    @Published var hyroxTargets: [String: Double] = [:]     { didSet { persist(hyroxTargets, "hyroxTargets") } }
    @Published var fastConfig = FastConfig()                { didSet { persist(fastConfig, "adamsAppleFastCfg"); pushWidgetFast() } }
    @Published var fastState: FastState?                    { didSet { persist(fastState, "adamsAppleFastState"); pushWidgetFast() } }
    @Published var fastHistory: [FastRecord] = []           { didSet { persist(fastHistory, "adamsAppleFastHistory") } }

    // Progress tracking
    @Published var weights: [MetricEntry] = []             { didSet { persist(weights, "ppWeights") } }
    @Published var bodyFat: [MetricEntry] = []             { didSet { persist(bodyFat, "ppBodyFat") } }
    @Published var restingHR: [MetricEntry] = []           { didSet { persist(restingHR, "ppRestingHR") } }
    @Published var bloodPressure: [BloodPressureEntry] = [] { didSet { persist(bloodPressure, "ppBP") } }
    @Published var bloodMarkers: [BloodMarkerEntry] = []   { didSet { persist(bloodMarkers, "ppBlood") } }
    @Published var measurements: [MeasurementEntry] = []   { didSet { persist(measurements, "ppMeasure") } }
    @Published var photos: [ProgressPhoto] = []            { didSet { persist(photos, "ppPhotos") } }

    // Food tracking
    @Published var foodLogs: [DayFoodLog] = []             { didSet { persist(foodLogs, "ppFoodLogs"); pushWidgetNutrition() } }
    @Published var foodGoals = FoodGoals()                 { didSet { persist(foodGoals, "ppFoodGoals"); pushWidgetNutrition() } }
    @Published var weightUnit: WeightUnit = .grams         { didSet { persist(weightUnit, "ppWeightUnit") } }
    @Published var customFoods: [OFFFood] = []             { didSet { persist(customFoods, "ppCustomFoods") } }

    // In-memory only
    @Published var remoteExercises: [DBExercise] = []
    @Published var selectedTab = 0     // 0 Dashboard · 1 Programs · 2 Nutrition · 3 Fasting · 4 Progress · 5 Workouts

    private var loading = true

    init() {
        log             = restore("adamsAppleLog", [LogEntry].self) ?? []
        workouts        = restore("adamsAppleWorkouts", [SavedWorkout].self) ?? []
        customExercises = restore("adamsAppleCustomEx", [DBExercise].self) ?? []
        fastConfig      = restore("adamsAppleFastCfg", FastConfig.self) ?? FastConfig()
        fastState       = restore("adamsAppleFastState", FastState.self) ?? nil
        fastHistory     = restore("adamsAppleFastHistory", [FastRecord].self) ?? []

        weights       = restore("ppWeights", [MetricEntry].self) ?? []
        bodyFat       = restore("ppBodyFat", [MetricEntry].self) ?? []
        restingHR     = restore("ppRestingHR", [MetricEntry].self) ?? []
        bloodPressure = restore("ppBP", [BloodPressureEntry].self) ?? []
        bloodMarkers  = restore("ppBlood", [BloodMarkerEntry].self) ?? []
        measurements  = restore("ppMeasure", [MeasurementEntry].self) ?? []
        photos        = restore("ppPhotos", [ProgressPhoto].self) ?? []
        foodLogs      = restore("ppFoodLogs",    [DayFoodLog].self) ?? []
        foodGoals     = restore("ppFoodGoals",   FoodGoals.self)    ?? FoodGoals()
        weightUnit    = restore("ppWeightUnit",  WeightUnit.self)   ?? .grams
        customFoods   = restore("ppCustomFoods", [OFFFood].self)    ?? []

        if let saved = restore("hyroxTargets", [String: Double].self) {
            hyroxTargets = saved
        } else {
            var t: [String: Double] = [:]
            for d in AppData.hyroxDefaults { t[d.name] = d.value }
            hyroxTargets = t
        }
        loading = false
    }

    // MARK: - Persistence helpers

    private func persist<T: Encodable>(_ value: T, _ key: String) {
        guard !loading else { return }
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private func restore<T: Decodable>(_ key: String, _ type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Exercise database

    /// custom + built-in + remote, de-duplicated by name (custom wins).
    var allExercises: [DBExercise] {
        var seen = Set<String>()
        var out: [DBExercise] = []
        func add(_ list: [DBExercise]) {
            for e in list {
                let key = e.name.lowercased()
                if seen.contains(key) { continue }
                seen.insert(key)
                out.append(e)
            }
        }
        add(customExercises)
        add(AppData.builtInExercises)
        add(remoteExercises)
        return out
    }

    func fetchRemoteDB() async {
        guard remoteExercises.isEmpty else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: AppData.exerciseDBURL)
            let raw = try JSONDecoder().decode([RawExercise].self, from: data)
            self.remoteExercises = raw.map { $0.toDB(isCustom: false) }
        } catch {
            // Offline is fine — built-in library still works.
        }
    }

    func addCustomExercise(_ ex: DBExercise) {
        customExercises.insert(ex, at: 0)
    }
    func deleteExercise(_ ex: DBExercise) {
        customExercises.removeAll { $0.id == ex.id }
    }

    // MARK: - Fasting history

    func recordFast(start: Date, end: Date) {
        let record = FastRecord(start: start, end: end,
                                protocolLabel: fastConfig.label,
                                targetHours: fastConfig.hours)
        fastHistory.insert(record, at: 0)
    }

    func deleteFastRecord(_ record: FastRecord) {
        fastHistory.removeAll { $0.id == record.id }
    }

    func updateFastRecord(_ record: FastRecord) {
        if let i = fastHistory.firstIndex(where: { $0.id == record.id }) {
            fastHistory[i] = record
        }
    }

    // MARK: - Food logs

    func dayLog(for date: Date) -> DayFoodLog {
        let day = Calendar.current.startOfDay(for: date)
        return foodLogs.first { Calendar.current.startOfDay(for: $0.day) == day }
            ?? DayFoodLog(day: day)
    }

    func addFoodEntry(_ entry: FoodEntry, for date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        if let i = foodLogs.firstIndex(where: { Calendar.current.startOfDay(for: $0.day) == day }) {
            foodLogs[i].entries.append(entry)
        } else {
            var log = DayFoodLog(day: day)
            log.entries.append(entry)
            foodLogs.insert(log, at: 0)
        }
        sortFoodLogs()
    }

    func deleteFoodEntry(_ entry: FoodEntry, for date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        if let i = foodLogs.firstIndex(where: { Calendar.current.startOfDay(for: $0.day) == day }) {
            foodLogs[i].entries.removeAll { $0.id == entry.id }
        }
    }

    func updateDayNote(_ note: String, for date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        if let i = foodLogs.firstIndex(where: { Calendar.current.startOfDay(for: $0.day) == day }) {
            foodLogs[i].note = note
        } else {
            foodLogs.insert(DayFoodLog(id: UUID(), day: day, entries: [], note: note), at: 0)
            sortFoodLogs()
        }
    }

    private func sortFoodLogs() {
        foodLogs.sort { $0.day > $1.day }
    }

    // MARK: - Custom foods

    func addCustomFood(_ food: OFFFood) {
        customFoods.insert(food, at: 0)
    }
    func deleteCustomFood(_ food: OFFFood) {
        customFoods.removeAll { $0.id == food.id }
    }

    /// All foods: custom first, then bundled OFF database
    var allFoods: [OFFFood] { customFoods + AppData.offFoods }

    /// Unit formatting helpers
    func formatWeight(_ grams: Double) -> String {
        let val = grams / weightUnit.toGrams
        return val.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(val))\(weightUnit.rawValue)"
            : String(format: "%.1f\(weightUnit.rawValue)", val)
    }

    // MARK: - Log

    func addLog(_ entry: LogEntry) {
        log.insert(entry, at: 0)
    }
    func clearLog() { log.removeAll() }

    func hasHistory(_ name: String) -> Bool {
        log.contains { $0.exercise.lowercased() == name.lowercased() }
    }
    func history(for name: String) -> [LogEntry] {
        log.filter { $0.exercise.lowercased() == name.lowercased() }
           .sorted { $0.date < $1.date }
    }

    // MARK: - Programs

    func createWorkout(name: String) -> SavedWorkout {
        let w = SavedWorkout(name: name)
        workouts.insert(w, at: 0)
        return w
    }
    func deleteWorkout(_ w: SavedWorkout) {
        workouts.removeAll { $0.id == w.id }
    }
    func update(_ w: SavedWorkout) {
        if let i = workouts.firstIndex(where: { $0.id == w.id }) { workouts[i] = w }
    }

    // MARK: - Stats

    var exercisesDone: Int { log.count }

    var streak: Int {
        guard !log.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(log.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        guard let newest = days.first else { return 0 }
        let today = cal.startOfDay(for: Date())
        // Streak only counts if the latest log is today or yesterday.
        let gap = cal.dateComponents([.day], from: newest, to: today).day ?? 99
        if gap > 1 { return 0 }
        var streak = 0
        var cursor = newest
        for day in days {
            if day == cursor {
                streak += 1
                cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Hyrox

    func hyroxNote(for stationName: String) -> String {
        guard let def = AppData.hyroxDefaults.first(where: { $0.name == stationName }) else { return "" }
        let val = hyroxTargets[stationName] ?? def.value
        let pct = Int((val / def.max) * 100)
        let atRace = val >= def.max
        return "\(fmtNum(val))\(def.unit)\(atRace ? " ✓" : " (\(pct)%)")"
    }
    func setHyroxTarget(_ name: String, _ value: Double) {
        guard let def = AppData.hyroxDefaults.first(where: { $0.name == name }) else { return }
        hyroxTargets[name] = min(value, def.max)
    }

    func fmtNum(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }

    // MARK: - Widget data sync

    private func pushWidgetFast() {
        guard !loading else { return }
        let ud = UserDefaults(suiteName: appGroupID)
        ud?.set(fastConfig.hours, forKey: "widget.fastHours")
        if let state = fastState,
           let data = try? JSONEncoder().encode(state.start) {
            ud?.set(data, forKey: "widget.fastStart")
        } else {
            ud?.removeObject(forKey: "widget.fastStart")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func pushWidgetNutrition() {
        guard !loading else { return }
        let today = dayLog(for: Date()).entries
        let ud = UserDefaults(suiteName: appGroupID)
        ud?.set(today.reduce(0.0) { $0 + $1.calories }, forKey: "widget.calories")
        ud?.set(today.reduce(0.0) { $0 + $1.protein },  forKey: "widget.protein")
        ud?.set(today.reduce(0.0) { $0 + $1.fat },      forKey: "widget.fat")
        ud?.set(today.reduce(0.0) { $0 + $1.carbs },    forKey: "widget.carbs")
        ud?.set(foodGoals.calories,                      forKey: "widget.calGoal")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
