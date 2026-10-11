import simd
import Foundation

/// Mk1 one-crew capsule (Mercury class, scaled to the 1.25 m bus): charred ablative heat-shield dish
/// on a heat-tinted retention ring, conical titanium shell in overlapping shingle bands, recovery neck
/// with RCS thruster quads, docking tunnel with a bolted ring, side hatch with a window on an outward
/// hinge and two handholds. States hatch-closed, hatch-open.
public struct CommandPod: RealArticulated {
    public static let id = "command-pod"
    public static let summary = "Mk1 crew capsule, 1.25 m: titanium shingled conical shell, ablative shield rim, side hatch on a hinge with window, docking tunnel and RCS ports."
    public static let tags = ["prop", "aerospace", "metal", "vehicle", "articulated"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 1.0, studio: true)

    /// Base (heat shield) diameter in meters.
    public var diameter: Float = 1.25
    /// Shell material (shingles, neck, hatch).
    public var shell: MaterialKey = "metal.titanium"
    /// Heat-shield ablator.
    public var ablator: MaterialKey = "ablative.char-light"
    /// Heat-tinted metal at the shield ring and thruster bells.
    public var tint: MaterialKey = "metal.heat-tint-cold"
    /// Hatch swing at hatch-open (degrees).
    public var hatchOpen: Float = 105
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let R0 = diameter / 2 - 0.025, yC0: Float = 0.11, yC1: Float = 1.02, R1: Float = 0.31
        let slope = (R0 - R1) / (yC1 - yC0)
        let cone: (Float) -> Float = { y in R0 - (min(max(y, yC0), yC1) - yC0) * slope }
        let band: Float = 0.115, lap: Float = 0.010
        // Shingle offset at height y: proud at each band's lower edge, flush at its top.
        let shingle: (Float) -> Float = { y in
            let f = (y - yC0) / band; return lap * (1 - (f - floor(f)))
        }
        let skin: (Float) -> Float = { y in cone(y) + shingle(y) }
        let hatchA: Float = 0.46, hy0: Float = 0.24, hy1: Float = 0.80
        let dark: MaterialKey = "plastic.black"

        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 60 : 28
            // Heat shield dish (shallow spherical face) and its retention ring.
            var dish: [V2] = []
            for k in 0...(l == 0 ? 10 : 5) {
                let r = Float(k) / Float(l == 0 ? 10 : 5) * (R0 + 0.012)
                dish.append(V2(r, 0.004 + 0.062 * pow(r / (R0 + 0.012), 2)))
            }
            dish.append(V2(R0 + 0.022, 0.072)); dish.append(V2(R0 + 0.022, 0.082)); dish.append(V2(R0 - 0.02, 0.084))
            m.add(Prim.lathe(dish, segments: sg, seamTile: 1, material: ablator))
            m.add(Prim.lathe([V2(R0 + 0.026, 0.07), V2(R0 + 0.03, 0.075), V2(R0 + 0.03, 0.098), V2(R0 + 0.022, yC0 + 0.004),
                              V2(R0 - 0.01, yC0 + 0.006)], segments: sg, seamTile: 0.6, material: tint))
            // Shell: overlapping shingle bands up the cone.
            var prof: [V2] = [V2(R0 - 0.01, yC0)]
            var y = yC0
            while y < yC1 - 0.001 {
                let top = min(y + band, yC1)
                prof.append(V2(cone(y) + lap, y + 0.002))
                prof.append(V2(cone(top - 0.003) + 0.0004, top - 0.003))
                y = top
            }
            prof.append(V2(R1 - 0.004, yC1 + 0.004))
            // Recovery neck, shoulder ring, docking tunnel.
            prof += [V2(R1 - 0.012, yC1 + 0.01), V2(R1 - 0.012, 1.17), V2(R1 - 0.004, 1.175), V2(R1 - 0.004, 1.19),
                     V2(0.235, 1.195), V2(0.225, 1.2), V2(0.225, 1.345)]
            // Lowest shingle band carries the reentry heat tint; the rest is bare titanium.
            m.add(Prim.lathe(Array(prof[0...6]), segments: sg, seamTile: 0.6, material: tint))
            m.add(Prim.lathe(Array(prof[6...]), segments: sg, seamTile: 0.6, material: shell))
            m.add(stackRing(radius: 0.225, y: 1.345, height: 0.05, proud: 0.022, segments: sg, material: "metal.aluminum-brushed"))
            m.add(Prim.lathe([V2(0.24, 1.395), V2(0.17, 1.395), V2(0.17, 1.37), V2(0, 1.37)], segments: sg, material: "metal.steel"))
            // Window on the far side, above the hatch line.
            let wa: Float = .pi * 0.72
            m.add(revPatch(radius: cone, a0: wa - 0.2, a1: wa + 0.2, y0: 0.70, y1: 0.92, lift: lap + 0.016, thickness: 0.02,
                           nu: l == 0 ? 6 : 2, nv: 2, material: tint))
            m.add(revPatch(radius: cone, a0: wa - 0.15, a1: wa + 0.15, y0: 0.735, y1: 0.885, lift: lap + 0.019, thickness: 0.006,
                           nu: l == 0 ? 6 : 2, nv: 2, material: "glass.tinted"))
            // Hatch frame recess (dark gap around the door).
            m.add(revPatch(radius: cone, a0: -hatchA - 0.03, a1: hatchA + 0.03, y0: hy0 - 0.02, y1: hy1 + 0.02,
                           lift: lap + 0.003, thickness: 0.006, nu: l == 0 ? 12 : 4, nv: 4, material: dark))
            // RCS thruster quads on the neck.
            for q in 0..<4 {
                let a = Float.pi / 4 + Float(q) * .pi / 2, d = V3(sin(a), 0, cos(a)), t = V3(cos(a), 0, -sin(a))
                let c = d * (R1 - 0.004) + V3(0, 1.095, 0)
                m.add(Prim.roundedBox(V3(0.13, 0.09, 0.03), radius: 0.008, bevelSegments: l == 0 ? 2 : 1, material: shell),
                      Xform(translation: c, rotation: simd_quatf(angle: a, axis: .up)))
                if l == 0 {
                    for (dir, off) in [(d, V3.zero), (t, t * 0.068), (-t, -t * 0.068), (V3.up, V3(0, 0.048, 0))] {
                        let base = c + off + d * 0.012
                        m.add(Prim.lathe([V2(0.004, -0.004), V2(0.011, 0.0), V2(0.016, 0.018), V2(0.0135, 0.018), V2(0.008, 0.004)],
                                         segments: 8, seamTile: 0.05, material: tint), Xform(translation: base, rotation: facing(dir)))
                    }
                }
            }
            if l == 0 {
                // Handholds beside the hatch.
                for (yy, hh) in [(Float(0.36), Float(0.16)), (0.6, 0.16)] {
                    let a = hatchA + 0.15
                    let path = [V3(sin(a), 0, cos(a)) * (skin(yy) - 0.002) + V3(0, yy, 0),
                                V3(sin(a), 0, cos(a)) * (cone(yy) + 0.05) + V3(0, yy + 0.02, 0),
                                V3(sin(a), 0, cos(a)) * (cone(yy + hh) + 0.05) + V3(0, yy + hh - 0.02, 0),
                                V3(sin(a), 0, cos(a)) * (skin(yy + hh) - 0.002) + V3(0, yy + hh, 0)]
                    m.add(Prim.tube(catmull(path, per: 4), radii: Array(repeating: 0.009, count: catmull(path, per: 4).count), sides: 8,
                                    seamTile: 0.1, material: "metal.steel", capEnd: true))
                }
                // Rivet seams on the shingle butt joints (8 meridians, clear of the hatch).
                for k in 0..<8 {
                    let a = Float.pi / 8 + Float(k) * .pi / 4
                    if abs(remainder(a, 2 * .pi)) < hatchA + 0.08 { continue }
                    var yy = yC0 + 0.05
                    while yy < yC1 - 0.03 {
                        let d = V3(sin(a), 0, cos(a))
                        rivet(&m, at: d * (skin(yy) - 0.0008) + V3(0, yy, 0), normal: simd_normalize(d + V3(0, slope, 0)),
                              radius: 0.005, height: 0.0028, segments: 5, material: "metal.steel")
                        yy += band
                    }
                }
                boltCircle(&m, radius: 0.205, y: 1.395, count: 12, up: true, size: 0.007, material: "metal.steel")
            }
            rig.base[l] = m
        }

        // Hatch: curved door on an outward hinge along its -X edge (slant axis of the cone).
        let hingeA = -hatchA - 0.015
        let pv = V3(sin(hingeA), 0, cos(hingeA)) * (cone(hy0) + lap + 0.03) + V3(0, hy0, 0)
        let pv1 = V3(sin(hingeA), 0, cos(hingeA)) * (cone(hy1) + lap + 0.03) + V3(0, hy1, 0)
        rig.part("hatch", pivot: pv, joint: .hinge(axis: simd_normalize(pv - pv1), 0...max(hatchOpen, 1), duration: 1.4))
        for l in 0..<2 {
            let nu = l == 0 ? 12 : 4
            rig.add(revPatch(radius: cone, a0: -hatchA, a1: hatchA, y0: hy0, y1: hy1, lift: lap + 0.018, thickness: 0.018,
                             nu: nu, nv: 4, material: shell), to: "hatch", lods: l...l)
            // Window frame and pane on the hatch.
            rig.add(revPatch(radius: cone, a0: -0.2, a1: 0.2, y0: 0.5, y1: 0.7, lift: lap + 0.03, thickness: 0.014,
                             nu: l == 0 ? 6 : 2, nv: 2, material: tint), to: "hatch", lods: l...l)
            rig.add(revPatch(radius: cone, a0: -0.15, a1: 0.15, y0: 0.53, y1: 0.67, lift: lap + 0.033, thickness: 0.006,
                             nu: l == 0 ? 6 : 2, nv: 2, material: "glass.tinted"), to: "hatch", lods: l...l)
        }
        // Hinge knuckles and the latch handle (LOD0 detail).
        var hd = Model(name: "hatch-detail")
        for yy in [hy0 + 0.06, (hy0 + hy1) / 2, hy1 - 0.06] {
            let p = V3(sin(hingeA), 0, cos(hingeA)) * (cone(yy) + lap + 0.03) + V3(0, yy, 0)
            hd.add(Prim.cylinder(radius: 0.013, height: 0.06, bevel: 0.002, segments: 10, material: "metal.steel"),
                   Xform(translation: p - simd_normalize(pv1 - pv) * 0.03, rotation: facing(pv1 - pv)))
        }
        let la: Float = hatchA - 0.1, ly: Float = 0.42
        let lp = V3(sin(la), 0, cos(la)) * (cone(ly) + lap + 0.018) + V3(0, ly, 0)
        hd.add(barHandle(length: 0.12, standoff: 0.035, radius: 0.008, material: "metal.steel"),
               Xform(translation: lp, rotation: simd_quatf(angle: la, axis: .up) * simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        for s in hd.surfaces { rig.add(s, to: "hatch", lods: 0...0) }
        rig.states = [RigState("hatch-closed"), RigState("hatch-open", ["hatch": hatchOpen])]
        groundAO(&rig, height: 0.15)
        return rig
    }
}
