import simd
import Foundation

/// Contemporary rod-hung glass canopy, 2.4 m wide, 1.2 m projection, 0.2 m high: two laminated glass panes (two 6 mm
/// leaves around a 1.5 mm interlayer) pitched 6 degrees, the back edges sealed in a stainless wall channel with a silicone
/// bead and the front corners clamped by spider fittings. Four stainless tie rods with hex turnbuckles run from cheek-plate
/// wall brackets down to the clamps. A black silicone joint closes the pane gap. The wall strip is stucco with tea stains
/// below the brackets; the glass carries a dust film, leaves and bird droppings. Wall plane at z = 0.
public struct GlassCanopyRodHung: RealAsset {
    public static let id = "glass-canopy-rod-hung"
    public static let summary = "Contemporary glass canopy, 2.4 m: two laminated panes hung on four stainless tie rods with turnbuckles and spider clamps."
    public static let tags = ["prop", "architecture", "facade", "glass", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 3.4)

    /// Overall width in meters.
    public var width: Float = 2.4
    /// Stainless fittings.
    public var steel: MaterialKey = "metal.stainless"
    /// Glass leaves.
    public var glass: MaterialKey = "glass.pane"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2
        let backY: Float = 0.158, backZ: Float = 0.03, frontZ: Float = 1.17
        let tanA = (0.118 as Float) / (frontZ - backZ)
        let alpha = atan(tanA)
        let aDeg = alpha * 180 / .pi
        let tilt = FA.q(aDeg, FA.X)
        let nrm = V3(0, cos(alpha), sin(alpha))
        func gy(_ z: Float) -> Float { backY - (z - backZ) * tanA + 0.0068 }   // top of the glass at z
        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, rot: simd_quatf = .identity) { FA.box(&m, s, c, mat, r: r, rot: rot) }
        func cylY(r: Float, h: Float, at c: V3, _ mat: MaterialKey, bevel: Float, segments: Int) {
            m.add(Prim.cylinder(radius: r, height: h, bevel: bevel, segments: segments, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        func flat(_ s: V3, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity) {
            let x = s.x / 2, y = s.y / 2
            m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: rot))
        }

        // Wall strip with tea stains below the brackets.
        let wallY0: Float = 0.025, wallH: Float = 0.2025
        bx(V3(width, wallH, 0.02), V3(0, wallY0 + wallH / 2, 0.01), "paint.stucco:D9D2C2", r: 0.002)
        flat(V3(width, 0.03, 0.0215), V3(0, wallY0 + 0.015, 0.0105), "paint.stucco:A79F8E")
        for x in [-1.14 as Float, -0.06, 0.06, 1.14] {
            if !lite { flat(V3(0.016, 0.1, 0.0012), V3(x + 0.004, 0.185 - 0.075, 0.0206), "metal.rust:8A5A36") }
        }

        // Wall channel (C section open to the front) with silicone bead.
        let ch: [V2] = [V2(0, 0.108), V2(0.05, 0.108), V2(0.05, 0.116), V2(0.012, 0.116), V2(0.012, 0.19), V2(0.05, 0.19), V2(0.05, 0.198), V2(0, 0.198)]
        FA.run(&m, ch, length: width, at: V3(0, 0, 0.02), steel, bevel: 0.0008)
        flat(V3(width - 0.01, 0.008, 0.006), V3(0, backY + 0.0078, 0.071), "plastic.black", rot: tilt)

        // Panes: two laminated panes with a gap, layered along the glass normal.
        let paneLen = (frontZ - backZ) / cos(alpha)
        let cz = (frontZ + backZ) / 2, cy = backY - 0.5 * (frontZ - backZ) * tanA + 0.0 - 0.0
        for sx: Float in [-1, 1] {
            let px = sx * (hw / 2 + 0.005)
            let pw = hw - 0.01
            for (off, th, mat) in [(0.0066 as Float, 0.010 as Float, glass), (0.0, 0.0032, "glass.emerald"), (-0.0066, 0.010, glass)] {
                let c = V3(px, cy, cz) + nrm * (off - 0.0)
                m.add(Prim.roundedBox(V3(pw, th, paneLen), radius: min(0.0009, th * 0.4), bevelSegments: 1, material: mat), Xform(translation: c, rotation: tilt))
            }
        }
        flat(V3(0.011, 0.014, paneLen), V3(0, cy, cz), "plastic.black", rot: tilt)

        // Tie rods, turnbuckles, clamps, wall brackets.
        for x in [-1.14 as Float, -0.06, 0.06, 1.14] {
            let fz: Float = 1.10
            let top = gy(fz)
            let clevisY = top + 0.036
            let a = V3(x, 0.185, 0.034), b = V3(x, clevisY, fz)
            FA.rod(&m, a, b, r: 0.0115, steel, sides: lite ? 6 : 8)
            let dir = simd_normalize(b - a)
            let mid = a + (b - a) * 0.5
            m.add(Prim.cylinder(radius: 0.0165, height: 0.1, bevel: 0.002, segments: 6, bevelSegments: 1, material: steel), Xform(translation: mid - dir * 0.05, rotation: facing(dir)))
            for e: Float in [-1, 1] { m.add(Prim.cylinder(radius: 0.0125, height: 0.014, bevel: 0.0015, segments: 8, bevelSegments: 1, material: steel), Xform(translation: mid + dir * (e * 0.06 - (e < 0 ? 0.008 : 0.0)), rotation: facing(dir))) }
            // Spider clamp: top disc, stud, bottom disc, clevis block.
            cylY(r: 0.042, h: 0.011, at: V3(x, top, fz), steel, bevel: 0.0015, segments: lite ? 12 : 20)
            cylY(r: 0.0085, h: 0.012, at: V3(x, top + 0.009, fz), steel, bevel: 0.001, segments: 8)
            cylY(r: 0.036, h: 0.009, at: V3(x, top - 0.023 - 0.009, fz), steel, bevel: 0.0012, segments: lite ? 12 : 18)
            bx(V3(0.022, 0.026, 0.03), V3(x, top + 0.0235, fz), steel, r: 0.003)
            if !lite { hexBolt(&m, at: V3(x, top + 0.0205, fz + 0.016), normal: FA.Z, size: 0.012, material: "metal.screw-zinc") }
            // Wall bracket: plate, cheeks, pin.
            bx(V3(0.07, 0.085, 0.008), V3(x, 0.185, 0.0215), steel, r: 0.0015)
            for c: Float in [-1, 1] { bx(V3(0.006, 0.034, 0.034), V3(x + c * 0.0115, 0.185, 0.043), steel, r: 0.001) }
            m.add(Prim.cylinder(radius: 0.0045, height: 0.036, bevel: 0.0008, segments: 8, bevelSegments: 1, material: steel), Xform(translation: V3(x - 0.018, 0.185, 0.043), rotation: FA.q(-90, FA.Z)))
            if !lite { for dy: Float in [-0.03, 0.03] { hexBolt(&m, at: V3(x, 0.185 + dy, 0.0255), normal: FA.Z, size: 0.009, material: "metal.screw-zinc") } }
        }

        // Printed ceramic frit band along the wall edge, leaves and bird droppings.
        for sx: Float in [-1, 1] {
            flat(V3(hw - 0.02, 0.0007, 0.13), V3(sx * (hw / 2 + 0.005), gy(0.17) + 0.0004, 0.17), "metal.painted:26282A", rot: tilt)
        }
        if !lite {
            func blob(_ pts: [V2], _ c: V3, _ mat: MaterialKey, yaw: Float) {
                m.add(Prim.extrude(pts, depth: 0.0018, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: tilt * FA.q(90, FA.X) * FA.q(yaw, FA.Z)))
            }
            let leafShape: [V2] = [V2(-0.03, 0), V2(-0.015, 0.012), V2(0.012, 0.014), V2(0.03, 0.002), V2(0.012, -0.012), V2(-0.014, -0.011)]
            for _ in 0..<8 {
                let x = rng.float(-1.1...1.1), z = rng.float(0.3...1.05)
                if abs(x) < 0.04 { continue }
                let leaf: MaterialKey = rng.chance(0.55) ? "wood.weathered:6B4E2E" : "stone.granite-moss"
                blob(leafShape, V3(x, gy(z) + 0.001, z), leaf, yaw: rng.float(0...360))
            }
            let drop: [V2] = [V2(-0.014, 0), V2(-0.006, 0.01), V2(0.008, 0.009), V2(0.015, 0), V2(0.006, -0.008), V2(-0.008, -0.009)]
            for _ in 0..<5 {
                let x = rng.float(-1.0...1.0), z = rng.float(0.35...1.0)
                if abs(x) < 0.04 { continue }
                blob(drop, V3(x, gy(z) + 0.001, z), "paint.stucco:F2F0E8", yaw: rng.float(0...360))
            }
            // Grime and algae collecting at the front edge, the pane gap and in water runs.
            for sx: Float in [-1, 1] {
                flat(V3(hw - 0.05, 0.0009, 0.06), V3(sx * (hw / 2 + 0.005), gy(1.13) + 0.0005, 1.13), "wood.weathered:4F4536", rot: tilt)
                flat(V3(0.03, 0.0009, 1.0), V3(sx * 0.03, gy(0.62) + 0.0005, 0.62), "wood.weathered:55483A", rot: tilt)
                for k in 0..<5 {
                    let x = sx * (0.15 + Float(k) * 0.24 + rng.float(-0.03...0.03)), len = rng.float(0.25...0.6)
                    flat(V3(0.012, 0.0009, len), V3(x, gy(0.2 + len / 2) + 0.0005, 0.2 + len / 2), "wood.weathered:6A5C4A", rot: tilt)
                }
            }
            // Tea staining around the clamps and on the rod ends.
            for x in [-1.14 as Float, -0.06, 0.06, 1.14] {
                flat(V3(0.1, 0.0009, 0.2), V3(x, gy(1.08) + 0.0006, 1.08), "wood.weathered:6B4A2A", rot: tilt)
            }
            for x in [-0.9 as Float, 0.8, -0.4] { flat(V3(0.1, 0.0009, 0.1), V3(x, gy(1.12) + 0.0006, 1.12), "stone.granite-moss", rot: tilt) }
            // Milky dust and limescale haze where water lingers at the lower edge.
            for sx: Float in [-1, 1] { flat(V3(hw - 0.12, 0.0009, 0.30), V3(sx * (hw / 2 + 0.005), gy(0.98) + 0.0007, 0.98), "glass.frosted", rot: tilt) }
            // Dust film along the front edge: narrow frosted strips.
            for sx: Float in [-1, 1] { flat(V3(hw - 0.12, 0.0007, 0.07), V3(sx * (hw / 2 + 0.005), gy(1.1) + 0.0004, 1.1), "glass.frosted", rot: tilt) }
        }

        groundAO(&m, height: 0.05, floor: 0.8)
        return FC.place(m)
    }
}
