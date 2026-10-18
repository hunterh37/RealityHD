import simd
import Foundation

/// Bare organic package substrate, 100 x 100 x 3 mm: ABF build-up laminate with solder mask, gold die-land
/// pad grid, perimeter pad ring, corner fiducials, an orientation chamfer marker and edge decoupling capacitors.
public struct PackageSubstrate: RealAsset {
    public static let id = "package-substrate"
    public static let summary = "Bare organic package substrate: ABF laminate, gold die-land pads, perimeter pads, fiducials, edge capacitors."
    public static let tags = ["prop", "electronics", "articulated"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 0.2, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.1, 0.003, 0.1)
    /// Die land pad grid per side and pitch (m).
    public var landCount = 5
    public var landPitch: Float = 0.0075
    /// Laminate and pad material keys.
    public var laminate: MaterialKey = "laminate.abf"
    public var padMaterial: MaterialKey = "metal.gold"
    public init() {}

    /// Flat prismatic pad (n-gon extrude) standing on y.
    func pad(_ m: inout Model, _ r: Float, _ h: Float, _ n: Int, _ at: V3, _ mat: MaterialKey) {
        m.add(Prim.lathe([V2(r, 0), V2(r, h), V2(0, h)], segments: n, seamTile: 1, material: mat), Xform(translation: at))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, T = size.y, D = size.z
        // Core with satin mask skin; sits on the bottom pad layer.
        let core: Float = 0.00235, y0: Float = T - core
        m.add(Prim.roundedBox(V3(W, core, D), radius: 0.00003, bevelSegments: 1, material: laminate),
              Xform(translation: V3(0, y0 + core / 2, 0)))
        let top = y0 + core
        let land = Float(landCount - 1) * landPitch
        // Die land: gold microbump pads.
        for i in 0..<landCount { for j in 0..<landCount {
            let x = (Float(i) - Float(landCount - 1) / 2) * landPitch, z = (Float(j) - Float(landCount - 1) / 2) * landPitch
            pad(&m, 0.0016, 0.00012, 6, V3(x, top, z), padMaterial)
        } }
        // Perimeter pad ring on the top: two rows per side, outside the capacitors.
        let ringR = W / 2 - 0.0035
        for k in 0..<7 {
            let t = (Float(k) - 3) * 0.0115
            for (p, q) in [(t, ringR), (t, -ringR), (ringR, t), (-ringR, t)] {
                pad(&m, 0.0012, 0.0001, 4, V3(p, top, q), padMaterial)
            }
        }
        // Edge decoupling capacitors (0402 class: 1.0 x 0.5 x 0.35 mm) with solder-tinned terminals.
        for k in 0..<4 {
            let t = (Float(k) - 1.5) * 0.0175 + rng.float(-0.0003...0.0003)
            for (p, q, rot) in [(t, W / 2 - 0.0085, Float(0)), (t, -(W / 2 - 0.0085), 0), (W / 2 - 0.0085, t, 90), (-(W / 2 - 0.0085), t, 90)] {
                let xf = Xform(translation: V3(p, top + 0.000175, q), rotation: simd_quatf(degrees: rot, axis: V3(0, 1, 0)))
                m.add(Prim.extrude(Shape2D.rect(0.001, 0.00035), depth: 0.0005, bevel: 0, bevelSegments: 1, material: "metal.solder"), xf)
                m.add(Prim.extrude(Shape2D.rect(0.0006, 0.00037), depth: 0.00048, bevel: 0, bevelSegments: 1, material: "plastic.underfill"),
                      Xform(translation: V3(p, top + 0.000185, q), rotation: xf.rotation))
            }
        }
        // Corner fiducials (gold discs) and a triangular pin-1 marker.
        for (sx, sz) in [(Float(-1), Float(-1)), (1, -1), (1, 1)] {
            let fx: Float = sx * (W / 2 - 0.0018), fz: Float = sz * (D / 2 - 0.0018)
            pad(&m, 0.0008, 0.00012, 8, V3(fx, top, fz), padMaterial)
        }
        m.add(Prim.extrude([V2(0, 0), V2(0.003, 0), V2(0, 0.003)], depth: 0.00012, bevel: 0.00002, bevelSegments: 1, material: padMaterial),
              Xform(translation: V3(-W / 2 + 0.0012, top + 0.00006, D / 2 - 0.0012), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        // Underside LGA pad rows (merged strips) under the core edge.
        for (dx, dz, sx, sz) in [(Float(0), W / 2 - 0.0032, W - 0.012, 0.0045), (0, -(W / 2 - 0.0032), W - 0.012, 0.0045),
                                  (W / 2 - 0.0032, 0, 0.0045, W - 0.012), (-(W / 2 - 0.0032), 0, 0.0045, W - 0.012)] {
            m.add(Prim.roundedBox(V3(sx, y0, sz), radius: 0.00003, bevelSegments: 1, material: padMaterial), Xform(translation: V3(dx, y0 / 2, dz)))
        }
        //groundAO(&m)
        return LODModel(m)
    }
}
