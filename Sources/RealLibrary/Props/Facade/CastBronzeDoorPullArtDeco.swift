import simd
import Foundation

/// Art Deco cast bronze door pull, 0.12 x 0.80 x 0.10 m: eight-flute vertical shaft with a smooth hand-worn grip
/// sleeve, stepped collars, and a ziggurat standoff block at each end with chevron banding. Each end sits on a
/// four-step stacked mounting plate fixed by hex-socket screws. Flutes and plate steps are dark bronze with copper
/// patina in the recesses; the grip, collar crowns and block edges are polished bright by hands.
public struct CastBronzeDoorPullArtDeco: RealAsset {
    public static let id = "cast-bronze-door-pull-art-deco"
    public static let summary = "Art Deco cast bronze door pull: tall vertical bar with stepped ziggurat ends, fluted shaft, mounting plates and bolts, polished high points and darkened recesses."
    public static let tags = ["prop", "architecture", "facade", "door", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 2.2)

    /// Overall bar length (m).
    public var length: Float = 0.8
    /// Number of flutes in the shaft.
    public var flutes = 8
    /// Cast surface, dulled.
    public var bronze: MaterialKey = "metal.brass-aged:7A5226"
    /// Plate steps, darker.
    public var plateBronze: MaterialKey = "metal.bronze-weathered"
    /// Hand-polished high points.
    public var polished: MaterialKey = "metal.bronze-cast"
    public var bright: MaterialKey = "metal.brass"
    public var patina: MaterialKey = "metal.copper-patina"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, zs: Float = 0.064, R: Float = 0.026

