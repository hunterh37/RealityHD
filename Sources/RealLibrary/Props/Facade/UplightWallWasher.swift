import simd
import Foundation

/// Wall washer uplight: architectural facade customizer, Contemporary. Black anodized cylindrical housing with
/// machined cooling rings, stainless trim bezel with a flat tempered lens and five-blade louver, a forked yoke on a
/// wall plate with two aiming knuckles and locking knobs, cable gland on the back. Anodize is chalked at the edges
/// and hard water scale spots the lens.
public struct UplightWallWasher: RealAsset {
    public static let id = "uplight-wall-washer"
    public static let summary = "Contemporary wall washer uplight, 0.3 m: anodized housing with lens, louver and aiming knuckle."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 0.9)

    /// Housing anodize.
    public var anodize: MaterialKey = "metal.anodized-black"
    /// Trim.
    public var trim: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let steel: MaterialKey = "metal.screw-zinc", worn: MaterialKey = "metal.anodized-worn"
        let cz: Float = 0.123, R: Float = 0.068, y0: Float = 0.02, y1: Float = 0.302, pivot: Float = 0.15
        // Wall plate with four screws, junction boss and gland.
        FA.box(&m, V3(0.1, 0.17, 0.008), V3(0, 0.15, 0.004), anodize, r: 0.003)
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] { FSV.screw(&m, at: V3(sx * 0.036, 0.15 + sy * 0.068, 0.008), normal: FA.Z, r: 0.0048, steel) } }
        FA.box(&m, V3(0.064, 0.064, 0.036), V3(0, 0.15, 0.026), anodize, r: 0.004)
        m.add(Prim.extrude(Shape2D.polygon(sides: 6, radius: 0.012), depth: 0.016, bevel: 0.0012, bevelSegments: 1, material: trim), Xform(translation: V3(0.0, 0.094, 0.025), rotation: FA.q(90, FA.X)))
        FSV.cyl(&m, V3(0, 0.094, 0.025), V3(0, 0.08, 0.025), r: 0.0075, "rubber.seal", bevel: 0.0008, segments: 10)
        // Forked yoke: two arms from the junction boss around the housing, pivot bolts and locking knobs.
        for s: Float in [-1, 1] {
            let p = [V3(s * 0.03, pivot, 0.04), V3(s * 0.062, pivot, 0.052), V3(s * 0.084, pivot, 0.08), V3(s * 0.086, pivot, cz)]
            FA.path(&m, p, r: 0.0085, anodize, sides: 10)
            FSV.cyl(&m, V3(s * 0.086, pivot, cz), V3(s * 0.092, pivot, cz), r: 0.0145, trim, bevel: 0.002, segments: 18)
            FSV.bolt(&m, at: V3(s * 0.092, pivot, cz), normal: V3(s, 0, 0), size: 0.012, material: steel)
            for k in 0..<8 {
                let a = Float(k) * .pi / 4
                FA.box(&m, V3(0.006, 0.0035, 0.0035), V3(s * 0.092, pivot + 0.0125 * sin(a), cz + 0.0125 * cos(a)), steel, r: 0.0006, rot: FA.q(a * 57.3, FA.X))
            }
        }
        // Housing: lathe with cooling rings, stepped top, machined stainless bezel.
        var prof: [V2] = [V2(0, y0), V2(R - 0.006, y0), V2(R, y0 + 0.006), V2(R, y0 + 0.02)]
        for k in 0..<10 {
            let y = y0 + 0.032 + Float(k) * 0.0215
            prof += [V2(R, y), V2(R + 0.0065, y + 0.003), V2(R + 0.0065, y + 0.0105), V2(R, y + 0.0135)]
        }
        prof += [V2(R, y1 - 0.016), V2(R + 0.002, y1 - 0.012), V2(R + 0.002, y1), V2(0, y1)]
        m.add(Prim.lathe(prof, segments: 36, seamTile: 0.3, material: anodize), Xform(translation: V3(0, 0, cz)))
        m.add(Prim.lathe([V2(R - 0.006, y1 - 0.006), V2(R + 0.0085, y1 - 0.006), V2(R + 0.0085, y1 + 0.012), V2(R + 0.003, y1 + 0.018), V2(R - 0.012, y1 + 0.018), V2(R - 0.012, y1 + 0.0), V2(R - 0.006, y1 - 0.002)],
                          segments: 36, seamTile: 0.3, material: trim), Xform(translation: V3(0, 0, cz)))
        // Lens and louver blades behind a retaining ring.
        FSV.cyl(&m, V3(0, y1 + 0.001, cz), V3(0, y1 + 0.005, cz), r: R - 0.012, "glass.led-lens", bevel: 0.001, segments: 32)
        let lens = V3(0, y1 + 0.009, cz)
        for k in 0..<5 {
            let off = (Float(k) - 2) * 0.022
            let half = sqrt(max(0.0003, (R - 0.014) * (R - 0.014) - off * off))
            FA.box(&m, V3(2 * half - 0.002, 0.0025, 0.0036), lens + V3(0, 0.0, off), anodize, r: 0.0006, rot: FA.q(0, FA.X))
            FA.box(&m, V3(2 * half - 0.002, 0.014, 0.0014), lens + V3(0, 0.0, off) - V3(0, 0.0045, 0), anodize, r: 0.0004)
        }
        // Retaining ring screws (four) and the identification plate.
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            FSV.screw(&m, at: V3((R + 0.0005) * cos(a), y1 + 0.019 + 0.0, cz + (R + 0.0005) * sin(a)) * V3(0.86, 1, 0.86) + V3(0.0, 0, 0) + V3(0, 0, cz * 0.14), normal: FA.Y, r: 0.0036, steel)
        }
        FA.box(&m, V3(0.034, 0.02, 0.0012), V3(0, y0 + 0.05, cz + R + 0.0008), "metal.stainless", r: 0.0003)
        // Wear: chalk at the fin crests, water scale spots on the lens, dirt below the bezel.
        for k in 0..<5 {
            let y = y0 + 0.032 + Float(k * 2) * 0.0215 + 0.0105
            FA.box(&m, V3(rng.float(0.012...0.024), 0.0012, 0.0012), V3(rng.float(-0.008...0.008), y, cz + R + 0.0068), worn, r: 0.0003)
        }
        for _ in 0..<7 {
            let a = rng.float(0...6.28), rr = rng.float(0.01...0.05)
            FA.box(&m, V3(0.004, 0.0004, 0.004), V3(rr * cos(a), y1 + 0.0052, cz + rr * sin(a)), "metal.painted:C9C7BE", r: 0.0001)
        }
        FSV.streak(&m, at: V3(rng.float(-0.04...0.04), y1 - 0.004, cz + R + 0.0086), w: 0.008, h: 0.04, "metal.anodized-worn")
        return LODModel(FC.seatY(m))
    }
}
