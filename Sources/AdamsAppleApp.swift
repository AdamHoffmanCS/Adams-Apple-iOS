import SwiftUI

@main
struct AdamsAppleApp: App {
    @StateObject private var store = Store()
    @StateObject private var timer = TimerModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(timer)
                .tint(Theme.green)
        }
    }
}
