import Foundation

/// Single-value, dated metric (weight, body-fat %, resting HR, …).
struct MetricEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date = Date()
    var value: Double
}

struct BloodPressureEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date = Date()
    var systolic: Int
    var diastolic: Int
}

struct BloodMarkerEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date = Date()
    var marker: String     // e.g. "A1C"
    var value: Double
}

struct MeasurementEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date = Date()
    var site: String       // Waist, Chest, …
    var value: Double      // inches
}

struct ProgressPhoto: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date = Date()
    var filename: String    // stored in Documents/ProgressPhotos
    var note: String?
}

enum BloodPanel {
    /// Common blood-test markers with their typical units.
    static let common: [(name: String, unit: String)] = [
        ("A1C", "%"),
        ("Total Cholesterol", "mg/dL"),
        ("LDL", "mg/dL"),
        ("HDL", "mg/dL"),
        ("Triglycerides", "mg/dL"),
        ("Fasting Glucose", "mg/dL"),
        ("Vitamin D", "ng/mL"),
        ("TSH", "mIU/L")
    ]
    static func unit(for marker: String) -> String {
        common.first { $0.name == marker }?.unit ?? ""
    }
}

enum BodySites {
    static let all = ["Waist", "Chest", "Arms", "Thighs", "Hips", "Shoulders", "Calves", "Neck"]
}
