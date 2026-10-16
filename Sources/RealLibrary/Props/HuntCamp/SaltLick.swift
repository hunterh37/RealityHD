import simd
import Foundation

/// 50 lb trace-mineral salt block, 41 x 20.5 x 20.5 cm, lying on trampled mud: red-brown pressed block with a
/// licked-out hollow in the top, worn rounded edges, a broken corner and its chip on the ground, crystalline pitting.
public struct SaltLick: RealAsset {
    public static let id = "salt-lick"
    public static let summary = "50 lb mineral salt block, 41 x 20.5 cm: pitted red-brown block with a licked-out hollow, broken corner and chip on a mud pad."
    public static let tags = ["prop", "hunting", "outdoor", "stone"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 24, distance: 1.1)

    /// Block length, height and depth in meters.
    public var size = V3(0.41, 0.205, 0.205)
    /// Block color (sRGB hex).
    public var color: UInt32 = 0x93503C
    /// Depth of the licked hollow in meters.
    public var lickDepth: Float = 0.045
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let ns = UInt32(truncatingIfNeeded: seed)
        var m = Model(name: Self.id)
        let mat = "stone.cast-grey:" + HuntCampKit.hex(color)
        let L = size.x, H = size.y, D = size.z
        // Mud pad trampled around the block.
        let pad = Shape2D.rounded(Shape2D.roundedRect(L + 0.17, D + 0.15, radius: 0.07).map { p in
            p * (1 + 0.05 * Float(Noise.perlin(V3(p.x * 9, 0.5, p.y * 9), seed: ns &+ 3)))
        }, radius: 0.02)
        var mud = Prim.extrude(pad, depth: 0.014, bevel: 0.006, bevelSegments: 1, material: "ground.dirt")
        mud.displace { p, _ in Float(Noise.fbm(V3(p.x * 30, p.y * 30, p.z * 30), octaves: 3, seed: ns &+ 5)) * 0.004 }
        m.add(mud, Xform(translation: V3(0, 0.007, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        // Block: boxy superellipsoid, licked hollow on the top toward one end, rounded rim, broken corner.
        var b = Prim.superellipsoid(size, exponent: 12, subdivisions: 18, material: mat)
        let lickC = V2(0.06, 0.0)
        b.deform { p in
            var q = p
            let top = smoothstep(H * 0.2, H * 0.5, p.y)
            let d = simd_length((V2(p.x, p.z) - lickC) / V2(0.15, 0.085))
            q.y -= lickDepth * (1 - smoothstep(0.2, 1.0, d)) * top
            // Broken corner at +x, -z, top.
            let br = (p.x - L * 0.5 + 0.055) + (-p.z - D * 0.5 + 0.055) + (p.y - H * 0.5 + 0.055)
            if br > 0 { q -= V3(0.35, 0.35, -0.35) * br * 0.33 }
            return q
        }
        b.displace { p, _ in
            let n = Float(Noise.fbm(V3(p.x * 55, p.y * 55, p.z * 55), octaves: 4, seed: ns &+ 1))
            let pit = max(0, Float(Noise.perlin(V3(p.x * 160, p.y * 160, p.z * 160), seed: ns &+ 2)) - 0.35)
            return n * 0.0035 - pit * 0.006
        }
        // Flat bottom resting on the pad.
        b.positions = b.positions.map { V3($0.x, max($0.y, -H * 0.5 + 0.0005) , $0.z) }
        b.recomputeNormals(weldSeams: true); b.computeTangents()
        m.add(b, Xform(translation: V3(0, H / 2 + 0.012, 0)))
        // Chip from the broken corner and loose crumbs on the mud.
        for i in 0..<6 {
            let big = i == 0
            let s = big ? V3(0.075, 0.04, 0.055) : V3(rng.float(0.012...0.026), rng.float(0.01...0.02), rng.float(0.012...0.024))
            var c = Prim.superellipsoid(s, exponent: 3.2, subdivisions: 8, material: mat)
            c.displace { p, _ in Float(Noise.fbm(V3(p.x * 90, p.y * 90, p.z * 90), octaves: 3, seed: ns &+ UInt32(10 + i))) * 0.003 }
            let p = big ? V3(L * 0.5 + 0.05, 0.012 + s.y * 0.4, -D * 0.5 - 0.005) : V3(rng.float(-L * 0.45...L * 0.5 + 0.05), 0.012 + s.y * 0.4, D / 2 + rng.float(0.01...0.045))
            m.add(c, Xform(translation: p, rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
        }
        // Hoof prints pressed into the pad: two crescent dents as dark mud rims.
        for k in 0..<2 {
            let x = (k == 0 ? -1 : 1) * L * 0.38
            let print = Prim.torus(major: 0.016, minor: 0.004, segments: 14, sides: 6, arc: 4.2, material: "ground.dirt")
            m.add(print, Xform(translation: V3(x, 0.016, D / 2 + 0.045), rotation: simd_quatf(degrees: Float(k) * 35, axis: .up)))
        }
        groundAO(&m, height: 0.06, floor: 0.75)
        return LODModel(m)
    }
}
