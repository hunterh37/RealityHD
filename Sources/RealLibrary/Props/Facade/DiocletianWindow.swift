import simd
import Foundation

/// Neoclassical Diocletian (thermal) window, 1.8 x 1.3 m: semicircular opening on straight jambs split by two mullions
/// into three lights, moulded limestone architrave (fillet, ovolo, cove) with voussoir joints, sandstone impost blocks,
/// keystone and a weathered projecting sill with drip. Wall plane at z = 0, piece projecting toward +Z.
public struct DiocletianWindow: RealAsset {
    public static let id = "diocletian-window"
    public static let summary = "Neoclassical Diocletian (thermal) window, 1.8 m: semicircular opening with two mullions into three lights, moulded stone architrave, impost blocks, keystone, sill."
    public static let tags = ["prop", "architecture", "facade", "window", "stone", "glass"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 3.0)

    /// Clear opening width in meters (the architrave adds 0.2 m each side).
    public var opening: Float = 1.4
    /// Height of the springing line above the base in meters.
    public var spring: Float = 0.4
    /// Architrave and arch stone.
    public var stone: MaterialKey = "stone.limestone:D8D0BC"
    /// Contrasting stone for imposts, keystone and sill.
    public var accent: MaterialKey = "stone.sandstone"
    /// Mortar joints and soot.
    public var joint: MaterialKey = "stone.limestone:5E5849"
    /// Painted timber mullions and glazing bars.
    public var timber: MaterialKey = "wood.painted-exterior"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = opening / 2, sillH: Float = 0.07
        let cy = spring        // arch centre (springing line)
        let crown = cy + hw

        // Architrave profile (x = projection from the wall, y = distance out from the opening edge):
        // inner fillet, ovolo, flat fascia, cove, outer fillet.
        var prof: [V2] = [V2(0, 0), V2(0.09, 0), V2(0.09, 0.04)]
        for i in 1...6 {
            let a = Float(i) / 6 * (.pi / 2)
            prof.append(V2(0.09 + 0.035 * sin(a), 0.04 + 0.035 * (1 - cos(a))))
        }
        prof.append(V2(0.125, 0.105))
        for i in 1...6 {
            let a = Float(i) / 6 * (.pi / 2)
            prof.append(V2(0.07 + 0.055 * cos(a), 0.105 + 0.055 * sin(a)))
        }
        prof += [V2(0.07, 0.2), V2(0, 0.2)]
        prof = Shape2D.deduped(prof)
        let path = FC.archPath(width: opening, spring: spring - sillH, pointed: false, z: 0, steps: 24)
            .map { V3($0.x, $0.y + sillH, 0) }
        m.add(Prim.sweep(prof, along: path, up: V3(0, 0, 1), material: stone))

        // Voussoir and coursing joints: dark mortar lines across the fascia and outer fillet.
        let nJ = 12
        for i in 1..<nJ {
            let a = Float(i) / Float(nJ) * .pi
            let dir = V3(cos(a), sin(a), 0)
            for (z, r0, r1) in [(Float(0.1255), Float(0.075), Float(0.105)), (0.0705, 0.16, 0.2)] {
                let rc = hw + (r0 + r1) / 2
                let c = V3(dir.x * rc, cy + dir.y * rc, z)
                FA.box(&m, V3(r1 - r0, 0.009, 0.003), c, joint, r: 0.0005, rot: FA.q(a * 180 / .pi, FA.Z))
            }
        }
        for s: Float in [-1, 1] {
            for k in 0..<2 {
                let y = sillH + 0.1 + Float(k) * 0.14
                for (z, r0, r1) in [(Float(0.1255), Float(0.075), Float(0.105)), (0.0705, 0.16, 0.2)] {
                    FA.box(&m, V3(r1 - r0, 0.004, 0.002), V3(s * (hw + (r0 + r1) / 2), y, z), joint, r: 0.0005)
                }
            }
        }

