import simd
import Foundation

/// Direct-to-Earth X-band dish, 3.5 m: ribbed white aluminium reflector with a rolled rim and a Cassegrain sub-reflector on
/// four struts, tilted 22 degrees above the horizon on a pedestal over a steel tripod with footpads, gold MLI equipment
/// box and orange accents. Faces +Z.
public struct LunarDteDish: RealAsset {
    public static let id = "lunar-dte-dish"
    public static let summary = "3.5 m X-band direct-to-Earth dish: ribbed reflector, Cassegrain feed on four struts, steel tripod, gold MLI equipment box."
    public static let tags = ["prop", "aerospace", "metal", "electronics"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 7.5, studio: true)

    /// Reflector diameter (m) and focal ratio f/D.
    public var diameter: Float = 3.5
    public var focalRatio: Float = 0.35
    /// Elevation above horizon (degrees).
    public var tilt: Float = 22
    /// Height of the reflector centre (m).
    public var hubHeight: Float = 2.35
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        typealias K = LunarKit
        let R = diameter / 2, f = diameter * focalRatio, depth = R * R / (4 * f)
        let q = simd_quatf(angle: -tilt * .pi / 180, axis: V3(1, 0, 0))
        let hub = V3(0, hubHeight, 0)
        func at(_ p: V3) -> V3 { hub + q.act(p) }        // dish-local (z boresight) -> asset
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 72 : 32
            for s in K.dish(R: R, f: f, thick: 0.03, segments: sg, rings: l == 0 ? 16 : 7, front: "metal.powder-white:E8EAEC", back: K.white) {
                m.add(s, Xform(translation: hub, rotation: q * K.toZ))
            }
            m.add(Prim.torus(major: R, minor: 0.018, segments: sg, sides: 8, material: K.silver), Xform(translation: at(V3(0, 0, depth - 0.015)), rotation: q * K.toZ))
            if l == 0 {
                // Radial ribs on the back, with an orange hub ring.
                for k in 0..<16 {
                    let a = Float(k) / 16 * 2 * .pi
                    let r0: Float = 0.3, r1 = R - 0.05
                    let p0 = V3(cos(a) * r0, sin(a) * r0, r0 * r0 / (4 * f) - 0.07)
                    let p1 = V3(cos(a) * r1, sin(a) * r1, r1 * r1 / (4 * f) - 0.045)
                    m.add(Prim.tube([at(p0), at((p0 + p1) / 2 + V3(0, 0, -0.03)), at(p1)], radii: [0.025, 0.02, 0.012], sides: 6, seamTile: 0.1, material: K.silver))
                }
                for ring in [0.9, 1.5] as [Float] {
                    let z = ring * ring / (4 * f) - 0.055
                    m.add(Prim.torus(major: ring, minor: 0.012, segments: 48, sides: 6, material: K.silver), Xform(translation: at(V3(0, 0, z)), rotation: q * K.toZ))
                }
            }
            m.add(Prim.lathe([V2(0.0, -0.1), V2(0.34, -0.1), V2(0.36, -0.07), V2(0.36, -0.03), V2(0.0, -0.03)].map { V2($0.x, $0.y) }, segments: 32, seamTile: 0.3, material: K.orange),
                  Xform(translation: at(V3(0, 0, -0.04)), rotation: q * K.toZ))
            // Quadripod struts and sub-reflector.
            let fz = f
            for k in 0..<4 {
                let a = Float(k) / 4 * 2 * .pi + .pi / 4
                m.add(Prim.tube([at(V3(cos(a) * (R * 0.6), sin(a) * (R * 0.6), (R * 0.6) * (R * 0.6) / (4 * f))), at(V3(cos(a) * 0.1, sin(a) * 0.1, fz - 0.05))],
                                radii: [0.03, 0.018], sides: 8, seamTile: 0.1, material: K.silver))
            }
            m.add(Prim.lathe([V2(0.0, 0.0), V2(0.2, 0.0), V2(0.24, 0.02), V2(0.18, 0.06), V2(0.0, 0.1)], segments: 28, seamTile: 0.3, material: K.silver),
                  Xform(translation: at(V3(0, 0, fz - 0.02)), rotation: q * simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.1, height: 0.18, bevel: 0.01, segments: 20, material: K.gold),
                  Xform(translation: at(V3(0, 0, fz - 0.28)), rotation: q * K.toZ))
            // Pedestal from hub down, elevation yoke.
            let pTop = at(V3(0, 0, -0.12)), pBot = V3(0, 0.55, 0)
            m.add(Prim.tube([pBot, pTop], radii: [0.17, 0.15], sides: 16, seamTile: 0.3, material: K.white))
            m.add(Prim.roundedBox(V3(0.5, 0.3, 0.32), radius: 0.02, bevelSegments: 2, material: K.gold), Xform(translation: at(V3(0, 0.42, -0.2)), rotation: q))
            // Tripod: three tubular legs, braced, with footpads.
            for k in 0..<3 {
                let a = Float(k) / 3 * 2 * .pi + .pi / 6 + rng.float(-0.01...0.01)
                let foot = V3(cos(a) * 1.35, 0.03, sin(a) * 1.35), top = V3(cos(a) * 0.12, 0.7, sin(a) * 0.12)
                m.add(Prim.tube([foot + V3(0, 0.02, 0), top], radii: [0.045, 0.06], sides: 10, seamTile: 0.15, material: K.silver))
                m.add(Prim.cylinder(radius: 0.17, height: 0.03, bevel: 0.006, segments: 18, material: K.silver), Xform(translation: V3(foot.x, 0, foot.z)))
                let b = Float(k + 1) / 3 * 2 * .pi + .pi / 6
                let mid = V3(cos(a) * 0.75, 0.38, sin(a) * 0.75), nxt = V3(cos(b) * 0.75, 0.38, sin(b) * 0.75)
                if l == 0 { m.add(Prim.tube([mid, nxt], radii: [0.022, 0.022], sides: 8, seamTile: 0.1, material: K.white)) }
                m.add(Prim.cylinder(radius: 0.065, height: 0.08, bevel: 0.006, segments: 12, material: K.orange), Xform(translation: V3(foot.x * 0.74 + top.x * 0.26, 0.58, foot.z * 0.74 + top.z * 0.26)))
            }
            m.add(Prim.cylinder(radius: 0.26, height: 0.1, bevel: 0.01, segments: 24, material: K.white), Xform(translation: V3(0, 0.62, 0)))
            levels.append(m)
        }
        groundAO(&levels[0], height: 0.3, floor: 0.6)
        groundAO(&levels[1], height: 0.3, floor: 0.6)
        return LODModel(levels: levels, switchDistances: [12])
    }
}
