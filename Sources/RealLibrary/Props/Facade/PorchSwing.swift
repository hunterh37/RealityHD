import simd
import Foundation

/// Southern vernacular porch swing, 1.5 m: six seat slats and seven back slats in sun-faded haint-blue paint, each slat
/// a slightly different tone, screwed to under-rails and back stiles, rounded arm boards on turned front posts, galvanized
/// four-chain suspension (oval links) through eye bolts in the arm ends up to ceiling plates with eye hooks. One slat is
/// a raw replacement board, paint is chipped at slat edges and sanded bare on the arm tops, chain links rust where they
/// meet the hooks.
public struct PorchSwing: RealAsset {
    public static let id = "porch-swing"
    public static let summary = "Southern porch swing, 1.5 m: haint-blue slat seat and back with turned arms, hung on four galvanized chains from ceiling hooks."
    public static let tags = ["prop", "architecture", "facade", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 2.5)

    /// Paint for slats, arms and posts (worn).
    public var paintKey = "wood.painted-shaker-worn"
    /// Haint blue base colour (sRGB hex).
    public var blue: UInt32 = 0x7BA3A1
    /// Galvanized chain and hardware.
    public var steel: MaterialKey = "metal.galvanized-aged"
    /// Rust staining.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func hex(_ r: Int, _ g: Int, _ b: Int) -> String {
        String(format: "%02X%02X%02X", max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    }

