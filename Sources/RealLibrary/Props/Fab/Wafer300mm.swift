import simd
import Foundation

/// 300 mm silicon wafer: polished prime wafer, 775 um thick, notch and laser ID, selectable process state.
public struct Wafer300mm: RealAsset {
    public static let id = "wafer-300mm"
    public static let summary = "300 mm silicon wafer with notch, selectable process state."
    public static let tags = ["prop", "semiconductor", "handheld"]
    public static let budget = 2000
    public static let author = "realityhd"

    /// Wafer diameter in meters.
    public var diameter: Float = 0.3
    /// Wafer thickness in meters (SEMI 775 um).
    public var thickness: Float = 0.000775
    /// Process state: bare, oxide, patterned or metal.
    public var state = "bare"
    /// Die pitch in meters for the patterned state (26 x 33 mm field).
    public var dieSize = V2(0.026, 0.033)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let mat: String
        switch state {
        case "oxide": mat = "silicon.thinfilm-oxide"
        case "patterned": mat = "silicon.thinfilm-patterned"
        case "metal": mat = "silicon.thinfilm-metal"
        default: mat = "silicon.thinfilm"
        }
        let r = diameter / 2
        // Outline with a V notch (1 mm deep) at -Y of the XY plane.
        var pts: [V2] = []
        let n = 96
        let notchA: Float = 0.012
        for i in 0..<n {
            let a = Float(i) / Float(n) * 2 * .pi
            let d = a - 1.5 * .pi
            if abs(atan2(sin(d), cos(d))) < notchA { continue }
            pts.append(V2(cos(a) * r, sin(a) * r))
        }
        let ia = pts.firstIndex { $0.y < -r * 0.99 } ?? 0
        pts.insert(V2(0, -r + 0.001), at: min(ia + 1, pts.count))
        let disc = Prim.extrude(Shape2D.deduped(pts), depth: thickness, bevel: 0.00025, bevelSegments: 1, material: mat)
        let flat = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        m.add(disc, Xform(translation: V3(0, thickness / 2, 0), rotation: flat))
        // Laser-marked ID beside the notch.
        m.add(Prim.roundedBox(V3(0.012, 0.00004, 0.0016), radius: 0.00002, bevelSegments: 1, material: "metal.steel"),
              Xform(translation: V3(0.016, thickness + 0.00002, r - 0.007)))
        if state == "patterned" {
            let cols = Int((diameter - 0.012) / dieSize.x), rows = Int((diameter - 0.012) / dieSize.y)
            for i in 0..<cols {
                for j in 0..<rows {
                    let x = (Float(i) - Float(cols - 1) / 2) * dieSize.x
                    let z = (Float(j) - Float(rows - 1) / 2) * dieSize.y
                    if simd_length(V2(abs(x) + dieSize.x / 2, abs(z) + dieSize.y / 2)) > r - 0.003 { continue }
                    m.add(Prim.roundedBox(V3(dieSize.x - 0.0008, 0.00004, dieSize.y - 0.0008), radius: 0.00001, bevelSegments: 1, material: "silicon.thinfilm"),
                          Xform(translation: V3(x, thickness + 0.00002, z)))
                }
            }
        }
        _ = rng.float()
        return LODModel(m)
    }
}