        // Impost blocks at the springing line: moulded cap over a block, brass bolt heads on the face.
        for s: Float in [-1, 1] {
            let x = s * (hw + 0.1)
            FA.box(&m, V3(0.2, 0.075, 0.15), V3(x, cy - 0.0375, 0.075), accent, r: 0.005)
            let cap: [V2] = [V2(0, 0), V2(0.16, 0), V2(0.16, 0.012), V2(0.17, 0.022), V2(0.17, 0.034), V2(0, 0.034)]
            FA.run(&m, cap, length: 0.2, at: V3(x, cy, 0), accent, bevel: 0.002)
            for (dx, dy) in [(Float(-0.06), Float(-0.02)), (0.06, -0.02), (-0.06, -0.055), (0.06, -0.055)] {
                let p = V3(x + dx, cy + dy, 0.151)
                m.add(Prim.torus(major: 0.0085, minor: 0.0022, segments: 10, sides: 4, material: "metal.brass-aged"),
                      Xform(translation: p, rotation: FA.q(90, FA.X)))
                FC.bead(&m, r: 0.0055, at: p + V3(0, 0, 0.002), "metal.brass-aged", sub: 3)
            }
        }

        // Keystone: wedge breaking the architrave, with a carved boss.
        let ky = crown + 0.105
        let key = [V2(-0.055, crown - 0.03), V2(0.055, crown - 0.03), V2(0.075, crown + 0.2), V2(-0.075, crown + 0.2)]
        m.add(Prim.extrude(key, depth: 0.2, bevel: 0.004, bevelSegments: 1, material: accent), Xform(translation: V3(0, 0, 0.1)))
        FA.box(&m, V3(0.17, 0.02, 0.19), V3(0, crown + 0.19, 0.1), accent, r: 0.003)
        m.add(Prim.superellipsoid(V3(0.065, 0.1, 0.03), exponent: 2.4, subdivisions: 5, material: accent),
              Xform(translation: V3(0, ky - 0.01, 0.19)))
        // Soot and lime runs on the fascia.
        for _ in 0..<9 {
            let a = rng.float(0.15...2.99)
            let rc = hw + 0.09
            FA.box(&m, V3(0.03, rng.float(0.02...0.05), 0.002), V3(cos(a) * rc, cy + sin(a) * rc, 0.1255), "stone.limestone:8E8674", r: 0.0006,
                   rot: FA.q(a * 180 / .pi - 90, FA.Z))
        }

        // Glazing: one glass sheet behind the bars, two mullions into three lights, transom, radial and ring bars.
        let outline = FC.archOutline(width: opening - 0.02, spring: spring - sillH, pointed: false, steps: 24)
        m.add(Prim.extrude(outline, depth: 0.008, bevel: 0.0005, bevelSegments: 1, material: "glass.tinted"),
              Xform(translation: V3(0, sillH, 0.04)))
        for s: Float in [-1, 1] {
            let x = s * opening / 6
            let top = cy + sqrt(hw * hw - x * x)
            FA.box(&m, V3(0.05, top - sillH, 0.06), V3(x, (top + sillH) / 2, 0.045), timber, r: 0.008)
            FA.box(&m, V3(0.028, top - sillH, 0.012), V3(x, (top + sillH) / 2, 0.081), timber, r: 0.004)
        }
        FA.box(&m, V3(opening, 0.035, 0.05), V3(0, cy, 0.045), timber, r: 0.006)
        for a in [Float(60), 120] {
            let r = a * .pi / 180
            FA.rod(&m, V3(0, cy, 0.045), V3(cos(r) * (hw - 0.005), cy + sin(r) * (hw - 0.005), 0.045), r: 0.012, timber, sides: 8)
        }
        let ring = FC.archPath(width: 0.72, spring: 0.0, pointed: false, z: 0.045, steps: 20).dropFirst().dropLast()
            .map { V3($0.x, $0.y + cy, $0.z) }
        FA.path(&m, Array(ring), r: 0.011, timber, sides: 8)
        // Perimeter frame inside the reveal.
        let frame = FC.archPath(width: opening - 0.02, spring: spring - sillH, pointed: false, z: 0.045, steps: 24)
            .map { V3($0.x * 0.995, $0.y + sillH, 0.045) }
        FA.path(&m, frame, r: 0.016, timber, sides: 8)

        // Sill: weathered slab with drip groove, sloped top, soot staining under it.
        let sill: [V2] = [V2(0, 0), V2(0.165, 0), V2(0.165, 0.014), V2(0.2, 0.014), V2(0.2, 0.04), V2(0.13, sillH), V2(0, sillH)]
        FA.run(&m, sill, length: 1.8, at: V3(0, 0, 0), accent, bevel: 0.002)
        FA.box(&m, V3(opening - 0.1, 0.004, 0.2), V3(0, sillH - 0.0015, 0.1), joint, r: 0.001)

        groundAO(&m, height: 0.1, floor: 0.88)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
