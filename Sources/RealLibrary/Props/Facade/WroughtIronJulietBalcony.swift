import simd
import Foundation

/// Spanish Colonial wrought iron Juliet balcony, 1.4 m wide and 0.35 m proud of the wall: a belly-bowed
/// reja with round top and bottom rails, a mid rail, twisted-bar balusters spaced along the curve, C-scroll
/// infill, spear finials and four wall anchor plates with bolts. Black paint with rust at the lower rail
/// and anchors. Wall plane at z = 0.
public struct WroughtIronJulietBalcony: RealAsset {
    public static let id = "wrought-iron-juliet-balcony"
    public static let summary = "Spanish Colonial Juliet balcony, 1.4 m wide: bowed wrought iron rail with twisted balusters, scroll infill and wall anchors."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 1.1)

    /// Painted wrought iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Rusted iron for wear.
    public var rust: MaterialKey = "metal.rust"
    /// Baluster spacing along the curve in meters.
    public var pitch: Float = 0.105
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw: Float = 0.7, belly: Float = 0.33, z0: Float = 0.02, n: Float = 3
        let yTop: Float = 0.97, yMid: Float = 0.52, yBot: Float = 0.07
        // Plan curve of the bowed front (x, z) as a superellipse half, wall to wall.
        let plan: [V2] = (0...24).map { i in
            let th = Float(i) / 24 * .pi
            let c = cos(th), s = sin(th)
            return V2(hw * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n),
                      z0 + belly * pow(abs(s), 2 / n))
        }.map { V2(-$0.x, $0.y) }
        func path(_ y: Float) -> [V3] { plan.map { V3($0.x, y, $0.y) } }
        // Arc-length samples for balusters and scrolls.
        var cum: [Float] = [0]
        for i in 1..<plan.count { cum.append(cum[i - 1] + simd_distance(plan[i], plan[i - 1])) }
        let total = cum.last!
        func at(_ s: Float) -> V2 {
            var i = 1
            while i < cum.count - 1 && cum[i] < s { i += 1 }
            let t = (s - cum[i - 1]) / max(cum[i] - cum[i - 1], 1e-5)
            return plan[i - 1] + (plan[i] - plan[i - 1]) * t
        }
        // Rails: top, mid, bottom with flat-bar edge below the top round.
        FA.path(&m, path(yTop), r: 0.0155, iron, sides: 10)
        FA.path(&m, path(yTop - 0.03), r: 0.007, iron, sides: 6)
        FA.path(&m, path(yMid), r: 0.0085, iron, sides: 6)
        FA.path(&m, path(yBot), r: 0.012, iron, sides: 8)
        FA.path(&m, path(yBot + 0.035), r: 0.006, iron, sides: 6)
        // Balusters: round core with a twisted-bar middle, collars at both rails.
        let count = Int(total / pitch)
        let step = total / Float(count)
        for k in 1..<count {
            let p = at(Float(k) * step)
            FA.rod(&m, V3(p.x, yBot, p.y), V3(p.x, yTop, p.y), r: 0.0062, iron, sides: 8)
            if k % 2 == 0 { m.add(Prim.helix(radius: 0.0065, pitch: 0.05, turns: 3, wire: 0.0043, perTurn: 9, sides: 5, material: iron), Xform(translation: V3(p.x, yMid + 0.07, p.y))) }
            for y in [yBot + 0.02] {
                m.add(Prim.torus(major: 0.0075, minor: 0.0028, segments: 8, sides: 4, material: k % 3 == 0 ? rust : iron), Xform(translation: V3(p.x, y, p.y), rotation: .identity))
            }
        }
        // C-scroll infill between the bottom and mid rails, alternating hand.
        for k in 0..<count {
            guard k % 2 == 0 else { continue }
            let mid = at((Float(k) + 0.5) * step)
            let dir: Float = (k / 2) % 2 == 0 ? 1 : -1
            let pts = (0...14).map { i -> V3 in
                let a = Float(i) / 14 * 9.4
                let r = 0.036 - 0.0033 * a
                return V3(mid.x + dir * r * cos(a * dir), yBot + 0.2 + r * sin(a * dir), mid.y)
            }
            FA.path(&m, pts, r: 0.0042, iron, sides: 6)
            FC.bead(&m, r: 0.0065, at: V3(mid.x, yBot + 0.2, mid.y), iron, sub: 3)
        }
        // Spear finials: end posts and mid points on the top rail.
        for k in [0, count / 3, 2 * count / 3, count] {
            let p = at(Float(k) * step)
            m.add(Prim.lathe([V2(0.0, 0.0), V2(0.011, 0.0), V2(0.0075, 0.012), V2(0.012, 0.03), V2(0.0, 0.062)], segments: 10, material: iron),
                  Xform(translation: V3(p.x, yTop + 0.012, p.y)))
        }
        // End posts running to the floor, and wall anchor plates with bolts.
        for e: Float in [-1, 1] {
            let p = V3(e * hw, 0, z0)
            FA.rod(&m, p, V3(p.x, yTop, p.z), r: 0.0135, iron, sides: 10)
            for y in [0.22, 0.78] as [Float] {
                FA.box(&m, V3(0.07, 0.13, 0.012), V3(e * hw, y, 0.006), iron, r: 0.002)
                hexBolt(&m, at: V3(e * hw - 0.02, y + 0.04, 0.0125), normal: FA.Z, size: 0.013, material: rust)
                hexBolt(&m, at: V3(e * hw + 0.02, y - 0.04, 0.0125), normal: FA.Z, size: 0.013, material: "metal.iron")
                FA.box(&m, V3(0.03, 0.014, 0.016), V3(e * hw, y, 0.02), iron, r: 0.002)
            }
            FA.box(&m, V3(0.05, 0.012, 0.05), V3(e * hw, 0.006, z0), iron, r: 0.002)
        }
        // Rivets at scroll to rail joins and rust blooms on the lower rail and a drip run on the plate.
        for _ in 0..<12 {
            let p = at(rng.float(0.05...(total - 0.05)))
            m.add(Prim.superellipsoid(V3(rng.float(0.04...0.09), 0.026, 0.03), exponent: 2, subdivisions: 3, material: rust),
                  Xform(translation: V3(p.x, yBot - 0.002, p.y)))
        }
        for _ in 0..<4 {
            let p = at(rng.float(0.1...(total - 0.1)))
            m.add(Prim.superellipsoid(V3(rng.float(0.05...0.09), 0.026, 0.03), exponent: 2, subdivisions: 3, material: rust),
                  Xform(translation: V3(p.x, yTop - 0.002, p.y)))
        }
        for e: Float in [-1, 1] { FA.box(&m, V3(0.012, 0.09, 0.0012), V3(e * hw + 0.015, 0.14, 0.0126), rust, r: 0.0003) }
        groundAO(&m, height: 0.08, floor: 0.8)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
