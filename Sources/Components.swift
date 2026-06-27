import SwiftUI

/// A circular progress ring (starts at the top, fills clockwise).
struct ProgressRing: View {
    var progress: Double          // 0...1
    var color: Color
    var lineWidth: CGFloat = 12
    var trackColor: Color = Theme.border

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
                .animation(.easeInOut(duration: 1.0), value: color)
        }
    }
}

/// red → yellow → green as progress goes 0 → 1 (matches the web fasting ring).
func fastingRingColor(_ progress: Double) -> Color {
    let p = max(0, min(1, progress))
    return Color(hue: p * (1.0 / 3.0), saturation: 0.8, brightness: 0.85)
}

/// Pill / chip selector button used for filters and presets.
struct ChipButton: View {
    var title: String
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.vertical, 8).padding(.horizontal, 14)
                .background(selected ? Theme.green : Theme.greenLight.opacity(0.5))
                .foregroundColor(selected ? .white : Theme.greenDark)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Primary green button matching `.btn-primary`.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.green.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.greenLight.opacity(configuration.isPressed ? 0.6 : 1))
            .foregroundColor(Theme.greenDark)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Simple bar chart for an exercise's logged weight/reps over time.
struct MiniBarChart: View {
    var values: [Double]
    var labels: [String]
    var unit: String

    private var maxV: Double { max(values.max() ?? 1, 1) }

    var body: some View {
        GeometryReader { geo in
            let count = max(values.count, 1)
            let spacing: CGFloat = 8
            let barW = (geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count)
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(values.indices, id: \.self) { idx in
                    let v = values[idx]
                    VStack(spacing: 4) {
                        Text(v == 0 ? "" : "\(Int(v))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.muted)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.green)
                            .frame(width: barW,
                                   height: max(4, CGFloat(v / maxV) * (geo.size.height - 40)))
                        Text(labels[safe: idx] ?? "")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.muted)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// A simple line chart for a metric trend (values oldest → newest).
struct TrendLineChart: View {
    var values: [Double]          // chronological
    var color: Color = Theme.green

    private var minV: Double { values.min() ?? 0 }
    private var maxV: Double { values.max() ?? 1 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let range = max(maxV - minV, 0.0001)
            let pts: [CGPoint] = values.enumerated().map { i, v in
                let x = values.count <= 1 ? w / 2 : w * CGFloat(i) / CGFloat(values.count - 1)
                let y = h - (CGFloat((v - minV) / range) * (h - 16)) - 8
                return CGPoint(x: x, y: y)
            }
            ZStack {
                if pts.count > 1 {
                    Path { p in
                        p.move(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                ForEach(pts.indices, id: \.self) { i in
                    Circle().fill(color)
                        .frame(width: 6, height: 6)
                        .position(pts[i])
                }
            }
        }
    }
}

/// Lightweight toast overlay.
struct ToastView: View {
    var message: String
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold))
            .padding(.vertical, 12).padding(.horizontal, 20)
            .background(Theme.card)
            .foregroundColor(Theme.text)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.border))
            .shadow(radius: 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
