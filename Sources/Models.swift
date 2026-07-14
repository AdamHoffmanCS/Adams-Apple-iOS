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

struct FastRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var start: Date
    var end: Date
    var protocolLabel: String  // e.g. "16:8"
    var targetHours: Double
    var note: String = ""

    var durationSeconds: TimeInterval { end.timeIntervalSince(start) }
    var durationHours: Double { durationSeconds / 3600 }
    var completed: Bool { durationHours >= targetHours }
}

// MARK: - Food Tracking

/// A food from Open Food Facts (values per 100g, convert at use-time).
struct OFFFood: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String        // 'n'
    var kcal100g: Double    // 'c'
    var protein100g: Double // 'p'
    var fat100g: Double     // 'f'
    var carbs100g: Double   // 'b'
    var barcode: String?    // 'k' (optional)
    var isCustom: Bool = false

    enum CodingKeys: String, CodingKey {
        case name = "n"; case kcal100g = "c"; case protein100g = "p"
        case fat100g = "f"; case carbs100g = "b"; case barcode = "k"
        case isCustom = "u"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name        = try c.decode(String.self,   forKey: .name)
        kcal100g    = try c.decode(Double.self,   forKey: .kcal100g)
        protein100g = try c.decode(Double.self,   forKey: .protein100g)
        fat100g     = try c.decode(Double.self,   forKey: .fat100g)
        carbs100g   = try c.decode(Double.self,   forKey: .carbs100g)
        barcode     = try c.decodeIfPresent(String.self, forKey: .barcode)
        isCustom    = try c.decodeIfPresent(Bool.self,   forKey: .isCustom) ?? false
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name,        forKey: .name)
        try c.encode(kcal100g,    forKey: .kcal100g)
        try c.encode(protein100g, forKey: .protein100g)
        try c.encode(fat100g,     forKey: .fat100g)
        try c.encode(carbs100g,   forKey: .carbs100g)
        try c.encodeIfPresent(barcode, forKey: .barcode)
        if isCustom { try c.encode(true, forKey: .isCustom) }
    }

    /// Initializer for custom user-created foods and live API results.
    init(name: String, kcal100g: Double, protein100g: Double, fat100g: Double,
         carbs100g: Double, barcode: String? = nil, isCustom: Bool = true) {
        self.name = name; self.kcal100g = kcal100g; self.protein100g = protein100g
        self.fat100g = fat100g; self.carbs100g = carbs100g; self.barcode = barcode
        self.isCustom = isCustom
    }
}

enum WeightUnit: String, Codable, CaseIterable {
    case grams = "g"
    case ounces = "oz"
    case pounds = "lbs"
    case kilograms = "kg"

    var toGrams: Double {
        switch self {
        case .grams:     return 1.0
        case .ounces:    return 28.3495
        case .pounds:    return 453.592
        case .kilograms: return 1000.0
        }
    }
    var label: String {
        switch self {
        case .grams:     return "Grams (g)"
        case .ounces:    return "Ounces (oz)"
        case .pounds:    return "Pounds (lbs)"
        case .kilograms: return "Kilograms (kg)"
        }
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch     = "Lunch"
    case dinner    = "Dinner"
    case snack     = "Snack"
}

struct FoodEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var foodName: String
    var grams: Double           // stored in grams; display converts via user's unit pref
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
    var mealType: MealType
}

struct DayFoodLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var day: Date          // startOfDay
    var entries: [FoodEntry] = []
    var note: String = ""
}

struct FoodGoals: Codable {
    var calories: Double = 2000
    var protein: Double  = 150
    var fat: Double      = 65
    var carbs: Double    = 250
}
