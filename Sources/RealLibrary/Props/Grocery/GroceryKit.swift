import simd
import Foundation

/// Shared helpers for the grocery pack: tinted keys, beveled boxes, a 5x7 printed font, and low-poly
/// product facings used to stock gondolas, cases and freezers. Brands are invented.
enum GroceryKit {
    static func tint(_ base: String, _ c: UInt32) -> MaterialKey { base + ":" + String(format: "%06X", c) }

    static func box(_ m: inout Model, _ size: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.002, rot: simd_quatf = .identity) {
        let rr = min(r, size.x / 2.1, size.y / 2.1, size.z / 2.1)
        m.add(Prim.roundedBox(size, radius: rr, bevelSegments: 1, material: key), Xform(translation: c, rotation: rot))
    }

    static func flat(_ m: inout Model, _ size: V3, _ c: V3, _ key: MaterialKey, rot: simd_quatf = .identity) {
        m.add(cuboid(size, material: key), Xform(translation: c, rotation: rot))
    }

    /// Solid cylinder along +Y from y = 0.
    static func cyl(_ r: Float, _ h: Float, seg: Int, _ key: MaterialKey, bevel: Float = 0.001) -> Surface {
        Prim.lathe(Profile.roundedCylinder(radius: r, height: h, bevel: min(bevel, r * 0.4, h * 0.4), segments: 1),
                   segments: seg, seamTile: 0.05, material: key)
    }

    /// 5x7 glyphs, rows top to bottom.
    static let glyphs: [Character: String] = [
        "A": "01110100011000111111100011000110001", "B": "11110100011000111110100011000111110",
        "C": "01110100011000010000100001000101110", "D": "11110100011000110001100011000111110",
        "E": "11111100001000011110100001000011111", "F": "11111100001000011110100001000010000",
        "G": "01110100011000010111100011000101111", "H": "10001100011000111111100011000110001",
        "I": "11111001000010000100001000010011111", "J": "00111000100001000010000101001001100",
        "K": "10001100101010011000101001001010001", "L": "10000100001000010000100001000011111",
        "M": "10001110111010110101100011000110001", "N": "10001110011010110011100011000110001",
        "O": "01110100011000110001100011000101110", "P": "11110100011000111110100001000010000",
        "Q": "01110100011000110001101011001001101", "R": "11110100011000111110101001001010001",
        "S": "01111100001000001110000010000111110", "T": "11111001000010000100001000010000100",
        "U": "10001100011000110001100011000101110", "V": "10001100011000110001100010101000100",
        "W": "10001100011000110101101011010101010", "X": "10001100010101000100010101000110001",
        "Y": "10001100010101000100001000010000100", "Z": "11111000010001000100010001000011111",
        "0": "01110100011001110101110011000101110", "1": "00100011000010000100001000010001110",
        "2": "01110100010000100110010001000011111", "3": "11110000010000101110000010000111110",
        "4": "00010001100101010010111110001000010", "5": "11111100001111000001000011000101110",
        "6": "00110010001000011110100011000101110", "7": "11111000010001000100010000100001000",
        "8": "01110100011000101110100011000101110", "9": "01110100011000101111000010001001100",
        "$": "00100011111010001110001011111000100", ".": "00000000000000000000000000110001100",
        "%": "11001110010001000100010001001110011", "-": "00000000000000011111000000000000000",
        "/": "00001000010001000100010001000010000", "&": "01100100101010001000101011001001101",
    ]

    /// Printed text as flat quads facing +Z at z = 0, centered on x = 0, glyph bottom at y = 0.
    static func text(_ s: String, height h: Float, material: MaterialKey) -> Surface {
        var out = Surface(material: material)
        let px = h / 7, adv = 6 * px
        let chars = Array(s.uppercased())
        var gx = -(Float(chars.count) * adv - px) / 2
        let n = V3(0, 0, 1)
        for ch in chars {
            if let g = glyphs[ch] {
                let bits = Array(g)
                for r in 0..<7 {
                    var c = 0
                    while c < 5 {
                        if bits[r * 5 + c] == "0" { c += 1; continue }
                        var e = c
                        while e < 5 && bits[r * 5 + e] == "1" { e += 1 }
                        let x0 = gx + Float(c) * px, x1 = gx + Float(e) * px, y = Float(6 - r) * px
                        let a = out.add(V3(x0, y, 0), n, V2(x0, y)), b = out.add(V3(x1, y, 0), n, V2(x1, y))
                        let cc = out.add(V3(x1, y + px, 0), n, V2(x1, y + px)), d = out.add(V3(x0, y + px, 0), n, V2(x0, y + px))
                        out.quad(a, b, cc, d)
                        c = e
                    }
                }
            }
            gx += adv
        }
        out.computeTangents()
        return out
    }

