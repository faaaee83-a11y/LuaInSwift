import Foundation

// Psych 風 Lua の互換テスト。stub の API は関数名を合わせた簡易版で、実物と挙動が違う所があります。

// (表示名, Lua の式, Lua 5.1 / LuaJIT での期待値, 参考扱いか)
private let probes: [(String, String, String, Bool)] = [
    ("10/2 の文字列化", "10/2", "5", false),
    ("2^31 の文字列化", "2^31", "2147483648", false),
    ("unpack", "type(unpack)", "function", false),
    ("loadstring", "type(loadstring)", "function", false),
    ("setfenv", "type(setfenv)", "function", false),
    ("math.pow", "type(math.pow)", "function", false),
    ("table.getn", "type(table.getn)", "function", false),
    ("bit ライブラリ（LuaJIT 専用・参考）", "type(bit)", "table", true),
]

func runProbes() -> String {
    let vm = LuaVM()
    var out = ""
    for (label, expr, want, info) in probes {
        let got: String
        do { got = try vm.eval(expr) } catch { got = "ERR \(error)" }
        let ok = got == want
        out += "\(ok ? "OK " : info ? "参考" : "NG ") \(label): \(got)\(ok ? "" : "（5.1 では \(want)）")\n"
    }
    return out
}

private final class Sim {
    var t = 0.0
    var calls = 0
    var state: [String: Double] = ["health": 1]
    var pending: [(at: Double, fn: String, args: [LuaValue], done: Bool)] = []
}

func runScript(_ name: String, _ code: String, frames: Int = 180) -> String {
    let vm = LuaVM()
    let sim = Sim()
    for n in ["makeLuaSprite", "addLuaSprite", "setObjectCamera", "playSound", "triggerEvent", "debugPrint", "close"] {
        vm.register(n) { _ in sim.calls += 1; return nil }
    }
    for n in ["doTweenX", "doTweenY", "doTweenAlpha"] {
        vm.register(n) { a in
            sim.calls += 1
            sim.pending.append((sim.t + a.num(3), "onTweenCompleted", [.string(a.str(0))], false))
            return nil
        }
    }
    vm.register("runTimer") { a in
        sim.calls += 1
        sim.pending.append((sim.t + a.num(1), "onTimerCompleted", [.string(a.str(0)), .number(1), .number(0)], false))
        return nil
    }
    vm.register("setProperty") { a in sim.calls += 1; sim.state[a.str(0)] = a.num(1); return nil }
    vm.register("getProperty") { a in .number(sim.state[a.str(0)] ?? 0) }
    vm.register("getSongPosition") { _ in .number(sim.t * 1000) }
    vm.set("songName", .string("test"))
    vm.set("bpm", .number(120))

    do {
        try vm.run(code)
        try vm.call("onCreate")
        try vm.call("onCreatePost")
        let t0 = Date()
        var step = -1, beat = -1
        for i in 0..<frames {
            sim.t = Double(i) / 60
            let s = Int(sim.t * 8), b = Int(sim.t * 2)
            vm.set("curStep", .number(Double(s)))
            vm.set("curBeat", .number(Double(b)))
            for idx in sim.pending.indices where !sim.pending[idx].done && sim.pending[idx].at <= sim.t {
                sim.pending[idx].done = true
                let p = sim.pending[idx]
                try vm.call(p.fn, p.args)
            }
            if s != step { step = s; try vm.call("onStepHit") }
            if b != beat { beat = b; try vm.call("onBeatHit") }
            try vm.call("onUpdate", [.number(1.0 / 60)])
        }
        let ms = Date().timeIntervalSince(t0) * 1000 / Double(frames)
        return "OK  \(name): 呼び出し \(sim.calls) 回, \(String(format: "%.3f", ms)) ms/フレーム\n"
    } catch {
        return "NG  \(name): \(error)\n"
    }
}
