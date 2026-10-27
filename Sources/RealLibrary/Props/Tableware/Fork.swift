import simd
import Foundation

/// Stainless steel dinner fork, 20 cm: a flat blank with a swelling rounded handle end, a tapered neck, a broad head
/// with four slotted tines, the whole piece lifted off the table at the neck. A raised centre ridge runs down the handle.
/// A fingerprint-smudged finish, polished tine tips, a dried food fleck at a tine root and water spots tell its use.
public struct Fork: RealAsset {
    public static let id = "fork"
    public static let summary = "Stainless steel dinner fork, 20 cm: four slotted tines, tapered handle, smudged finish, dried food fleck and water spots."
    public static let tags = ["prop", "interior", "tableware", "metal", "handheld"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 40, studio: true)

    /// Satin body with fingerprint smudges.
    public var steel: MaterialKey = "metal.stainless-smudged"
    /// Polished tine tips and ridge.
    public var polish: MaterialKey = "metal.mirror-polish"
    public init() {}

    static let len: Float = 0.20

    /// Height of the blank's midplane above the table at distance s from the handle end.
    static func lift(_ s: Float) -> Float {
        let neck = 0.0030 * DD1GWare.smooth(0.085, 0.140, s)
        let rise = 0.0035 * DD1GWare.smooth(0.095, 0.130, s)
        let tips = 0.0016 * pow(max(0, (s - 0.150) / 0.050), 2)
        let curl = 0.0007 * (1 - DD1GWare.smooth(0, 0.02, s))
        return 0.0011 + neck + rise + tips + curl
    }

    static func tineOutline() -> [V2] {
        // Right edge of the handle and neck, then the head and four tines right to left, then the left edge back down.
        func hw(_ s: Float) -> Float {
            if s < 0.020 { return 0.0095 * sqrt(max(0, 1 - pow((0.020 - s) / 0.020, 2))) }
            if s < 0.055 { return 0.0095 - 0.0027 * DD1GWare.smooth(0.020, 0.055, s) }
            if s < 0.100 { return 0.0068 - 0.0030 * DD1GWare.smooth(0.055, 0.100, s) }
            if s < 0.140 { return 0.0038 + 0.0090 * DD1GWare.smooth(0.104, 0.140, s) }
            return 0.0128
        }
        var pts: [V2] = []
        var s: Float = 0
        while s < 0.1495 { pts.append(V2(hw(s), s)); s += 0.0035 }
        pts.append(V2(0.0126, 0.1495))
        // Tines from +X to -X, each with a rounded tip, separated by slots with round roots.
        let xs: [Float] = [0.0102, 0.0034, -0.0034, -0.0102]
        let root: Float = 0.1520, tipS: Float = 0.1992
        for (i, cx) in xs.enumerated() {
            func w(_ s: Float) -> Float { 0.0018 - 0.0006 * DD1GWare.smooth(0.165, tipS, s) }
            // Up the right edge of this tine.
            pts.append(V2(cx + w(root), root))
            var t = root + 0.008
            while t < tipS { pts.append(V2(cx + w(t), t)); t += 0.008 }
            for k in 1..<6 {
                let a = Float(k) / 6 * .pi
                pts.append(V2(cx + w(tipS) * cos(a), tipS + w(tipS) * 0.9 * sin(a)))
            }
            // Down the left edge.
            t = tipS
            while t > root + 0.008 { pts.append(V2(cx - w(t), t)); t -= 0.008 }
            pts.append(V2(cx - w(root), root))
            // Slot root to the next tine (round bottom).
            if i < xs.count - 1 {
                let sx = (cx + xs[i + 1]) / 2, r = (cx - w(root) - (xs[i + 1] + w(root))) / 2
                for k in 1..<5 {
                    let a = Float(k) / 5 * .pi
                    pts.append(V2(sx + r * cos(a), root - r * 0.9 * sin(a)))
                }
            }
        }
        pts.append(V2(-0.0126, 0.1495))
        var u: Float = 0.1495 - 0.0035
        while u > 0.0001 { pts.append(V2(-hw(u), u)); u -= 0.0035 }
        return DD1GWare.densify(pts, max: 0.0035)
    }

    func level(detail: Bool) -> Model {
        var rng = SeededRNG(seed: 81)
        var m = Model(name: Self.id)
        let outline = Self.tineOutline().map { V2($0.x * 1.14, $0.y - Self.len / 2) }
        var body = DD1GWare.plate(outline, thick: 0.0018, bevel: 0.0006, material: steel)
        body.deform { p in V3(p.x, p.y + Self.lift(p.z + Self.len / 2), p.z) }
        m.add(body)
        // Raised centre ridge down the handle.
        let ridge = DD1GWare.blank({ s in 0.0009 * sin(.pi * (s - 0.018) / 0.074) }, from: 0.018, to: 0.092, step: 0.004).map { V2($0.x, $0.y - Self.len / 2) }
        var rs = DD1GWare.plate(DD1GWare.densify(ridge, max: 0.004), thick: 0.0006, bevel: 0.00025, material: polish)
        rs.deform { p in V3(p.x, p.y + Self.lift(p.z + Self.len / 2) + 0.0010, p.z) }
        m.add(rs)
        // Dried food fleck lodged at a tine root.
        let fs: Float = 0.1535 - Self.len / 2
        m.add(DD1GWare.blob(V3(0.0030, 0.0009, 0.0022), material: "food.egg-curd:E8D79A"),
              Xform(translation: V3(0.0034, Self.lift(0.1535) + 0.0010, fs), rotation: simd_quatf(degrees: 20, axis: V3(0, 1, 0))))
        // Water spots on the handle.
        if detail {
            for _ in 0..<7 {
                let s = rng.float(0.030...0.095), x = rng.float(-0.003...0.003)
                m.add(Prim.cylinder(radius: rng.float(0.0006...0.0012), height: 0.0001, bevel: 0.00005, segments: 8, material: polish),
                      Xform(translation: V3(x, Self.lift(s) + 0.0009 + 0.0007, s - Self.len / 2)))
            }
        }
        DD1GWare.plant(&m)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(detail: true), level(detail: false)], switchDistances: [1.5])
    }
}
