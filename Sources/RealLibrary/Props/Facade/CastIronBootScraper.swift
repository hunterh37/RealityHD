import simd
import Foundation

/// Victorian cast iron boot scraper, 0.4 m: pierced base plate bolted to the step, two scrolled end standards
/// (each a pair of legs ending in outward volutes) carrying a sharpened blade, two bristle brushes and cross
/// braces. Black japanned paint worn to rust at the edges where boots strike. Stands on the ground.
public struct CastIronBootScraper: RealAsset {
    public static let id = "cast-iron-boot-scraper"
    public static let summary = "Victorian cast iron boot scraper, 0.4 m: scrolled standards, sharpened blade, bristle brushes, bolted base plate."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 0.85)

    /// Worn cast iron (bare metal showing).
    public var iron: MaterialKey = "metal.cast-iron"
    /// Rust where the paint has worn.
    public var rust: MaterialKey = "metal.rust"
    /// Black japanned paint.
    public var paint: MaterialKey = "metal.cast-iron:2B2724"
    /// Blade steel.
    public var steel: MaterialKey = "metal.steel:55575A"
    /// Bolt heads.
    public var bolt: MaterialKey = "metal.galvanized-aged"
    /// Bristle fibre.
    public var bristle: MaterialKey = "fabric.canvas:5A4A32"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.4, D: Float = 0.15
        // Base plate: 12 mm cast plate with rounded corners, a raised lip all round and four bolt bosses.
        let plate = Shape2D.rounded(Shape2D.rect(W, D), radius: 0.014)
        m.add(Prim.extrude(plate, depth: 0.012, bevel: 0.0025, bevelSegments: 2, material: paint), Xform(translation: V3(0, 0.006, 0), rotation: FA.q(-90, FA.X)))
        FA.box(&m, V3(W - 0.03, 0.008, 0.01), V3(0, 0.015, D / 2 - 0.011), iron, r: 0.0025)
        FA.box(&m, V3(W - 0.03, 0.008, 0.01), V3(0, 0.015, -D / 2 + 0.011), iron, r: 0.0025)
        for s: Float in [-1, 1] { FA.box(&m, V3(0.01, 0.008, D - 0.03), V3(s * (W / 2 - 0.011), 0.015, 0), iron, r: 0.0025) }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            hexBolt(&m, at: V3(sx * 0.17, 0.012, sz * 0.056), normal: V3(0, 1, 0), size: 0.012, material: bolt)
        } }
        // Two bristle brushes in cast troughs, in front of and behind the blade.
        var brs = rng.fork(3)
        for z: Float in [-0.043, 0.043] {
            FA.box(&m, V3(0.25, 0.026, 0.026), V3(0, 0.025, z), paint, r: 0.004)
            for ix in 0..<20 {
                let x = -0.114 + Float(ix) * 0.012
                for iz in 0..<2 {
                    let zz = z - 0.006 + Float(iz) * 0.012
                    let top = V3(x + brs.float(-0.004...0.004), 0.092 + brs.float(0...0.008), zz + brs.float(-0.003...0.003))
                    FA.rod(&m, V3(x, 0.036, zz), top, r: 0.0026, bristle, sides: 4)
                }
            }
        }
        // End standards: each end has two legs bowing inward then curling out into volutes in the YZ plane.
        for s: Float in [-1, 1] {
            let x = s * (W / 2 - 0.026)
            for zs: Float in [-1, 1] {
                var path: [V3] = []
                for i in 0...14 {
                    let t = Float(i) / 14
                    path.append(V3(x, 0.014 + t * 0.26, zs * (0.056 - 0.034 * FL.smooth(t))))
                }
                // Volute: starts moving up at the leg top, curls outward and inward over about 1.7 turns.
                let cz = zs * 0.022, vc = V2(zs * (0.022 + 0.0255), 0.274)
                _ = cz
                for i in 1...16 {
                    let t = Float(i) / 16, a = t * 1.75 * .pi, r = 0.0255 * (1 - t * 0.7)
                    path.append(V3(x, vc.y + r * sin(a), vc.x - zs * r * cos(a)))
                }
                let n = path.count
                m.add(Prim.tube(path, radii: path.indices.map { 0.0098 - 0.0038 * Float($0) / Float(n) }, sides: 10, seamTile: 0.1, material: paint, capEnd: true))
                // Foot: cast pad under the leg with a rim.
                FA.box(&m, V3(0.034, 0.014, 0.036), V3(x, 0.019, zs * 0.056), iron, r: 0.004)
            }
            // Cross braces between the legs: lower stretcher and the blade socket clamp.
            FA.rod(&m, V3(x, 0.05, -0.052), V3(x, 0.05, 0.052), r: 0.0075, paint, sides: 8)
            FA.box(&m, V3(0.024, 0.062, 0.062), V3(x, 0.162, 0), paint, r: 0.005)
            // Acorn finials on the volute tips are cast as one with the scroll; a collar ring marks the join.
            for zs: Float in [-1, 1] {
                m.add(Prim.torus(major: 0.0098, minor: 0.0028, segments: 12, sides: 5, material: iron),
                      Xform(translation: V3(x, 0.12, zs * 0.0395), rotation: FA.q(90, FA.X)))
            }
            // Set screw through the socket clamp.
            hexBolt(&m, at: V3(x + s * 0.012, 0.162, 0), normal: V3(s, 0, 0), size: 0.009, material: bolt)
        }
        // Paint chips: bare iron and rust at points on the legs and feet that boots and weather reach.
        var wr = rng.fork(9)
        for _ in 0..<16 {
            let s: Float = wr.chance(0.5) ? -1 : 1, zs: Float = wr.chance(0.5) ? -1 : 1
            let y = wr.float(0.03...0.2)
            let t = (y - 0.014) / 0.26
            let z = zs * (0.056 - 0.034 * FL.smooth(max(0, min(1, t))))
            FA.box(&m, V3(0.0025, wr.float(0.006...0.014), 0.007), V3(s * (W / 2 - 0.026) + s * 0.0098, y, z), wr.chance(0.5) ? rust : iron, r: 0.0006)
        }
        for _ in 0..<10 {
            FA.box(&m, V3(wr.float(0.006...0.02), 0.0014, wr.float(0.006...0.016)), V3(wr.float(-0.17...0.17), 0.0125, wr.float(-0.06...0.06)), rust, r: 0.0004)
        }
        // Blade: flat steel bar on edge, sharpened top and bevelled face, passing through both clamps.
        let bladeProfile: [V2] = [V2(-0.0045, 0), V2(0.0045, 0), V2(0.0045, 0.052), V2(0.0008, 0.066), V2(-0.0008, 0.066), V2(-0.0045, 0.052)]
        m.add(Prim.extrude(bladeProfile, depth: W - 0.05, bevel: 0.0008, bevelSegments: 1, material: steel),
              Xform(translation: V3(0, 0.131, 0), rotation: FA.q(90, FA.Y)))
        // Rust bloom on the strike edge and a chipped steel notch.
        FA.box(&m, V3(0.12, 0.003, 0.003), V3(0.05, 0.197, 0), rust, r: 0.0008)
        FA.box(&m, V3(0.03, 0.006, 0.01), V3(-0.08, 0.15, 0.0), rust, r: 0.001)
        groundAO(&m, height: 0.06, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
