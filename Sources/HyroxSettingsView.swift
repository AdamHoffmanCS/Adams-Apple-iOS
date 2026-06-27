import SwiftUI

struct HyroxSettingsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var values: [String: String] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Set your current training targets. Full race standard shown for reference.")
                        .font(.subheadline).foregroundColor(Theme.muted)

                    ForEach(AppData.hyroxDefaults, id: \.name) { def in
                        let current = Double(values[def.name] ?? "") ?? (store.hyroxTargets[def.name] ?? def.value)
                        let pct = min(1.0, current / def.max)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(def.name).font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Text("/ \(store.fmtNum(def.max))\(def.unit)")
                                    .font(.caption).foregroundColor(Theme.muted)
                            }
                            ProgressView(value: pct).tint(Theme.green)
                            HStack {
                                TextField("\(store.fmtNum(def.value))",
                                          text: Binding(
                                            get: { values[def.name] ?? store.fmtNum(store.hyroxTargets[def.name] ?? def.value) },
                                            set: { values[def.name] = $0 }))
                                    .keyboardType(.decimalPad)
                                    .padding(8)
                                    .background(Theme.inset)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .frame(width: 100)
                                Text(def.unit).foregroundColor(Theme.muted)
                                Spacer()
                            }
                        }
                        .padding(14)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border))
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("⚙️ Race Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
    }

    private func save() {
        for def in AppData.hyroxDefaults {
            if let raw = values[def.name], let v = Double(raw), v > 0 {
                store.setHyroxTarget(def.name, v)
            }
        }
        dismiss()
    }
}
