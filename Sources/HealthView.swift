import SwiftUI

struct HealthView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetricSectionCard(
                    title: "Weight", unit: "lbs", icon: "scalemass.fill",
                    entries: store.weights,
                    onAdd: { d, v in store.weights.append(MetricEntry(date: d, value: v)) },
                    onDelete: { e in store.weights.removeAll { $0.id == e.id } }
                )
                MetricSectionCard(
                    title: "Body Fat", unit: "%", icon: "percent",
                    entries: store.bodyFat,
                    onAdd: { d, v in store.bodyFat.append(MetricEntry(date: d, value: v)) },
                    onDelete: { e in store.bodyFat.removeAll { $0.id == e.id } }
                )
                MetricSectionCard(
                    title: "Resting Heart Rate", unit: "bpm", icon: "heart.fill",
                    entries: store.restingHR,
                    onAdd: { d, v in store.restingHR.append(MetricEntry(date: d, value: v)) },
                    onDelete: { e in store.restingHR.removeAll { $0.id == e.id } }
                )
                BloodPressureCard()
                MeasurementsCard()
                BloodWorkCard()
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Health")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Single-value metric card (weight, body fat, resting HR)

struct MetricSectionCard: View {
    @EnvironmentObject var store: Store
    var title: String
    var unit: String
    var icon: String
    var entries: [MetricEntry]
    var onAdd: (Date, Double) -> Void
    var onDelete: (MetricEntry) -> Void

    @State private var showAdd = false
    @State private var showHistory = false

    private var sortedDesc: [MetricEntry] { entries.sorted { $0.date > $1.date } }
    private var chronological: [Double] { entries.sorted { $0.date < $1.date }.map(\.value) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon).font(.headline)
                Spacer()
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
            }

            if let latest = sortedDesc.first {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(store.fmtNum(latest.value)).font(.system(size: 30, weight: .bold)).foregroundColor(Theme.green)
                    Text(unit).font(.subheadline).foregroundColor(Theme.muted)
                    Spacer()
                    Text(dateStr(latest.date)).font(.caption).foregroundColor(Theme.muted)
                }
                if chronological.count > 1 {
                    TrendLineChart(values: chronological).frame(height: 80)
                }
                DisclosureGroup("History (\(entries.count))", isExpanded: $showHistory) {
                    ForEach(sortedDesc) { e in
                        HStack {
                            Text(dateStr(e.date)).font(.subheadline).foregroundColor(Theme.muted)
                            Spacer()
                            Text("\(store.fmtNum(e.value)) \(unit)").font(.subheadline.weight(.semibold))
                            Button { onDelete(e) } label: {
                                Image(systemName: "trash").font(.caption).foregroundColor(Theme.red)
                            }.padding(.leading, 8)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .tint(Theme.green)
            } else {
                Text("No entries yet — tap + to add your first.").font(.subheadline).foregroundColor(Theme.muted)
            }
        }
        .card()
        .sheet(isPresented: $showAdd) {
            AddSingleValueSheet(title: title, unit: unit) { d, v in onAdd(d, v) }
        }
    }
}

// MARK: - Blood pressure

struct BloodPressureCard: View {
    @EnvironmentObject var store: Store
    @State private var showAdd = false
    @State private var showHistory = false

    private var sortedDesc: [BloodPressureEntry] { store.bloodPressure.sorted { $0.date > $1.date } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Blood Pressure", systemImage: "waveform.path.ecg").font(.headline)
                Spacer()
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
            }
            if let latest = sortedDesc.first {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(latest.systolic)/\(latest.diastolic)").font(.system(size: 30, weight: .bold)).foregroundColor(Theme.green)
                    Text("mmHg").font(.subheadline).foregroundColor(Theme.muted)
                    Spacer()
                    Text(dateStr(latest.date)).font(.caption).foregroundColor(Theme.muted)
                }
                DisclosureGroup("History (\(store.bloodPressure.count))", isExpanded: $showHistory) {
                    ForEach(sortedDesc) { e in
                        HStack {
                            Text(dateStr(e.date)).font(.subheadline).foregroundColor(Theme.muted)
                            Spacer()
                            Text("\(e.systolic)/\(e.diastolic)").font(.subheadline.weight(.semibold))
                            Button { store.bloodPressure.removeAll { $0.id == e.id } } label: {
                                Image(systemName: "trash").font(.caption).foregroundColor(Theme.red)
                            }.padding(.leading, 8)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .tint(Theme.green)
            } else {
                Text("No readings yet — tap + to add one.").font(.subheadline).foregroundColor(Theme.muted)
            }
        }
        .card()
        .sheet(isPresented: $showAdd) {
            AddBloodPressureSheet { d, s, dia in
                store.bloodPressure.append(BloodPressureEntry(date: d, systolic: s, diastolic: dia))
            }
        }
    }
}

// MARK: - Body measurements

