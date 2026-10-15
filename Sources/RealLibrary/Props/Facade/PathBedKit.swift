import simd
import Foundation

/// Helpers for the allotment and dirt ground tiles: edging boards on pegs, nails, field stones,
/// straw stalks, chips and grass blades. Tiles are 2 x 2 m, centered, base at y = 0.
enum PBK {
    /// Treated softwood edging board standing on edge from `a` to `b` (XZ), top at `top`, with
    /// square pegs every `pegEvery` meters on the `pegSide` (+1 / -1) face and two nails per peg.
    static func edging(_ m: inout Model, _ a: V2, _ b: V2, top: Float, height: Float = 0.15, thick: Float = 0.022,
                       pegSide: Float = 1, pegEvery: Float = 0.9, wood: MaterialKey = "wood.cedar-weathered",
                       nail: MaterialKey = "metal.galvanized-aged", rng: inout SeededRNG) {
        let d = b - a, len = simd_length(d), dir = d / len
        let yaw = -atan2(dir.y, dir.x) * 180 / .pi
        let c = (a + b) / 2
        let rot = simd_quatf(degrees: yaw, axis: .up)
        // Board: grain along X, slight lean and sag.
        let lean = rng.float(-1.5...1.5)
        m.add(Prim.roundedBox(V3(len - 0.004, height, thick), radius: 0.003, bevelSegments: 2, material: wood),
              Xform(translation: V3(c.x, top - height / 2, c.y), rotation: rot * simd_quatf(degrees: lean, axis: V3(1, 0, 0))))
        let nrm = V2(-dir.y, dir.x) * pegSide
        let n = max(2, Int((len / pegEvery).rounded()) + 1)
        for i in 0..<n {
            let t = (Float(i) + 0.5) / Float(n) * 0.94 + 0.03
            let p = a + d * t + nrm * (thick / 2 + 0.021)
            let ph = height + rng.float(0.0...0.015)
            m.add(Prim.roundedBox(V3(0.04, ph, 0.04), radius: 0.004, bevelSegments: 1, material: wood),
                  Xform(translation: V3(p.x, top - height + ph / 2 + 0.005, p.y), rotation: rot * simd_quatf(degrees: rng.float(-3...3), axis: .up)))
            // End-grain cap on the peg top.
            m.add(Prim.roundedBox(V3(0.038, 0.003, 0.038), radius: 0.001, bevelSegments: 1, material: "wood.endgrain-weathered"),
                  Xform(translation: V3(p.x, top - height + ph + 0.0055, p.y), rotation: rot))
            // Two nail heads on the outer face of the board through the peg.
            for k in 0..<2 {
                let q = a + d * t + d / len * (Float(k) - 0.5) * 0.018 - nrm * (thick / 2 + 0.0008)
                let face = V3(-nrm.x, 0, -nrm.y)
                m.add(Prim.cylinder(radius: 0.0045, height: 0.0018, bevel: 0.0006, segments: 8, material: nail),
                      Xform(translation: V3(q.x, top - height * (0.3 + 0.35 * Float(k)), q.y), rotation: facing(face)))
            }
        }
    }

    /// Field stone: noisy flattened superellipsoid half buried at `p`.
    static func stone(_ m: inout Model, at p: V3, size: Float, _ mat: MaterialKey, rng: inout SeededRNG) {
        let sd = UInt32(rng.int(0...9999))
        let s = Prim.superellipsoid(V3(size, size * rng.float(0.45...0.7), size * rng.float(0.6...0.9)), exponent: rng.float(2.2...3.2), subdivisions: 2, material: mat) { d in
            1 + 0.18 * Noise.fbm(d * 2.2, octaves: 2, seed: sd)
        }
        m.add(s, Xform(translation: p, rotation: simd_quatf(degrees: rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(-12...12), axis: V3(1, 0, 0))))
    }

    /// Straw stalk: thin hollow-looking tube with a kink.
    static func stalk(at p: V3, length: Float, yaw: Float, pitch: Float, rng: inout SeededRNG, material: MaterialKey) -> Surface {
        let d = V3(cos(yaw) * cos(pitch), sin(pitch), sin(yaw) * cos(pitch))
        let kink = rng.float(0.3...0.7)
        let bend = V3(rng.float(-0.15...0.15), rng.float(-0.05...0.08), rng.float(-0.15...0.15))
        let p1 = p + d * length * kink
        let p2 = p1 + simd_normalize(d + bend) * length * (1 - kink)
        let r = rng.float(0.0016...0.0028)
        return Prim.tube([p, p1, p2], radii: [r, r * 1.1, r * 0.8], sides: 4, seamTile: 0.2, material: material, capEnd: false)
    }

    /// Mown or long grass blades scattered in a rectangle (x0...x1, z0...z1) on height field `h`.
    static func grass(_ count: Int, x: ClosedRange<Float>, z: ClosedRange<Float>, height: Float, mown: Bool,
                      material: MaterialKey, rng: inout SeededRNG, keep: (V2) -> Bool = { _ in true }, h: (V2) -> Float) -> Surface {
        var s = Surface(material: material)
        var placed = 0, tries = 0
        while placed < count && tries < count * 4 {
            tries += 1
            let q = V2(rng.float(x), rng.float(z))
            guard keep(q) else { continue }
            var t = PlantKit.Tuft()
            t.count = mown ? 1 : 3; t.radius = mown ? 0.0001 : 0.02
            t.height = height; t.heightRange = 0.55...1.3
            t.width = mown ? 0.0025...0.0045 : 0.003...0.006
            t.lean = mown ? 0.05...0.5 : 0.1...0.6; t.splay = mown ? 0 : 0.4
            t.curl = 0...0.6; t.twist = 0.5
            t.segments = mown ? 2 : 3; t.mown = mown
            s.append(PlantKit.tuft(t, at: V3(q.x, h(q) - 0.002, q.y), rng: &rng, material: material))
            placed += 1
        }
        return s
    }
}
