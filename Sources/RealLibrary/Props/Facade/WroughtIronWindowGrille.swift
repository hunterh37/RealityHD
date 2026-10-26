import simd
import Foundation

/// Spanish Colonial reja: forged square bars belled forward in the middle (reja de panza), a twisted
/// section on each bar, spear heads, scroll crest, riveted collars at the rails, lugs set into the wall.
public struct WroughtIronWindowGrille: RealAsset {
    public static let id = "wrought-iron-window-grille"
    public static let summary = "Wrought-iron reja, 1.0 x 1.2 m: bellied square bars, twisted midsection, scroll crest, collars, wall lugs."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 2.4)

    public var width: Float = 1.0
    public var height: Float = 1.2
    public var belly: Float = 0.037
    public var iron: MaterialKey = "metal.wrought-iron"
    public var rust: MaterialKey = "metal.rust"
    public var grime: MaterialKey = "metal.rust-grime"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, hw = W / 2, z0: Float = 0.03, topY: Float = 1.117
        let yLo: Float = 0.26, yHi: Float = 0.94
        func bulge(_ x: Float, _ y: Float) -> Float {
            guard y > yLo, y < yHi else { return 0 }
            let t = (y - yLo) / (yHi - yLo)
            let u = max(0, 1 - powf(x / (hw - 0.05), 2))
            return belly * powf(sinf(t * .pi), 1.5) * u
        }
        // Frame: flat bars top and bottom, square uprights, crossbars that collar the bars.
        FA.box(&m, V3(W, 0.032, 0.022), V3(0, 0.016, z0), grime, r: 0.003)
        FA.box(&m, V3(W, 0.032, 0.022), V3(0, topY - 0.016, z0), iron, r: 0.003)
        for s: Float in [-1, 1] { FA.box(&m, V3(0.028, topY, 0.022), V3(s * (hw - 0.014), topY / 2, z0), iron, r: 0.003) }
        for y in [0.2, 0.98] as [Float] { FA.box(&m, V3(W - 0.04, 0.014, 0.014), V3(0, y, z0), iron, r: 0.002) }
        let n = 9
        for i in 0..<n {
            let x = -hw + 0.09 + Float(i) * (W - 0.18) / Float(n - 1)
            // Lower and upper plain runs: square section, belled with the plan curve.
            func run(_ ya: Float, _ yb: Float, _ mat: MaterialKey) {
                let steps = 10
                var pts: [V3] = []
                for k in 0...steps {
                    let y = ya + (yb - ya) * Float(k) / Float(steps)
                    pts.append(V3(x, y, z0 + bulge(x, y)))
                }
                m.add(Prim.tube(pts, radii: Array(repeating: 0.0085, count: pts.count), sides: 4, seamTile: 0.1, material: mat, phase: .pi / 4, capEnd: true))
            }
            run(0.032, 0.19, rng.int(0...3) == 0 ? rust : grime)
            run(0.19, 0.52, iron)
            run(0.68, topY - 0.02, iron)
            // Twisted section: square blocks stepped round the bar axis.
            let ty0: Float = 0.52, ty1: Float = 0.68, tn = 8
            for k in 0..<tn {
                let y = ty0 + (Float(k) + 0.5) * (ty1 - ty0) / Float(tn)
                m.add(Prim.extrude(Shape2D.polygon(sides: 4, radius: 0.0131, rotation: .pi / 4), depth: (ty1 - ty0) / Float(tn) + 0.0012,
                                   bevel: 0.0015, bevelSegments: 1, material: iron),
                      Xform(translation: V3(x, y, z0 + bulge(x, y)), rotation: FA.q(Float(k) * 20 + 8, FA.Y) * FA.q(90, FA.X)))
            }
            // Riveted collars at both crossbars.
            for y in [0.2, 0.98] as [Float] {
                m.add(Prim.cylinder(radius: 0.0125, height: 0.022, bevel: 0.0015, segments: 8, bevelSegments: 1, material: y < 0.3 ? grime : iron),
                      Xform(translation: V3(x, y - 0.011, z0 + bulge(x, y))))
            }
            // Spear head above the top bar: forged leaf on a short neck.
            m.add(Prim.lathe([V2(0, 0), V2(0.0085, 0), V2(0.0085, 0.012), V2(0.0165, 0.032), V2(0.0145, 0.05), V2(0.0045, 0.082), V2(0, 0.092)], segments: 8, seamTile: 0.05, material: iron),
                  Xform(translation: V3(x, topY - 0.01, z0)).jittered(&rng))
        }
        // Central medallion on the belly: forged ring, cross-lugs and four scrolled tails, riveted to the bars.
        let mz = z0 + belly + 0.0085 + 0.007
        m.add(Prim.torus(major: 0.085, minor: 0.007, segments: 24, sides: 6, material: iron),
              Xform(translation: V3(0, 0.6, mz), rotation: FA.q(90, FA.X)))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            var pts: [V3] = []
            for j in 0...10 {
                let t = Float(j) / 10, r = 0.085 + 0.05 * t, ang = a + t * 0.9 * (k % 2 == 0 ? 1 : -1)
                pts.append(V3(cos(ang) * r, 0.6 + sin(ang) * r, mz))
            }
            FA.path(&m, pts, r: 0.0055, iron, sides: 6)
            rivet(&m, at: V3(cos(a) * 0.085, 0.6 + sin(a) * 0.085, mz + 0.004), normal: FA.Z, radius: 0.0055, segments: 6, material: iron)
        }
        FA.cylZ(&m, r: 0.022, h: 0.012, at: V3(0, 0.6, mz - 0.004), iron, bevel: 0.002, segments: 14)
        FC.bead(&m, r: 0.011, at: V3(0, 0.6, mz + 0.006), iron, sub: 2)
        // Scroll crest: opposed spirals between each pair of bars, below the top bar.
        for i in 0..<(n - 1) {
            let xm = -hw + 0.09 + (Float(i) + 0.5) * (W - 0.18) / Float(n - 1)
            for s: Float in [-1, 1] {
                var pts: [V3] = []
                for k in 0...14 {
                    let t = Float(k) / 14, a = t * 2.4 * .pi, r = 0.026 * (1 - t * 0.72)
                    pts.append(V3(xm + s * 0.026 + s * r * cosf(a + (s > 0 ? .pi : 0)) * -1, 1.045 + r * sinf(a), z0 + 0.002))
                }
                FA.path(&m, pts, r: 0.0034, iron, sides: 6)
            }
        }
        // Lugs: round forged pins through washers, set into the wall; rusted where they weep.
        for p in [V2(-hw + 0.022, 0.12), V2(hw - 0.022, 0.12), V2(-hw + 0.022, 1.0), V2(hw - 0.022, 1.0)] {
            FA.rod(&m, V3(p.x, p.y, 0.0), V3(p.x, p.y, z0), r: 0.0105, rust, sides: 8)
            FA.box(&m, V3(0.04, 0.04, 0.006), V3(p.x, p.y, 0.003), rust, r: 0.0015)
        }
        // Rust weep under the lower crossbar.
        for i in 0..<4 { FA.box(&m, V3(0.006, rng.float(0.05...0.11), 0.002), V3(-hw + 0.15 + Float(i) * 0.24, 0.13, z0 + 0.009), rust, r: 0.0008) }
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
