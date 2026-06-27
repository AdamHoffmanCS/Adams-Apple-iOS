import UIKit

/// Stores progress photos as JPEGs in Documents/ProgressPhotos.
enum PhotoStore {
    static var dir: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent("ProgressPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: d.path) {
            try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        }
        return d
    }

    @discardableResult
    static func save(_ image: UIImage) -> String? {
        let name = UUID().uuidString + ".jpg"
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: dir.appendingPathComponent(name))
            return name
        } catch {
            return nil
        }
    }

    static func load(_ filename: String) -> UIImage? {
        UIImage(contentsOfFile: dir.appendingPathComponent(filename).path)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(filename))
    }
}
