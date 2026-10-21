import simd
import Foundation

/// 18th-century slate headstone from Boston's Central Burying Ground: a 5 cm slab with a tall
/// arched tympanum between two rounded shoulders, a winged death's head carved in low relief,
/// an incised border and rows of lettering grooves. Leans in the turf; lichen on the weather side.
public struct SlateHeadstone: RealAsset {
    public static let id = "slate-headstone"
    public static let summary = "18th-century Boston slate headstone with tympanum and shoulders, winged death's head, lettering grooves and lichen, leaning."
    public static let tags = ["prop", "stone", "antique", "park", "outdoor"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 10, distance: 1.0)

    /// Slab width in meters.
    public var width: Float = 0.62
    /// Height above grade to the tympanum crown in meters.
    public var height: Float = 0.92
    /// Slab thickness in meters.
    public var thickness: Float = 0.05
    /// Lean in degrees (positive tips backward, negative forward).
    public var tilt: Float = 6
    /// Sideways lean in degrees.
    public var roll: Float = 2.5
    /// Slate material key.
    public var slate: MaterialKey = "stone.slate"
    /// Carved (freshly-cut, paler) relief material key.
    public var carved: MaterialKey = "stone.slate:6B737B"
    /// Cut lettering grooves (shadowed, darker than the face).
    public var letters: MaterialKey = "stone.slate:1F2328"
    /// Lichen material key.
    public var lichen: MaterialKey = "concrete.rough:7A8064"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2
        let sh = height * 0.74                  // shoulder spring line
        let lobe: Float = width * 0.11          // shoulder radius
        let tx = hw * 0.53                      // tympanum half width
        let tyH = height - sh                   // tympanum rise
        var o: [V2] = [V2(-hw, 0), V2(hw, 0), V2(hw, sh)]
        // Right shoulder lobe, then notch, tympanum arch, left notch and lobe.
        let rc = V2(hw - lobe, sh)
        for i in 1...6 { let a = Float.pi * 0.85 * Float(i) / 6; o.append(rc + V2(cos(a), sin(a)) * lobe) }
        o.append(V2(tx + 0.012, sh + lobe * 0.35))
        for i in 0...14 { let a = Float.pi * Float(i) / 14; o.append(V2(tx * cos(a), sh + lobe * 0.35 + (tyH - lobe * 0.35) * sin(a))) }
        o.append(V2(-tx - 0.012, sh + lobe * 0.35))
        let lc = V2(-hw + lobe, sh)
        for i in 0...5 { let a = Float.pi * 0.15 + Float.pi * 0.85 * Float(i) / 6; o.append(lc + V2(cos(a), sin(a)) * lobe) }
        o.append(V2(-hw, sh))
        o = Shape2D.deduped(o)
        var slab = Prim.extrude(o, depth: thickness, bevel: 0.006, bevelSegments: 2, material: slate)
        slab.displace { p, n in 0.0015 * sin(p.x * 31 + p.y * 17) * sin(p.y * 23) }   // riven slate face
        var g = Model(name: "stone")
        g.add(slab)
        let fz = thickness / 2
        // Incised border following the outline.
        let border = Shape2D.offset(o.filter { $0.y > -0.01 }, -0.03)
        _ = border
        // Death's head: skull dome, brow, eye sockets, teeth bar.
        let skullY = sh + tyH * 0.42
        var skull = Prim.superellipsoid(V3(0.1, 0.11, 0.03), exponent: 2.4, subdivisions: 6, material: carved)
        skull.deform { V3($0.x, $0.y, max($0.z, -0.004)) }
        g.add(skull, Xform(translation: V3(0, skullY, fz)))
        let socket = Prim.superellipsoid(V3(0.028, 0.022, 0.012), exponent: 2, subdivisions: 3, material: slate)
        for sx in [Float(-0.022), 0.022] { g.add(socket, Xform(translation: V3(sx, skullY + 0.004, fz + 0.012))) }
        g.add(Prim.roundedBox(V3(0.006, 0.016, 0.008), radius: 0.002, bevelSegments: 1, material: slate), Xform(translation: V3(0, skullY - 0.018, fz + 0.012)))
        for i in 0..<5 {
            g.add(Prim.roundedBox(V3(0.007, 0.012, 0.01), radius: 0.002, bevelSegments: 1, material: carved), Xform(translation: V3(Float(i - 2) * 0.009, skullY - 0.05, fz + 0.004)))
        }
        // Wings: feather fans either side, each feather a thin extruded blade.
        for side in [Float(-1), 1] {
            for k in 0..<5 {
                let len: Float = 0.112 - Float(k) * 0.011
                let blade = Shape2D.deduped([V2(0, -0.011), V2(len * 0.85, -0.009), V2(len, 0), V2(len * 0.85, 0.011), V2(0, 0.011)])
                var b = Prim.extrude(side > 0 ? blade : blade.map { V2(-$0.x, $0.y) }.reversed(), depth: 0.01, bevel: 0.002, bevelSegments: 1, material: carved)
                b.deform { $0 }
                let ang = side * (12 - Float(k) * 9)
                g.add(b, Xform(translation: V3(side * 0.04, skullY + 0.012 - Float(k) * 0.004, fz + 0.002), rotation: simd_quatf(degrees: ang, axis: V3(0, 0, 1))))
            }
        }
        // Lettering grooves: rows of short dark strokes in a pale ground (worn cut letters).
        let groove = Prim.extrude(Shape2D.rect(1, 0.012), depth: 0.004, bevel: 0, bevelSegments: 0, material: letters)
        let rows: [Float] = [0.42, 0.66, 0.7, 0.6, 0.48, 0.55, 0.3]
        for (j, w) in rows.enumerated() {
            var r = rng.fork(j)
            let y = sh - 0.07 - Float(j) * 0.052
            if y < 0.1 { break }
            var x = -width * w / 2
            let end = width * w / 2
            while x < end {
                let wl = min(r.float(0.03...0.1), end - x)
                if wl > 0.012 {
                    g.add(groove, Xform(translation: V3(x + wl / 2, y, fz - 0.0005), scale: V3(wl, j == 0 ? 1.4 : 1, 1)))
                }
                x += wl + r.float(0.012...0.02)
            }
        }
        // Border line: four incised strips inside the edges.
        let line = Prim.extrude(Shape2D.rect(0.006, 1), depth: 0.004, bevel: 0, bevelSegments: 0, material: letters)
        for sx in [Float(-1), 1] {
            g.add(line, Xform(translation: V3(sx * (hw - 0.035), (sh - 0.02) / 2 + 0.05, fz - 0.0005), scale: V3(1, sh - 0.12, 1)))
        }
        // Lichen rosettes, mostly on the upper back and shoulders.
        for i in 0..<12 {
            var r = rng.fork(100 + i)
            let rad = r.float(0.015...0.045)
            let px = r.float(-hw * 0.8...hw * 0.8)
            let py = r.float(sh * 0.5...sh + 0.02)
            let back = true
            let blob = (0..<9).map { k -> V2 in let a = Float(k) / 9 * 2 * .pi; let rr = rad * r.float(0.6...1.15); return V2(cos(a) * rr, sin(a) * rr) }
            let disc = Prim.extrude(blob, depth: 0.0016, bevel: 0, bevelSegments: 0, material: lichen)
            g.add(disc, Xform(translation: V3(px, py, back ? -fz - 0.0002 : fz + 0.0003)))
        }
        // Lean: rotate about the grade line, keep the foot buried.
        let q = simd_quatf(degrees: roll, axis: V3(0, 0, 1)) * simd_quatf(degrees: -tilt, axis: V3(1, 0, 0))
        var t = Model(name: Self.id)
        t.add(g, Xform(rotation: q))
        let bb = t.bounds
        m.add(g, Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y - 0.012, -(bb.min.z + bb.max.z) / 2), rotation: q))
        // Clip below grade by shifting nothing: base sits at y = 0 through the mound.
        groundAO(&m)
        return LODModel(m)
    }
}
