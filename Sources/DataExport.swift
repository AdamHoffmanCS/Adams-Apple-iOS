import SwiftUI
import UIKit

/// Everything the app persists, bundled into a single JSON backup file.
struct AppBackup: Codable {
    var exportDate: Date = Date()
    var appVersion: String =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var workoutLog: [LogEntry]
    var workouts: [SavedWorkout]
    var customExercises: [DBExercise]
    var hyroxTargets: [String: Double]
    var fastConfig: FastConfig
    var fastState: FastState?
    var fastHistory: [FastRecord]
    var weights: [MetricEntry]
    var bodyFat: [MetricEntry]
    var restingHR: [MetricEntry]
    var bloodPressure: [BloodPressureEntry]
    var bloodMarkers: [BloodMarkerEntry]
    var measurements: [MeasurementEntry]
    var photos: [ProgressPhoto]
    var foodLogs: [DayFoodLog]
    var foodGoals: FoodGoals
    var customFoods: [OFFFood]
}

extension Store {
    /// Writes a full JSON backup to a temporary file and returns its URL for sharing.
    func exportAllData() throws -> URL {
        let backup = AppBackup(
            workoutLog: log,
            workouts: workouts,
            customExercises: customExercises,
            hyroxTargets: hyroxTargets,
            fastConfig: fastConfig,
            fastState: fastState,
            fastHistory: fastHistory,
            weights: weights,
            bodyFat: bodyFat,
            restingHR: restingHR,
            bloodPressure: bloodPressure,
            bloodMarkers: bloodMarkers,
            measurements: measurements,
            photos: photos,
            foodLogs: foodLogs,
            foodGoals: foodGoals,
            customFoods: customFoods
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AdamsApple-Backup-\(df.string(from: Date())).json")
        try data.write(to: url, options: .atomic)
        return url
    }
}

/// UIKit share-sheet wrapper (lets us generate the file only when tapped).
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
