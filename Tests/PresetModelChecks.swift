import Foundation

@main
struct PresetModelChecks {
    static func main() throws {
        let baseValues = [88, 72, 58, 48, 38, 65]
        let labels = ["General", "Red Dot", "2x Scope", "4x Scope", "Sniper", "Free Look"]
        var combinations = 0

        for role in Role.allCases {
            for grip in Grip.allCases {
                let preset = Preset.build(role: role, grip: grip, name: "Model check")
                let expected = baseValues.map {
                    min(100, max(20, $0 + role.bias + grip.bias))
                }

                precondition(preset.name == "Model check")
                precondition(preset.rows.map { $0.0 } == labels)
                precondition(preset.rows.map { $0.1 } == expected)
                precondition(preset.rows.allSatisfy {
                    (20...100).contains($0.1)
                })
                combinations += 1
            }
        }

        var edited = Preset.build(role: .support, grip: .three)
        for index in edited.rows.indices {
            edited.set(index, 20 + index)
            precondition(edited.rows[index].1 == 20 + index)
        }
        precondition(edited.rows.map { $0.1 } == [20, 21, 22, 23, 24, 25])

        let encoded = try JSONEncoder().encode(edited)
        let decoded = try JSONDecoder().decode(Preset.self, from: encoded)
        precondition(decoded == edited)

        let another = Preset.build(role: .support, grip: .three)
        precondition(another.id != edited.id)
        precondition(edited.text.hasPrefix("New preset\n\nGeneral: 20\n"))
        precondition(edited.text.contains("Free Look: 25"))
        precondition(edited.text.contains("Aim Assist: ON"))

        print("Preset model checks passed: \(combinations) role/grip combinations.")
    }
}