    /// Text placed on a face: `at` is the bottom center, `rot` turns +Z to the face normal.
    static func print(_ m: inout Model, _ s: String, height: Float, at: V3, _ key: MaterialKey, rot: simd_quatf = .identity, maxWidth: Float? = nil) {
        var h = height
        if let w = maxWidth { let full = Float(s.count) * 6 * h / 7; if full > w { h *= w / full } }
        m.add(text(s, height: h, material: key), Xform(translation: at, rotation: rot))
    }

    /// Bends a +Z-facing surface (built at z = 0, centered on x = 0) around a vertical cylinder of radius
    /// `r` (axis through the origin), so printed text wraps a can or jar.
    static func wrap(_ s: Surface, radius r: Float) -> Surface {
        var o = s
        for i in o.positions.indices {
            let p = o.positions[i], a = p.x / r, rr = r + p.z
            o.positions[i] = V3(rr * sin(a), p.y, rr * cos(a))
            o.normals[i] = V3(sin(a), 0, cos(a))
        }
        o.computeTangents()
        return o
    }

    /// Printed text wrapped on a cylinder of radius `r`, bottom at `y`, centered at angle 0 (+Z).
    static func wrapPrint(_ m: inout Model, _ s: String, height: Float, radius r: Float, y: Float, _ key: MaterialKey, maxWidth: Float? = nil) {
        var h = height
        if let w = maxWidth { let full = Float(s.count) * 6 * h / 7; if full > w { h *= w / full } }
        m.add(wrap(text(s, height: h, material: key), radius: r + 0.0006), Xform(translation: V3(0, y, 0)))
    }

    // MARK: product facings

    /// Package shapes for shelf stock.
    enum Pack: CaseIterable { case box, tallBox, can, bottle, jar, bag, jug, carton, cup, tray, roll }

    /// Invented brand palettes: body, label, accent.
    static let palettes: [(UInt32, UInt32, UInt32)] = [
        (0xC8262B, 0xF6F1E4, 0xF2C230), (0x1F4E96, 0xF4F4F0, 0xE8913A), (0x2F7D45, 0xF3EFD9, 0xC8262B),
        (0xF2B632, 0x7A2E1A, 0xFFFFFF), (0x6B2C8F, 0xF6E9F5, 0xF2C230), (0x101A2B, 0xE8D7A8, 0xC8102E),
        (0xE8742A, 0xFFF6E8, 0x2E4D8A), (0x2FA6B8, 0xFFFFFF, 0x173A5C), (0xEFE8D6, 0x9A2E24, 0x2F6E3A),
        (0x8A1F2C, 0xF2E3C4, 0xD9A441), (0x3A3F44, 0xF5F5F0, 0x4FB04A), (0xD9D2C2, 0x2D5D9C, 0xD6282B),
    ]

    /// Single quad facing +Z (rotated by `rot`), for printed panels on visible faces.
    static func decal(_ m: inout Model, _ w: Float, _ h: Float, _ c: V3, _ key: MaterialKey, rot: simd_quatf = .identity) {
        var s = Surface(material: key)
        let n = V3(0, 0, 1)
        let a = s.add(V3(-w / 2, -h / 2, 0), n, V2(0, 0)), b = s.add(V3(w / 2, -h / 2, 0), n, V2(w, 0))
        let cc = s.add(V3(w / 2, h / 2, 0), n, V2(w, h)), d = s.add(V3(-w / 2, h / 2, 0), n, V2(0, h))
        s.quad(a, b, cc, d)
        s.computeTangents()
        m.add(s, Xform(translation: c, rotation: rot))
    }

