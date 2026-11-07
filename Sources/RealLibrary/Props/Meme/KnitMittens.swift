import simd
import Foundation

/// Knit mittens: a pair of cable-knit wool mittens, 27 cm long, ribbed cuffs, lofted hand with twisting cables and a thumb. Lying flat, fingers toward -Z.
public struct KnitMittens: RealAsset {
    public static let id = "knit-mittens"
    public static let summary = "Pair of cable-knit wool mittens, 27 cm: 2x2 ribbed cuffs, braided cables on the hand, tapered thumbs, fuzzy wool fiber."
    public static let tags = ["prop", "fabric", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"

    public var bodyColor: MaterialKey = "fabric.wool:B3202A"
    public var cuffColor: MaterialKey = "fabric.wool:EFE8D8"
    public init() {}

    private static let length: Float = 0.27, cuffEnd: Float = 0.075

    /// Full width and thickness of the mitten section at distance y from the cuff edge.
    private static func section(_ y: Float) -> (w: Float, h: Float) {
        let t = y / length
        if y < cuffEnd { return (0.088 + 0.004 * t, 0.046) }
        let u = (y - cuffEnd) / (length - cuffEnd)
        let widen = 0.088 + 0.030 * sin(min(1, u * 2.2) * .pi / 2)
        // Rounded fingertip: elliptical closure over the last 22 %.
        let tip: Float = u > 0.78 ? sqrt(max(0, 1 - pow((u - 0.78) / 0.22, 2))) : 1
        return (widen * max(0.04, tip), (0.046 - 0.006 * u) * max(0.04, tip))
    }

    /// One mitten loft between two distances from the cuff edge.
    private func loft(_ y0: Float, _ y1: Float, rings count: Int, ribs: Bool, material: MaterialKey) -> Surface {
        let base = Shape2D.superellipse(1, 1, exponent: 2.6, segments: 64)
        var rings: [[V3]] = []
        for i in 0..<count {
            let y = y0 + (y1 - y0) * Float(i) / Float(count - 1), s = Self.section(y)
            let pts = base.enumerated().map { (k, p) -> V2 in
                let a = Float(k) / 64 * 2 * .pi
                // Cuff: 16 ribs of 2x2 knit and purl. Hand: braided cable columns that weave with height.
                let bump: Float = ribs ? 0.045 * sin(a * 16) : 0.035 * sin(a * 8 + 2.4 * sin(y * 70)) + 0.012 * sin(a * 24)
                let fold: Float = y < Self.cuffEnd + 0.004 && y > Self.cuffEnd - 0.006 ? 1.04 : 1
                return V2(p.x * s.w * (1 + bump) * fold, p.y * s.h * (1 + bump) * fold)
            }
            rings.append(Prim.ring(pts, y: y))
        }
        return Prim.loft(rings, capStart: y0 == 0, capEnd: y1 >= Self.length - 0.0001, material: material)
    }

    private func mitten(thumbSide: Float) -> Model {
        var m = Model(name: "mitten")
        m.add(loft(0, Self.cuffEnd, rings: 10, ribs: true, material: cuffColor))
        m.add(loft(Self.cuffEnd, Self.length, rings: 34, ribs: false, material: bodyColor))
        // Thumb: tapered tube angled out and forward from the side of the hand, closed with a rounded tip.
        var path: [V3] = [], radii: [Float] = []
        let root = V3(thumbSide * 0.040, 0.100, 0)
        for k in 0...10 {
            let t = Float(k) / 10
            path.append(root + V3(thumbSide * (0.012 + 0.030 * t), 0.004 + 0.062 * t, 0.002 * sin(t * .pi)))
            radii.append(0.0185 * (1 - 0.22 * t))
        }
        for k in 1...3 { let t = Float(k) / 3; path.append(path[10] + V3(thumbSide * 0.003 * t, 0.011 * sin(t * .pi / 2), 0)); radii.append(0.0145 * cos(t * .pi / 2 * 0.95) + 0.0006) }
        m.add(Prim.tube(path, radii: radii, sides: 24, seamTile: 0.03, material: bodyColor))
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        // Mitten is built along +Y with thickness on Z; tip it flat so the length runs to -Z and thickness is vertical.
        let flat = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        let right = mitten(thumbSide: 1).transformed(Xform(rotation: flat))
        let left = mitten(thumbSide: -1).transformed(Xform(rotation: flat))
        let lift: Float = 0.0245
        m.add(right, Xform(translation: V3(0.075, lift, 0.135)))
        m.add(left, Xform(translation: V3(-0.075, lift, 0.115), rotation: simd_quatf(degrees: 5, axis: .up)))
        return LODModel(m)
    }
}
