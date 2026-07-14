import SwiftUI

struct AddFoodEntrySheet: View {
    var onAdd: (FoodEntry) -> Void

    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var selected: OFFFood? = nil
    @State private var amountText = ""
    @State private var mealType: MealType = .lunch
    @State private var showScanner = false
    @State private var showCustomFood = false
    @State private var scanError: String? = nil
    @State private var isLookingUp = false

    private var results: [OFFFood] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2 else { return [] }
        return store.allFoods
            .filter { $0.name.lowercased().contains(q) }
            .prefix(40).map { $0 }
    }

    private var amount: Double { Double(amountText) ?? 0 }
    private var grams: Double { amount * store.weightUnit.toGrams }

    private var preview: (cal: Double, p: Double, f: Double, c: Double)? {
        guard let food = selected, grams > 0 else { return nil }
        let factor = grams / 100.0
        return (food.kcal100g * factor, food.protein100g * factor,
                food.fat100g * factor, food.carbs100g * factor)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    searchSection
                    if selected != nil { entrySection }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEntry() }
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Theme.green)
                        .disabled(selected == nil || amount <= 0)
                        .opacity((selected == nil || amount <= 0) ? 0.4 : 1)
                }
            }
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView { code in
                handleBarcode(code)
            }
        }
        .sheet(isPresented: $showCustomFood) {
            CustomFoodSheet { food in
                store.addCustomFood(food)
                selected = food
                query = food.name
            }
            .environmentObject(store)
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Food").font(.title3.weight(.semibold))
                Spacer()
                Button {
                    showScanner = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "barcode.viewfinder")
                        Text("Scan").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Theme.green)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.greenLight.opacity(0.6))
                    .clipShape(Capsule())
                }
            }

            if isLookingUp {
                HStack(spacing: 8) {
                    ProgressView().tint(Theme.green)
                    Text("Looking up barcode…")
                        .font(.caption).foregroundColor(Theme.muted)
                }
            } else if let err = scanError {
                Text(err).font(.caption).foregroundColor(Theme.red)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
                TextField("Search 100,000+ foods…", text: $query)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button { query = ""; selected = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted)
                    }
                }
            }
            .padding(12)
            .background(Theme.inset)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))

            if let sel = selected {
                selectedFoodBadge(sel)
            } else if query.count >= 2 {
                if results.isEmpty {
                    VStack(spacing: 10) {
                        Text("No results for \"\(query)\"")
                            .font(.subheadline).foregroundColor(Theme.muted)
                        Button {
                            showCustomFood = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create custom food")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.green)
                        }
                    }
                    .padding(.top, 4)
                } else {
                    VStack(spacing: 6) {
                        ForEach(results) { food in
                            Button { selected = food; query = food.name } label: {
                                resultRow(food)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Custom food shortcut
            Button {
                showCustomFood = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                    Text("Create a custom food")
                    Spacer()
                }
                .font(.system(size: 14))
                .foregroundColor(Theme.muted)
            }
        }
        .card()
    }

    private func resultRow(_ food: OFFFood) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if food.isCustom {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.green)
                    }
                    Text(food.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.text)
                        .multilineTextAlignment(.leading)
                }
                Text(String(format: "%.0f kcal · P %.1fg · F %.1fg · C %.1fg per 100g",
                            food.kcal100g, food.protein100g, food.fat100g, food.carbs100g))
                    .font(.caption).foregroundColor(Theme.muted)
            }
            Spacer()
            Image(systemName: "plus.circle").foregroundColor(Theme.green)
        }
        .padding(10)
        .background(Theme.inset)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func selectedFoodBadge(_ food: OFFFood) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                if let bc = food.barcode {
                    Text("Barcode: \(bc)")
                        .font(.caption2).foregroundColor(Theme.muted)
                }
            }
            Spacer()
            Button { selected = nil; query = "" } label: {
                Image(systemName: "xmark").font(.caption).foregroundColor(Theme.muted)
            }
        }
        .padding(10)
        .background(Theme.greenLight.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Entry details

    private var entrySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Serving & Meal").font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Amount (\(store.weightUnit.rawValue))").font(.caption).foregroundColor(Theme.muted)
                HStack {
                    TextField("e.g. 100", text: $amountText)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .background(Theme.inset)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                    Text(store.weightUnit.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.muted)
                }
            }

            // Quick amounts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { val in
                        Button("\(val)\(store.weightUnit.rawValue)") {
                            amountText = "\(val)"
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.vertical, 6).padding(.horizontal, 12)
                        .background(amountText == "\(val)" ? Theme.green : Theme.inset)
                        .foregroundColor(amountText == "\(val)" ? .white : Theme.muted)
                        .clipShape(Capsule())
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Meal").font(.caption).foregroundColor(Theme.muted)
                HStack(spacing: 8) {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Button(meal.rawValue) { mealType = meal }
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(mealType == meal ? Theme.green : Theme.inset)
                            .foregroundColor(mealType == meal ? .white : Theme.muted)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            if let p = preview {
                Divider().background(Theme.border)
                HStack(spacing: 0) {
                    nutrientPreview("Calories", "\(Int(p.cal))", "kcal", Theme.green)
                    nutrientPreview("Protein",  "\(Int(p.p))",  "g",    Color(hex: "#5C9EFF"))
                    nutrientPreview("Fat",      "\(Int(p.f))",  "g",    Color(hex: "#FF9F43"))
                    nutrientPreview("Carbs",    "\(Int(p.c))",  "g",    Color(hex: "#FF6B6B"))
                }
            }
        }
        .card()
    }

    private var quickAmounts: [Int] {
        switch store.weightUnit {
        case .grams:     return [50, 100, 150, 200, 250]
        case .ounces:    return [1, 2, 3, 4, 6, 8]
        case .pounds:    return [1, 2, 3]
        case .kilograms: return [1]
        }
    }

    private func nutrientPreview(_ label: String, _ val: String, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10)).foregroundColor(Theme.muted)
            Text(val).font(.system(size: 16, weight: .bold)).foregroundColor(color)
            Text(unit).font(.system(size: 10)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Barcode handling

    private func handleBarcode(_ code: String) {
        showScanner = false
        scanError = nil

        // 1. The user's own custom foods win.
        if let food = store.customFoods.first(where: { $0.barcode == code }) {
            selected = food; query = food.name; return
        }

        // 2. Live Open Food Facts lookup, falling back to the bundled offline list.
        isLookingUp = true
        Task { @MainActor in
            do {
                let food = try await OpenFoodFactsAPI.lookup(barcode: code)
                selected = food
                query = food.name
            } catch {
                if let food = AppData.offByBarcode[code] {
                    selected = food
                    query = food.name
                } else if (error as? OpenFoodFactsAPI.LookupError) == .notFound {
                    scanError = "Barcode \(code) isn't in Open Food Facts yet. Try searching by name or create a custom food."
                } else {
                    scanError = "Couldn't reach the food database — check your connection and try again."
                }
            }
            isLookingUp = false
        }
    }

    // MARK: - Add

    private func addEntry() {
        guard let food = selected, grams > 0 else { return }
        let factor = grams / 100.0
        let entry = FoodEntry(
            date: Date(), foodName: food.name,
            grams: grams,
            calories: food.kcal100g    * factor,
            protein:  food.protein100g * factor,
            fat:      food.fat100g     * factor,
            carbs:    food.carbs100g   * factor,
            mealType: mealType
        )
        onAdd(entry)
        dismiss()
    }
}