    /// Detail tier for shelf stock: 0 full, 1 coarse lathes, 2 boxes only.
    static func product(_ m: inout Model, _ kind: Pack, size s: V3, at c: V3, palette p: (UInt32, UInt32, UInt32), hi: Bool,
                        yaw: Float = 0, tier: Int = 0) {
        let body = tint("paper.sheet", p.0), label = tint("paper.sheet", p.1), accent = tint("paper.sheet", p.2)
        let rot = simd_quatf(degrees: yaw, axis: .up)
        func at(_ v: V3) -> V3 { c + rot.act(v) }
        let fz = s.z / 2 + 0.0006
        let seg = tier == 0 ? (hi ? 8 : 6) : 5
        let k: Pack = tier >= 2 ? .box : kind
        switch k {
        case .box, .tallBox, .tray:
            flat(&m, s, at(V3(0, s.y / 2, 0)), body, rot: rot)
            decal(&m, s.x * 0.8, s.y * 0.36, at(V3(0, s.y * 0.6, fz)), label, rot: rot)
            decal(&m, s.x * 0.8, s.y * 0.08, at(V3(0, s.y * 0.26, fz)), accent, rot: rot)
        case .can:
            let r = min(s.x, s.z) / 2
            m.add(Prim.lathe([V2(0, 0), V2(r * 0.86, 0), V2(r, s.y * 0.06), V2(r, s.y * 0.94), V2(r * 0.88, s.y), V2(0, s.y)],
                             segments: seg, seamTile: 0.05, material: label), Xform(translation: c))
            m.add(Prim.lathe([V2(r * 1.004, s.y * 0.3), V2(r * 1.004, s.y * 0.7)], segments: seg, seamTile: 0.05, material: body), Xform(translation: c))
        case .bottle, .jug:
            let r = min(s.x, s.z) / 2
            let shoulder: Float = k == .jug ? 0.78 : 0.62
            let neckR = r * (k == .jug ? 0.42 : 0.3)
            let pts = [V2(0, 0), V2(r, s.y * 0.03), V2(r, s.y * shoulder), V2(neckR, s.y * 0.86), V2(neckR, s.y * 0.92), V2(0, s.y * 0.92)]
            m.add(Prim.lathe(pts, segments: seg, seamTile: 0.05, material: k == .jug ? "plastic.matte:EDEDE6" : body), Xform(translation: c))
            m.add(Prim.lathe([V2(r * 1.004, s.y * 0.18), V2(r * 1.004, s.y * 0.5)], segments: seg, seamTile: 0.05, material: label), Xform(translation: c))
            m.add(Prim.lathe([V2(neckR * 1.15, s.y * 0.92), V2(neckR * 1.15, s.y), V2(0, s.y)], segments: seg, seamTile: 0.05, material: accent),
                  Xform(translation: c))
        case .jar, .cup:
            let r = min(s.x, s.z) / 2
            let rb = k == .cup ? r * 0.8 : r
            m.add(Prim.lathe([V2(0, 0), V2(rb, 0), V2(r, s.y * 0.85), V2(0, s.y * 0.85)], segments: seg, seamTile: 0.05, material: body), Xform(translation: c))
            m.add(Prim.lathe([V2(rb + (r - rb) * 0.2 + 0.0008, s.y * 0.2), V2(rb + (r - rb) * 0.7 + 0.0008, s.y * 0.65)], segments: seg, seamTile: 0.05,
                             material: label), Xform(translation: c))
            m.add(Prim.lathe([V2(r * 1.02, s.y * 0.85), V2(r * 1.02, s.y), V2(0, s.y)], segments: seg, seamTile: 0.05, material: accent), Xform(translation: c))
        case .bag:
            m.add(Prim.superellipsoid(V3(s.x, s.y * 0.9, s.z), exponent: 3, subdivisions: tier == 0 && hi ? 3 : 2, material: body),
                  Xform(translation: at(V3(0, s.y * 0.45, 0)), rotation: rot))
            flat(&m, V3(s.x * 0.9, s.y * 0.1, s.z * 0.3), at(V3(0, s.y * 0.93, 0)), body, rot: rot)
            decal(&m, s.x * 0.55, s.y * 0.3, at(V3(0, s.y * 0.5, s.z * 0.47)), label, rot: rot)
        case .carton:
            flat(&m, V3(s.x, s.y * 0.82, s.z), at(V3(0, s.y * 0.41, 0)), label, rot: rot)
            let roof = Prim.extrude([V2(-s.z / 2, 0), V2(s.z / 2, 0), V2(0, s.y * 0.14)], depth: s.x, bevel: 0.0005, bevelSegments: 1, material: label)
            m.add(roof, Xform(translation: at(V3(0, s.y * 0.82, 0)), rotation: rot * simd_quatf(degrees: 90, axis: .up)))
            flat(&m, V3(s.x, s.y * 0.04, 0.003), at(V3(0, s.y * 0.98, 0)), label, rot: rot)
            decal(&m, s.x * 0.96, s.y * 0.3, at(V3(0, s.y * 0.35, fz)), body, rot: rot)
            decal(&m, s.x * 0.96, s.y * 0.06, at(V3(0, s.y * 0.68, fz)), accent, rot: rot)
        case .roll:
            let r = min(s.x, s.z) / 2
            m.add(Prim.lathe([V2(0, 0), V2(r, 0), V2(r, s.y), V2(0, s.y)], segments: seg, seamTile: 0.05, material: "paper.sheet:F6F5F0"), Xform(translation: c))
            m.add(Prim.lathe([V2(r * 1.01, s.y * 0.3), V2(r * 1.01, s.y * 0.6)], segments: seg, seamTile: 0.05, material: body), Xform(translation: c))
        }
    }