struct MeasurementsCard: View {
    @EnvironmentObject var store: Store
    @State private var showAdd = false

    private func latest(for site: String) -> MeasurementEntry? {
        store.measurements.filter { $0.site == site }.sorted { $0.date > $1.date }.first
    }
    private var usedSites: [String] {
        BodySites.all.filter { site in store.measurements.contains { $0.site == site } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Body Measurements", systemImage: "ruler.fill").font(.headline)
                Spacer()
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
            }
            if usedSites.isEmpty {
                Text("No measurements yet — tap + to add one.").font(.subheadline).foregroundColor(Theme.muted)
            } else {
                ForEach(usedSites, id: \.self) { site in
                    if let e = latest(for: site) {
                        HStack {
                            Text(site).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(store.fmtNum(e.value)) in").foregroundColor(Theme.green)
                            Text(dateStr(e.date)).font(.caption).foregroundColor(Theme.muted)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .card()
        .sheet(isPresented: $showAdd) {
            AddMeasurementSheet { d, site, v in
                store.measurements.append(MeasurementEntry(date: d, site: site, value: v))
            }
        }
    }
}

// MARK: - Blood work panel

struct BloodWorkCard: View {
    @EnvironmentObject var store: Store
    @State private var showAdd = false

    private func latest(for marker: String) -> BloodMarkerEntry? {
        store.bloodMarkers.filter { $0.marker == marker }.sorted { $0.date > $1.date }.first
    }
    private var usedMarkers: [String] {
        BloodPanel.common.map(\.name).filter { name in store.bloodMarkers.contains { $0.marker == name } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Blood Work", systemImage: "drop.fill").font(.headline)
                Spacer()
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
            }
            if usedMarkers.isEmpty {
                Text("Log results from a blood test — A1C, cholesterol, glucose & more.")
                    .font(.subheadline).foregroundColor(Theme.muted)
            } else {
                ForEach(usedMarkers, id: \.self) { marker in
                    if let e = latest(for: marker) {
                        HStack {
                            Text(marker).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(store.fmtNum(e.value)) \(BloodPanel.unit(for: marker))").foregroundColor(Theme.green)
                            Text(dateStr(e.date)).font(.caption).foregroundColor(Theme.muted)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .card()
        .sheet(isPresented: $showAdd) {
            AddBloodMarkerSheet { d, marker, v in
                store.bloodMarkers.append(BloodMarkerEntry(date: d, marker: marker, value: v))
            }
        }
    }
}

// MARK: - Add sheets

private func dateStr(_ d: Date) -> String {
    let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: d)
}

struct AddSingleValueSheet: View {
    @Environment(\.dismiss) private var dismiss
    var title: String
    var unit: String
    var onSave: (Date, Double) -> Void
    @State private var date = Date()
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                HStack {
                    TextField("Value", text: $value).keyboardType(.decimalPad)
                    Text(unit).foregroundColor(Theme.muted)
                }
            }
            .navigationTitle("Add \(title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if let v = Double(value) { onSave(date, v) }; dismiss() }
                        .disabled(Double(value) == nil)
                }
            }
        }
    }
}

struct AddBloodPressureSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Date, Int, Int) -> Void
    @State private var date = Date()
    @State private var sys = ""
    @State private var dia = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Systolic (top)", text: $sys).keyboardType(.numberPad)
                TextField("Diastolic (bottom)", text: $dia).keyboardType(.numberPad)
            }
            .navigationTitle("Add Blood Pressure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let s = Int(sys), let d = Int(dia) { onSave(date, s, d) }
                        dismiss()
                    }
                    .disabled(Int(sys) == nil || Int(dia) == nil)
                }
            }
        }
    }
}

struct AddMeasurementSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Date, String, Double) -> Void
    @State private var date = Date()
    @State private var site = BodySites.all[0]
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Site", selection: $site) {
                    ForEach(BodySites.all, id: \.self) { Text($0).tag($0) }
                }
                HStack {
                    TextField("Measurement", text: $value).keyboardType(.decimalPad)
                    Text("in").foregroundColor(Theme.muted)
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if let v = Double(value) { onSave(date, site, v) }; dismiss() }
                        .disabled(Double(value) == nil)
                }
            }
        }
    }
}

struct AddBloodMarkerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Date, String, Double) -> Void
    @State private var date = Date()
    @State private var marker = BloodPanel.common[0].name
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Marker", selection: $marker) {
                    ForEach(BloodPanel.common.map(\.name), id: \.self) { Text($0).tag($0) }
                }
                HStack {
                    TextField("Result", text: $value).keyboardType(.decimalPad)
                    Text(BloodPanel.unit(for: marker)).foregroundColor(Theme.muted)
                }
            }
            .navigationTitle("Add Blood Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if let v = Double(value) { onSave(date, marker, v) }; dismiss() }
                        .disabled(Double(value) == nil)
                }
            }
        }
    }
}