    /// Hex head screw, 6 sides.
    func screw(_ m: inout Model, _ p: V3, _ n: V3, _ size: Float = 0.009, _ mat: MaterialKey = "metal.bolt-bright") {
        m.add(Prim.cylinder(radius: size * 0.5, height: size * 0.4, bevel: 0, segments: 6, bevelSegments: 1, material: mat), Xform(translation: p, rotation: facing(n)))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let br = Int((blue >> 16) & 0xFF), bg = Int((blue >> 8) & 0xFF), bb = Int(blue & 0xFF)
        func tone(_ d: Int) -> MaterialKey { "\(paintKey):" + hex(br + d, bg + d, bb + d) }
        let aSeat: Float = 6 * .pi / 180, aBack: Float = 14 * .pi / 180
        let seatFrontZ: Float = 0.29, seatFrontY: Float = 0.45
        let slatT: Float = 0.022
        // Seat: six slats along X, tilted down toward the back.
        let sLen: Float = 1.37
        var seatTop: [V3] = []
        for k in 0..<6 {
            let s = 0.035 + Float(k) * 0.08
            let top = V3(0, seatFrontY - s * sin(aSeat), seatFrontZ - s * cos(aSeat))
            seatTop.append(top)
            let n = V3(0, cos(aSeat), -sin(aSeat))
            let mat: MaterialKey = k == 3 ? "wood.weathered" : tone(rng.int(-22...14))
            m.add(Prim.roundedBox(V3(sLen, slatT, 0.07), radius: 0.005, bevelSegments: 1, material: mat),
                  Xform(translation: top - n * (slatT / 2), rotation: FA.q(-aSeat * 180 / .pi, FA.X)))
        }
        // Seat under-rails: two side rails plus a centre rail, bolted to the slats.
        let railLen: Float = 0.53, railH: Float = 0.06
        let railMid = V3(0, seatFrontY - 0.27 * sin(aSeat), seatFrontZ - 0.27 * cos(aSeat))
        for (i, x) in ([-0.66, 0, 0.66] as [Float]).enumerated() {
            let n = V3(0, cos(aSeat), -sin(aSeat))
            let c = railMid + V3(x, 0, 0) - n * (slatT + railH / 2 - 0.001)
            m.add(Prim.roundedBox(V3(0.028, railH, railLen), radius: 0.004, bevelSegments: 1, material: i == 1 ? "wood.weathered:6E6A5E" : tone(-30)),
                  Xform(translation: c, rotation: FA.q(-aSeat * 180 / .pi, FA.X)))
            if !lite {
                for k in 0..<6 {
                    let t = seatTop[k] + V3(x, 0.0008, 0)
                    screw(&m, t, V3(0, cos(aSeat), -sin(aSeat)), 0.0075, "metal.steel")
                }
            }
        }
        // Back: seven slats along the back slope, stiles behind.
        let rearTop = V3(0, seatFrontY - 0.5 * sin(aSeat), seatFrontZ - 0.5 * cos(aSeat))
        let bT: Float = 0.018
        let up = V3(0, cos(aBack), -sin(aBack)), nf = V3(0, sin(aBack), cos(aBack))
        func bp(_ h: Float) -> V3 { rearTop + up * h }
        var backCentres: [V3] = []
        for k in 0..<7 {
            let h = 0.03 + Float(k) * 0.077 + 0.035
            let c = bp(h) + nf * (bT / 2 - 0.0005)
            backCentres.append(c)
            let mat: MaterialKey = k == 5 ? "wood.weathered:8C7B64" : tone(rng.int(-22...16))
            m.add(Prim.roundedBox(V3(sLen, 0.07, bT), radius: 0.005, bevelSegments: 1, material: mat),
                  Xform(translation: c, rotation: FA.q(-aBack * 180 / .pi, FA.X)))
        }
        // Back stiles: three inner behind the slats, two outer beside the slat ends, tops rounded.
        let stileLen: Float = 0.64
        for (i, x) in ([-0.705, -0.34, 0, 0.34, 0.705] as [Float]).enumerated() {
            let outer = i == 0 || i == 4
            let c = bp(stileLen / 2 - 0.02) + V3(x, 0, 0) - nf * (outer ? -0.0 : 0.016)
            let size = outer ? V3(0.034, stileLen, 0.036) : V3(0.04, stileLen - 0.04, 0.018)
            m.add(Prim.roundedBox(size, radius: 0.006, bevelSegments: 1, material: tone(outer ? -22 : -34)),
                  Xform(translation: c, rotation: FA.q(-aBack * 180 / .pi, FA.X)))
            if !lite && !outer {
                for k in 0..<7 {
                    let sp = backCentres[k] + V3(x, 0, 0) + nf * (bT / 2 + 0.0008)
                    screw(&m, sp, nf, 0.0075, "metal.steel")
                }
            }
        }
        // Back top rail: shaped cap running across the stiles.
        let capC = bp(0.61) + nf * 0.002
        m.add(Prim.roundedBox(V3(1.43, 0.05, 0.03), radius: 0.008, bevelSegments: 1, material: tone(-18)), Xform(translation: capC, rotation: FA.q(-aBack * 180 / .pi, FA.X)))
        // Arms: rounded boards on turned front posts, side aprons joining seat rails to the back stiles.
        let armY: Float = 0.665
        for sx: Float in [-1, 1] {
            let x = sx * 0.705
            let outline = Shape2D.roundedRect(0.078, 0.54, radius: 0.026, segments: lite ? 2 : 4)
            m.add(Prim.extrude(outline, depth: 0.026, bevel: 0.006, bevelSegments: 1, material: tone(rng.int(-20 ... -6))),
                  Xform(translation: V3(x, armY, 0.03), rotation: FA.q(90, FA.X)))
            // Sanded bare strip along the arm top where forearms rest.
            m.add(cuboid(V3(0.05, 0.0008, 0.26), material: "wood.weathered:A19480"), Xform(translation: V3(x, armY + 0.0134, 0.06)))
            // Front turned post.
            m.add(turned([(0, 0.39), (0.017, 0.39), (0.017, 0.4), (0.012, 0.415), (0.0125, 0.43), (0.0185, 0.455), (0.0145, 0.49), (0.0105, 0.53), (0.012, 0.565), (0.0185, 0.59), (0.0195, 0.612), (0.0155, 0.64), (0.021, 0.654), (0, 0.654)], segments: lite ? 8 : 14, material: tone(-8), seamTile: 0.1, grainVertical: true),
                  Xform(translation: V3(x, 0, 0.26)))
            // Side apron: slim board from front post to the back stile, low under the arm.
            let apronA = V3(x, 0.455, 0.26), apronB = V3(x, 0.455, -0.19)
            m.add(Prim.roundedBox(V3(0.022, 0.07, simd_length(apronA - apronB) + 0.03), radius: 0.004, bevelSegments: 1, material: tone(-26)), Xform(translation: (apronA + apronB) / 2 + V3(0, -0.01, 0)))
            // Back arm bracket: angled board from arm back end down to the back stile.
            let bkA = V3(x, armY - 0.01, -0.2), bkB = bp(0.16) + V3(x, 0, 0)
            let d = bkB - bkA
            let L = simd_length(d)
            let q = simd_quatf(from: V3(0, 0, 1), to: simd_normalize(d))
            m.add(Prim.roundedBox(V3(0.028, 0.045, L), radius: 0.005, bevelSegments: 1, material: tone(-14)), Xform(translation: (bkA + bkB) / 2, rotation: q))
            if !lite {
                // Carriage bolts through the arm into the post and bracket.
                screw(&m, V3(x, armY + 0.0134, 0.26), FA.Y, 0.012, steel)
                screw(&m, V3(x, armY + 0.0134, -0.19), FA.Y, 0.012, steel)
                // Eye bolts through the arm ends: washer, ring.
                for ez: Float in [0.285, -0.17] {
                    m.add(Prim.cylinder(radius: 0.015, height: 0.0025, bevel: 0.0006, segments: 12, bevelSegments: 1, material: steel), Xform(translation: V3(x, armY + 0.013, ez)))
                    m.add(Prim.torus(major: 0.0135, minor: 0.0028, segments: 12, sides: 5, material: steel), Xform(translation: V3(x, armY + 0.0305, ez), rotation: FA.q(90, FA.X)))
                    m.add(Prim.cylinder(radius: 0.0045, height: 0.012, bevel: 0.0006, segments: 8, bevelSegments: 1, material: steel), Xform(translation: V3(x, armY + 0.0155, ez)))
                    // Rust bleed from the eye bolt down the outer arm face.
                    m.add(cuboid(V3(0.0009, rng.float(0.035...0.07), 0.009), material: rust), Xform(translation: V3(x + sx * 0.0391, armY - 0.035, ez)))
                    // Nut under the arm.
                    m.add(Prim.cylinder(radius: 0.012, height: 0.01, bevel: 0.001, segments: 6, bevelSegments: 1, material: steel), Xform(translation: V3(x, armY - 0.024, ez)))
                }
            }
        }
        // Ceiling rails: a pine joist per side the plates are lagged to.
        let H0: Float = 0.33
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.062, 0.05, 0.52), V3(sx * 0.705, 1.6 + H0 - 0.025, 0.0575), "wood.pine-aged", r: 0.004)
            if !lite {
                for ez: Float in [-0.12, 0.05, 0.22] { m.add(cuboid(V3(0.0012, 0.04, 0.006), material: "wood.charred"), Xform(translation: V3(sx * 0.705 + 0.031, 1.6 + H0 - 0.03, ez))) }
            }
        }
        // Chains: four runs from the eye bolts to ceiling plates with eye hooks.
        let linkMaj: Float = 0.028, linkMin: Float = 0.0036
        let pitch: Float = 2 * (linkMaj - linkMin)
        let H: Float = 0.33   // ceiling sits 0.33 above the old 1.6 datum so the seat bottom lands on y = 0 after placement
        let yTop: Float = 1.494 + H
        for sx: Float in [-1, 1] { for (zi, ez) in ([0.285, -0.17] as [Float]).enumerated() {
            let x = sx * 0.705
            let y0 = armY + 0.0305 + 0.013
            let n = Int((yTop - y0) / pitch)
            for i in 0..<n {
                let y = y0 + Float(i) * pitch + linkMaj - linkMin
                let roll: simd_quatf = i % 2 == 0 ? FA.q(90, FA.X) : FA.q(90, FA.Y) * FA.q(90, FA.X)
                let rustLink = i >= n - 2 || i == 0 || i % 6 == 2
                let mat: MaterialKey = rustLink ? rust : (i % 5 == 3 ? "metal.galvanized" : steel)
                if lite {
                    m.add(Prim.tube([V3(x, y - 0.012, ez), V3(x, y + 0.012, ez)], radii: [0.0036, 0.0036], sides: 4, seamTile: 0.1, material: mat, capEnd: true), Xform())
                } else {
                    m.add(Prim.torus(major: linkMaj, minor: linkMin, segments: 7, sides: 4, material: mat),
                          Xform(translation: V3(x, y, ez), rotation: roll, scale: V3(0.6, 1, 1)))
                }
            }
            // Ceiling plate and eye hook.
            FA.box(&m, V3(0.075, 0.012, 0.075), V3(x, 1.543 + H, ez), "metal.galvanized-aged", r: 0.003)
            if !lite {
                for (dx, dz) in [(-0.026, -0.026), (0.026, -0.026), (-0.026, 0.026), (0.026, 0.026)] as [(Float, Float)] {
                    screw(&m, V3(x + dx, 1.5365 + H, ez + dz), -FA.Y, 0.011, "metal.steel")
                }
                m.add(Prim.torus(major: 0.017, minor: 0.0042, segments: 14, sides: 5, material: steel), Xform(translation: V3(x, 1.506 + H, ez), rotation: FA.q(90, FA.X)))
                m.add(Prim.cylinder(radius: 0.0055, height: 0.018, bevel: 0.0008, segments: 8, bevelSegments: 1, material: steel), Xform(translation: V3(x, 1.5225 + H, ez)))
                // Rust bleed from the hook down the plate's front edge.
                m.add(cuboid(V3(0.006, 0.05, 0.0008), material: rust), Xform(translation: V3(x + rng.float(-0.02...0.02), 1.519 + H, ez + 0.0386)))
            } else {
                m.add(Prim.torus(major: 0.017, minor: 0.0042, segments: 8, sides: 4, material: steel), Xform(translation: V3(x, 1.506 + H, ez), rotation: FA.q(90, FA.X)))
            }
        }}
        // Paint chips: bare grey wood along slat edges, irregular and thin.
        if !lite {
            for _ in 0..<26 {
                let onSeat = rng.chance(0.5)
                let side: Float = rng.chance(0.5) ? -1 : 1
                let yaw = rng.float(-0.25...0.25)
                if onSeat {
                    let k = rng.int(0...5)
                    let top = seatTop[k]
                    let edge: Float = rng.chance(0.6) ? 0.034 : -0.034
                    m.add(cuboid(V3(rng.float(0.012...0.07), 0.0009, rng.float(0.003...0.008)), material: "wood.weathered"),
                          Xform(translation: V3(side * rng.float(0.05...0.68), top.y + 0.0004 - edge * sin(aSeat) * -1, top.z + edge * cos(aSeat) * -1 * -1 - 0.0), rotation: FA.q(-aSeat * 180 / .pi, FA.X) * simd_quatf(angle: yaw, axis: FA.Y)))
                } else {
                    let kb = rng.int(0...6)
                    let edge: Float = rng.chance(0.5) ? 0.034 : -0.034
                    let c = backCentres[kb] + nf * (bT / 2 + 0.0004) + up * edge + V3(side * rng.float(0.05...0.68), 0, 0)
                    m.add(cuboid(V3(rng.float(0.012...0.07), rng.float(0.003...0.008), 0.0009), material: "wood.weathered"),
                          Xform(translation: c, rotation: FA.q(-aBack * 180 / .pi, FA.X) * simd_quatf(angle: yaw, axis: FA.Z)))
                }
            }
        }
        _ = rng
        return FC.place(m)
    }
}
