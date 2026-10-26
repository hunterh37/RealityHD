import simd
import Foundation

/// Craftsman hipped porch roof bay, 3.0 m wide, 1.8 m projection, 0.9 m high: a low hip roof against the wall (front
/// slope plus two hip returns) laid in randomised cedar shakes with moss, over exposed rafter tails with plumb cuts on
/// the front and both sides. A stained front beam and two side beams run on two cream-painted tapered posts that stand
/// on brick pier caps, each post held by two triangular knee braces. A beaded ceiling closes the underside, hip rolls
/// cover the hips and copper flashing seals the wall joint. Wall plane at z = 0.
public struct HippedPorchRoofBay: RealAsset {
    public static let id = "hipped-porch-roof-bay"
    public static let summary = "Craftsman hipped porch roof bay, 3.0 m: cedar shake hip roof, exposed rafter tails, beams, tapered posts, knee braces."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 4.2)

    /// Overall width in meters.
    public var width: Float = 3.0
    /// Projection from the wall.
    public var projection: Float = 1.75
    /// Stained timber.
    public var timber: MaterialKey = "wood.weathered:5E4C3A"
    /// Painted posts.
    public var paint: MaterialKey = "wood.painted-exterior:E3DAC3"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, D = projection
        let yE: Float = 0.58, apex: Float = 0.865, topHW: Float = 0.6
        let bare: MaterialKey = "wood.weathered"
        let beamZ: Float = D - 0.22, postX: Float = hw - 0.25
        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, rot: simd_quatf = .identity) {
            if r <= 0.001 {
                let x = s.x / 2, y = s.y / 2
                m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: c, rotation: rot))
            } else { FA.box(&m, s, c, mat, r: r, rot: rot) }
        }

        // Roof planes: base slabs, shakes, hip rolls.
        let fl = V3(-hw, yE, D), fr = V3(hw, yE, D), tl = V3(-topHW, apex, 0), tr = V3(topHW, apex, 0)
        let wl = V3(-hw, yE, 0), wr = V3(hw, yE, 0)
        let under: MaterialKey = "wood.cedar-weathered:2E281F"
        FR.slab(&m, [fl, fr, tr, tl], t: 0.03, bevel: 0.003, under)
        FR.slab(&m, [wr, fr, tr], t: 0.03, bevel: 0.003, under)
        FR.slab(&m, [fl, wl, tl], t: 0.03, bevel: 0.003, under)
        var tints: [MaterialKey] = ["wood.cedar:7A5C3E", "wood.cedar:8A6A48", "wood.cedar:664A33", "wood.cedar:94775A",
                                    "wood.cedar:6E5440", "wood.cedar:80664A", "wood.cedar:5A4432", "wood.cedar:9A8468"]
        if !lite { tints += ["stone.granite-moss", "wood.cedar:5E6048", "wood.cedar:707858"] }
        let lw: Float = lite ? 0.22 : 0.16
        FR.shakes(&m, lowerL: fl, lowerR: fr, upperL: tl, upperR: tr, courses: lite ? 7 : 13, lift: 0.006, tints: tints, rng: &rng, minW: lite ? 0.18 : 0.09, maxW: lw)
        FR.shakes(&m, lowerL: wr, lowerR: fr, upperL: tr, upperR: tr, courses: lite ? 4 : 7, lift: 0.006, tints: tints, rng: &rng, minW: lite ? 0.18 : 0.09, maxW: lw)
        FR.shakes(&m, lowerL: fl, lowerR: wl, upperL: tl, upperR: tl, courses: lite ? 4 : 7, lift: 0.006, tints: tints, rng: &rng, minW: lite ? 0.18 : 0.09, maxW: lw)
        for sx: Float in [-1, 1] {
            FA.rod(&m, V3(sx * hw, yE + 0.012, D), V3(sx * topHW, apex + 0.012, 0.0), r: 0.02, "wood.cedar-weathered:4E4234", sides: lite ? 6 : 10)
        }
        // Eave edge boards along the front and sides of the roof.
        let fasc: MaterialKey = "wood.weathered:6A5A48"
        bx(V3(width + 0.02, 0.014, 0.02), V3(0, yE - 0.012, D + 0.005), fasc, r: 0.002, rot: FA.q(11, FA.X))

        // Half-round gutter on brackets along the front eave and water streaks down the slope.
        let gz = D + 0.03
        m.add(Prim.sweep([V2(0.0, -0.032), V2(-0.03, -0.022), V2(-0.04, 0.0), V2(-0.03, 0.022), V2(0.0, 0.032), V2(0.0, 0.026), V2(-0.03, 0.018), V2(-0.033, 0.0), V2(-0.03, -0.018), V2(0.0, -0.026)],
                         along: [V3(-hw + 0.02, yE - 0.052, gz), V3(hw - 0.02, yE - 0.052, gz)], up: FA.Y, material: "metal.galvanized-aged"))
        if !lite {
            for x: Float in [-1.2, -0.4, 0.4, 1.2] { bx(V3(0.012, 0.05, 0.05), V3(x, yE - 0.07, gz - 0.01), "metal.galvanized-aged", r: 0.001) }
            for k in 0..<6 {
                let x = Float(k - 2) * 0.46 + rng.float(-0.08...0.08)
                let t0 = rng.float(0.1...0.45), t1 = t0 + rng.float(0.25...0.5)
                let xl = x * (1 - t0 * 0.5), xr = x * (1 - t1 * 0.5)
                let a = FR.lerp(V3(x, yE, D), V3(x * 0.4, apex, 0), t0), b = FR.lerp(V3(x, yE, D), V3(x * 0.4, apex, 0), t1)
                _ = (xl, xr)
                FR.slab(&m, [a - V3(0.02, 0, 0), a + V3(0.02, 0, 0), b + V3(0.02, 0, 0), b - V3(0.02, 0, 0)], t: 0.004, lift: 0.0125, "wood.cedar:3A2F25")
            }
        }

        // Exposed rafter tails.
        let b1: Float = atan2(apex - yE, D) * 180 / .pi, b2: Float = atan2(apex - yE, hw - topHW) * 180 / .pi
        let tail: [V2] = [V2(-0.64, 0), V2(-0.03, 0), V2(0, 0.025), V2(0, 0.09), V2(-0.64, 0.09)]
        let nt = lite ? 5 : 10
        for i in 0..<nt {
            let x = -hw + 0.15 + (Float(i) + 0.0) * (width - 0.3) / Float(nt - 1)
            m.add(Prim.extrude(tail, depth: 0.06, bevel: 0.003, bevelSegments: 1, material: timber),
                  Xform(translation: V3(x, yE - 0.03 - 0.085, D), rotation: FA.q(b1, FA.X) * FA.q(-90, FA.Y)))
        }
        for sx: Float in [-1, 1] {
            for k in 0..<(lite ? 3 : 5) {
                let z = 0.28 + Float(k) * ((D - 0.62) / Float(lite ? 2 : 4))
                m.add(Prim.extrude(tail, depth: 0.06, bevel: 0.003, bevelSegments: 1, material: timber),
                      Xform(translation: V3(sx * hw, yE - 0.03 - 0.085, z), rotation: FA.q(sx * 90, FA.Y) * FA.q(b2, FA.X) * FA.q(-90, FA.Y)))
            }
        }

        // Beams, ceiling.
        let beamY: Float = 0.33 + 0.07
        bx(V3(width - 0.24, 0.14, 0.11), V3(0, beamY, beamZ), timber, r: 0.004)
        for sx: Float in [-1, 1] {
            bx(V3(0.11, 0.14, beamZ), V3(sx * postX, beamY, beamZ / 2), timber, r: 0.004)
            // Chamfered outrigger end of the front beam.
            m.add(Prim.extrude([V2(0, -0.07), V2(0.10, -0.07), V2(0.14, 0.0), V2(0.10, 0.07), V2(0, 0.07)], depth: 0.11, bevel: 0.003, bevelSegments: 1, material: timber),
                  Xform(translation: V3(sx > 0 ? hw - 0.12 : -hw + 0.12, beamY, beamZ), rotation: FA.q(sx > 0 ? 0 : 180, FA.Y) * FA.q(0, FA.Y)))
        }
        bx(V3(width - 0.50, 0.02, beamZ - 0.12), V3(0, 0.48, beamZ / 2 + 0.02), "wood.painted-exterior:C3D2CE", r: 0.002)
        if !lite { for k in 0..<12 { bx(V3(0.003, 0.003, beamZ - 0.14), V3(-hw + 0.37 + Float(k) * (width - 0.74) / 11, 0.4685, beamZ / 2 + 0.02), "wood.painted-exterior:7E8F8C", r: 0.0008) } }

        // Posts on brick pier caps, knee braces.
        for sx: Float in [-1, 1] {
            let px = sx * postX
            bx(V3(0.27, 0.12, 0.27), V3(px, 0.06, beamZ), "brick.common", r: 0.003)
            bx(V3(0.30, 0.02, 0.30), V3(px, 0.13, beamZ), "stone.cast-stone:A89F8C", r: 0.003)
            let rings = [Prim.ring(Shape2D.roundedRect(0.21, 0.21, radius: 0.008, segments: 2), y: 0.14, offset: V3(px, 0, beamZ)),
                         Prim.ring(Shape2D.roundedRect(0.19, 0.19, radius: 0.008, segments: 2), y: 0.22, offset: V3(px, 0, beamZ)),
                         Prim.ring(Shape2D.roundedRect(0.165, 0.165, radius: 0.008, segments: 2), y: 0.30, offset: V3(px, 0, beamZ))]
            m.add(Prim.loft(rings, capStart: true, capEnd: true, material: paint))
            bx(V3(0.225, 0.02, 0.225), V3(px, 0.15, beamZ), paint, r: 0.003)
            bx(V3(0.21, 0.03, 0.21), V3(px, 0.315, beamZ), timber, r: 0.003)
            let brace: [V2] = [V2(0, -0.24), V2(0, 0), V2(-sx * 0.34, 0), V2(-sx * 0.31, -0.03)]
            m.add(Prim.extrude(brace, depth: 0.05, bevel: 0.003, bevelSegments: 1, material: timber), Xform(translation: V3(px - sx * 0.085, 0.33, beamZ)))
            let braceZ: [V2] = [V2(0, -0.24), V2(0, 0), V2(-0.34, 0), V2(-0.31, -0.03)]
            m.add(Prim.extrude(braceZ, depth: 0.05, bevel: 0.003, bevelSegments: 1, material: timber), Xform(translation: V3(px, 0.33, beamZ - 0.085), rotation: FA.q(-90, FA.Y)))
            if !lite {
                for k in 0..<4 {
                    let a = rng.float(0...(2 * .pi)), yy = 0.09 + rng.float(0...0.14)
                    bx(V3(0.045, 0.07, 0.003), V3(px + cos(a) * 0.088, yy, beamZ + sin(a) * 0.088), bare, r: 0.001, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
                }
                bx(V3(0.2, 0.004, 0.2), V3(px, 0.141, beamZ), "stone.granite-moss", r: 0.001)
                hexBolt(&m, at: V3(px - sx * 0.1, 0.29, beamZ), normal: V3(-sx, 0, 0), size: 0.016, material: "metal.rust")
            }
        }

        // Copper flashing at the wall, following the roof edge.
        bx(V3(2 * topHW + 0.04, 0.06, 0.010), V3(0, apex + 0.002, 0.005), "metal.copper-patina:5E9C84", r: 0.002)
        let ang = atan2(apex - yE, hw - topHW) * 180 / .pi
        for sx: Float in [-1, 1] {
            let len = ((hw - topHW) * (hw - topHW) + (apex - yE) * (apex - yE)).squareRoot()
            bx(V3(len + 0.02, 0.06, 0.010), V3(sx * (hw + topHW) / 2, (yE + apex) / 2 + 0.004, 0.005), "metal.copper-patina:5E9C84", r: 0.002, rot: FA.q(-sx * ang, FA.Z))
        }
        if !lite {
            for k in 0..<5 { bx(V3(0.014, rng.float(0.05...0.12), 0.002), V3(Float(k - 2) * 0.22 + rng.float(-0.04...0.04), apex - 0.09, 0.0012 + 0.012), "metal.copper-patina:79B79C", r: 0.0005) }
        }

        groundAO(&m, height: 0.15, floor: 0.7)
        return FC.place(m)
    }
}
