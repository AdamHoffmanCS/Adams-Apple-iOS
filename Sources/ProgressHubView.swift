import SwiftUI

/// The "Progress" tab — a hub linking to Health, Progress Photos, and the
/// Workout Log. (Named ProgressHubView to avoid clashing with SwiftUI.ProgressView.)
struct ProgressHubView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink {
                        HealthView()
                    } label: {
                        HubCard(icon: "heart.text.square.fill", title: "Health",
                                subtitle: "Weight, body fat, blood work, BP & measurements",
                                detail: healthSummary)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ProgressPhotosView()
                    } label: {
                        HubCard(icon: "camera.fill", title: "Progress Photos",
                                subtitle: "Track your transformation over time",
                                detail: store.photos.isEmpty ? "No photos yet" : "\(store.photos.count) photo\(store.photos.count == 1 ? "" : "s")")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        LogView()
                    } label: {
                        HubCard(icon: "square.and.pencil", title: "Workout Log",
                                subtitle: "Your logged sets & exercise history",
                                detail: store.log.isEmpty ? "No workouts yet" : "\(store.log.count) entr\(store.log.count == 1 ? "y" : "ies")")
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Progress")
        }
    }

    private var healthSummary: String {
        if let w = store.weights.sorted(by: { $0.date > $1.date }).first {
            return "Latest weight: \(store.fmtNum(w.value)) lbs"
        }
        return "Add your first entry"
    }
}

struct HubCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var detail: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(Theme.green)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                Text(subtitle).font(.system(size: 13)).foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail).font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.greenDark)
                    .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(Theme.muted)
        }
        .card()
    }
}
