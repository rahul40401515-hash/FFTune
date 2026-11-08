import SwiftUI
import UIKit

struct Drill: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let seconds: Int
}

let drills: [Drill] = [
    .init(title: "Track with fire held", detail: "10m. Strafe past dummies with your thumb on fire the whole time. Watch where the assist pulls.", seconds: 60),
    .init(title: "Red Dot overshoot", detail: "Tap-fire heads. If it overshoots, drop Red Dot by 5 after this round.", seconds: 45),
    .init(title: "Gyro correction", detail: "Hold the assist, then correct 3cm with your wrist. Smooth, not jerky.", seconds: 60),
    .init(title: "Cone sweep", detail: "Sweep 2cm past a head at 5m. Default should grab it. If it takes the chest, you are too far out.", seconds: 45),
    .init(title: "180 turn", detail: "One full-screen swipe should be one 180. Adjust General only.", seconds: 30)
]

struct DrillsView: View {
    @State private var index = 0
    @State private var remaining = 0
    @State private var running = false
    @State private var timer: Timer?

    var drill: Drill { drills[index] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(drill.title).font(.title2.bold())
                Text("\(remaining)s").font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(running ? .orange : .secondary)
                Text(drill.detail)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Button(running ? "Stop" : "Start") { running ? stop() : start() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                HStack(spacing: 16) {
                    Button("Previous") { index = max(0, index - 1); reset() }
                    Button("Next") { index = min(drills.count - 1, index + 1); reset() }
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Drills")
        }
        .onDisappear(perform: stop)
    }

    private func reset() { stop(); remaining = drills[index].seconds }

    private func start() {
        remaining = drill.seconds
        running = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remaining <= 1 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                stop()
            } else {
                remaining -= 1
                if remaining <= 3 { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            }
        }
    }

    private func stop() { timer?.invalidate(); timer = nil; running = false }
}
