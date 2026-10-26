import simd
import Foundation

/// Haussmann cast-iron balconette window guard, 1.4 x 0.9 x 0.2 m: a handrail with a half-round cap over square
/// posts topped by urn finials, round balusters with turned collars, a lower band of S-scrolls, a central ring
/// panel with four C-scrolls and a rosette, and two side returns with wall plates and bolted fixings. Black paint
/// is chipped to rust at the rail tops, collars and bolts, with one bright replacement bolt.
public struct CastIronBalconetteWindowGuard: RealAsset {
    public static let id = "cast-iron-balconette-window-guard"
    public static let summary = "Haussmann cast-iron balconette guard, 1.4 x 0.9 m: handrail, collared balusters, S-scroll band, central ring panel, urn finials and side returns."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 1.1)

    /// Black painted wrought iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Bare cast iron of the finials and collars.
    public var cast: MaterialKey = "metal.cast-iron"
    /// Rust showing through chipped paint.
    public var rust: MaterialKey = "metal.rust"
    /// Replacement bolt.
    public var bolt: MaterialKey = "metal.bolt-bright"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sides = lite ? 5 : 7
        let px: Float = 0.665, zf: Float = 0.186, zw: Float = 0.012
        let yTop: Float = 0.82, yBot: Float = 0.07
        // Planar spiral in the plane spanned by `u` and Y.
        func spiral(_ c: V3, u: V3, radius R: Float, turns: Float, start: Float, dir: Float, wire: Float) {
            var pts: [V3] = [], rad: [Float] = []
            let steps = lite ? 8 : 11
            for k in 0...steps {
                let t = Float(k) / Float(steps), a = start + dir * t * turns * 2 * .pi, r = R * (1 - 0.8 * t)
                pts.append(c + u * (cos(a) * r) + FA.Y * (sin(a) * r)); rad.append(wire * (1 - 0.35 * t))
            }
            m.add(Prim.tube(pts, radii: rad, sides: 4, seamTile: 0.1, material: iron, capEnd: true))
            FC.bead(&m, r: wire * 1.5, at: pts.last!, iron, sub: 1)
        }
        // Handrail: flat bar with a half-round cap, front and both returns.
        FA.box(&m, V3(2 * px + 0.028, 0.024, 0.034), V3(0, yTop - 0.004, zf), iron, r: 0.003)
        FA.rod(&m, V3(-px - 0.012, yTop + 0.011, zf), V3(px + 0.012, yTop + 0.011, zf), r: 0.0105, iron, sides: sides)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.034, 0.024, zf - zw), V3(s * px, yTop - 0.004, (zf + zw) / 2), iron, r: 0.003)
            FA.rod(&m, V3(s * px, yTop + 0.011, zw), V3(s * px, yTop + 0.011, zf), r: 0.0105, iron, sides: sides)
        }
        // Bottom rails and a mid rail on the front.
        FA.box(&m, V3(2 * px, 0.026, 0.026), V3(0, yBot, zf), iron, r: 0.003)
        FA.box(&m, V3(2 * px, 0.016, 0.018), V3(0, 0.215, zf), iron, r: 0.002)
        for s: Float in [-1, 1] { FA.box(&m, V3(0.026, 0.026, zf - zw), V3(s * px, yBot, (zf + zw) / 2), iron, r: 0.003) }
        // Posts: square, front corners and wall returns, with plinth blocks and urn finials on the front.
        for s: Float in [-1, 1] {
            for (z, tall) in [(zf, true), (zw + 0.01, false)] {
                FA.box(&m, V3(0.03, yTop, 0.03), V3(s * px, yTop / 2, z), iron, r: 0.003)
                FA.box(&m, V3(0.04, 0.05, 0.04), V3(s * px, 0.025, z), iron, r: 0.004)
                if tall {
                    m.add(turned([(0, 0), (0.016, 0), (0.018, 0.006), (0.012, 0.012), (0.014, 0.024), (0.022, 0.036), (0.02, 0.05), (0.012, 0.06), (0.012, 0.064), (0.006, 0.07), (0, 0.076)], segments: lite ? 8 : 14, material: cast, seamTile: 0.1),
                          Xform(translation: V3(s * px, yTop + 0.0, z)))
                }
            }
            // Wall plate with bolts at the return end.
            FA.box(&m, V3(0.07, 0.3, 0.012), V3(s * px, 0.5, 0.006), iron, r: 0.003)
            FA.box(&m, V3(0.07, 0.3, 0.012), V3(s * px, 0.28, 0.006), iron, r: 0.003)
        }
        // Round balusters with collars: front bays either side of the centre panel and two on each return.
        var bxs: [Float] = []
        for k in 0..<5 { bxs.append(0.30 + Float(k) * 0.0775); bxs.append(-(0.30 + Float(k) * 0.0775)) }
        for x in bxs {
            FA.rod(&m, V3(x, yBot, zf), V3(x, yTop - 0.012, zf), r: 0.0065, iron, sides: sides)
            for y: Float in [0.36, 0.62] { FC.bead(&m, r: 0.0105, at: V3(x, y, zf), cast, sub: lite ? 1 : 2) }
            FC.bead(&m, r: 0.0095, at: V3(x, 0.215, zf), cast, sub: lite ? 1 : 2)
        }
        for s: Float in [-1, 1] {
            for z: Float in [0.07, 0.13] {
                FA.rod(&m, V3(s * px, yBot, z), V3(s * px, yTop - 0.012, z), r: 0.0065, iron, sides: sides)
                for y: Float in [0.36, 0.62] { FC.bead(&m, r: 0.0105, at: V3(s * px, y, z), cast, sub: lite ? 1 : 2) }
            }
        }
        // Lower band of S-scrolls between rails, in each front bay.
        for k in 0..<5 {
            for sd: Float in [-1, 1] {
                let cx = sd * (0.30 + (Float(k) + 0.5) * 0.0775 - 0.0775 * 0.0)
                if k == 4 { continue }
                spiral(V3(cx - 0.012, 0.145, zf), u: FA.X, radius: 0.026, turns: 0.8, start: .pi, dir: 1, wire: 0.0042)
                spiral(V3(cx + 0.012, 0.145, zf), u: FA.X, radius: 0.026, turns: 0.8, start: 0, dir: 1, wire: 0.0042)
            }
        }
        // Top band of opposed C-scrolls under the handrail in the outer bays.
        for k in 0..<4 {
            for sd: Float in [-1, 1] {
                let cx = sd * (0.30 + (Float(k) + 0.5) * 0.0775)
                spiral(V3(cx - 0.0125, 0.745, zf), u: FA.X, radius: 0.026, turns: 0.8, start: 0, dir: -1, wire: 0.0042)
                spiral(V3(cx + 0.0125, 0.745, zf), u: FA.X, radius: 0.026, turns: 0.8, start: .pi, dir: -1, wire: 0.0042)
            }
        }
        // Central panel: ring, diamond, four inward C-scrolls and a rosette.
        let cy: Float = 0.47
        m.add(Prim.torus(major: 0.17, minor: 0.0075, segments: lite ? 20 : 36, sides: sides - 2, material: iron), Xform(translation: V3(0, cy, zf), rotation: FA.q(90, FA.X)))
        let d: Float = 0.2
        for (a, b) in [(V3(0, cy + d, zf), V3(d, cy, zf)), (V3(d, cy, zf), V3(0, cy - d, zf)), (V3(0, cy - d, zf), V3(-d, cy, zf)), (V3(-d, cy, zf), V3(0, cy + d, zf))] {
            FA.rod(&m, a, b, r: 0.0055, iron, sides: sides - 2)
        }
        for k in 0..<4 {
            let ang = Float(k) * .pi / 2 + .pi / 4
            let c = V3(cos(ang) * 0.1, cy + sin(ang) * 0.1, zf)
            spiral(c, u: FA.X, radius: 0.052, turns: 0.9, start: ang + .pi * 0.9, dir: k % 2 == 0 ? 1 : -1, wire: 0.0048)
        }
        m.add(turned([(0, 0), (0.03, 0), (0.03, 0.004), (0.022, 0.009), (0.012, 0.016), (0, 0.02)], segments: lite ? 8 : 16, material: cast, seamTile: 0.1),
              Xform(translation: V3(0, cy, zf + 0.004), rotation: FA.q(90, FA.X)))
        FC.bead(&m, r: 0.008, at: V3(0, cy, zf + 0.018), iron, sub: lite ? 1 : 2)
        // Ring tied to the posts by short horizontal bars.
        FA.rod(&m, V3(-0.37, cy, zf), V3(-0.17, cy, zf), r: 0.0055, iron, sides: sides - 2)
        FA.rod(&m, V3(0.37, cy, zf), V3(0.17, cy, zf), r: 0.0055, iron, sides: sides - 2)
        // Bolts through the wall plates.
        if !lite {
            for (i, s) in ([Float(-1), 1]).enumerated() {
                for (j, y) in ([Float(0.2), 0.38, 0.58]).enumerated() {
                    FO.head(&m, at: V3(s * px + 0.0, y, 0.012), r: 0.0075, h: 0.005, segments: 6, (i == 1 && j == 1) ? bolt : cast)
                }
            }
            // Rust runs and chips on the wall plates beneath the bolts.
            for s: Float in [-1, 1] {
                for y in [Float(0.2), 0.38, 0.58] { FA.box(&m, V3(0.008, rng.float(0.05...0.12), 0.0016), V3(s * px + rng.float(-0.004...0.004), y - 0.07, 0.0128), rust, r: 0.0005) }
                for _ in 0..<3 { FO.patch(&m, cx: s * px + rng.float(-0.025...0.025), cy: rng.float(0.1...0.65), rx: rng.float(0.006...0.015), ry: rng.float(0.01...0.03), z: 0.0124, rust, rng: &rng, depth: 0.0006) }
            }
            // Weathering: paint chips along the rail top and rust at collars, the bottom rail, post plinths and bolts.
            for _ in 0..<14 { FO.patchTop(&m, cx: rng.float(-0.64...0.64), cz: zf + rng.float(-0.006...0.006), rx: rng.float(0.01...0.04), rz: 0.004, y: yTop + 0.0225, rust, rng: &rng, depth: 0.0006, n: 7) }
            for x in bxs.prefix(8) { m.add(Prim.cylinder(radius: 0.0072, height: 0.02, bevel: 0.0004, segments: 6, bevelSegments: 1, material: rust), Xform(translation: V3(x, yBot + 0.013, zf))) }
            for _ in 0..<8 { FO.patchTop(&m, cx: rng.float(-0.64...0.64), cz: zf + rng.float(-0.005...0.005), rx: rng.float(0.01...0.05), rz: 0.004, y: yBot + 0.0135, rust, rng: &rng, depth: 0.0006, n: 7) }
            for s: Float in [-1, 1] { FA.box(&m, V3(0.0414, 0.01, 0.0414), V3(s * px, 0.005, zf), rust, r: 0.001) }
            for k in 0..<10 { FO.patch(&m, cx: rng.float(-0.65...0.65), cy: rng.float(0.79...0.81), rx: rng.float(0.008...0.03), ry: 0.005, z: zf + 0.0175, rust, rng: &rng, depth: 0.0006, n: 6); _ = k }
        }
        groundAO(&m, height: 0.1, floor: 0.9)
        return FC.place(m)
    }
}
