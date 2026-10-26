import simd
import Foundation

/// Cast iron boot scraper: architectural facade customizer, Victorian. Base plate with two scrolled
/// standards, a wedge scraper blade and a tie bar, bolted down; paint worn to rust and bright steel along the blade.
public struct BootScraperIron: RealAsset {
    public static let id = "boot-scraper-iron"
    public static let summary = "Cast iron boot scraper 0.3 m: base plate with two scrolled standards, a wedge scraper blade and tie bar, bolted down."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 0.9)

    /// Painted cast iron.
    public var paint: MaterialKey = "metal.wrought-iron"
    /// Bare cast iron on the blade.
    public var castIron: MaterialKey = "metal.cast-iron-street"
    public init() {}

    /// Spiral scroll in the XY plane: starts at `p0`, curls about a centre with shrinking radius.
    static func scroll(_ m: inout Model, from p0: V2, centre c: V2, turns: Float, dir: Float, r: Float, _ mat: MaterialKey, z: Float) {
        var pts: [V3] = []
        let a0 = atan2(p0.y - c.y, p0.x - c.x), r0 = simd_length(p0 - c)
        let n = 30
        for k in 0...n {
            let t = Float(k) / Float(n)
            let a = a0 + dir * t * turns * 2 * .pi
            let rr = r0 * (1 - 0.75 * t)
            pts.append(V3(c.x + rr * cos(a), c.y + rr * sin(a), z))
        }
        FA.path(&m, pts, r: r, mat, sides: 8)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.3, D: Float = 0.2, plateH: Float = 0.018, sx: Float = 0.1
        // Base plate with a rolled rope edge and four countersunk bolts.
        FA.box(&m, V3(W, plateH, D), V3(0, plateH / 2, 0), castIron, r: 0.006)
        FA.box(&m, V3(W - 0.03, 0.006, D - 0.03), V3(0, plateH + 0.002, 0), castIron, r: 0.003)
        for sx2: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.0095, height: 0.005, bevel: 0.0015, segments: 8, bevelSegments: 1, material: "metal.rust"),
                  Xform(translation: V3(sx2 * (W / 2 - 0.022), plateH - 0.001, sz * (D / 2 - 0.022))))
        }}
        for e: Float in [-1, 1] {
            let x = e * sx
            // Standard: tapered post with a foot block, cast collar and ball.
            FA.box(&m, V3(0.036, 0.03, 0.05), V3(x, plateH + 0.015, 0), paint, r: 0.004)
            m.add(Prim.loft([Prim.ring(Shape2D.roundedRect(0.032, 0.026, radius: 0.005), y: plateH + 0.025), Prim.ring(Shape2D.roundedRect(0.022, 0.018, radius: 0.004), y: 0.238)],
                            capStart: false, capEnd: true, material: paint), Xform(translation: V3(x, 0, 0)))
            FA.box(&m, V3(0.034, 0.012, 0.03), V3(x, 0.13, 0), paint, r: 0.003)
            FA.box(&m, V3(0.03, 0.01, 0.026), V3(x, 0.226, 0), paint, r: 0.003)
            // Top scroll in the face plane, curling outward, with a terminal ball.
            Self.scroll(&m, from: V2(x, 0.243), centre: V2(x + e * 0.02, 0.268), turns: 1.15, dir: -e, r: 0.0065, paint, z: 0)
            FA.ball(&m, r: 0.01, at: V3(x, 0.252, 0), paint)
            // Side scroll buttresses front and back in the YZ plane, from the plate up to the post.
            for sz: Float in [-1, 1] {
                var pts: [V3] = []
                for k in 0...22 {
                    let t = Float(k) / 22, a = t * 1.6 * .pi
                    let r0: Float = 0.06 * (1 - 0.7 * t)
                    // quarter stem then curl
                    pts.append(V3(x, 0.03 + 0.1 * (1 - cos(a * 0.5)) * 0.0 + r0 * sin(a) * 0.9 + 0.06 * (1 - t) * 0, sz * (0.045 + 0.05 * (1 - t) * cos(a))))
                }
                FA.path(&m, pts, r: 0.0055, paint, sides: 8)
            }
        }
        // Wedge scraper blade between the standards: sharp upper edge, rubbed bright by boots.
        let blade: [V2] = [V2(-0.012, 0), V2(0.012, 0), V2(0.0035, 0.052), V2(-0.0035, 0.052)]
        FA.run(&m, blade, length: 2 * sx - 0.03, at: V3(0, 0.14, 0), castIron, bevel: 0.0008)
        FA.box(&m, V3(2 * sx - 0.03, 0.0012, 0.005), V3(0, 0.1925, 0), "metal.steel", r: 0.0004)
        // Lower stretcher and upper tie bar.
        FA.rod(&m, V3(-sx, 0.075, 0.0), V3(sx, 0.075, 0.0), r: 0.0085, paint, sides: 10)
        FA.rod(&m, V3(-sx, 0.232, 0.0), V3(sx, 0.232, 0.0), r: 0.0065, paint, sides: 10)
        // Rust fleck patches where paint has gone, at the foot and blade seat.
        for _ in 0..<6 {
            FE.stain(&m, V3(rng.float(-0.12...0.12), plateH + 0.0045, rng.float(-0.07...0.07)), w: rng.float(0.014...0.03), d: rng.float(0.012...0.02), "metal.rust", yaw: rng.float(0...180))
        }
        m = FE.seat(m)
        groundAO(&m, height: 0.05, floor: 0.6)
        return LODModel(m)
    }
}
