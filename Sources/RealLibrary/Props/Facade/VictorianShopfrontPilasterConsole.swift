import simd
import Foundation

/// Victorian shopfront pilaster with console, 0.3 x 2.8 x 0.2 m: a painted timber plinth with a double base
/// moulding, a reeded shaft (nine half-round reeds between fillets), astragal necking, a swelling capital with an
/// anthemion boss and side paterae, and a scrolled console bracket with volutes and an acanthus drop that carries the
/// fascia. Claret paint is dirty and flaked at the foot, with brass screw heads and one rusted fixing.
public struct VictorianShopfrontPilasterConsole: RealAsset {
    public static let id = "victorian-shopfront-pilaster-console"
    public static let summary = "Victorian shopfront pilaster, 0.3 x 2.8 m: plinth, base moulding, reeded shaft, capital with anthemion boss and a scrolled console bracket."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 8, distance: 1.2)

    /// Main claret paint.
    public var paint: MaterialKey = "wood.painted-exterior:3F1218"
    /// Slightly lighter paint on the reeds and mouldings.
    public var light: MaterialKey = "wood.painted-exterior:4F1A21"
    /// Dirty paint at the foot.
    public var grime: MaterialKey = "wood.painted-exterior:1E0B0E"
    /// Bare timber under flaked paint.
    public var bare: MaterialKey = "wood.painted-exterior:7A6A4C"
    /// Gilt boss.
    public var gilt: MaterialKey = "metal.gold-leaf"
    /// Screw heads.
    public var brass: MaterialKey = "metal.brass"
    /// Rusted screw.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sides = lite ? 6 : 10
        // Plinth, then base moulding (torus and scotia) at two widths.
        FA.run(&m, [V2(0, 0), V2(0.074, 0), V2(0.074, 0.23), V2(0.068, 0.24), V2(0.068, 0.262), V2(0.058, 0.28), V2(0, 0.28)], length: 0.3, paint, bevel: 0.002)
        FA.run(&m, [V2(0, 0.278), V2(0.06, 0.278), V2(0.066, 0.288), V2(0.066, 0.31), V2(0.058, 0.322), V2(0.05, 0.328), V2(0.05, 0.34), V2(0.055, 0.35), V2(0.054, 0.37), V2(0, 0.37)], length: 0.26, light, bevel: 0.0015)
        // Raised plinth panel.
        FA.box(&m, V3(0.19, 0.15, 0.01), V3(0, 0.12, 0.076), light, r: 0.003)
        FA.box(&m, V3(0.15, 0.11, 0.01), V3(0, 0.12, 0.082), paint, r: 0.003)
        // Shaft: core with nine half-round reeds.
        FA.box(&m, V3(0.22, 1.74, 0.04), V3(0, 1.24, 0.019), paint, r: 0.002)
        let nReeds = 9, pitch: Float = 0.0225
        for k in 0..<nReeds {
            let x = (Float(k) - Float(nReeds - 1) / 2) * pitch
            FA.rod(&m, V3(x, 0.375, 0.042), V3(x, 2.1, 0.042), r: 0.0108, light, sides: lite ? 5 : 8)
        }
        // Fillets framing the reeds at foot and head (astragals).
        for y: Float in [0.38, 2.095] { FA.box(&m, V3(0.226, 0.012, 0.058), V3(0, y, 0.03), light, r: 0.003) }
        // Necking, capital with swelling echinus and abacus.
        FA.run(&m, [V2(0, 2.1), V2(0.05, 2.1), V2(0.055, 2.112), V2(0.055, 2.13), V2(0.05, 2.142), V2(0, 2.142)], length: 0.24, paint, bevel: 0.0015)
        FA.run(&m, [V2(0, 2.14), V2(0.052, 2.14), V2(0.062, 2.162), V2(0.068, 2.2), V2(0.072, 2.236), V2(0.084, 2.246), V2(0.084, 2.29), V2(0, 2.29)], length: 0.3, light, bevel: 0.002)
        // Anthemion boss on the capital face and two side paterae.
        m.add(turned([(0, 0), (0.03, 0), (0.03, 0.004), (0.022, 0.008), (0.014, 0.014), (0.006, 0.02), (0, 0.022)], segments: lite ? 8 : 16, material: gilt, seamTile: 0.1),
              Xform(translation: V3(0, 2.2, 0.0735), rotation: FA.q(90, FA.X)))
        for k in 0..<(lite ? 5 : 7) {
            let a = (Float(k) / Float(lite ? 4 : 6) - 0.5) * 2.0
            m.add(turned([(0, 0), (0.007, 0.004), (0.011, 0.016), (0.006, 0.034), (0, 0.04)], segments: 6, material: light, seamTile: 0.1),
                  Xform(translation: V3(sin(a) * 0.03, 2.2 + cos(a) * 0.033, 0.074), rotation: FA.q(a * 180 / .pi, FA.Z), scale: V3(1, 1, 0.45)))
        }
        for s: Float in [-1, 1] {
            m.add(turned([(0, 0), (0.02, 0), (0.02, 0.003), (0.012, 0.007), (0, 0.01)], segments: lite ? 8 : 12, material: gilt, seamTile: 0.1),
                  Xform(translation: V3(s * 0.12, 2.2, 0.074), rotation: FA.q(90, FA.X)))
            _ = s
        }
        // Console bracket: S-curved front under the fascia; the profile runs in (out, up).
        let front = catmull([V3(0.018, 2.29, 0), V3(0.04, 2.3, 0), V3(0.075, 2.35, 0), V3(0.12, 2.43, 0), V3(0.17, 2.52, 0), V3(0.2, 2.62, 0), V3(0.2, 2.76, 0)], per: lite ? 3 : 6)
        var prof: [V2] = [V2(0, 2.29)] + front.map { V2($0.x, $0.y) } + [V2(0.2, 2.76), V2(0, 2.76)]
        prof = Shape2D.deduped(prof)
        FA.side(&m, prof, thick: 0.19, at: .zero, paint, bevel: 0.003)
        // Face rib on the console front (a raised centre band).
        FA.side(&m, [V2(0.0, 2.33), V2(0.052, 2.33), V2(0.095, 2.4), V2(0.15, 2.5), V2(0.19, 2.6), V2(0.203, 2.7), V2(0.203, 2.74), V2(0.0, 2.74)].map { $0 }, thick: 0.055, at: .zero, light, bevel: 0.003)
        // Abacus cap block under the fascia.
        FA.box(&m, V3(0.27, 0.036, 0.2), V3(0, 2.782, 0.1), light, r: 0.004)
        FA.box(&m, V3(0.24, 0.012, 0.19), V3(0, 2.76, 0.095), paint, r: 0.003)
        // Volute scrolls on both flanks, in the YZ plane.
        for s: Float in [-1, 1] {
            let x = s * 0.098
            var pts: [V3] = [], rad: [Float] = []
            let n = lite ? 12 : 22
            for k in 0...n {
                let t = Float(k) / Float(n), a = -.pi / 2 + t * 2.4 * .pi
                let r = 0.08 * (1 - 0.8 * t)
                pts.append(V3(x + s * 0.0, 2.5 + sin(a) * r, 0.1 + cos(a) * r)); rad.append(0.014 * (1 - 0.5 * t))
            }
            m.add(Prim.tube(pts, radii: rad, sides: sides, seamTile: 0.1, material: light, capEnd: true))
            FC.bead(&m, r: 0.018, at: pts.last!, light, sub: lite ? 1 : 2)
        }
        // Acanthus drop on the console face, a flattened lozenge.
        m.add(turned([(0, 0), (0.014, 0.012), (0.026, 0.06), (0.016, 0.13), (0, 0.17)], segments: lite ? 5 : 8, material: light, seamTile: 0.1),
              Xform(translation: V3(0, 2.57, 0.18), rotation: FA.q(180, FA.X) * FA.q(-25, FA.Z), scale: V3(1, 1, 0.55)))
        // Carved acanthus leaves fanning up the console flanks and a leaf crest under the abacus.
        for sd: Float in [-1, 1] {
            for k in 0..<(lite ? 3 : 5) {
                let t = Float(k) / 4
                m.add(turned([(0, 0), (0.008, 0.01), (0.017, 0.05), (0.011, 0.1), (0, 0.13)], segments: lite ? 4 : 6, material: light, seamTile: 0.1),
                      Xform(translation: V3(sd * 0.099, 2.55 + t * 0.045, 0.1 + t * 0.015), rotation: FA.q(15 + t * 30, FA.X), scale: V3(0.5, 0.9, 1)))
            }
        }
        for k in 0..<(lite ? 5 : 9) {
            let x = (Float(k) - Float(lite ? 4 : 8) / 2) * (lite ? 0.04 : 0.022)
            m.add(turned([(0, 0), (0.006, 0.004), (0.01, 0.025), (0.005, 0.045), (0, 0.055)], segments: 5, material: light, seamTile: 0.1),
                  Xform(translation: V3(x, 2.72, 0.147), rotation: FA.q(90, FA.X), scale: V3(1, 1, 0.6)))
        }
        // Raised beading around the plinth panel.
        FA.box(&m, V3(0.19, 0.005, 0.014), V3(0, 0.198, 0.0795), gilt, r: 0.0015)
        FA.box(&m, V3(0.19, 0.005, 0.014), V3(0, 0.042, 0.0795), gilt, r: 0.0015)
        // Fixings: brass screw heads in the plinth panel and shaft fillets, one rusted.
        if !lite {
            for (i, p) in [V3(-0.1, 0.4, 0.0585), V3(0.1, 0.4, 0.0585), V3(-0.1, 2.095, 0.0585), V3(0.1, 2.095, 0.0585), V3(0, 0.2, 0.0875), V3(0.07, 0.065, 0.0775)].enumerated() {
                FO.head(&m, at: p, r: 0.0055, h: 0.0035, i == 4 ? rust : brass)
            }
            // Wear: grime on the plinth, flaked paint on the reeds near knee height and the mouldings.
            for _ in 0..<7 { FO.patch(&m, cx: rng.float(-0.13...0.13), cy: rng.float(0.01...0.2), rx: rng.float(0.01...0.05), ry: rng.float(0.015...0.06), z: 0.0753, grime, rng: &rng, depth: 0.0005) }
            for _ in 0..<8 { FO.patch(&m, cx: rng.float(-0.1...0.1), cy: rng.float(0.5...1.1), rx: rng.float(0.004...0.012), ry: rng.float(0.01...0.05), z: 0.0535, bare, rng: &rng, depth: 0.0006, n: 7) }
            for _ in 0..<5 { FO.patch(&m, cx: rng.float(-0.12...0.12), cy: rng.float(0.065...0.075), rx: rng.float(0.01...0.04), ry: 0.01, z: 0.0752, bare, rng: &rng, depth: 0.0005) }
            for _ in 0..<5 { FO.patchTop(&m, cx: rng.float(-0.12...0.12), cz: rng.float(0.1...0.18), rx: rng.float(0.01...0.04), rz: rng.float(0.01...0.03), y: 2.8001, bare, rng: &rng, depth: 0.0006) }
        }
        if !lite {
            // Rain streaks: dark vertical grime lines under the capital and light chalking on the reed crests.
            for k in 0..<9 { FO.patch(&m, cx: (Float(k) - 4) * 0.0225 + rng.float(-0.003...0.003), cy: 2.0 - rng.float(0...0.12), rx: 0.0025, ry: rng.float(0.05...0.2), z: 0.0536, grime, rng: &rng, depth: 0.0004, n: 6) }
            for _ in 0..<6 { FO.patch(&m, cx: rng.float(-0.1...0.1), cy: rng.float(0.4...0.9), rx: rng.float(0.02...0.05), ry: rng.float(0.05...0.15), z: 0.0537, grime, rng: &rng, depth: 0.0003) }
        }
        groundAO(&m, height: 0.3, floor: 0.8)
        return FC.place(m)
    }
}
