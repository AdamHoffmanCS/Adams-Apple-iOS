import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var timer: TimerModel
    @State private var showTimer = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $store.selectedTab) {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "house.fill") }.tag(0)
                ProgramsView()
                    .tabItem { Label("Programs", systemImage: "list.bullet.rectangle.fill") }.tag(1)
                FoodView()
                    .tabItem { Label("Nutrition", systemImage: "fork.knife") }.tag(2)
                FastingView()
                    .tabItem { Label("Fasting", systemImage: "hourglass") }.tag(3)
                ProgressHubView()
                    .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }.tag(4)
                ExerciseDBView()
                    .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }.tag(5)
            }

            // Floating timer button (mirrors the web app's floating timer widget)
            Button {
                showTimer = true
            } label: {
                ZStack {
                    Circle().fill(Theme.green)
                        .frame(width: 56, height: 56)
                        .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                    if timer.isRunning {
                        Text(timer.displayShort)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "timer")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 64) // sit above the tab bar
        }
        .sheet(isPresented: $showTimer) {
            TimerView()
        }
    }
}
