import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Welcome back, Adam 💪")
                        .font(.system(size: 28, weight: .bold))

                    HStack(spacing: 12) {
                        StatCard(number: store.log.count, label: "Workouts Logged")
                        StatCard(number: store.exercisesDone, label: "Exercises Done")
                        StatCard(number: store.streak, label: "Day Streak 🔥")
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Start").font(.title3.weight(.semibold))
                        Button("Start a Workout") { store.selectedTab = 1 }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .card()

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("🍎 Adams Apple")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatCard: View {
    var number: Int
    var label: String
    var body: some View {
        VStack(spacing: 8) {
            Text("\(number)")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Theme.green)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20).padding(.horizontal, 8)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
    }
}
