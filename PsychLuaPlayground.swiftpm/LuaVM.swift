import CLua

enum LuaValue { case none, number(Double), string(String), bool(Bool) }

struct LuaError: Error, CustomStringConvertible { let description: String }

extension Array where Element == LuaValue {
    func str(_ i: Int) -> String { if i < count, case .string(let s) = self[i] { return s }; return "" }
    func num(_ i: Int) -> Double { if i < count, case .number(let n) = self[i] { return n }; return 0 }
}

private final class HostBox {
    let fn: ([LuaValue]) -> LuaValue?
    init(_ fn: @escaping ([LuaValue]) -> LuaValue?) { self.fn = fn }
}

// Swift のクロージャを Lua に渡すための共通入口。
// 呼び出す HostBox は upvalue 1 番に入れておく（Lua 5.1 の lua_upvalueindex(1) は GLOBALSINDEX - 1）。
private let trampoline: lua_CFunction = { L in
    guard let L = L, let raw = lua_touserdata(L, LUA_GLOBALSINDEX - 1) else { return 0 }
    let box = Unmanaged<HostBox>.fromOpaque(raw).takeUnretainedValue()
    var args: [LuaValue] = []
    let n = lua_gettop(L)
    if n > 0 {
        for i in 1...n {
            switch lua_type(L, i) {
            case LUA_TNUMBER: args.append(.number(lua_tonumber(L, i)))
            case LUA_TSTRING: args.append(.string(String(cString: lua_tolstring(L, i, nil))))
            case LUA_TBOOLEAN: args.append(.bool(lua_toboolean(L, i) != 0))
            default: args.append(.none)
            }
        }
    }
    switch box.fn(args) {
    case .number(let d)?: lua_pushnumber(L, d); return 1
    case .string(let s)?: lua_pushstring(L, s); return 1
    case .bool(let b)?: lua_pushboolean(L, b ? 1 : 0); return 1
    default: return 0
    }
}

final class LuaVM {
    private let L: OpaquePointer
    private var boxes: [HostBox] = []

    init() { L = luaL_newstate(); luaL_openlibs(L) }
    deinit { lua_close(L) }

    private func push(_ v: LuaValue) {
        switch v {
        case .number(let d): lua_pushnumber(L, d)
        case .string(let s): lua_pushstring(L, s)
        case .bool(let b): lua_pushboolean(L, b ? 1 : 0)
        case .none: lua_pushnil(L)
        }
    }

    func set(_ name: String, _ v: LuaValue) {
        push(v)
        lua_setfield(L, LUA_GLOBALSINDEX, name)
    }

    func register(_ name: String, _ fn: @escaping ([LuaValue]) -> LuaValue?) {
        let box = HostBox(fn)
        boxes.append(box)
        lua_pushlightuserdata(L, Unmanaged.passUnretained(box).toOpaque())
        lua_pushcclosure(L, trampoline, 1)
        lua_setfield(L, LUA_GLOBALSINDEX, name)
    }

    func run(_ code: String) throws {
        if luaL_loadstring(L, code) != 0 || lua_pcall(L, 0, 0, 0) != 0 { throw LuaError(description: popError()) }
    }

    /// 式を評価して tostring した結果を返す
    func eval(_ expr: String) throws -> String {
        if luaL_loadstring(L, "return tostring(\(expr))") != 0 || lua_pcall(L, 0, 1, 0) != 0 {
            throw LuaError(description: popError())
        }
        defer { lua_settop(L, -2) }
        return String(cString: lua_tolstring(L, -1, nil))
    }

    /// グローバル関数があれば呼ぶ（無ければ何もしない）
    func call(_ name: String, _ args: [LuaValue] = []) throws {
        lua_getfield(L, LUA_GLOBALSINDEX, name)
        guard lua_type(L, -1) == LUA_TFUNCTION else { lua_settop(L, -2); return }
        for a in args { push(a) }
        if lua_pcall(L, Int32(args.count), 0, 0) != 0 { throw LuaError(description: popError()) }
    }

    private func popError() -> String {
        let s = lua_tolstring(L, -1, nil).map { String(cString: $0) } ?? "不明なエラー"
        lua_settop(L, -2)
        return s
    }
}
