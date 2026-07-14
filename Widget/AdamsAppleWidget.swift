import WidgetKit
import SwiftUI

// MARK: - Shared data keys (must match Store.swift)

private let appGroup = "group.com.adamhoffman.adamsapple"

struct SharedData {
    // Fasting
    var fastEnd: Date?      // nil = not fasting
    var fastHours: Double
    // Nutrition
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
    var calGoal: Double

    init() {
        let ud = UserDefaults(suiteName: appGroup)
        if let data = ud?.data(forKey: "widget.fastStart"),
           let start = try? JSONDecoder().decode(Date.self, from: data) {
            let hours = ud?.double(forKey: "widget.fastHours") ?? 16
            let end = start.addingTimeInterval(hours * 3600)
            fastEnd = end > Date() ? end : nil
        }
        fastHours = ud?.double(forKey: "widget.fastHours") ?? 16
        calories  = ud?.double(forKey: "widget.calories")  ?? 0
        protein   = ud?.double(forKey: "widget.protein")   ?? 0
        fat       = ud?.double(forKey: "widget.fat")       ?? 0
        carbs     = ud?.double(forKey: "widget.carbs")     ?? 0
        calGoal   = ud?.double(forKey: "widget.calGoal")   ?? 2000
    }
}

// MARK: - Timeline provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), data: SharedData())
    }
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: Date(), data: SharedData()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let data = SharedData()
        let entry = WidgetEntry(date: .now, data: data)
        // Schedule next refresh when the fast ends (so "not fasting" state shows),
        // or in 15 min if idle. The countdown itself ticks via Text(.timer) — no
        // per-second timeline entries needed.
        let policy: TimelineReloadPolicy = data.fastEnd.map { .after($0) } ?? .after(.now.addingTimeInterval(900))
        completion(Timeline(entries: [entry], policy: policy))
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let data: SharedData
}

// MARK: - Widget view

struct AdamsAppleWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        HStack(spacing: 0) {
            fastingPanel
            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.vertical, 12)
            nutritionPanel
        }
        .containerBackground(Color.black, for: .widget)
    }

    // MARK: Fasting half

    private var fastingPanel: some View {
        let data = entry.data
        let accent = data.fastEnd != nil
            ? Color(red: 0.3, green: 0.69, blue: 0.31)
            : Color(white: 0.5)

        return VStack(alignment: .center, spacing: 4) {
            Label("Fasting", systemImage: "hourglass")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(white: 0.6))

            if let end = data.fastEnd {
                // Text(.timer) ticks every second automatically — no timeline reload needed
                Text(end, style: .timer)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("remaining")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.5))
            } else {
                Text(String(format: "%02d:00:00", Int(data.fastHours)))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("not fasting")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Nutrition half

    private var nutritionPanel: some View {
        let data = entry.data
        let hasFood = data.calories > 0
        let accent = hasFood ? Color(red: 0.3, green: 0.69, blue: 0.31) : Color(white: 0.5)

        return VStack(alignment: .center, spacing: 4) {
            Label("Nutrition", systemImage: "fork.knife")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(white: 0.6))
            Text("\(Int(data.calories))")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("kcal")
                .font(.system(size: 10))
                .foregroundColor(Color(white: 0.5))
            if hasFood {
                Text("P\(Int(data.protein)) F\(Int(data.fat)) C\(Int(data.carbs))")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color(white: 0.45))
            } else {
                Text("of \(Int(data.calGoal)) goal")
                    .font(.system(size: 9))
                    .foregroundColor(Color(white: 0.45))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget declaration

@main
struct AdamsAppleWidget: Widget {
    let kind = "AdamsAppleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AdamsAppleWidgetView(entry: entry)
        }
        .configurationDisplayName("Adams Apple")
        .description("Fasting countdown and today's calories.")
        .supportedFamilies([.systemMedium])
    }
}
