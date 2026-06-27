import Foundation
import SwiftUI

@MainActor
final class Store: ObservableObject {

    // Persisted state (mirrors the web app's localStorage keys)
    @Published var log: [LogEntry] = []                     { didSet { persist(log, "adamsAppleLog") } }
    @Published var workouts: [SavedWorkout] = []            { didSet { persist(workouts, "adamsAppleWorkouts") } }
    @Published var customExercises: [DBExercise] = []       { didSet { persist(customExercises, "adamsAppleCustomEx") } }
    @Published var hyroxTargets: [String: Double] = [:]     { didSet { persist(hyroxTargets, "hyroxTargets") } }
    @Published var fastConfig = FastConfig()                { didSet { persist(fastConfig, "adamsAppleFastCfg") } }
    @Published var fastState: FastState?                    { didSet { persist(fastState, "adamsAppleFastState") } }

    // Progress tracking
    @Published var weights: [MetricEntry] = []             { didSet { persist(weights, "ppWeights") } }
    @Published var bodyFat: [MetricEntry] = []             { didSet { persist(bodyFat, "ppBodyFat") } }
    @Published var restingHR: [MetricEntry] = []           { didSet { persist(restingHR, "ppRestingHR") } }
    @Published var bloodPressure: [BloodPressureEntry] = [] { didSet { persist(bloodPressure, "ppBP") } }
    @Published var bloodMarkers: [BloodMarkerEntry] = []   { didSet { persist(bloodMarkers, "ppBlood") } }
    @Published var measurements: [MeasurementEntry] = []   { didSet { persist(measurements, "ppMeasure") } }
    @Published var photos: [ProgressPhoto] = []            { didSet { persist(photos, "ppPhotos") } }

    // In-memory only
    @Published var remoteExercises: [DBExercise] = []
    @Published var selectedTab = 0     // 0 Dashboard · 1 Programs · 2 Workouts · 3 Fasting · 4 Log

    private var loading = true

    init() {
        log             = restore("adamsAppleLog", [LogEntry].self) ?? []
        workouts        = restore("adamsAppleWorkouts", [SavedWorkout].self) ?? []
        customExercises = restore("adamsAppleCustomEx", [DBExercise].self) ?? []
        fastConfig      = restore("adamsAppleFastCfg", FastConfig.self) ?? FastConfig()
        fastState       = restore("adamsAppleFastState", FastState.self) ?? nil

        weights       = restore("ppWeights", [MetricEntry].self) ?? []
        bodyFat       = restore("ppBodyFat", [MetricEntry].self) ?? []
        restingHR     = restore("ppRestingHR", [MetricEntry].self) ?? []
        bloodPressure = restore("ppBP", [BloodPressureEntry].self) ?? []
        bloodMarkers  = restore("ppBlood", [BloodMarkerEntry].self) ?? []
        measurements  = restore("ppMeasure", [MeasurementEntry].self) ?? []
        photos        = restore("ppPhotos", [ProgressPhoto].self) ?? []

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
}
