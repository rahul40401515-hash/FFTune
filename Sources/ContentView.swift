import SwiftUI

struct ContentView: View {
    @StateObject private var store = Store()
    var body: some View {
        TabView {
            PresetView().tabItem { Label("Preset", systemImage: "slider.horizontal.3") }
            DrillsView().tabItem { Label("Drills", systemImage: "timer") }
            CrosshairView().tabItem { Label("Crosshair", systemImage: "plus") }
        }
        .environmentObject(store)
    }
}
