import simd
import Foundation

/// Stone wheel guard: architectural facade customizer, Victorian. Tapered rock-faced granite post with a
/// moulded base, bullnose cap, a wheel scuff band and an iron strap.
public struct RailWheelGuardStone: RealAsset {
    public static let id = "rail-wheel-guard-stone"
    public static let summary = "Stone wheel guard 0.5 m: tapered rock-faced granite post with a bullnose cap, moulded base, wheel scuff band and iron strap."
    public static let tags = ["prop", "architecture", "facade", "stone", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.8)

    /// Granite.
    public var granite: MaterialKey = "stone.granite-curb"
    /// Iron strap.
    public var iron: MaterialKey = "metal.cast-iron-street"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Tapered body: smooth plinth at the foot, rock-faced shaft, smooth neck and bullnose cap.
        let body: [V2] = [V2(0, 0), V2(0.172, 0), V2(0.172, 0.03), V2(0.166, 0.04), V2(0.17, 0.05), V2(0.165, 0.065), V2(0.158, 0.1), V2(0.146, 0.2), V2(0.132, 0.3),
                          V2(0.12, 0.37), V2(0.116, 0.4), V2(0.126, 0.41), V2(0.13, 0.425), V2(0.12, 0.44), V2(0.1, 0.465), V2(0.07, 0.487), V2(0.03, 0.498), V2(0, 0.5)]
        FE.turnDisp(&m, body.map { V2($0.x * 1.02, $0.y) }, granite, segments: 72, seamTile: 0.4) { p in
            if p.y < 0.07 || p.y > 0.38 { return 0 }
            let w = min(1, (p.y - 0.07) / 0.04, (0.38 - p.y) / 0.04)
            let a = atan2(p.z, p.x)
            let big = FE.noise(V3(a * 5, p.y * 18, 0.5), seed: 9), fine = FE.noise(V3(a * 14, p.y * 45, 2.5), seed: 5)
            return 0.011 * w * (0.7 * big + 0.3 * fine)
        }
        // Wheel graze band: stone rubbed pale and smooth where hubs have scraped it, with ragged edges.
        let band: [V2] = [V2(0.1455, 0.2), V2(0.1445, 0.215), V2(0.1425, 0.25), V2(0.1405, 0.285), V2(0.1385, 0.3)].map { V2($0.x * 1.02, $0.y) }
        FE.turnDisp(&m, [V2(0, 0.2)] + band + [V2(0, 0.3)], granite, segments: 72, seamTile: 0.4) { p in
            let a = atan2(p.z, p.x)
            return 0.0045 + 0.0025 * FE.noise(V3(a * 4, p.y * 30, 7), seed: 3)
        }
        // Iron strap: a band around the neck with a bolted lug.
        let strap: [V2] = [V2(0.118, 0.343), V2(0.124, 0.346), V2(0.124, 0.378), V2(0.118, 0.381)]
        m.add(Prim.lathe(strap, segments: 72, seamTile: 0.3, material: iron), Xform())
        FA.box(&m, V3(0.03, 0.04, 0.012), V3(0.13, 0.362, 0), iron, r: 0.003)
        m.add(Prim.cylinder(radius: 0.007, height: 0.006, bevel: 0.0015, segments: 8, bevelSegments: 1, material: "metal.rust"),
              Xform(translation: V3(0.1405, 0.362, 0), rotation: FA.q(-90, FA.Z)))
        // Chips on the cap and the plinth, pale fresh granite.
        FA.box(&m, V3(0.034, 0.026, 0.03), V3(0.098, 0.448, 0.07), "stone.granite-paver", r: 0.004, rot: FA.q(30, FA.Y))
        FA.box(&m, V3(0.04, 0.03, 0.03), V3(-0.14, 0.018, -0.08), "stone.granite-paver", r: 0.004, rot: FA.q(-35, FA.Y))
        m = FE.seat(m)
        groundAO(&m, height: 0.08, floor: 0.6)
        return LODModel(m)
    }
}
