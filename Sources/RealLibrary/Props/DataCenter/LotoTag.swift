import simd
import Foundation

/// Lockout tagout set: red laminated safety padlock with a steel shackle through the grommet of a red and white DANGER DO NOT OPERATE tag, on a nylon zip tie. Parts: tag, red header, DANGER text, DO NOT OPERATE text, grommet, zip tie, padlock body, padlock shackle, keyhole.
public struct LotoTag: RealAsset {
    public static let id = "loto-tag"
    public static let summary = "Lockout/tagout set: red laminated safety padlock with steel shackle through the grommet of a red/white DANGER DO NOT OPERATE tag on a zip tie."
    public static let tags = ["prop", "handheld"]
    public static let budget = 1500
    public static let author = "realityhd"

    /// Tag size in meters (x width, y height, z thickness).
    public var tagSize = V3(0.075, 0.14, 0.004)
    /// Tag stock.
    public var paper: MaterialKey = "plastic.matte:F2F2F2"
    /// Header, border and lettering red.
    public var red: MaterialKey = "plastic.matte:D62A1E"
    /// Padlock plates.
    public var lockBody: MaterialKey = "metal.painted:C21E1A"
    /// Shackle and grommet.
    public var steel: MaterialKey = "metal.steel"
    /// Zip tie nylon.
    public var nylon: MaterialKey = "plastic.matte:1C1C1E"

    public init() {}

