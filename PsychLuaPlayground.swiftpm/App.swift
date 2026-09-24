import SwiftUI
import UniformTypeIdentifiers

@main
struct PsychLuaApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var output = "「テストを実行」を押してください"
    @State private var picking = false
    @State private var extra: [(String, String)] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("Psych Lua 互換テスト")
            .toolbar {
                ToolbarItem { Button("Lua を追加") { picking = true } }
                ToolbarItem { Button("テストを実行", action: run) }
            }
            .fileImporter(isPresented: $picking,
                          allowedContentTypes: [UTType(filenameExtension: "lua") ?? .plainText, .plainText],
                          allowsMultipleSelection: true) { result in
                for url in (try? result.get()) ?? [] {
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let s = try? String(contentsOf: url, encoding: .utf8) { extra.append((url.lastPathComponent, s)) }
                }
                run()
            }
        }
    }

    private func run() {
        var out = "## Lua 5.1.5（Swift から実行）\n" + runProbes()
        for (name, code) in sampleScripts + extra { out += runScript(name, code) }
        output = out
    }
}
