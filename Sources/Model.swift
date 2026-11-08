import Foundation

enum Role: String, CaseIterable, Identifiable, Codable {
    case rusher = "Rusher / entry"
    case support = "Support / mid"
    case sniper = "Sniper / anchor"
    var id: String { rawValue }
    var bias: Int {
        switch self { case .rusher: 7; case .support: 0; case .sniper: -7 }
    }
}

enum Grip: String, CaseIterable, Identifiable, Codable {
    case claw = "4-finger claw"
    case three = "3-finger"
    case two = "2-thumb"
    var id: String { rawValue }
    var bias: Int {
        switch self { case .claw: 5; case .three: 0; case .two: -6 }
    }
}

struct Preset: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var general: Int
    var redDot: Int
    var x2: Int
    var x4: Int
    var sniper: Int
    var freeLook: Int

    static func build(role: Role, grip: Grip, name: String = "New preset") -> Preset {
        let b = role.bias + grip.bias
        func c(_ v: Int) -> Int { min(100, max(20, v + b)) }
        return Preset(name: name, general: c(88), redDot: c(72), x2: c(58),
                      x4: c(48), sniper: c(38), freeLook: c(65))
    }

    var rows: [(String, Int)] {
        [("General", general), ("Red Dot", redDot), ("2x Scope", x2),
         ("4x Scope", x4), ("Sniper", sniper), ("Free Look", freeLook)]
    }

    mutating func set(_ i: Int, _ v: Int) {
        switch i {
        case 0: general = v
        case 1: redDot = v
        case 2: x2 = v
        case 3: x4 = v
        case 4: sniper = v
        default: freeLook = v
        }
    }

    var text: String {
        var out = [name, ""] + rows.map { "\($0.0): \($0.1)" }
        out += ["", "Aim Assist: ON", "Aim Precision: Default",
                "Fire Button: 40%, bottom-right", "Crosshair: small, no dot",
                "High FPS: ON / Graphics: Smooth"]
        return out.joined(separator: "\n")
    }
}
