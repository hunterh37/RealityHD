import simd
import Foundation

/// Oculus roof light: architectural facade customizer, modernism, weathered. Parts: concrete kerb ring, clamped glass dome, aluminium clamp ring with stainless bolts, dome bars, lead skirt flashing, roofing deck.
public struct OculusRoofLight: RealAsset {
    public static let id = "oculus-roof-light"
    public static let summary = "Oculus roof light, 1.2 m: round concrete kerb, clamped glass dome, bolted ring, lead skirt, roof deck."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 28, distance: 2.4)

    /// Kerb outer radius in meters.
    public var kerbRadius: Float = 0.5
    /// Glass material key.
    public var glass: MaterialKey = "glass.clear"
    /// Kerb material key.
    public var kerb: MaterialKey = "stone.cast-stone"
    /// Clamp ring and bar material key.
    public var alu: MaterialKey = "metal.anodized-worn"
    /// Lead flashing material key.
    public var lead: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let Y = V3(0, 1, 0)
        let ro = kerbRadius, ri: Float = 0.4
        let deckT: Float = 0.04, kTop: Float = 0.24
        // Roof deck with standing seams and a welded cross seam.
        FA.box(&m, V3(1.2, deckT, 1.2), V3(0, deckT / 2, 0), "metal.roofing", r: 0.004)
        for z: Float in [-0.45, 0.45] { FA.box(&m, V3(1.18, 0.022, 0.03), V3(0, deckT + 0.011, z), "metal.roofing", r: 0.006) }
        FA.box(&m, V3(0.03, 0.006, 1.18), V3(0.52, deckT + 0.003, 0), "metal.roofing", r: 0.002)
        // Concrete kerb ring with chamfered top, board-mark grooves and form-tie holes.
        m.add(Prim.lathe([V2(ri, deckT - 0.002), V2(ro, deckT - 0.002), V2(ro, kTop - 0.008), V2(ro - 0.008, kTop), V2(ri + 0.008, kTop), V2(ri, kTop - 0.008), V2(ri, deckT - 0.002)],
                         segments: 40, seamTile: 0.45, material: kerb))
        for y: Float in [0.11, 0.17] {
            m.add(Prim.torus(major: ro + 0.0005, minor: 0.0018, segments: 40, sides: 4, material: "stone.limestone-sooted"), Xform(translation: V3(0, y, 0)))
        }
        for k in 0..<8 {
            let a = Float(k) * .pi / 4 + 0.2
            FA.cylZ(&m, r: 0.011, h: 0.004, at: V3(sin(a) * (ro + 0.001), 0.14, cos(a) * (ro + 0.001)), "metal.rust", bevel: 0.001, segments: 10)
        }
        // Lead skirt: flared collar with welted top roll, lapping onto the deck.
        m.add(Prim.lathe([V2(ro - 0.002, 0.2), V2(ro + 0.006, 0.2), V2(ro + 0.008, 0.19), V2(ro + 0.02, 0.1), V2(ro + 0.085, deckT + 0.004), V2(ro + 0.09, deckT + 0.002)],
                         segments: 40, seamTile: 0.5, material: lead))
        m.add(Prim.torus(major: ro + 0.008, minor: 0.006, segments: 40, sides: 8, material: lead), Xform(translation: V3(0, 0.2, 0)))
        // Aluminium clamp ring on the kerb and compression bead.
        m.add(Prim.lathe([V2(0.36, kTop), V2(0.47, kTop), V2(0.475, kTop + 0.006), V2(0.47, kTop + 0.022), V2(0.455, kTop + 0.028), V2(0.4, kTop + 0.028), V2(0.39, kTop + 0.02), V2(0.36, kTop + 0.016), V2(0.36, kTop)],
                         segments: 40, seamTile: 0.3, material: alu))
        m.add(Prim.torus(major: 0.372, minor: 0.008, segments: 40, sides: 8, material: "metal.anodized-black"), Xform(translation: V3(0, kTop + 0.02, 0)))
        // Stainless bolts around the ring.
        let nB = 16
        for k in 0..<nB {
            let a = Float(k) * 2 * .pi / Float(nB)
            let p = V3(sin(a) * 0.435, kTop + 0.028, cos(a) * 0.435)
            m.add(Prim.cylinder(radius: 0.0075, height: 0.008, bevel: 0.0015, segments: 6, material: "metal.stainless"), Xform(translation: p))
        }
        // Glass dome: two skins on a spherical cap, base radius 0.36.
        let rb: Float = 0.36, hDome: Float = 0.2
        let R = (rb * rb + hDome * hDome) / (2 * hDome)
        let tMax = asin(rb / R)
        let yBase = kTop + 0.03
        func cap(_ rr: Float) -> [V2] {
            (0...12).map { i in
                let t = tMax * Float(i) / 12
                return V2(max(0.0005, rr * sin(t)), yBase + rr * cos(t) - (R - hDome))
            }.reversed()
        }
        m.add(Prim.lathe(cap(R), segments: 40, seamTile: 0.5, material: glass))
        m.add(Prim.lathe(cap(R - 0.012), segments: 40, seamTile: 0.5, material: glass))
        // Dome bars: six meridians, a latitude hoop, top boss.
        for k in 0..<6 {
            let a = Float(k) * .pi / 3 + 0.15
            let pts: [V3] = (0...12).map { i in
                let t = tMax * Float(i) / 12
                let rr = R + 0.008
                let rad = rr * sin(t)
                return V3(sin(a) * rad, yBase + rr * cos(t) - (R - hDome), cos(a) * rad)
            }
            FA.path(&m, pts, r: 0.0065, alu, sides: 6)
        }
        let tH = tMax * 0.55
        m.add(Prim.torus(major: (R + 0.008) * sin(tH), minor: 0.0055, segments: 40, sides: 6, material: alu),
              Xform(translation: V3(0, yBase + (R + 0.008) * cos(tH) - (R - hDome), 0)))
        m.add(Prim.lathe([V2(0.0005, yBase + hDome + 0.014), V2(0.03, yBase + hDome + 0.008), V2(0.034, yBase + hDome - 0.002), V2(0.0005, yBase + hDome - 0.012)],
                         segments: 18, seamTile: 0.2, material: alu))
        // Weathering: drip streaks and moss on the kerb, leaves and silt on the deck, corrosion at a seam.
        for k in 0..<6 {
            var wr = rng.fork(10 + k)
            let a = wr.float(0...(2 * .pi)), h = wr.float(0.06...0.14)
            FA.box(&m, V3(wr.float(0.012...0.03), h, 0.003), V3(sin(a) * (ro + 0.003), kTop - 0.01 - h / 2, cos(a) * (ro + 0.003)), "stone.limestone-sooted", r: 0.001, rot: simd_quatf(angle: a, axis: Y))
        }
        m.add(Prim.superellipsoid(V3(0.2, 0.06, 0.006), exponent: 3, subdivisions: 5, material: "stone.granite-moss"),
              Xform(translation: V3(0.08, 0.075, -(ro + 0.004))))
        for k in 0..<4 {
            var lr = rng.fork(100 + k)
            let a = lr.float(0...(2 * .pi)), d = lr.float(0.55...0.7)
            m.add(Prim.superellipsoid(V3(lr.float(0.04...0.07), 0.004, lr.float(0.02...0.035)), exponent: 3, subdivisions: 3, material: "wood.deadwood"),
                  Xform(translation: V3(sin(a) * d * 0.8, deckT + 0.003, cos(a) * d * 0.8), rotation: simd_quatf(angle: a, axis: Y)))
        }
        FA.box(&m, V3(0.03, 0.002, 0.2), V3(-0.45, deckT + 0.023, 0.45), "metal.rust", r: 0.0005)
        groundAO(&m)
        return LODModel(m)
    }
}
