import simd
import Foundation

/// Uncrewed probe core on the 1.25 m bus, 0.4 m tall: aluminum avionics ring wrapped in gold MLI foil,
/// four bolted access panels (one with status LEDs and a connector), two blade antennas, a star
/// tracker with a sun baffle, steel stack rings top and bottom with bolt circles.
public struct ProbeCore: RealAsset {
    public static let id = "probe-core"
    public static let summary = "Uncrewed probe core, 1.25 m: aluminum avionics ring wrapped in gold MLI foil with access panels, stack rings, blade antennas and status light."
    public static let tags = ["prop", "aerospace", "metal", "electronics"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 18, distance: 1.0, studio: true)

    /// Bus diameter in meters.
    public var diameter: Float = 1.25
    /// Ring height in meters.
    public var height: Float = 0.4
    /// Thermal blanket.
    public var foil: MaterialKey = "insulation.foil-gold"
    /// Panels and decks.
    public var panel: MaterialKey = "metal.aluminum-brushed"
    /// Status light.
    public var led: MaterialKey = "emissive.led-green"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2 - 0.012, H = height, ringH: Float = 0.04
        let body: (Float) -> Float = { _ in R - 0.01 }
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 64 : 28
            m.add(stackRing(radius: R, y: 0, height: ringH, proud: 0.012, segments: sg, material: "metal.steel"))
            m.add(stackRing(radius: R, y: H - ringH, height: ringH, proud: 0.012, segments: sg, material: "metal.steel"))
            // Decks: bottom closeout, top deck with a raised centre hub and cable pass-through.
            m.add(Prim.lathe([V2(R - 0.004, 0.003), V2(0, 0.003)].reversed(), segments: sg, material: panel))
            m.add(Prim.lathe([V2(R - 0.004, H - 0.004), V2(0.2, H - 0.004), V2(0.19, H - 0.0), V2(0.09, H - 0.0),
                              V2(0.085, H - 0.006), V2(0, H - 0.006)], segments: sg, seamTile: 1, material: panel))
            // Structure ring under the blanket, then the crinkled foil wrap with taped seams.
            m.add(Prim.lathe([V2(R - 0.01, ringH), V2(R - 0.01, H - ringH)], segments: sg, seamTile: 1, material: panel))
            var wrap = Prim.lathe((0...8).map { k in V2(R - 0.004, ringH + 0.006 + (H - 2 * ringH - 0.012) * Float(k) / 8) },
                                  segments: l == 0 ? 72 : 32, seamTile: 0.6, material: foil)
            if l == 0 {
                wrap.displace { p, _ in
                    let a = atan2(p.x, p.z)
                    return 0.0025 * sin(a * 37 + p.y * 41) * sin(a * 13 - p.y * 23) + 0.0015 * sin(a * 71 + p.y * 90)
                }
            }
            m.add(wrap)
            // Blanket closeout seams: dark hook-and-loop strips between the panels.
            for q in 0..<4 {
                let a = Float(q) * .pi / 2 + 0.03
                m.add(revPatch(radius: body, a0: a - 0.012, a1: a + 0.012, y0: ringH + 0.006, y1: H - ringH - 0.006, lift: 0.0095,
                               thickness: 0.004, nu: 1, nv: 1, material: "fabric.webbing:2A2A2A"))
            }
            // Top deck interface: raised docking ring with its own bolt circle and three service valves.
            m.add(Prim.lathe([V2(0.36, H - 0.002), V2(0.36, H + 0.006), V2(0.356, H + 0.009), V2(0.309, H + 0.009),
                              V2(0.305, H + 0.006), V2(0.305, H - 0.002)], segments: sg, seamTile: 0.5, material: "metal.machined"))
            for k in 0..<3 {
                let a = Float(k) / 3 * 2 * .pi + 0.4, d = V3(sin(a), 0, cos(a))
                m.add(Prim.lathe([V2(0.022, 0), V2(0.022, 0.006), V2(0.012, 0.008), V2(0.012, 0.009), V2(0.016, 0.01),
                                  V2(0.016, 0.012), V2(0, 0.012)], segments: l == 0 ? 12 : 6, seamTile: 0.1, material: "metal.steel"),
                      Xform(translation: d * 0.47 + V3(0, H - 0.004, 0)))
            }
            // Access panels over the blanket.
            for q in 0..<4 {
                let a = Float(q) * .pi / 2 + .pi / 4, hw: Float = 0.26
                m.add(revPatch(radius: body, a0: a - hw, a1: a + hw, y0: ringH + 0.035, y1: H - ringH - 0.035, lift: 0.016,
                               thickness: 0.006, nu: l == 0 ? 8 : 3, nv: 1, material: panel))
                if l == 0 {
                    for (ca, cy) in [(a - hw + 0.03, ringH + 0.055), (a + hw - 0.03, ringH + 0.055),
                                     (a - hw + 0.03, H - ringH - 0.055), (a + hw - 0.03, H - ringH - 0.055)] {
                        let d = V3(sin(ca), 0, cos(ca))
                        rivet(&m, at: d * (body(cy) + 0.016) + V3(0, cy, 0), normal: d, radius: 0.006, height: 0.003, segments: 6, material: "metal.steel")
                    }
                }
            }
            // Status panel: LED row and a round connector on the front panel.
            let fa: Float = .pi / 4
            let fd = V3(sin(fa), 0, cos(fa)), ft = V3(cos(fa), 0, -sin(fa))
            for k in 0..<4 {
                let p = fd * (body(0) + 0.022) + ft * (Float(k) * 0.03 - 0.045) + V3(0, H - ringH - 0.09, 0)
                m.add(Prim.roundedBox(V3(0.016, 0.01, 0.008), radius: 0.002, bevelSegments: 1, material: k == 3 ? "emissive.led-red" : led),
                      Xform(translation: p, rotation: simd_quatf(angle: fa, axis: .up)))
            }
            m.add(Prim.lathe([V2(0.03, 0), V2(0.03, 0.014), V2(0.024, 0.02), V2(0.024, 0.04), V2(0.02, 0.044), V2(0, 0.044)],
                             segments: l == 0 ? 16 : 8, seamTile: 0.1, material: "metal.anodized-black"),
                  Xform(translation: fd * (body(0) + 0.02) - ft * 0.1 + V3(0, ringH + 0.12, 0), rotation: facing(fd)))
            // Blade antennas on two opposite panels.
            for a in [Float.pi * 0.75, -Float.pi * 0.25] {
                let d = V3(sin(a), 0, cos(a))
                let blade = Shape2D.rounded([V2(0, 0), V2(0.07, 0), V2(0.045, 0.085), V2(0.02, 0.085)], radius: 0.006, segments: 2)
                m.add(Prim.extrude(blade, depth: 0.008, bevel: 0.0015, bevelSegments: 1, material: "plastic.black"),
                      Xform(translation: d * (body(0) + 0.019) + V3(0, H / 2 - 0.04, 0),
                            rotation: simd_quatf(angle: a - .pi / 2, axis: .up)))
            }
            // Star tracker: box plus sun baffle canted 30 degrees up from the side.
            let sa = -Float.pi * 0.75, sd = V3(sin(sa), 0, cos(sa))
            let sp = sd * (body(0) + 0.04) + V3(0, H / 2 - 0.03, 0)
            m.add(Prim.roundedBox(V3(0.1, 0.09, 0.05), radius: 0.008, bevelSegments: l == 0 ? 2 : 1, material: "metal.anodized-black"),
                  Xform(translation: sp, rotation: simd_quatf(angle: sa, axis: .up)))
            let bd = simd_normalize(sd * 0.35 + V3(0, 1, 0))
            m.add(Prim.lathe([V2(0.03, 0), V2(0.03, 0.06), V2(0.042, 0.1), V2(0.039, 0.1), V2(0.027, 0.06), V2(0.027, 0.01), V2(0, 0.01)],
                             segments: l == 0 ? 20 : 10, seamTile: 0.1, material: "metal.anodized-black"),
                  Xform(translation: sp + V3(0, 0.04, 0), rotation: facing(bd)))
            if l == 0 {
                boltCircle(&m, radius: 0.3325, y: H + 0.009, count: 12, up: true, size: 0.006, material: "metal.steel")
                boltCircle(&m, radius: R - 0.03, y: H, count: 18, phase: rng.float(0...0.1), up: true, size: 0.006, material: "metal.steel")
                boltCircle(&m, radius: R + 0.012, y: ringH * 0.5, count: 12, size: 0.005, material: "metal.steel")
                boltCircle(&m, radius: R + 0.012, y: H - ringH * 0.5, count: 12, phase: 0.1, size: 0.005, material: "metal.steel")
            }
            groundAO(&m, height: 0.08)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [8])
    }
}