    /// Typical outer sizes (m) for a pack kind.
    static func size(_ k: Pack, _ rng: inout SeededRNG) -> V3 {
        switch k {
        case .box: return V3(rng.float(0.13...0.19), rng.float(0.2...0.3), 0.06)
        case .tallBox: return V3(0.075, rng.float(0.24...0.28), 0.045)
        case .tray: return V3(0.16, 0.06, 0.12)
        case .can: return V3(0.075, rng.float(0.1...0.13), 0.075)
        case .bottle: return V3(0.075, rng.float(0.22...0.3), 0.075)
        case .jug: return V3(0.15, 0.26, 0.15)
        case .jar: return V3(0.085, rng.float(0.1...0.14), 0.085)
        case .cup: return V3(0.075, 0.085, 0.075)
        case .bag: return V3(rng.float(0.18...0.24), rng.float(0.26...0.32), 0.08)
        case .carton: return V3(0.095, 0.25, 0.095)
        case .roll: return V3(0.13, 0.27, 0.13)
        }
    }

    /// Fills one shelf from x0 to x1 with facings whose fronts sit at `zFront` (facing +Z), `depth` deep,
    /// at most `maxH` tall. `backRows` adds cheap stock behind each facing.
    static func stockShelf(_ m: inout Model, x0: Float, x1: Float, y: Float, zFront: Float, depth: Float, maxH: Float,
                           packs: [Pack], fill: Float, rng: inout SeededRNG, hi: Bool, coarseAt: Int = 3500, boxAt: Int = 5000) {
        var x = x0 + rng.float(0...0.015)
        while x < x1 - 0.06 {
            let kind = packs[rng.int(0...(packs.count - 1))]
            var s = size(kind, &rng)
            if s.y > maxH { let k = maxH / s.y; s.y = maxH; if kind == .bag || kind == .box { s.x *= max(0.7, k) } }
            let p = palettes[rng.int(0...(palettes.count - 1))]
            let n = rng.int(2...5)
            let rows = max(1, Int((depth - 0.01) / s.z))
            for f in 0..<n {
                if x + s.x > x1 { break }
                if rng.float() > fill { x += s.x + 0.004; continue }
                let cx = x + s.x / 2
                let front = zFront - s.z / 2 - rng.float(0...0.008)
                let t = m.triangleCount
                let tier = t > boxAt ? 2 : (t > coarseAt || !hi ? 1 : 0)
                product(&m, kind, size: s, at: V3(cx, y, front), palette: p, hi: hi, yaw: rng.float(-1.5...1.5), tier: tier)
                if rows > 1 {
                    // Rest of the row behind the facing as one block in the body color.
                    let back = s.z * Float(rows - 1)
                    flat(&m, V3(s.x * 0.96, s.y * 0.9, back - 0.004), V3(cx, y + s.y * 0.45, front - s.z / 2 - back / 2), tint("paper.sheet", p.0))
                }
                x += s.x + rng.float(0.002...0.006)
            }
            x += rng.float(0.006...0.02)
        }
    }

    /// Clear price rail on a shelf lip (front face at `z`, facing +Z) with paper tags.
    static func priceRail(_ m: inout Model, x0: Float, x1: Float, y: Float, z: Float, rng: inout SeededRNG, hi: Bool) {
        flat(&m, V3(x1 - x0, 0.032, 0.006), V3((x0 + x1) / 2, y, z + 0.003), "plastic.clear")
        var tx = x0 + 0.06 + rng.float(0...0.04)
        while tx < x1 - 0.05 {
            let yellow = rng.chance(0.2)
            decal(&m, 0.06, 0.026, V3(tx, y, z + 0.0065), yellow ? "paper.sheet:F4D24A" : "paper.sheet:F7F6F0")
            if hi {
                decal(&m, 0.026, 0.008, V3(tx + 0.012, y - 0.002, z + 0.007), "plastic.matte:1A1A1C")
                decal(&m, 0.05, 0.003, V3(tx, y + 0.008, z + 0.007), yellow ? "plastic.matte:C8262B" : "plastic.matte:5A5C60")
            }
            tx += rng.float(0.12...0.22)
        }
    }

    /// Centers a model on X/Z and drops its base to y = 0.
    static func plant(_ m: Model) -> Model {
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }
}
