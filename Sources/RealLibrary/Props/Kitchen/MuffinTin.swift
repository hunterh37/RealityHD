import simd
import Foundation

/// Twelve-cup nonstick muffin tin: 4 x 3 tapered cups pressed through a flat flange sheet, rolled
/// perimeter bead, baked patina on the underside.
public struct MuffinTin: RealAsset {
    public static let id = "muffin-tin"
    public static let summary = "12-cup nonstick muffin tin: tapered cups, flat flange, rolled perimeter bead."
    public static let tags = ["prop", "interior", "kitchen", "nonstick", "steel", "metal"]
    public static let budget = 24000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 0.8, studio: true)

    /// Overall width and depth (m).
    public var width: Float = 0.35
    public var depth: Float = 0.27
    /// Flange height above the base (m).
    public var flangeY: Float = 0.0375
    /// Cup pitch (m).
    public var pitch: Float = 0.08
    /// Sheet thickness (m).
    public var sheet: Float = 0.0009
    /// Coated inside.
    public var coating: MaterialKey = "metal.powdercoat:3A3A3E"
    /// Outer steel.
    public var steel: MaterialKey = "metal.sheet-pan"
    public init() {}

    func cup(depth h: Float) -> Vessel {
        let f: Float = 0.0012, R: Float = 0.022
        let curve = Profile.smooth([V2(R - 0.006, f), V2(R, f), V2(R + 0.003, f + 0.002), V2(0.0285, f + 0.012), V2(0.0325, h)], per: 3)
        return Vessel(inner: [V2(0, f)] + curve, wall: sheet, floorRadius: R, rim: .cut)
    }

    func model(segments: Int) -> Model {
        var m = Model(name: Self.id)
        let v = cup(depth: flangeY - 0.0004)
        let holeR = v.rimOuterRadius + 0.0006, seg = max(24, segments / 2)
        let cols = 4, rows = 3
        let gw = Float(cols) * pitch, gd = Float(rows) * pitch
        var floors: [Surface] = []
        for i in 0..<cols { for j in 0..<rows {
            let c = V3((Float(i) - 1.5) * pitch, 0, (Float(j) - 1) * pitch)
            for (role, s) in v.surfaces(segments: seg, interior: coating, exterior: steel, edge: steel, floorMaterial: coating, seamTile: 0.1, planarFloor: true) {
                if role == .floor { floors.append(s.transformed(Xform(translation: c))) } else { m.add(s, Xform(translation: c)) }
            }
            let sq = Shape2D.superellipse(pitch * 1.004, pitch * 1.004, exponent: 60, segments: seg)
            let hole = Shape2D.circle(holeR, segments: seg)
            let top = Prim.loft([Prim.ring(hole, y: flangeY), Prim.ring(sq, y: flangeY)], material: coating).flipped()
            m.add(top, Xform(translation: c))
            m.add(Prim.loft([Prim.ring(hole, y: flangeY - sheet), Prim.ring(sq, y: flangeY - sheet)], material: steel), Xform(translation: c))
        }}
        // Border ring between the cup grid and the outer edge.
        let outerR = Shape2D.roundedRect(width, depth, radius: 0.012, segments: 6)
        let innerR = Shape2D.roundedRect(gw, gd, radius: 0.002, segments: 6)
        m.add(Prim.loft([Prim.ring(innerR, y: flangeY), Prim.ring(outerR, y: flangeY)], material: coating).flipped())
        m.add(Prim.loft([Prim.ring(innerR, y: flangeY - sheet), Prim.ring(outerR, y: flangeY - sheet)], material: steel))
        let path = Prim.ring(Shape2D.roundedRect(width - 0.003, depth - 0.003, radius: 0.0105, segments: 8), y: flangeY - 0.0004)
        m.add(Prim.sweep(Shape2D.circle(0.0024, segments: 10), along: path, closedPath: true, material: steel))
        for f in floors { m.surfaces.append(f) }
        groundAO(&m, height: 0.02, floor: 0.55)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(segments: 40), model(segments: 16)], switchDistances: [3])
    }
}
