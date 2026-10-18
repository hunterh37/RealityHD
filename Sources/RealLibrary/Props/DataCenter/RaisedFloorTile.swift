import simd
import Foundation

/// Raised floor airflow tile: 600 mm steel shell, grey anti-static laminate border, 25 percent perforated field (or solid), black PVC edge trim, caster wheel marks and scuffs. Named part "lift" slides up 0.3 m.
public struct RaisedFloorTile: RealArticulated {
    public static let id = "raised-floor-tile"
    public static let summary = "Raised floor airflow tile: 600 mm perforated steel panel with grey anti-static laminate border, edge trim, scuffs and wheel marks; lifts out as a named part."
    public static let tags = ["prop", "articulated"]
    public static let budget = 800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 38, distance: 1.1, studio: true)

    /// Width (x), thickness (y), depth (z) in meters.
    public var size = V3(0.6, 0.03, 0.6)
    /// True for the perforated airflow tile, false for the solid laminate-faced tile.
    public var perforated: Bool = true
    /// Border and solid-face laminate.
    public var laminate: MaterialKey = "laminate.antistatic"
    /// Perforated field material.
    public var perforatedMaterial: MaterialKey = "metal.perforated"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1, switchDistances: [])
        let W = size.x - 0.002, H = size.y, hw = W / 2
        let lam = laminate, trim: MaterialKey = "plastic.matte:151617", zinc: MaterialKey = "metal.galvanized"
        let rubber: MaterialKey = "plastic.matte:0C0C0D"
        let b: Float = 0.05                 // laminate border width
        let topY = H - 0.0015                // laminate face
        rig.part("lift", pivot: V3(0, H / 2, 0), joint: .slide(axis: V3(0, 1, 0), 0...0.3, duration: 0.8))
        func bar(_ s: V3, _ t: V3, _ mat: MaterialKey, r: Float = 0.0008) {
            if r < 0.0006 { rig.add(cuboid(s, material: mat), Xform(translation: t), to: "lift"); return }
            let rr = min(r, min(s.x, min(s.y, s.z)) * 0.4)
            rig.add(Prim.roundedBox(s, radius: rr, bevelSegments: 1, material: mat), Xform(translation: t), to: "lift")
        }
        // Pan underside and edge trim (black PVC strip around the 30 mm edge).
        bar(V3(W - 0.012, 0.0015, W - 0.012), V3(0, 0.0015, 0), zinc, r: 0)
        let t: Float = 0.0035
        for s: Float in [-1, 1] {
            bar(V3(W, H - 0.004, t), V3(0, (H - 0.004) / 2 + 0.002, s * (hw - t / 2)), trim, r: 0)
            bar(V3(t, H - 0.004, W - 2 * t), V3(s * (hw - t / 2), (H - 0.004) / 2 + 0.002, 0), trim, r: 0)
        }
        // Steel shell walls inside the trim.
        for s: Float in [-1, 1] {
            bar(V3(W - 2 * t, H - 0.006, 0.0015), V3(0, (H - 0.006) / 2 + 0.0015, s * (hw - t - 0.0008)), zinc, r: 0)
            bar(V3(0.0015, H - 0.006, W - 2 * t - 0.003), V3(s * (hw - t - 0.0008), (H - 0.006) / 2 + 0.0015, 0), zinc, r: 0)
        }
        // Laminate border frame, 1.5 mm proud of the field.
        let inner = W - 2 * t - 2 * b, lamH: Float = 0.003
        for s: Float in [-1, 1] {
            bar(V3(W - 2 * t, lamH, b), V3(0, topY - lamH / 2 + 0.0015, s * (hw - t - b / 2)), lam, r: 0.0007)
            bar(V3(b, lamH, inner), V3(s * (hw - t - b / 2), topY - lamH / 2 + 0.0015, 0), lam, r: 0.0007)
        }
        // Field: perforated plate over a dark pan floor, or a solid laminate plate.
        if perforated {
            bar(V3(inner, 0.0012, inner), V3(0, 0.008, 0), "metal.galvanized:5A5C5E", r: 0)
            rig.add(cuboid(V3(inner, 0.0015, inner), material: perforatedMaterial), Xform(translation: V3(0, topY - 0.0007, 0)), to: "lift")
            // Stiffener ribs under the field.
            for x: Float in [-0.12, 0, 0.12] { bar(V3(0.006, 0.014, inner - 0.01), V3(x, 0.0155, 0), zinc, r: 0) }
        } else {
            bar(V3(inner, 0.0025, inner), V3(0, topY - 0.00125 + 0.0015, 0), lam, r: 0.0007)
        }
        // Wheel marks: two parallel caster streaks crossing the tile at a shallow angle.
        let top = H + 0.0003
        func streak(_ len: Float, _ w: Float, _ c: V3, _ deg: Float, _ mat: MaterialKey) {
            let q = simd_quatf(degrees: deg, axis: V3(0, 1, 0))
            rig.add(cuboid(V3(len, 0.0004, w), material: mat), Xform(translation: c, rotation: q), to: "lift")
        }
        let ca = cos(Float(18) * .pi / 180), sa = sin(Float(18) * .pi / 180)
        for o: Float in [-0.012, 0.012] {
            let jz: Float = Float.random(in: 0...0.01, using: &rng)
            let cx: Float = -o * sa + 0.01
            let cz: Float = o * ca - 0.19 + jz
            streak(0.54, 0.0035, V3(cx, top, cz), -18, "plastic.matte:2E2F30")
        }
        // Scuffs on the border: pale abrasion slivers and dark heel marks.
        streak(0.06, 0.004, V3(-0.27, top, 0.22), 35, "plastic.matte:C9CAC7")
        streak(0.045, 0.003, V3(0.2, top, 0.275), -20, "plastic.matte:B8B9B6")
        streak(0.05, 0.006, V3(0.275, top, -0.12), 80, "plastic.matte:3A3B3C")
        streak(0.035, 0.003, V3(-0.1, top, -0.275), 8, "plastic.matte:C2C3C0")
        // Stamped tile ID plate on the border, near one corner.
        bar(V3(0.03, 0.0004, 0.012), V3(-0.255, H + 0.00015, -0.265), "plastic.matte:E4E4DF", r: 0)
        bar(V3(0.02, 0.0004, 0.003), V3(-0.255, H + 0.00035, -0.265), "plastic.matte:151515", r: 0)
        var base = Model(name: Self.id)
        groundAO(&base)
        rig.base[0] = base
        rig.states = [RigState("seated"), RigState("lifted", ["lift": 0.3])]
        return rig
    }
}
