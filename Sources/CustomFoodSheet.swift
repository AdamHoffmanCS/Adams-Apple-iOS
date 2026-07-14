import SwiftUI

struct CustomFoodSheet: View {
    var onSave: (OFFFood) -> Void

    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var barcode = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(kcal) != nil
            && Double(protein) != nil
            && Double(fat) != nil
            && Double(carbs) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Food Info").font(.title3.weight(.semibold))
                        field("Food Name", placeholder: "e.g. Grandma's Protein Bar", text: $name)
                        field("Barcode (optional)", placeholder: "Scan or type barcode", text: $barcode)
                            .keyboardType(.numberPad)
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Nutrition per 100g").font(.title3.weight(.semibold))
                        Text("All values are per 100 grams of the food.")
                            .font(.subheadline).foregroundColor(Theme.muted)
                        field("Calories (kcal)", placeholder: "e.g. 250", text: $kcal)
                            .keyboardType(.decimalPad)
                        field("Protein (g)", placeholder: "e.g. 20", text: $protein)
                            .keyboardType(.decimalPad)
                        field("Fat (g)", placeholder: "e.g. 8", text: $fat)
                            .keyboardType(.decimalPad)
                        field("Carbohydrates (g)", placeholder: "e.g. 30", text: $carbs)
                            .keyboardType(.decimalPad)
                    }
                    .card()

                    if !store.customFoods.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Custom Foods").font(.title3.weight(.semibold))
                            ForEach(store.customFoods) { food in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(food.name).font(.system(size: 14, weight: .semibold))
                                        Text(String(format: "%.0f kcal · P %.1fg · F %.1fg · C %.1fg per 100g",
                                                    food.kcal100g, food.protein100g, food.fat100g, food.carbs100g))
                                            .font(.caption).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Theme.inset)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        store.deleteCustomFood(food)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .card()
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Custom Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Theme.green)
                        .disabled(!isValid).opacity(isValid ? 1 : 0.4)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
            }
        }
    }

    @ViewBuilder
    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(Theme.muted)
            TextField(placeholder, text: text)
                .padding(10)
                .background(Theme.inset)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
        }
    }

    private func save() {
        let food = OFFFood(
            name: name.trimmingCharacters(in: .whitespaces),
            kcal100g:    Double(kcal)    ?? 0,
            protein100g: Double(protein) ?? 0,
            fat100g:     Double(fat)     ?? 0,
            carbs100g:   Double(carbs)   ?? 0,
            barcode:     barcode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : barcode.trimmingCharacters(in: .whitespaces)
        )
        onSave(food)
        dismiss()
    }
}
