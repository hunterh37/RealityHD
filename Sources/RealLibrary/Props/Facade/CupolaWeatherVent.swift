import simd
import Foundation

/// Cupola with weather vane: architectural facade customizer, Colonial Revival. Moulded plinth, square louvered
/// body with corner pilasters, bed-mould and crown cornice, ogee copper roof with hip rolls and standing seams,
/// gilded ball finial and an arrow vane on cardinal arms. Copper runoff stains the cornice.
public struct CupolaWeatherVent: RealAsset {
    public static let id = "cupola-weather-vent"
    public static let summary = "Colonial Revival roof cupola, 0.8 m: louvered sides, cornice, copper roof and vane."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 2.4)

    /// Painted wood.
    public var paint: MaterialKey = "wood.painted-exterior:EDEAE0"
    /// Roof metal.
    public var roof: MaterialKey = "metal.copper-patina"
    /// Vane rotation in degrees.
    public var vaneAngle: Float = 28
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let aged: MaterialKey = "wood.trim-weathered", copper: MaterialKey = "metal.copper", iron: MaterialKey = "metal.iron"
        let hb: Float = 0.26   // body half width
        // Plinth: base fillet, ogee skirt, cap with a drip, stepping in to the body.
        FSV.squareMoulding(&m, half: 0.4, steps: [V2(-0.4 + 0.4, 0), V2(0, 0.055), V2(-0.006, 0.062), V2(-0.014, 0.074), V2(-0.02, 0.09), V2(-0.12, 0.1)].map { V2($0.x, $0.y) }, y0: 0, paint)
        // Flashing apron at the plinth foot, soldered copper, with a stain tint at the corner.
        FSV.squareMoulding(&m, half: 0.4, steps: [V2(0.0, 0.0), V2(0.0, 0.004), V2(-0.004, 0.008)], y0: 0, copper)
        // Body: stud wall block, painted, slightly weathered at the bottom.
        m.add(Prim.loft([FSV.sq(hb, 0.098), FSV.sq(hb, 0.5)], capStart: false, capEnd: false, material: paint))
        // Corner pilasters with base and capital blocks.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            FA.box(&m, V3(0.07, 0.4, 0.07), V3(sx * (hb - 0.0), 0.3, sz * hb), paint, r: 0.004)
            FA.box(&m, V3(0.082, 0.026, 0.082), V3(sx * hb, 0.113, sz * hb), paint, r: 0.004)
            FA.box(&m, V3(0.082, 0.03, 0.082), V3(sx * hb, 0.485, sz * hb), paint, r: 0.004)
        } }
        // Four louvered openings: frame, slats cut to the opening, screen behind.
        for f in 0..<4 {
            let ry = FA.q(Float(f) * 90, FA.Y)
            func at(_ x: Float, _ y: Float, _ z: Float) -> V3 { ry.act(V3(x, y, z)) }
            let ow: Float = 0.3, oh: Float = 0.29, cy: Float = 0.3
            FA.box(&m, V3(ow, oh, 0.004), at(0, cy, hb - 0.012), "metal.rust-grime", r: 0.0006, rot: ry)
            FA.box(&m, V3(ow - 0.02, oh - 0.02, 0.002), at(0, cy, hb - 0.006), "glass.wire-mesh", r: 0.0004, rot: ry)
            // Architrave: rails and stiles with a back bead.
            let fw: Float = 0.036
            FA.box(&m, V3(ow + 2 * fw, fw, 0.03), at(0, cy + oh / 2 + fw / 2, hb + 0.006), paint, r: 0.004, rot: ry)
            FA.box(&m, V3(ow + 2 * fw, fw, 0.03), at(0, cy - oh / 2 - fw / 2, hb + 0.006), paint, r: 0.004, rot: ry)
            for s: Float in [-1, 1] { FA.box(&m, V3(fw, oh, 0.03), at(s * (ow / 2 + fw / 2), cy, hb + 0.006), paint, r: 0.004, rot: ry) }
            FA.box(&m, V3(ow + 0.01, 0.01, 0.012), at(0, cy - oh / 2 - fw - 0.002, hb + 0.012), paint, r: 0.003, rot: ry)
            // Slats: 9 at 33 mm, tilted 40 degrees, with a lost-paint slat on the lowest side.
            for k in 0..<9 {
                let y = cy - oh / 2 + 0.02 + Float(k) * 0.0315
                FA.box(&m, V3(ow + 0.006, 0.007, 0.046), at(0, y, hb + 0.002), (k == 1 && f == 0) ? aged : paint, r: 0.0018, rot: ry * FA.q(-40, FA.X))
            }
            // Pins through the architrave stiles.
            for s: Float in [-1, 1] {
                FSV.screw(&m, at: at(s * (ow / 2 + fw / 2), cy + oh / 2 - 0.02, hb + 0.0213), normal: ry.act(FA.Z), r: 0.0034, "metal.galvanized")
            }
        }
        // Cornice: frieze band, bed mould, corona with drip, cyma crown.
        FSV.squareMoulding(&m, half: hb, steps: [V2(0.004, 0), V2(0.004, 0.026), V2(0.026, 0.034), V2(0.044, 0.05), V2(0.044, 0.062), V2(0.05, 0.066), V2(0.05, 0.086), V2(0.04, 0.094), V2(0.03, 0.108), V2(0.0, 0.12)].map { V2($0.x, $0.y) }, y0: 0.5, paint)
        // Roof: ogee pyramid, rings from the eave to the neck.
        let eave = hb + 0.05, yr: Float = 0.62
        func half(_ t: Float) -> Float {
            let u = 1 - (1 - t) * (1 - t)   // flat kick at the eave, steeper crown
            return 0.03 + (eave - 0.005 - 0.03) * (1 - (0.45 * t + 0.55 * u))
        }
        let yo: [Float] = (0...12).map { yr + 0.002 + Float($0) / 12 * 0.2 }
        let ts: [Float] = (0...12).map { Float($0) / 12 }
        let roofRings = zip(yo, ts).map { y, t in FSV.sq(half(t), y) }
        m.add(Prim.loft(roofRings, capStart: true, capEnd: true, material: roof))
        // Eave drip edge and hip rolls.
        FSV.squareMoulding(&m, half: eave - 0.005, steps: [V2(0.003, 0), V2(0.008, 0.004), V2(0.003, 0.012)], y0: yr - 0.004, copper)
        for k in 0..<4 {
            let ry = FA.q(Float(k) * 90 + 45, FA.Y)
            let pts = zip(yo, ts).map { y, t in ry.act(V3(0, y + 0.003, half(t) * 1.4142 + 0.0)) }
            FA.path(&m, pts, r: 0.0075, copper, sides: 8)
        }
        // Standing seams, two per face.
        for f in 0..<4 {
            let ry = FA.q(Float(f) * 90, FA.Y)
            for s: Float in [-0.5, 0.5] {
                let pts = zip(yo, ts).map { y, t in ry.act(V3(s * half(t), y + 0.003, half(t) + 0.0)) }
                FA.path(&m, pts, r: 0.0035, roof, sides: 6)
            }
        }
        // Neck collar, ball, spire, cardinal arms and vane.
        let yn = yr + 0.22
        m.add(Prim.lathe([V2(0, yn - 0.01), V2(0.032, yn - 0.01), V2(0.026, yn + 0.004), V2(0.014, yn + 0.012), V2(0.014, yn + 0.04), V2(0.02, yn + 0.044), V2(0, yn + 0.046)], segments: 18, seamTile: 0.1, material: copper))
        FA.ball(&m, r: 0.033, at: V3(0, yn + 0.074, 0), "metal.gold-leaf")
        FA.rod(&m, V3(0, yn + 0.1, 0), V3(0, 0.99, 0), r: 0.005, iron, sides: 8)
        let yv: Float = 0.935
        for s in 0..<4 {
            let a = FA.q(Float(s) * 90, FA.Y)
            FA.rod(&m, a.act(V3(0.012, yv - 0.02, 0)), a.act(V3(0.11, yv - 0.02, 0)), r: 0.0035, iron, sides: 6)
            FC.bead(&m, r: 0.007, at: a.act(V3(0.115, yv - 0.02, 0)), iron)
        }
        let vq = FA.q(vaneAngle, FA.Y)
        // Arrow: shaft with barbed head to the right, forked tail to the left.
        let arrow: [V2] = [V2(0.16, 0), V2(0.105, 0.03), V2(0.105, 0.007), V2(-0.12, 0.007), V2(-0.17, 0.04), V2(-0.17, 0.012), V2(-0.145, 0),
                           V2(-0.17, -0.012), V2(-0.17, -0.04), V2(-0.12, -0.007), V2(0.105, -0.007), V2(0.105, -0.03)]
        m.add(Prim.extrude(arrow, depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: iron),
              Xform(translation: V3(0, yv, 0), rotation: vq).jittered(&rng))
        // Copper runoff stains below the eave drip on two faces.
        for s: Float in [-0.12, 0.05, 0.16] {
            FSV.streak(&m, at: V3(s, 0.585, hb + 0.054), w: 0.012, h: 0.07, roof)
        }
        return LODModel(FC.place(m))
    }
}
