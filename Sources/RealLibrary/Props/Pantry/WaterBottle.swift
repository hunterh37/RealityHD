import simd
import Foundation

/// 500 ml PET water bottle, 6.9 cm wide, 21.5 cm tall: clear body with five ribbed grip rings, petaloid-free flat
/// heel, printed label band, threaded neck with support ring, ribbed blue screw cap with tamper band. The water
/// is its own part ("water", entity `joint:water`) so apps can slosh or hide it; states "still" and "slosh".
public struct WaterBottle: RealArticulated {
    public static let id = "water-bottle"
    public static let summary = "Clear 500 ml PET bottle, 21.5 cm: ribbed grip, label band, blue ribbed cap, separate water volume part."
    public static let tags = ["prop", "interior", "pantry", "plastic", "container", "handheld", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.2, studio: true)

    /// Water level above the base (m); 500 ml sits just under the shoulder.
    public var fillY: Float = 0.158
    public var pet: MaterialKey = "plastic.clear"
    public var water: MaterialKey = "glass.water-clear"
    public var cap: MaterialKey = "plastic.gloss:1F5FB8"
    public var label: MaterialKey = "plastic.white:1E6FC4"
    public var labelStripe: MaterialKey = "plastic.white:F4F6F8"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        var m = Model(name: Self.id)
        var outer: [V2] = [V2(0.0262, 0.0004), V2(0.0318, 0.004), V2(0.0340, 0.012), V2(0.0345, 0.024)]
        // Grip rings: smooth sinusoidal waist grooves, sampled finely so the silhouette has no facets.
        for k in 0...25 {
            let t = Float(k) / 25, y = 0.03 + t * 0.072
            outer.append(V2(0.0345 - 0.0016 * pow(sin(t * 5 * .pi), 2), y))
        }
        outer += [V2(0.0345, 0.11), V2(0.0345, 0.128), V2(0.0336, 0.14), V2(0.0300, 0.152), V2(0.0236, 0.164),
                  V2(0.0168, 0.174), V2(0.0124, 0.181), V2(0.0108, 0.186), V2(0.0106, 0.192), V2(0.0106, 0.1985)]
        var shell = Model(name: "shell")
        DD1MPantry.shell(&shell, outer: outer, wall: 0.0005, baseThick: 0.0035, material: pet, seg: 48, tile: 0.12)
        m.add(shell)
        // Label band over the straight upper body, with a white stripe and lap seam.
        m.add(Prim.lathe([V2(0.0346, 0.1065), V2(0.03485, 0.107), V2(0.03485, 0.1355), V2(0.0346, 0.136)], segments: 48, seamTile: 0.1, material: label))
        m.add(Prim.lathe([V2(0.03487, 0.115), V2(0.0351, 0.1153), V2(0.0351, 0.1222), V2(0.03487, 0.1225)], segments: 48, seamTile: 0.1, material: labelStripe))
        m.add(Prim.roundedBox(V3(0.006, 0.029, 0.0003), radius: 0.0001, bevelSegments: 1, material: label), Xform(translation: V3(0, 0.1212, -0.0350)))
        // Neck support ring, thread, cap and tamper band.
        m.add(Prim.lathe([V2(0.0106, 0.1838), V2(0.0138, 0.1841), V2(0.0141, 0.1850), V2(0.0138, 0.1860), V2(0.0106, 0.1864)], segments: 48, seamTile: 0.06, material: pet))
        DD1MPantry.threads(&m, r: 0.0107, y: 0.1895, turns: 1.4, pitch: 0.0030, wire: 0.0006, material: pet)
        DD1MPantry.cap(&m, r: 0.0130, y: 0.1885, h: 0.0185, ribs: 48, ribDepth: 0.00035, material: cap, seg: 48)
        DD1MPantry.tamperRing(&m, r: 0.0126, y: 0.1868, h: 0.0028, material: cap)
        // Mould seam and light scuffs on the heel.
        DD1MPantry.mouldSeam(&m, profile: outer, y0: 0.13, y1: 0.172, material: pet)
        DD1MPantry.flecks(&m, rng: &rng, profile: outer, y0: 0.006, y1: 0.024, count: 10, size: 0.001...0.003, material: "plastic.frosted", lift: 0.0002)
        DD1MPantry.droplets(&m, rng: &rng, profile: outer, y0: 0.01, y1: 0.15, count: 14, size: 0.0009...0.0022)
        rig.base[0].add(m)
        // Water volume, its own part. Pivot at the base center; slosh tilts it a few degrees inside the wall gap.
        var w = Model(name: "water")
        DD1MPantry.fill(&w, outer: outer, wall: 0.0005, baseThick: 0.0035, fillY: fillY, material: water, seg: 48)
        rig.part("water", pivot: V3(0, 0.0035, 0), joint: .hinge(axis: V3(1, 0, 0), -1.5...1.5, duration: 0.5))
        for s in w.surfaces { rig.add(s, to: "water") }
        rig.states = [RigState("still"), RigState("slosh", ["water": 1.5])]
        groundAO(&rig, height: 0.03, floor: 0.6)
        return rig
    }
}
