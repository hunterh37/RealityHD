import simd
import Foundation

/// 24 in square four-way supply diffuser, authored in place: the face flange sits 2 mm below the ceiling plane at
/// y = 2.6 and the cones recess 0.1 m up into the ceiling void. White baked-enamel flange with a rolled lip, three
/// concentric stepped cones, a center cap, a galvanized sheet-metal collar and four corner screws.
public struct CeilingDiffuser: RealAsset {
    public static let id = "ceiling-diffuser"
    public static let summary = "24 in square four-way ceiling supply diffuser: white flange, three stepped louver cones, center cap, sheet-metal collar."
    public static let tags = ["prop", "floorplan", "interior", "ceiling", "hvac", "metal"]
    public static let budget = 3500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: -48, distance: 1.5, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.6, 0.1, 0.6)
    /// Ceiling plane height (m).
    public var ceilingY: Float = 2.6
    /// Face paint.
    public var paint: MaterialKey = "metal.powder-white:F6F6F3"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let yb = ceilingY - 0.002
        let S = size.x
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 2 : 1
            // Flange frame: four bars with a rolled lip, border 0.042 wide.
            let bw: Float = 0.042, fh: Float = 0.004
            for k in 0..<4 {
                let along = k < 2
                let s: Float = k % 2 == 0 ? 1 : -1
                let sz = along ? V3(S, fh, bw) : V3(bw, fh, S - 2 * bw + 0.002)
                let c = along ? V3(0, yb + fh / 2, s * (S - bw) / 2) : V3(s * (S - bw) / 2, yb + fh / 2, 0)
                m.add(lod == 0 ? Prim.roundedBox(sz, radius: 0.0016, bevelSegments: seg, material: paint) : cuboid(sz, material: paint), Xform(translation: c))
            }
            // Stepped cones: lowest lip at the outside, inner cones recessed higher. Rings run top to bottom so the
            // inner (visible from below) face is outward-facing.
            let cones: [(hb: Float, rise: Float, lip: Float)] = [(0.257, 0.03, 0.0), (0.19, 0.048, 0.006), (0.123, 0.064, 0.012)]
            for c in cones {
                let ht = c.hb - 0.034
                let r = lod == 0 ? Float(0.01) : 0.004
                let top = Prim.ring(Shape2D.roundedRect(ht * 2, ht * 2, radius: r, segments: seg), y: yb + c.lip + c.rise)
                let bot = Prim.ring(Shape2D.roundedRect(c.hb * 2, c.hb * 2, radius: r * 1.4, segments: seg), y: yb + c.lip)
                m.add(Prim.loft([top, bot], material: paint))
                m.add(Prim.loft([bot, top], material: paint))
                // Thin rolled lip band at the bottom of each cone.
                let lipTop = Prim.ring(Shape2D.roundedRect(c.hb * 2, c.hb * 2, radius: r * 1.4, segments: seg), y: yb + c.lip + 0.004)
                let lipBot = Prim.ring(Shape2D.roundedRect((c.hb + 0.003) * 2, (c.hb + 0.003) * 2, radius: r * 1.5, segments: seg), y: yb + c.lip - 0.0005)
                m.add(Prim.loft([lipBot, lipTop], material: paint))
                m.add(Prim.loft([lipTop, lipBot].reversed(), material: paint))
                // Return fold at the top edge of the cone: a short vertical band, doubled for thickness.
                let tr = Prim.ring(Shape2D.roundedRect(ht * 2, ht * 2, radius: r, segments: seg), y: yb + c.lip + c.rise)
                let tr2 = Prim.ring(Shape2D.roundedRect(ht * 2, ht * 2, radius: r, segments: seg), y: yb + c.lip + c.rise + 0.012)
                m.add(Prim.loft([tr, tr2], material: paint))
                m.add(Prim.loft([tr2, tr], material: paint))
            }
            // Center cap: square plate with a raised dome.
            let cap = Prim.ring(Shape2D.roundedRect(0.1, 0.1, radius: 0.012, segments: seg), y: yb + 0.096)
            let capB = Prim.ring(Shape2D.roundedRect(0.136, 0.136, radius: 0.014, segments: seg), y: yb + 0.082)
            m.add(Prim.loft([cap, capB], capStart: true, material: paint))
            m.add(Prim.loft([capB, cap], capEnd: true, material: paint))
            // Supply collar above the cones: four galvanized walls, hollow so the cones stay visible.
            for k in 0..<4 {
                let a = Float(k) * .pi / 2
                let dir = V3(cos(a), 0, -sin(a))
                m.add(cuboid(V3(0.4, 0.094, 0.002), material: "metal.galvanized"), Xform(translation: V3(0, yb + 0.052, 0) + dir * 0.2, rotation: simd_quatf(angle: a + .pi / 2, axis: .up)))
            }
            // Air-ghosting dust streaks on the flange next to the opening.
            if lod == 0 {
                for k in 0..<4 {
                    let a = Float(k) * .pi / 2
                    let dir = V3(cos(a), 0, -sin(a))
                    m.add(cuboid(V3(0.34, 0.0004, 0.02), material: "decal.soap-residue"), Xform(translation: V3(0, yb - 0.0003, 0) + dir * (S / 2 - 0.021), rotation: simd_quatf(angle: a + .pi / 2, axis: .up)))
                }
            }
            m.add(cuboid(V3(0.4, 0.002, 0.4), material: "metal.galvanized"), Xform(translation: V3(0, yb + 0.099, 0)))
            if lod == 0 {
                // Rating label on the flange and a damper adjustment screw at the cap.
                m.add(cuboid(V3(0.05, 0.0006, 0.014), material: "metal.aluminum-brushed"), Xform(translation: V3(0.2, yb - 0.0003, S / 2 - 0.021)))
                m.add(cuboid(V3(0.012, 0.0006, 0.012), material: "metal.chrome"), Xform(translation: V3(0, yb + 0.0815, 0)))
            }
            if lod == 0 {
                for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
                    rivet(&m, at: V3(sx * (S / 2 - 0.02), yb, sz * (S / 2 - 0.02)), normal: V3(0, -1, 0), radius: 0.0045, height: 0.0008, segments: 8, material: "metal.chrome")
                } }
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [5])
    }
}
