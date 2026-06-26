import Foundation

// MARK: - Logging

struct LogEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var exercise: String
    var sets: Int
    var reps: Int
    var weight: Double?
    var date: Date = Date()
}

// MARK: - Custom Programs (the "My Workouts" builder)

struct ProgramExercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var sets: Int?
    var reps: String?     // free text, e.g. "8-12"
    var notes: String?
}

struct SavedWorkout: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var exercises: [ProgramExercise] = []
    var createdAt: Date = Date()
}

// MARK: - Exercise database (built-in + custom + remote)

struct DBExercise: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var category: String                 // strength / cardio / stretching / plyometrics / ...
    var level: String?
    var equipment: String?
    var primaryMuscles: [String] = []
    var secondaryMuscles: [String] = []
    var instructions: [String] = []
    var suggestedSets: Int?
    var suggestedReps: String?
    var youtube: String?
    var isCustom: Bool = false

    /// One of the workout-category tabs used in the picker / Programs grid.
    var pickerCategory: String {
        switch category.lowercased() {
        case "cardio":      return "cardio"
        case "stretching":  return "flexibility"
        case "plyometrics": return "hiit"
        default:            return "strength"
        }
    }
}

/// Decoder for entries that come from the bundled `builtinExercises.json`
/// (which has no `id`) and from the remote free-exercise-db.
struct RawExercise: Decodable {
    var id: String?
    var name: String
    var category: String?
    var level: String?
    var equipment: String?
    var primaryMuscles: [String]?
    var secondaryMuscles: [String]?
    var instructions: [String]?
    var suggestedSets: Int?
    var suggestedReps: String?
    var youtube: String?

    func toDB(isCustom: Bool = false) -> DBExercise {
        DBExercise(
            id: id ?? name.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: name,
            category: category ?? "strength",
            level: level,
            equipment: equipment,
            primaryMuscles: primaryMuscles ?? [],
            secondaryMuscles: secondaryMuscles ?? [],
            instructions: instructions ?? [],
            suggestedSets: suggestedSets,
            suggestedReps: suggestedReps,
            youtube: youtube,
            isCustom: isCustom
        )
    }
}

// MARK: - Hyrox

struct HyroxStation: Codable, Hashable {
    var name: String
    var note: String
}

struct HyroxDefault: Codable, Hashable {
    var name: String
    var value: Double
    var unit: String
    var max: Double
}

// MARK: - Fasting

struct FastConfig: Codable, Equatable {
    var hours: Double = 16
    var eat: Double? = 8

    var label: String {
        if let eat = eat {
            return "\(fmt(hours)):\(fmt(eat))"
        }
        return "\(fmt(hours))h"
    }
    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
    }
}

struct FastState: Codable, Equatable {
    var start: Date
}
