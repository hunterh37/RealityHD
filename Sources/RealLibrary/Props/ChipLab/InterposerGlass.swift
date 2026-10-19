import simd
import Foundation

/// Glass interposer: Ultra realistic glass-core interposer, 80 x 60 mm, 1 mm thick, bare, no die, pale clear glass with copper TGVs and RDL.. Parts: clear glass core slab, through-glass-via copper grid visible in the front and right polished edges, copper redistribution layer traces on top, copper landing pads, central die landing footprint microbump grid, two HBM landing footprints flanking the die, corner fiducials.
public struct InterposerGlass: RealAsset {
    public static let id = "interposer-glass"
    public static let summary = "Glass-core interposer with TGV copper grid, RDL traces, die and HBM landing footprints."
    public static let tags = ["prop"]
    public static let budget = 2000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.08, 0.001, 0.06)
    public init() {}

    /// Via pitch along the polished edges (m).
    public var viaPitch: Float = 0.0038
    /// Microbump pitch in the die and HBM footprints (m).
    public var bumpPitch: Float = 0.0023
    public var glass: MaterialKey = "glass.substrate-clear"
    public var copper: MaterialKey = "metal.copper"

    func box(_ m: inout Model, _ w: Float, _ h: Float, _ d: Float, _ at: V3, _ mat: MaterialKey) {
        m.add(Prim.extrude(Shape2D.rect(w, h), depth: d, bevel: 0, bevelSegments: 1, material: mat), Xform(translation: at))
    }

    func pad(_ m: inout Model, _ r: Float, _ h: Float, _ at: V3, _ mat: MaterialKey) {
        m.add(Prim.lathe([V2(r, 0), V2(r, h), V2(0, h)], segments: 4, seamTile: 1, material: mat), Xform(translation: at))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let gT: Float = 0.0009, film: Float = 0.00004, cu: Float = 0.00008
        // Glass core with ground, slightly chamfered edges.
        m.add(Prim.roundedBox(V3(W, gT, D), radius: 0.00008, bevelSegments: 1, material: glass),
              Xform(translation: V3(0, gT / 2, 0)))
        // Polyimide build-up film, inset from the edge so the glass edge and vias stay visible.
        let fx = W - 0.006, fz = D - 0.006
        m.add(Prim.roundedBox(V3(fx, film, fz), radius: 0.00002, bevelSegments: 1, material: glass),
              Xform(translation: V3(0, gT + film / 2, 0)))
        let top = gT + film
        // Through-glass vias seen as copper columns in the front and right polished edges.
        let nF = Int((W - 0.008) / viaPitch)
        for k in 0..<nF {
            let x = (Float(k) - Float(nF - 1) / 2) * viaPitch
            box(&m, 0.0003, gT - 0.0001, 0.00004, V3(x, gT / 2, D / 2 + 0.00001), copper)
        }
        let nR = Int((D - 0.008) / viaPitch)
        for k in 0..<nR {
            let z = (Float(k) - Float(nR - 1) / 2) * viaPitch
            m.add(Prim.extrude(Shape2D.rect(0.0003, gT - 0.0001), depth: 0.00004, bevel: 0, bevelSegments: 1, material: copper),
                  Xform(translation: V3(W / 2 + 0.00001, gT / 2, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
        }
        // Landing footprints: die (centre) and two HBM sites, each a frame of copper plus perimeter bumps.
        let sites: [(Float, Float, Float, Float)] = [(0, 0, 0.026, 0.034), (-0.0285, 0, 0.0105, 0.0125), (0.0285, 0, 0.0105, 0.0125)]
        for (cx, cz, sw, sd) in sites {
            let t: Float = 0.0004, y = top + cu / 2
            box(&m, sw + t, cu, t, V3(cx, y, cz + sd / 2), copper); box(&m, sw + t, cu, t, V3(cx, y, cz - sd / 2), copper)
            m.add(Prim.extrude(Shape2D.rect(t, sd), depth: cu, bevel: 0, bevelSegments: 1, material: copper),
                  Xform(translation: V3(cx + sw / 2, y, cz), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            m.add(Prim.extrude(Shape2D.rect(t, sd), depth: cu, bevel: 0, bevelSegments: 1, material: copper),
                  Xform(translation: V3(cx - sw / 2, y, cz), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            let nx = Int(sw / bumpPitch) - 1, nz = Int(sd / bumpPitch) - 1
            for i in 0..<nx { for j in 0..<nz {
                let edge = (i == 0 || j == 0 || i == nx - 1 || j == nz - 1)
                if !edge { continue }
                let x = cx + (Float(i) - Float(nx - 1) / 2) * bumpPitch, z = cz + (Float(j) - Float(nz - 1) / 2) * bumpPitch
                pad(&m, 0.0008, cu, V3(x, top, z), "metal.gold")
            } }
        }
        // RDL traces: fan-out lines from the die edge to each HBM site, with via-land pads at the bends.
        for k in 0..<8 {
            let z = (Float(k) - 3.5) * 0.0024 + rng.float(-0.0002...0.0002)
            for s in [Float(-1), 1] {
                let x0 = s * 0.0145, x1 = s * 0.0228
                box(&m, abs(x1 - x0), 0.0002, cu, V3((x0 + x1) / 2, top + cu / 2 - 0.00003, z), copper)
            }
        }
        // Edge routing along the film border and corner fiducials.
        for s in [Float(-1), 1] {
            box(&m, fx - 0.004, cu, 0.00035, V3(0, top + cu / 2, s * (fz / 2 - 0.0015)), copper)
            m.add(Prim.extrude(Shape2D.rect(0.00035, fz - 0.004), depth: cu, bevel: 0, bevelSegments: 1, material: copper),
                  Xform(translation: V3(s * (fx / 2 - 0.0015), top + cu / 2, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            pad(&m, 0.0006, cu, V3(s * (fx / 2 - 0.0035), top, s * (fz / 2 - 0.0035)), "metal.gold")
        }
        // Lot marking pad and a stray solder-flux fleck near the front edge: one story detail.
        box(&m, 0.0042, cu, 0.0018, V3(-0.026, top + cu / 2, fz / 2 - 0.0035), "metal.gold")
        box(&m, 0.0009, 0.00012, 0.0007, V3(0.0305, top + 0.00006, fz / 2 - 0.0058), "metal.solder")
        return LODModel(m)
    }
}