        // Mounting plates: four stacked steps at each end, bevelled, with hex-socket screws on the first step.
        for end in 0..<2 {
            let flip: Float = end == 0 ? 1 : -1
            func y(_ v: Float) -> Float { end == 0 ? v : L - v }       // distance from the bar end
            let steps: [(Float, Float, Float)] = [(0.12, 0.14, 0.008), (0.10, 0.12, 0.008), (0.08, 0.10, 0.008), (0.06, 0.08, 0.006)]
            var z: Float = 0
            for (i, st) in steps.enumerated() {
                FA.box(&m, V3(st.0, st.1, st.2), V3(0, y(st.1 / 2), z + st.2 / 2), i % 2 == 0 ? plateBronze : polished, r: 0.0016)
                z += st.2
            }
            for sx: Float in [-1, 1] { for sy: Float in [0.015, 0.125] {
                let p = V3(sx * 0.0545, y(sy), 0.008)
                rivet(&m, at: p, normal: FA.Z, radius: 0.0042, height: 0.0028, segments: 6, material: bright)
                FJ.slab(&m, V3(0.0032, 0.0032, 0.0008), p + V3(0, 0, 0.0027), "metal.painted:121110")        // hex socket
            } }
            // Ziggurat standoff block carrying the shaft: stepped profile extruded across 50 mm, chevron banding on its face.
            let prof: [V2] = [V2(0.03, 0.025), V2(0.099, 0.025), V2(0.099, 0.138), V2(0.087, 0.138), V2(0.087, 0.122), V2(0.072, 0.122), V2(0.072, 0.106), V2(0.057, 0.106), V2(0.057, 0.09), V2(0.03, 0.09)]
            let pf = prof.map { V2($0.x, y($0.y)) }
            m.add(Prim.extrude(flip > 0 ? pf : pf.reversed(), depth: 0.05, bevel: 0.0022, bevelSegments: 1, material: bronze), Xform(translation: V3(0, 0, 0), rotation: simd_quatf(degrees: -90, axis: FA.Y)))
            for k in 0..<3 {
                let cyv = y(0.045 + Float(k) * 0.02)
                for s: Float in [-1, 1] {
                    FJ.slab(&m, V3(0.021, 0.0035, 0.0016), V3(s * 0.0105, cyv + flip * s * 0.0035 * 0, 0.0995), polished, rot: FA.q(s * 38 * flip, FA.Z))
                }
            }
            // Collar: stepped crown where the shaft enters the block.
            let cy0 = y(0.138)
            m.add(Prim.lathe([V2(0, 0), V2(0.036, 0), V2(0.036, 0.005), V2(0.031, 0.007), V2(0.031, 0.012), V2(0.0285, 0.014), V2(0.0285, 0.019), V2(0, 0.019)], segments: 28, seamTile: 0.1, material: polished),
                  Xform(translation: V3(0, cy0 - (end == 0 ? 0.0 : 0.019), zs), rotation: .identity))
        }
        // Fluted shaft: sweep of a scalloped section along the vertical axis; smooth grip sleeve with collars over the middle.
        var fl: [V2] = []
        let nf = flutes, per = 12
        for i in 0..<(nf * per) {
            let a = Float(i) / Float(nf * per) * 2 * .pi
            fl.append(V2(cos(a), sin(a)) * (R * (1 - 0.16 * (0.5 + 0.5 * cos(Float(nf) * a)))))
        }
        m.add(Prim.sweep(fl, along: [V3(0, 0.145, zs), V3(0, L / 2, zs), V3(0, L - 0.145, zs)], up: FA.X, caps: true, grainAlongPath: true, material: bronze))
        let g0 = L / 2 - 0.1, g1 = L / 2 + 0.1
        m.add(Prim.lathe([V2(0, g0), V2(R * 1.01, g0), V2(R * 1.01, g1), V2(0, g1)], segments: 28, seamTile: 0.15, material: bright), Xform(translation: V3(0, 0, zs)))
        for gy in [g0, g1 - 0.014] {
            m.add(Prim.lathe([V2(0, 0), V2(0.030, 0), V2(0.030, 0.004), V2(0.0275, 0.006), V2(0.0275, 0.009), V2(0.0305, 0.011), V2(0.0305, 0.014), V2(0, 0.014)], segments: 28, seamTile: 0.1, material: polished),
                  Xform(translation: V3(0, gy, zs)))
        }
        // Wear: patina in the recesses and plate steps, bright gouges, handprint dulling above the grip.
        for end in 0..<2 {
            func y(_ v: Float) -> Float { end == 0 ? v : L - v }
            for (i, zz) in [Float(0.008), 0.016, 0.024].enumerated() {
                FJ.peel(&m, at: V3(rng.float(-0.03...0.03), y(0.025 + rng.float(0...0.09)), zz), w: rng.float(0.02...0.05), h: rng.float(0.012...0.03), patina, rng: &rng)
                _ = i
            }
            FJ.peel(&m, at: V3(rng.float(-0.012...0.012), y(0.058), 0.1002), w: 0.014, h: 0.01, patina, rng: &rng)
        }
        for k in 0..<10 {
            let y = rng.float(0.17...L - 0.17)
            if y > L / 2 - 0.1 && y < L / 2 + 0.1 { continue }
            FJ.slab(&m, V3(0.0036, rng.float(0.05...0.16), 0.002), V3(rng.float(-0.02...0.02), y, zs + R * 0.9), patina, rot: FA.q(rng.float(-3...3), FA.Z))
            _ = k
        }
        for _ in 0..<3 { FJ.peel(&m, at: V3(rng.float(-0.02...0.02), rng.float(g0 + 0.02...g1 - 0.02), zs + R * 1.01 + 0.0006), w: 0.012, h: 0.008, polished, rng: &rng) }
        // Patina streaks lying in the flute valleys and polished lines along the ridges, front half only.
        for k in 0..<nf {
            for (a, rad, mat, wd) in [(2 * .pi * Float(k) / Float(nf), R * 0.84 + 0.0004, patina, Float(0.0042)), ((2 * Float(k) + 1) * .pi / Float(nf), R * 0.995, polished, Float(0.0024))] as [(Float, Float, MaterialKey, Float)] {
                let zc = -sin(a) * rad
                if zc < 0.004 { continue }
                let phi = atan2(cos(a), -sin(a)) * 180 / .pi
                var yy: Float = 0.17
                while yy < L - 0.17 {
                    let ln = rng.float(0.04...0.16)
                    if !(yy + ln > g0 && yy < g1), mat == patina || rng.chance(0.6) {
                        FJ.slab(&m, V3(wd, ln, 0.0016), V3(cos(a) * rad, yy + ln / 2, zs + zc), mat, rot: FA.q(phi, FA.Y))
                    }
                    yy += ln + rng.float(0.03...0.12)
                }
            }
        }
        // Verdigris pooled in the collar undercuts, and dark grime where the grip meets the flutes.
        for gy in [g0 - 0.004, g1 + 0.0] {
            for k in 0..<5 {
                let a = Float(k) / 5 * .pi + 0.4
                FJ.slab(&m, V3(0.006, 0.007, 0.0018), V3(cos(a) * 0.029, gy, zs + sin(a) * 0.029), patina, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
            }
            FJ.slab(&m, V3(0.034, 0.012, 0.0016), V3(0, gy + (gy < L / 2 ? -0.012 : 0.012), zs + R * 0.97), "metal.brass-aged:3C2A14")
        }
        groundAO(&m, height: 0.06, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
