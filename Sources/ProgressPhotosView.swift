import SwiftUI
import UIKit

struct ProgressPhotosView: View {
    @EnvironmentObject var store: Store
    @State private var showSourceDialog = false
    @State private var activeSheet: PhotoSheet?

    enum PhotoSheet: Identifiable {
        case picker(PickerSource)
        case detail(ProgressPhoto)
        var id: String {
            switch self {
            case .picker(let s): return "picker-\(s.id)"
            case .detail(let p): return "detail-\(p.id.uuidString)"
            }
        }
    }

    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private var sorted: [ProgressPhoto] { store.photos.sorted { $0.date > $1.date } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Button { showSourceDialog = true } label: {
                    Label("Add Photo", systemImage: "camera.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                if sorted.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled").font(.largeTitle).foregroundColor(Theme.muted)
                        Text("No progress photos yet.\nTap **Add Photo** to capture your first.")
                            .multilineTextAlignment(.center).foregroundColor(Theme.muted)
                    }
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(sorted) { photo in
                            Button { activeSheet = .detail(photo) } label: {
                                PhotoThumb(photo: photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Progress Photos")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Add a progress photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
            Button("Take Photo") { activeSheet = .picker(.camera) }
            Button("Choose from Library") { activeSheet = .picker(.library) }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .picker(let src):
                ImagePicker(sourceType: src.uiType) { image in
                    if let filename = PhotoStore.save(image) {
                        store.photos.append(ProgressPhoto(date: Date(), filename: filename))
                    }
                }
                .ignoresSafeArea()
            case .detail(let photo):
                PhotoDetailView(photo: photo) {
                    PhotoStore.delete(photo.filename)
                    store.photos.removeAll { $0.id == photo.id }
                    activeSheet = nil
                }
            }
        }
    }
}

enum PickerSource: Identifiable {
    case camera, library
    var id: Int { self == .camera ? 0 : 1 }
    var uiType: UIImagePickerController.SourceType { self == .camera ? .camera : .photoLibrary }
}

struct PhotoThumb: View {
    var photo: ProgressPhoto
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let img = PhotoStore.load(photo.filename) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo").font(.largeTitle).foregroundColor(Theme.muted)
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
            Text(dateLabel(photo.date)).font(.caption).foregroundColor(Theme.muted)
        }
    }
    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: d)
    }
}

struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    var photo: ProgressPhoto
    var onDelete: () -> Void
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            VStack {
                if let img = PhotoStore.load(photo.filename) {
                    Image(uiImage: img).resizable().scaledToFit()
                } else {
                    Text("Image unavailable").foregroundColor(Theme.muted)
                }
                Text(dateLabel(photo.date)).font(.headline).padding(.top, 8)
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { confirmDelete = true } label: { Image(systemName: "trash") }
                }
            }
            .confirmationDialog("Delete this photo?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy"; return f.string(from: d)
    }
}
