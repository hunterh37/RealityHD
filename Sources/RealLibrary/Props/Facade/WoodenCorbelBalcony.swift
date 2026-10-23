import simd
import Foundation

/// Alpine timber balcony, 2.0 m wide, 1.0 m projection, 1.0 m high: three carved corbels (scroll tip, groove lines,
/// base boss) under a wall ledger bolted with iron, five joists with chamfered ends, a scalloped front fascia, a gapped
/// plank floor, four chamfered posts with pyramid caps, and a balustrade of pointed slats between top and bottom rails on
/// three sides. The wall is vertical planks. Wood is silver-brown weathered spruce with checks, rust bleed at the bolts
/// and moss in the corbel joints. Wall plane at z = 0.
public struct WoodenCorbelBalcony: RealAsset {
    public static let id = "wooden-corbel-balcony"
    public static let summary = "Alpine timber balcony, 2.0 m: carved corbels, joists, scalloped fascia, plank floor, pointed slat balustrade."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 2.6)

    /// Overall width in meters.
    public var width: Float = 2.0
    /// Projection from the wall.
    public var projection: Float = 1.0
    /// Dark stained structural timber.
    public var timber: MaterialKey = "wood.weathered:8F7456"
    /// Weathered boards and slats.
    public var board: MaterialKey = "wood.weathered:8E7A62"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, D = projection
        let dark: MaterialKey = "wood.weathered:4A3A2C"
        let joistY0: Float = 0.30, joistY1: Float = 0.40, floorTop: Float = 0.43
        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, rot: simd_quatf = .identity) {
            if r <= 0.0006 {
                let x = s.x / 2, y = s.y / 2
                m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: rot))
            } else { FA.box(&m, s, c, mat, r: r, rot: rot) }
        }
        func pick(_ i: Int) -> MaterialKey {
            let t: [MaterialKey] = [board, "wood.weathered:826C54", "wood.weathered:9A866C", "wood.weathered:76624C", "wood.weathered:A19076"]
            return t[i % t.count]
        }

        // Wall cleats: short vertical plank strips behind each corbel and the rear posts, so the piece stands on the wall plane.
        for cx in [-0.8 as Float, 0, 0.8] {
            bx(V3(0.16, 0.34, 0.03), V3(cx, 0.17, 0.015), pick(rng.int(0...4)), r: 0.0005)
        }
        for sx: Float in [-1, 1] { bx(V3(0.12, 1.0, 0.03), V3(sx * (hw - 0.06), 0.5, 0.015), pick(rng.int(0...4)), r: 0.0005) }

        // Corbels.
        var prof: [V2] = [V2(0.04, joistY0), V2(0.88, joistY0), V2(0.90, joistY0 - 0.012), V2(0.90, joistY0 - 0.065)]
        let n = lite ? 8 : 16
        func curve(_ t: Float) -> V2 { V2(0.90 - 0.80 * t, 0.045 + 0.19 * (1 - (3 * t * t - 2 * t * t * t))) }
        for i in 1...n { prof.append(curve(Float(i) / Float(n))) }
        prof += [V2(0.08, 0.0), V2(0.04, 0.0)]
        for cx in [-0.8 as Float, 0, 0.8] {
            m.add(Prim.extrude(prof, depth: 0.09, bevel: 0.006, bevelSegments: 1, material: "wood.weathered:5E4835"), Xform(translation: V3(cx, 0, 0), rotation: FA.q(-90, FA.Y)))
            if !lite {
                for f: Float in [-1, 1] {
                    var ribbon: [V2] = []
                    for i in 0...10 { let c = curve(0.08 + Float(i) / 10 * 0.8); ribbon.append(V2(c.x, c.y + 0.036)) }
                    for i in (0...10).reversed() { let c = curve(0.08 + Float(i) / 10 * 0.8); ribbon.append(V2(c.x, c.y + 0.046)) }
                    m.add(Prim.extrude(ribbon, depth: 0.002, bevel: 0, bevelSegments: 1, material: "wood.weathered:B09A7A"), Xform(translation: V3(cx + f * 0.0455, 0, 0), rotation: FA.q(-90, FA.Y)))
                    FA.cylX(&m, r: 0.034, h: 0.006, at: V3(cx + f * 0.0475 - 0.003, 0.07, 0.12), board, bevel: 0.0015, segments: 16)
                    FA.cylX(&m, r: 0.011, h: 0.008, at: V3(cx + f * 0.0475 - 0.004, 0.262, 0.845), dark, bevel: 0.001, segments: 10)
                }
                // Moss where the corbel meets the ledger, rust bleed under the bolt.
                bx(V3(0.07, 0.01, 0.06), V3(cx, joistY0 - 0.004, 0.09), "stone.granite-moss", r: 0.0005)
            }
            for f: Float in [-1, 1] { hexBolt(&m, at: V3(cx + f * 0.045, 0.17, 0.09), normal: V3(f, 0, 0), size: 0.02, material: "metal.rust") }
        }

        // Ledger with bolts, joists, front fascia, floor planks.
        bx(V3(width, 0.12, 0.07), V3(0, joistY0 + 0.04, 0.055), timber, r: 0.004)
        for x in [-0.9 as Float, -0.45, 0, 0.45, 0.9] {
            hexBolt(&m, at: V3(x, joistY0 + 0.04, 0.0915), normal: FA.Z, size: 0.018, material: "metal.rust")
            if !lite { bx(V3(0.014, 0.09, 0.0016), V3(x + 0.004, joistY0 - 0.012, 0.0925), "metal.rust", r: 0.0003) }
        }
        for x in [-0.9 as Float, -0.45, 0, 0.45, 0.9] {
            let jp: [V2] = [V2(0.09, joistY0), V2(D - 0.045, joistY0), V2(D - 0.03, joistY0 + 0.012), V2(D - 0.03, joistY1 - 0.012), V2(D - 0.045, joistY1), V2(0.09, joistY1)]
            m.add(Prim.extrude(jp, depth: 0.09, bevel: 0.004, bevelSegments: 1, material: timber), Xform(translation: V3(x, 0, 0), rotation: FA.q(-90, FA.Y)))
            if !lite { bx(V3(0.002, 0.003, 0.5), V3(x + 0.045, 0.37, 0.5), dark, r: 0.0003) }   // drying check
        }
        // Scalloped fascia.
        let nS = lite ? 5 : 10
        var fa: [V2] = [V2(-hw, 0.405), V2(hw, 0.405)]
        let sw = width / Float(nS)
        for i in (0..<nS).reversed() {
            let cxs = -hw + (Float(i) + 0.5) * sw
            for k in 0...6 {
                let a = Float(k) / 6 * .pi
                fa.append(V2(cxs + cos(a) * (sw / 2 - 0.004), 0.30 - sin(a) * 0.035 + 0.0))
            }
        }
        // reorder bottom: right to left already (i descending, angle 0..pi goes right to left within a scallop)
        m.add(Prim.extrude(fa, depth: 0.035, bevel: 0.003, bevelSegments: 1, material: board), Xform(translation: V3(0, 0, D - 0.0175)))
        let plankW: Float = 0.118
        let nP = Int((D - 0.10) / plankW)
        for i in 0..<nP {
            let z = 0.10 + (Float(i) + 0.5) * (D - 0.10) / Float(nP)
            let len = width - 0.02 - (i % 3 == 1 ? 0.01 : 0)
            let fresh = i == 3 || i == 6
            FA.box(&m, V3(len, 0.03, plankW - 0.006), V3(0, joistY1 + 0.015, z), fresh ? "wood.pine-aged:C8A878" : pick(i * 2 + 1), r: 0.003)
        }
        if !lite { for i in 0..<nP { for x in [-0.9 as Float, -0.45, 0, 0.45, 0.9] { m.add(Prim.cylinder(radius: 0.004, height: 0.002, bevel: 0.0005, segments: 6, bevelSegments: 1, material: "metal.rust"), Xform(translation: V3(x, floorTop - 0.001, 0.10 + (Float(i) + 0.5) * (D - 0.10) / Float(nP) + 0.02))) } } }

        // Posts, rails, slats.
        let postX = hw - 0.04, postZ = D - 0.045, rearZ: Float = 0.085
        for (px, pz) in [(-postX, postZ), (postX, postZ), (-postX, rearZ), (postX, rearZ)] {
            bx(V3(0.08, 0.70, 0.08), V3(px, 0.62, pz), timber, r: 0.005)
            m.add(Prim.loft([Prim.ring(Shape2D.rect(0.092, 0.092), y: 0.97, offset: V3(px, 0, pz)), Prim.ring(Shape2D.rect(0.012, 0.012), y: 1.0, offset: V3(px, 0, pz))], capStart: true, capEnd: true, material: timber))
        }
        func rail(_ a: V3, _ b: V3, _ y: Float, h: Float, d: Float, _ mat: MaterialKey) {
            let c = (a + b) / 2, len = simd_length(b - a)
            let ang: Float = abs(b.x - a.x) > 0.01 ? 0 : 90
            FA.box(&m, V3(len, h, d), V3(c.x, y, c.z), mat, r: 0.004, rot: FA.q(ang, FA.Y))
        }
        let runs: [(V3, V3)] = [(V3(-postX, 0, postZ), V3(postX, 0, postZ)), (V3(-postX, 0, rearZ), V3(-postX, 0, postZ)), (V3(postX, 0, rearZ), V3(postX, 0, postZ))]
        let slat: [V2] = [V2(-0.0155, 0), V2(0.0155, 0), V2(0.0155, 0.40), V2(0, 0.425), V2(-0.0155, 0.40)]
        for (a, b) in runs {
            rail(a, b, 0.925, h: 0.05, d: 0.062, "wood.weathered:B4A288")
            rail(a, b, 0.465, h: 0.045, d: 0.05, timber)
            let len = simd_length(b - a) - 0.06
            let cnt = Int(len / 0.078)
            let along = simd_normalize(b - a)
            let horiz = abs(b.x - a.x) > 0.01
            for i in 0...cnt {
                let t = -len / 2 + Float(i) * len / Float(cnt)
                let p = (a + b) / 2 + along * t
                m.add(Prim.extrude(slat, depth: 0.03, bevel: lite ? 0 : 0.0015, bevelSegments: 1, material: pick(i + 2)),
                      Xform(translation: V3(p.x, 0.487, p.z), rotation: horiz ? .identity : FA.q(90, FA.Y)))
            }
        }
        if !lite {
            bx(V3(0.7, 0.002, 0.16), V3(0.45, floorTop + 0.0005, 0.22), "wood.weathered:4B3E30", r: 0.0003)       // wet stain by the wall
            bx(V3(0.22, 0.0035, 0.1), V3(-0.8, floorTop + 0.0006, 0.17), "stone.granite-moss", r: 0.0003)
            bx(V3(0.012, 0.012, 0.9), V3(-0.3, floorTop - 0.0, 0.55), "wood.weathered:3A2E22", r: 0.0003)       // gap shadow line
            // Snow-melt staining at the post feet and moss on the floor edge.
            for (px, pz) in [(-postX, postZ), (postX, postZ)] { bx(V3(0.082, 0.06, 0.082), V3(px, floorTop + 0.03, pz), dark, r: 0.001) }
            bx(V3(0.5, 0.003, 0.05), V3(-0.55, floorTop + 0.0005, D - 0.07), "stone.granite-moss", r: 0.0005)
        }

        groundAO(&m, height: 0.12, floor: 0.7)
        return FC.place(m)
    }
}
