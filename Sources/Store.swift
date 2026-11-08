import Foundation
import Combine

final class Store: ObservableObject {
    private let key = "fftune.presets"
    @Published var saved: [Preset] = [] { didSet { persist() } }

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Preset].self, from: data) else { return }
        saved = list
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
