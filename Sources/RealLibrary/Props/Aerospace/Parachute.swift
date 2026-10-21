import simd
import Foundation

/// Parachute canister for the 0.625 m node, 0.4 m by 0.3 m: spun aluminum pot with a bolted base
/// flange, orange nylon pack under a cross of webbing straps and a steel riser fitting. States packed,
/// drogue (4 m conical canopy on 6 m lines) and main (16 m ringsail-style canopy on 20 m lines), with
/// alternating orange and white gores and suspension lines to the riser.
public struct Parachute: RealArticulated {
    public static let id = "parachute"
    public static let summary = "Parachute canister, 0.4 m: aluminum pot with an orange nylon pack and straps; states packed, drogue and main show the canopy deployed."
    public static let tags = ["prop", "aerospace", "fabric", "articulated"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 20, distance: 1.0, studio: true)

    /// Canister diameter in meters.
    public var diameter: Float = 0.4
    /// Packed height in meters.
    public var height: Float = 0.3
    /// Canopy diameters (drogue, main) in meters.
    public var drogueDiameter: Float = 4
    public var mainDiameter: Float = 16
    /// Gore colors.
    public var goreA: MaterialKey = "fabric.nylon:E8622C"
    public var goreB: MaterialKey = "fabric.nylon:F2F2F0"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let R = diameter / 2, potH = height * 0.62
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 40 : 20
            // Base flange and pot.
            m.add(Prim.lathe([V2(0, 0.0), V2(R - 0.004, 0.0), V2(R, 0.004), V2(R, 0.012), V2(R - 0.004, 0.016), V2(R - 0.014, 0.016),
                              V2(R - 0.016, 0.02), V2(R - 0.016, potH - 0.006), V2(R - 0.012, potH - 0.004), V2(R - 0.012, potH),
                              V2(R - 0.02, potH), V2(R - 0.024, potH - 0.004)], segments: sg, seamTile: 0.3, material: "metal.anodized-worn"))
            // Pack inside the pot rim (visible ring of nylon in every state).
            m.add(Prim.lathe([V2(R - 0.024, potH - 0.004), V2(R - 0.03, potH - 0.01), V2(0, potH - 0.01)], segments: sg, material: goreA))
            if l == 0 {
                boltCircle(&m, radius: R - 0.007, y: 0.016, count: 8, up: true, size: 0.005, material: "metal.steel")
                // Placard on the pot.
                m.add(revPatch(radius: { _ in R - 0.016 }, a0: -0.3, a1: 0.3, y0: 0.06, y1: 0.12, lift: 0.0012, thickness: 0.001,
                               nu: 4, nv: 1, material: "metal.painted:E8C21C"))
            }
            rig.base[l] = m
        }
        // Pack cover: domed nylon pack with webbing cross, present only when packed (option 0).
        rig.part("pack", pivot: V3(0, potH, 0), joint: .fixed, options: 2)
        for l in 0..<2 {
            var dome = Prim.superellipsoid(V3(2 * (R - 0.009), 2 * (height - potH - 0.006), 2 * (R - 0.009)), exponent: 2.2,
                                           subdivisions: l == 0 ? 10 : 6, material: goreA)
            dome.deform { p in V3(p.x, max(p.y, -0.012) + potH - 0.004, p.z) }
            rig.add(dome, to: "pack", option: 0, lods: l...l)
            for k in 0..<2 {
                let a = Float(k) * .pi / 2
                let d = V3(sin(a), 0, cos(a))
                let pts = (0...16).map { i -> V3 in
                    let t = (Float(i) / 16 * 2 - 1) * 0.94
                    let a = R - 0.009, b = height - potH - 0.006
                    let x = t * (a - 0.004)
                    let hh = b * pow(max(0, 1 - pow(abs(x / a), 2.2)), 1 / 2.2)
                    return d * x * 1.02 + V3(0, potH - 0.004 + hh + 0.006, 0)
                }
                rig.add(Prim.sweep(Shape2D.roundedRect(0.004, 0.035, radius: 0.0015, segments: 1), along: pts, up: .up,
                                   material: "fabric.webbing"), to: "pack", option: 0, lods: l...l)
            }
        }
        rig.add(Prim.lathe([V2(0.02, 0), V2(0.02, 0.012), V2(0.012, 0.018), V2(0.012, 0.03), V2(0, 0.032)], segments: 12, material: "metal.steel"),
                Xform(translation: V3(0, height - 0.03, 0)), to: "pack", option: 0)
        // Canopy: option 1 drogue, option 2 main, on a fixed part at the riser.
        rig.part("canopy", pivot: V3(0, potH, 0), joint: .fixed, options: 3)
        for (opt, D, lineL, gores, vent) in [(1, drogueDiameter, Float(6), 12, Float(0.12)), (2, mainDiameter, Float(20), 24, Float(0.06))] {
            let Rc = D / 2, hDome = Rc * 0.62, yTop = potH + lineL + hDome
            let skirtY = potH + lineL
            let r: (Float) -> Float = { y in
                let t = min(max((y - skirtY) / hDome, 0), 1)
                return Rc * sqrt(max(0, 1 - t * t)) * (0.94 + 0.06 * (1 - t))
            }
            for g in 0..<gores {
                let a0 = Float(g) / Float(gores) * 2 * .pi, a1 = a0 + 2 * .pi / Float(gores)
                var gore = revPatch(radius: r, a0: a0, a1: a1, y0: skirtY, y1: skirtY + hDome * sqrt(1 - vent * vent), lift: 0,
                                    thickness: Rc * 0.004, nu: 3, nv: 8, material: g % 2 == 0 ? goreA : goreB)
                // Billow between radials: bulge each gore outward at mid-angle.
                let mid = (a0 + a1) / 2
                gore.deform { p in
                    let a = atan2(p.x, p.z), da = remainder(a - mid, 2 * .pi) / (a1 - a0) * 2
                    let s = 1 + 0.035 * max(0, 1 - da * da)
                    return V3(p.x * s, p.y, p.z * s)
                }
                gore.recomputeNormals(weldSeams: false)
                rig.add(gore, to: "canopy", option: opt)
            }
            // Suspension lines from each radial seam to the riser, plus the riser itself.
            let riser = V3(0, potH + 0.4 + lineL * 0.05, 0)
            for g in 0..<gores {
                let a = Float(g) / Float(gores) * 2 * .pi
                let p = V3(sin(a), 0, cos(a)) * r(skirtY) + V3(0, skirtY, 0)
                rig.add(Prim.tube([riser, p], radii: [0.004, 0.004], sides: 3, seamTile: 0.2, material: "fabric.webbing:F2F2F0", capEnd: false),
                        to: "canopy", option: opt)
            }
            rig.add(Prim.tube([V3(0, potH, 0), riser], radii: [0.012, 0.012], sides: 6, seamTile: 0.2, material: "fabric.webbing", capEnd: true),
                    to: "canopy", option: opt)
            _ = yTop
        }
        _ = rng.float()
        rig.states = [RigState("packed"), RigState("drogue", options: ["pack": 1, "canopy": 1]),
                      RigState("main", options: ["pack": 1, "canopy": 2])]
        groundAO(&rig, height: 0.06)
        return rig
    }
}
