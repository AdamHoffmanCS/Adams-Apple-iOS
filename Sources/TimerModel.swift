import Foundation
import SwiftUI
import Combine

@MainActor
final class TimerModel: ObservableObject {
    enum Mode { case stopwatch, countdown }

    @Published var mode: Mode = .stopwatch
    @Published var isRunning = false

    // Stopwatch
    @Published var swElapsed = 0
    @Published var rounds: [(num: Int, duration: Int)] = []
    private var swRoundStart = 0

    // Countdown
    @Published var cdTotal = 60
    @Published var cdRemaining = 60

    private var ticker: AnyCancellable?

    // MARK: - Display

    var display: String {
        let secs = mode == .stopwatch ? swElapsed : cdRemaining
        return Self.format(secs)
    }
    var displayShort: String {
        let secs = mode == .stopwatch ? swElapsed : cdRemaining
        let m = secs / 60, s = secs % 60
        return String(format: "%02d:%02d", m % 60, s)
    }
    var progress: Double {
        switch mode {
        case .stopwatch:
            return Double(swElapsed % 60) / 60.0
        case .countdown:
            guard cdTotal > 0 else { return 0 }
            return Double(cdTotal - cdRemaining) / Double(cdTotal)
        }
    }

    static func format(_ secs: Int) -> String {
        let s = max(0, secs)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%02d:%02d", m, sec)
    }

    // MARK: - Controls

    func toggle() { isRunning ? pause() : start() }

    func start() {
        if mode == .countdown && cdRemaining == 0 { cdRemaining = cdTotal }
        isRunning = true
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
    }

    func reset() {
        pause()
        if mode == .stopwatch {
            swElapsed = 0
            swRoundStart = 0
            rounds = []
        } else {
            cdRemaining = cdTotal
        }
    }

    func setMode(_ m: Mode) {
        guard m != mode else { return }
        pause()
        mode = m
    }

    func setCountdown(seconds: Int) {
        cdTotal = max(1, seconds)
        cdRemaining = cdTotal
        if mode != .countdown { mode = .countdown }
    }

    func roundComplete() {
        guard mode == .stopwatch, isRunning else { return }
        let dur = swElapsed - swRoundStart
        rounds.insert((num: rounds.count + 1, duration: dur), at: 0)
        swRoundStart = swElapsed
    }

    private func tick() {
        switch mode {
        case .stopwatch:
            swElapsed += 1
        case .countdown:
            if cdRemaining > 0 { cdRemaining -= 1 }
            if cdRemaining == 0 {
                pause()
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            }
        }
    }
}
