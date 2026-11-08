import SwiftUI
import UIKit

struct PresetView: View {
    @EnvironmentObject private var store: Store
    @State private var role: Role = .support
    @State private var grip: Grip = .three
    @State private var draft: Preset = .build(role: .support, grip: .three)
    @State private var askName = false
    @State private var nameField = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Input") {
                    Picker("Role", selection: $role) {
                        ForEach(Role.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    Picker("Grip", selection: $grip) {
                        ForEach(Grip.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    Button("Rebuild from input") {
                        draft = .build(role: role, grip: grip, name: draft.name)
                    }
                }
                Section("Fine tune") {
                    ForEach(draft.rows.indices, id: \.self) { i in
                        HStack {
                            Text(draft.rows[i].0)
                            Spacer()
                            Stepper("\(draft.rows[i].1)",
                                    value: Binding(get: { draft.rows[i].1 },
                                                   set: { draft.set(i, $0) }),
                                    in: 20...100)
                            .labelsHidden()
                            Text("\(draft.rows[i].1)")
                                .monospacedDigit()
                                .foregroundStyle(.orange)
                                .frame(width: 34, alignment: .trailing)
                        }
                    }
                }
                Section {
                    Button("Save preset") { nameField = ""; askName = true }
                    Button("Copy to clipboard") {
                        UIPasteboard.general.string = draft.text
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
                Section("Saved") {
                    if store.saved.isEmpty {
                        Text("Nothing saved yet").foregroundStyle(.secondary)
                    }
                    ForEach(store.saved) { p in
                        VStack(alignment: .leading) {
                            Text(p.name).font(.headline)
                            Text("G\(p.general) R\(p.redDot) 2x\(p.x2) 4x\(p.x4) S\(p.sniper) F\(p.freeLook)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .onTapGesture { draft = p }
                    }
                    .onDelete { store.saved.remove(atOffsets: $0) }
                }
            }
            .navigationTitle("FF Tune")
            .alert("Name this preset", isPresented: $askName) {
                TextField("name", text: $nameField)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    var copy = draft
                    copy.name = nameField.isEmpty ? "Untitled" : nameField
                    store.saved.append(copy)
                }
            }
        }
    }
}
