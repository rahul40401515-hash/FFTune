import SwiftUI
import AVKit

struct CrosshairView: View {
    @StateObject private var engine = CrosshairEngine()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LayerHost(layer: engine.layer)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Section("Style") {
                    ColorPicker("Color", selection: $engine.tint)
                    HStack { Text("Size"); Slider(value: $engine.side, in: 90...220) }
                    HStack { Text("Thickness"); Slider(value: $engine.thickness, in: 1...8) }
                    HStack { Text("Gap"); Slider(value: $engine.gap, in: 4...30) }
                }
                Section {
                    Button(engine.isActive ? "Stop overlay" : "Start overlay") {
                        engine.isActive ? engine.stop() : engine.start()
                    }
                    .buttonStyle(.borderedProminent)
                } footer: {
                    Text("Start, then swipe home and open Free Fire. Drag the floating window to center it. Pinch it as small as iOS allows. The window is opaque, so it will cover a small patch of screen.")
                }
            }
            .navigationTitle("Crosshair")
            .onDisappear { if engine.isActive { engine.stop() } }
        }
    }
}
