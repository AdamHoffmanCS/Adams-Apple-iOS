import Foundation

/// Loads the bundled JSON that was extracted verbatim from the web app,
/// so the native app has identical built-in content.
enum AppData {

    static func loadJSON<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// category -> [exercise name], e.g. strength/cardio/flexibility/hiit/hyrox
    static let categoryExercises: [String: [String]] =
        loadJSON("exerciseData", as: [String: [String]].self) ?? [:]

    static let hyroxStations: [HyroxStation] =
        loadJSON("hyroxStations", as: [HyroxStation].self) ?? []

    static let hyroxTraining: [String] =
        loadJSON("hyroxTraining", as: [String].self) ?? []

    static let hyroxDefaults: [HyroxDefault] =
        loadJSON("hyroxDefaults", as: [HyroxDefault].self) ?? []

    static let builtInExercises: [DBExercise] = {
        let raw = loadJSON("builtinExercises", as: [RawExercise].self) ?? []
        return raw.map { $0.toDB(isCustom: false) }
    }()

    static let exerciseDBURL =
        URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json")!

    /// Open Food Facts database (per-100g macros). Loaded once at startup.
    /// This app uses data from Open Food Facts (https://world.openfoodfacts.org),
    /// made available under the Open Database License (ODbL v1.0).
    static let offFoods: [OFFFood] = {
        guard let url = Bundle.main.url(forResource: "offFoods", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let foods = try? JSONDecoder().decode([OFFFood].self, from: data) else { return [] }
        return foods
    }()

    /// Barcode → food lookup (built lazily from offFoods)
    static let offByBarcode: [String: OFFFood] = {
        var map: [String: OFFFood] = [:]
        for food in offFoods {
            if let code = food.barcode { map[code] = food }
        }
        return map
    }()

    /// Category tabs for the exercise database filter (mirrors the web filter row).
    static let dbFilters: [(key: String, label: String)] = [
        ("all", "All"), ("chest", "Chest"), ("back", "Back"), ("shoulders", "Shoulders"),
        ("biceps", "Biceps"), ("triceps", "Triceps"), ("quadriceps", "Quads"),
        ("hamstrings", "Hamstrings"), ("glutes", "Glutes"), ("abdominals", "Core"),
        ("lats", "Lats"), ("calves", "Calves"), ("cardio", "Cardio")
    ]

    /// The five program categories shown on the Programs grid.
    static let programCategories: [(key: String, icon: String, title: String, subtitle: String)] = [
        ("strength",    "figure.strengthtraining.traditional", "Strength",    "Build muscle and power"),
        ("cardio",      "figure.run",                          "Cardio",      "Boost your endurance"),
        ("flexibility", "figure.cooldown",                     "Flexibility", "Stretch and recover"),
        ("hiit",        "bolt.fill",                           "HIIT",        "High-intensity intervals"),
        ("hyrox",       "trophy.fill",                         "Hyrox",       "8 stations · 8km run · race-ready")
    ]
}
