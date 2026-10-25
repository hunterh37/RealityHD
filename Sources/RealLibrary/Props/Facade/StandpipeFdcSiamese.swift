import simd
import Foundation

/// Siamese fire department connection: architectural facade customizer, Commercial. Wall escutcheon plate on hex
/// bolts, 4 in stem with flange union, forked body with two angled 2-1/2 in swivel inlets (rocker lugs, knurled
/// collars), threaded plug caps on chains, and a raised cast "FDC" plate. Brass is polished on the couplings and
/// tarnished on the plate; verdigris runs under the caps.
public struct StandpipeFdcSiamese: RealAsset {
    public static let id = "standpipe-fdc-siamese"
    public static let summary = "Wall mount Siamese FDC, 0.4 m: polished brass inlets with plugs, chains and escutcheon plate."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 0.9)

    /// Polished brass.
    public var brass: MaterialKey = "metal.brass"
    /// Tarnished brass.
    public var aged: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let patina: MaterialKey = "metal.copper-patina", steel: MaterialKey = "metal.steel"
        let cy: Float = 0.145
        // Wall escutcheon: square plate, bead border, six hex bolts, raised cast legend plate above.
        FA.box(&m, V3(0.19, 0.19, 0.012), V3(0, cy, 0.006), aged, r: 0.004)
        FA.box(&m, V3(0.176, 0.176, 0.006), V3(0, cy, 0.013), aged, r: 0.003)
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            FSV.bolt(&m, at: V3(sx * 0.078, cy + sy * 0.078, 0.016), normal: FA.Z, size: 0.016, material: steel)
        } }
        FA.box(&m, V3(0.24, 0.07, 0.01), V3(0, 0.265, 0.005), aged, r: 0.003)
        FA.box(&m, V3(0.226, 0.056, 0.004), V3(0, 0.265, 0.011), aged, r: 0.002)
        FSV.letters(&m, "FDC", c: V3(0, 0.265, 0.0145), h: 0.03, stroke: 0.006, gap: 0.008, brass)
        for s: Float in [-1, 1] { FSV.bolt(&m, at: V3(s * 0.108, 0.265, 0.011), normal: FA.Z, size: 0.012, material: steel) }
        // Stem: 4 in pipe from the plate with a flange union and a cast elbow body.
        let zj: Float = 0.115
        FSV.cyl(&m, V3(0, cy, 0.012), V3(0, cy, zj), r: 0.038, aged, bevel: 0.002, segments: 16)
        FSV.cyl(&m, V3(0, cy, 0.05), V3(0, cy, 0.062), r: 0.054, brass, bevel: 0.0025, segments: 16)
        for a in 0..<8 {
            let ang = Float(a) * .pi / 4
            FSV.bolt(&m, at: V3(0.046 * cos(ang), cy + 0.046 * sin(ang), 0.0625), normal: FA.Z, size: 0.007, material: steel)
        }
        m.add(Prim.superellipsoid(V3(0.1, 0.1, 0.1), exponent: 2, subdivisions: 6, material: brass), Xform(translation: V3(0, cy, zj)))
        // Two inlets.
        let dirs: [V3] = [V3(-0.7, -0.4, 0.6), V3(0.7, -0.4, 0.6)].map { simd_normalize($0) }
        for (i, d) in dirs.enumerated() {
            let q = facing(d)
            let side = simd_normalize(simd_cross(d, V3(0, 1, 0)))
            let j = V3(0, cy, zj)
            let a = j + d * 0.03, b = j + d * 0.118, c = j + d * 0.198, e = j + d * 0.244
            FSV.cyl(&m, a, b, r: 0.034, brass, bevel: 0.002)
            // Cast flange collar, then swivel female coupling with knurled collar and rocker lugs.
            FSV.cyl(&m, b - d * 0.004, b + d * 0.01, r: 0.046, aged, bevel: 0.002)
            let len = simd_length(c - (b + d * 0.01))
            var grooves: [V2] = [V2(0, 0), V2(0.04, 0)]
            for k in 0..<5 {
                let y0 = len * (0.2 + Float(k) * 0.14)
                grooves += [V2(0.0415, y0), V2(0.0385, y0 + 0.002), V2(0.0385, y0 + 0.006), V2(0.0415, y0 + 0.008)]
            }
            grooves += [V2(0.0415, len), V2(0, len)]
            m.add(Prim.lathe(grooves, segments: 16, seamTile: 0.2, material: aged), Xform(translation: b + d * 0.01, rotation: q))
            for sgn: Float in [-1, 1] {
                FA.box(&m, V3(0.02, 0.016, 0.014), (b + c) / 2 + side * sgn * 0.051 + d * 0.006, brass, r: 0.003, rot: q)
            }
            // Threaded plug: cap with a square drive lug, ring seal, eye for the chain.
            FSV.cyl(&m, c, e, r: 0.045, aged, bevel: 0.003)
            FSV.cyl(&m, c - d * 0.002, c + d * 0.003, r: 0.047, "rubber.seal", bevel: 0.0008)
            FA.box(&m, V3(0.034, 0.012, 0.012), e + d * 0.004, aged, r: 0.002, rot: q)
            m.add(Prim.torus(major: 0.009, minor: 0.0025, segments: 12, sides: 6, material: steel),
                  Xform(translation: (b + c) / 2 + side * (i == 0 ? -1 : 1) * 0.0, rotation: q * FA.q(90, FA.X)))
            // Chain from the plug eye toward the plate hook: sagging catenary.
            let hook = V3((i == 0 ? -1 : 1) * 0.06, 0.065, 0.014)
            let eye = e + side * 0.0 + V3(0, -0.04, 0)
            var cp: [V3] = []
            for k in 0...10 {
                let t = Float(k) / 10
                cp.append(eye + (hook - eye) * t - V3(0, 0.035 * sin(t * .pi), 0))
            }
            FSV.chain(&m, along: cp, steel)
            FA.box(&m, V3(0.012, 0.008, 0.01), hook, steel, r: 0.002)
            // Verdigris and water staining under the cap.
        }
        FSV.streak(&m, at: V3(0.03, cy - 0.052, 0.0165), w: 0.012, h: 0.03, patina)
        // Stain on the plate from weeping coupling.
        FSV.streak(&m, at: V3(rng.float(-0.02...0.02), cy - 0.045, 0.0165), w: 0.02, h: 0.04, "metal.rust-grime")
        return LODModel(FC.seatY(m))
    }
}
