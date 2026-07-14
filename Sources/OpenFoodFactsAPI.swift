import Foundation

/// Live barcode lookup against the Open Food Facts database (~4M products).
/// Docs: https://openfoodfacts.github.io/openfoodfacts-server/api/
/// Data is licensed under the Open Database License (ODbL v1.0).
enum OpenFoodFactsAPI {

    enum LookupError: LocalizedError, Equatable {
        case notFound
        case badResponse

        var errorDescription: String? {
            switch self {
            case .notFound:    return "Product not found in Open Food Facts."
            case .badResponse: return "Could not reach Open Food Facts."
            }
        }
    }

    /// Looks up a scanned barcode, trying common UPC-A / EAN-13 variants.
    static func lookup(barcode: String) async throws -> OFFFood {
        var lastError: Error = LookupError.notFound
        for code in candidates(for: barcode) {
            do {
                if let food = try await fetchProduct(code) { return food }
            } catch {
                lastError = error   // network hiccup — still try the next variant
            }
        }
        throw lastError
    }

    /// iPhones report UPC-A barcodes as EAN-13 with a leading zero, but OFF
    /// stores some products under the 12-digit form and some under 13 digits.
    private static func candidates(for raw: String) -> [String] {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var out = [code]
        if code.count == 13 && code.hasPrefix("0") { out.append(String(code.dropFirst())) }
        if code.count == 12 { out.append("0" + code) }
        return out
    }

    private static func fetchProduct(_ code: String) async throws -> OFFFood? {
        var comps = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(code)")!
        comps.queryItems = [URLQueryItem(name: "fields", value: "code,product_name,brands,nutriments")]
        guard let url = comps.url else { throw LookupError.badResponse }

        var request = URLRequest(url: url, timeoutInterval: 10)
        // OFF asks API users to identify their app in the User-Agent.
        request.setValue("AdamsApple-iOS/1.0 (ahoffm24@gmail.com)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LookupError.badResponse }
        if http.statusCode == 404 { return nil }   // unknown product
        guard (200..<300).contains(http.statusCode) else { throw LookupError.badResponse }

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let product = root["product"] as? [String: Any] else { return nil }
        return parse(product: product, code: code)
    }

    private static func parse(product: [String: Any], code: String) -> OFFFood? {
        let nutriments = product["nutriments"] as? [String: Any] ?? [:]

        // kcal per 100 g; fall back to converting from kJ if kcal is missing.
        var kcal = number(nutriments["energy-kcal_100g"])
        if kcal == nil, let kj = number(nutriments["energy_100g"]) { kcal = kj / 4.184 }

        let protein = number(nutriments["proteins_100g"])
        let fat     = number(nutriments["fat_100g"])
        let carbs   = number(nutriments["carbohydrates_100g"])

        // A product with no nutrition data at all isn't useful for logging.
        guard kcal != nil || protein != nil || fat != nil || carbs != nil else { return nil }

        var name = (product["product_name"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if name.isEmpty { name = "Product \(code)" }
        if let brands = product["brands"] as? String {
            let brand = brands.split(separator: ",").first
                .map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
            if !brand.isEmpty, !name.lowercased().contains(brand.lowercased()) {
                name = "\(brand) \(name)"
            }
        }

        return OFFFood(name: name,
                       kcal100g: kcal ?? 0,
                       protein100g: protein ?? 0,
                       fat100g: fat ?? 0,
                       carbs100g: carbs ?? 0,
                       barcode: code,
                       isCustom: false)
    }

    /// OFF sometimes returns numeric fields as strings.
    private static func number(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) }
        return nil
    }
}