    static let font: [Character: [UInt8]] = [
        "D": [0b11110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11110],
        "A": [0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
        "N": [0b10001, 0b11001, 0b10101, 0b10101, 0b10011, 0b10001, 0b10001],
        "G": [0b01110, 0b10001, 0b10000, 0b10111, 0b10001, 0b10001, 0b01111],
        "E": [0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111],
        "R": [0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001],
        "O": [0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110],
        "T": [0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100],
        "P": [0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000],
        "M": [0b10001, 0b11011, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001],
    ]

    /// Printed lettering as merged pixel runs on the plane z, facing +Z, centered on cx, bottom at y0.
    static func decal(_ text: String, cx: Float, y0: Float, z: Float, px: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let adv = 6 * px
        let total = Float(text.count) * adv - px
        var gx = cx - total / 2
        for ch in text {
            if let rows = font[ch] {
                // Pixel runs per row, then merge identical runs on consecutive rows into taller quads.
                var open: [Int: (c: Int, e: Int, r0: Int)] = [:]   // keyed by c*8+e
                var rects: [(c: Int, e: Int, r0: Int, r1: Int)] = []
                for (r, bits) in rows.enumerated() {
                    var keys = Set<Int>()
                    var c = 0
                    while c < 5 {
                        if bits & (1 << UInt8(4 - c)) == 0 { c += 1; continue }
                        var e = c
                        while e < 5 && bits & (1 << UInt8(4 - e)) != 0 { e += 1 }
                        keys.insert(c * 8 + e)
                        if open[c * 8 + e] == nil { open[c * 8 + e] = (c, e, r) }
                        c = e
                    }
                    for (k, v) in open where !keys.contains(k) { rects.append((v.c, v.e, v.r0, r - 1)); open[k] = nil }
                }
                for v in open.values { rects.append((v.c, v.e, v.r0, 6)) }
                for q in rects {
                    let x0 = gx + Float(q.c) * px, x1 = gx + Float(q.e) * px
                    let ya = y0 + Float(6 - q.r1) * px, yb = y0 + Float(7 - q.r0) * px
                    let n = V3(0, 0, 1)
                    let a = s.add(V3(x0, ya, z), n, V2(x0, ya)), b = s.add(V3(x1, ya, z), n, V2(x1, ya))
                    let cc = s.add(V3(x1, yb, z), n, V2(x1, yb)), d = s.add(V3(x0, yb, z), n, V2(x0, yb))
                    s.quad(a, b, cc, d)
                }
            }
            gx += adv
        }
        s.computeTangents()
        return s
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = tagSize.x, h = tagSize.y, t = tagSize.z
        let hy: Float = h - 0.014          // grommet centre height
        let hr: Float = 0.0055             // hole radius
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.0004) {
            if r < 0.001 { m.add(cuboid(s, material: mat), Xform(translation: c)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        func layer0(_ s: V3, _ c: V3, _ mat: MaterialKey) { m.add(cuboid(s, material: mat), Xform(translation: c)) }
        func flat(_ s: V3, _ c: V3, _ mat: MaterialKey) { m.add(cuboid(s, material: mat), Xform(translation: c)) }

        // Tag stock around the grommet hole: lower body, two cheeks, top strip.
        let lowTop = hy - hr
        box(V3(w, lowTop, t), V3(0, lowTop / 2, 0), paper, r: 0.0009)
        let cheek = w / 2 - hr
        for s: Float in [-1, 1] { box(V3(cheek, 2 * hr, t), V3(s * (hr + cheek / 2), hy, 0), paper) }
        box(V3(w, h - hy - hr, t), V3(0, (h + hy + hr) / 2, 0), paper, r: 0.0009)
        // Steel grommet ring (rotated into the tag plane).
        m.add(Prim.torus(major: hr + 0.0008, minor: 0.0009, segments: 12, sides: 5, material: steel),
              Xform(translation: V3(0, hy, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

        // Printed layers, both faces. Face f = +1 front, -1 back (rotated 180 degrees about Y).
        let zf = t / 2 + 0.0003
        for f: Float in [1, -1] {
            let q = simd_quatf(degrees: f > 0 ? 0 : 180, axis: V3(0, 1, 0))
            func add(_ s: Surface) { m.add(s, Xform(rotation: q)) }
            func layer(_ s: V3, _ c: V3, _ mat: MaterialKey) { m.add(cuboid(s, material: mat), Xform(translation: V3(c.x * f, c.y, c.z * f), rotation: q) ) }
            // Red header block with the hole cut out: top strip, cheeks, lower band.
            let headY0: Float = 0.088
            layer(V3(w - 0.002, hy - hr - headY0, 0.0006), V3(0, (headY0 + hy - hr) / 2, t / 2 + 0.0001), red)
            for s: Float in [-1, 1] {
                layer(V3(w / 2 - hr - 0.0015, 2 * hr, 0.0006), V3(s * (hr + 0.0005 + (w / 2 - hr - 0.001) / 2 - 0.0005 + 0.0005), hy, t / 2 + 0.0001), red)
            }
            layer(V3(w - 0.002, h - hy - hr - 0.001, 0.0006), V3(0, (h + hy + hr) / 2 - 0.0005, t / 2 + 0.0001), red)
            // Red border on the white lower field.
            let bw: Float = 0.0035
            layer(V3(w - 0.002, bw, 0.0005), V3(0, 0.0015 + bw / 2, t / 2 + 0.0001), red)
            for s: Float in [-1, 1] {
                layer(V3(bw, headY0 - 0.0015, 0.0005), V3(s * (w / 2 - 0.001 - bw / 2), (headY0 + 0.0015) / 2, t / 2 + 0.0001), red)
            }
            add(Self.decal("DANGER", cx: 0, y0: 0.0955, z: zf + 0.0005, px: 0.0016, material: "plastic.matte:FAFAFA"))
            if f > 0 {
                add(Self.decal("DO NOT", cx: 0, y0: 0.066, z: zf, px: 0.0016, material: red))
                add(Self.decal("OPERATE", cx: 0, y0: 0.045, z: zf, px: 0.0014, material: red))
            }
            if f > 0 {
                layer(V3(0.046, 0.0007, 0.0004), V3(0.012, 0.0205, t / 2 + 0.0001), "plastic.matte:2A2A2C")
                layer(V3(0.046, 0.0007, 0.0004), V3(0.012, 0.0095, t / 2 + 0.0001), "plastic.matte:2A2A2C")
                // Story detail: ballpoint scrawl and a crease scuff.
                let j = rng.float(0...1)
                layer(V3(0.018 + 0.012 * j, 0.0008, 0.0004), V3(0.004, 0.0225, t / 2 + 0.0002), "plastic.matte:1F3A8A")
                layer(V3(0.012, 0.0008, 0.0004), V3(0.02, 0.0125, t / 2 + 0.0002), "plastic.matte:1F3A8A")
                layer(V3(0.022, 0.0009, 0.0004), V3(0.012, 0.0765, t / 2 + 0.0002), "plastic.matte:E4E4E0")
            }
        }

        // Zip tie: flat band loop around the top strip, through the grommet; head and tail.
        let loopR: Float = 0.011, loopCy: Float = hy - hr + 0.0005 + loopR - 0.0005
        m.add(Prim.torus(major: loopR, minor: 0.0019, segments: 16, sides: 4, material: nylon),
              Xform(translation: V3(0.0034, loopCy, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        box(V3(0.0075, 0.009, 0.0065), V3(0.0034, loopCy + loopR, 0.0), nylon, r: 0.0006)
        box(V3(0.0036, 0.022, 0.001), V3(0.0034, loopCy + loopR + 0.014, 0.0048), nylon, r: 0.0002)

        // Wear: scuffs and a dirty thumb smear on the tag front, scratches on the padlock.
        for i in 0..<3 {
            let r = rng.fork(i)
            var rr = r
            layer0(V3(0.004 + rr.float(0...0.01), 0.0009, 0.0004), V3(rr.float(-0.03...0.03), 0.01 + rr.float(0...0.04), t / 2 + 0.0004), "plastic.matte:C9C5B8")
        }
        flat(V3(0.03, 0.012, 0.0003), V3(0.008, 0.032, t / 2 + 0.0002), "plastic.matte:D9D2BE")
        flat(V3(0.018, 0.02, 0.0003), V3(-0.015, 0.012, t / 2 + 0.0002), "plastic.matte:DDD7C6")
        // Padlock: laminated plate stack above the tag, shackle legs straddling the top strip.
        let lw: Float = 0.05, ld: Float = 0.028, lh: Float = 0.04
        let ly0: Float = 0.158
        let plates = 6
        let ph = lh / Float(plates)
        box(V3(lw, lh, ld), V3(-0.0015, ly0 + lh / 2, 0), lockBody, r: 0.0025)
        for i in 1..<plates {
            flat(V3(lw + 0.0006, 0.0005, ld + 0.0006), V3(-0.0015, ly0 + ph * Float(i), 0), "plastic.matte:2B1412")
        }
        // Corner rivets on the front plate and a keyhole boss on the front lower plate.
        for sx: Float in [-1, 1] {
            for y in [ly0 + 0.006, ly0 + lh - 0.006] {
                flat(V3(0.0034, 0.0034, 0.0012), V3(-0.0015 + sx * (lw / 2 - 0.006), y, ld / 2), steel)
            }
        }
        m.add(Prim.cylinder(radius: 0.0055, height: 0.0014, bevel: 0.0003, segments: 10, bevelSegments: 1, material: steel),
              Xform(translation: V3(-0.0015, ly0 + 0.011, ld / 2 - 0.0002), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        flat(V3(0.0024, 0.0066, 0.0004), V3(-0.0015, ly0 + 0.011, ld / 2 + 0.0014), "plastic.matte:0E0E10")
        for i in 0..<4 {
            var rr = rng.fork(10 + i)
            flat(V3(0.006 + rr.float(0...0.008), 0.0007, 0.0004), V3(-0.0015 + rr.float(-0.018...0.018), ly0 + 0.004 + rr.float(0...0.032), ld / 2 + 0.0002), "plastic.matte:E6A59A")
        }
        // Steel shackle: inverted U, legs in the body, round through the grommet.
        let sr: Float = 0.0055, scy = hy - hr + 0.0015 + sr - 0.0015
        var sp: [V3] = [V3(0, ly0 + 0.014, -sr), V3(0, scy + 0.012, -sr), V3(0, scy + 0.004, -sr)]
        for i in 0...8 {
            let a = Float(i) / 8 * .pi
            sp.append(V3(0, scy - sr * sin(a), -sr * cos(a)))
        }
        sp += [V3(0, scy + 0.004, sr), V3(0, scy + 0.012, sr), V3(0, ly0 + 0.014, sr)]
        m.add(Prim.tube(sp, radii: Array(repeating: 0.002, count: sp.count), sides: 6, seamTile: 0.02, material: steel, capEnd: true),
              Xform(translation: V3(-0.0015, 0, 0)))
        return LODModel(m)
    }
}
