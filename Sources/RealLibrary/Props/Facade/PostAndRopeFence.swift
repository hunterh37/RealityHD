import simd
import Foundation

/// Post and rope fence: architectural facade customizer, Coastal. Parts: round posts, rope runs, rope sag, eye screws, post caps, knots, base.
public struct PostAndRopeFence: RealAsset {
    public static let id = "post-and-rope-fence"
    public static let summary = "Coastal weathered round posts with sagging manila rope through eye hooks"
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 1.0, 0.1)
    public init() {}

    /// Weathered round post (driftwood grey).
    public var post: MaterialKey = "wood.driftwood"
    /// Tar-dark lower post where it was creosoted or sits in damp sand.
    public var tarred: MaterialKey = "wood.pole-creosote"
    /// Sun-bleached end grain on post tops.
    public var endGrain: MaterialKey = "wood.driftwood-end"
    /// Three-strand manila rope.
    public var rope: MaterialKey = "wood.rattan"
    /// Galvanised eye screws.
    public var eye: MaterialKey = "metal.galvanized-aged"
    /// Rust runs below the eye screws, and dark checks.
    public var rust: MaterialKey = "metal.rust-grime"
    public var check: MaterialKey = "wood.charred"
    /// Rope sag at mid span in meters (top run, lower run).
    public var sag: V2 = V2(0.17, 0.12)

    /// Three-strand lay: radius pulses around the circumference and advances along the rope.
    private func lay(_ t: Float, _ v: Float) -> Float { 1 + 0.26 * sin(2 * .pi * (3 * t + v / 0.07)) }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let px = W / 2 - 0.05
        // Round posts: turned profile with a worn crown, a groove, and a darker foot; organic displacement.
        for sx in [-1, 1] as [Float] {
            var r = rng.fork(sx > 0 ? 1 : 2)
            let rad = r.float(0.042...0.045)
            let prof: [V2] = [V2(0.0001, 0), V2(rad * 1.04, 0), V2(rad * 1.08, 0.04), V2(rad * 1.0, 0.16), V2(rad * 0.97, 0.5), V2(rad * 0.96, 0.8),
                              V2(rad * 1.0, 0.86), V2(rad * 0.93, 0.89), V2(rad * 0.97, 0.92), V2(rad * 1.0, H - 0.04), V2(rad * 0.88, H - 0.012), V2(rad * 0.7, H - 0.002), V2(0.0001, H)]
            var ps = Prim.lathe(prof, segments: 22, seamTile: 0.2, material: post, swapUV: true).subdivided()
            let ph = r.float(0...6)
            ps.displace { p, _ in 0.0035 * sin(23 * p.y + ph + 7 * p.x) + 0.0025 * sin(61 * p.y + 5 * p.z + ph) }
            m.add(ps, Xform(translation: V3(sx * px, 0, 0)))
            // Darker foot and end-grain crown with a radial check.
            m.add(Prim.lathe([V2(0.0001, 0.001), V2(rad * 1.045, 0.001), V2(rad * 1.09, 0.04), V2(rad * 1.02, 0.15), V2(rad * 1.01, 0.16), V2(0.0001, 0.16)], segments: 18, seamTile: 0.2, material: tarred, swapUV: true),
                  Xform(translation: V3(sx * px, 0, 0)).self)
            m.add(Prim.cylinder(radius: rad * 0.66, height: 0.006, bevel: 0.002, segments: 14, bevelSegments: 1, material: endGrain), Xform(translation: V3(sx * px, H - 0.004, 0)))
            FGate.slab(&m, V3(0.004, 0.05, 0.003), V3(sx * px + 0.006, H - 0.0005, 0.0), check, rot: FA.q(-90, FA.X))
            // Long vertical checks and a knot on the weather face.
            for k in 0..<5 {
                let ang = r.float(0...6.28)
                let cx = cos(ang) * (rad * 0.97), cz = sin(ang) * (rad * 0.97)
                FGate.slab(&m, V3(0.004, r.float(0.15...0.35), 0.003), V3(sx * px + cx, r.float(0.2...0.7), cz), check, rot: FA.q(-ang * 180 / .pi + 90, FA.Y))
            }
        }
        // Eye screws: shank, ring facing along the rope, small rust run below.
        let ys: [Float] = [0.86, 0.46]
        for sx in [-1, 1] as [Float] {
            for y in ys {
                let ex = sx * (px - 0.05) * 1.0
                FA.rod(&m, V3(sx * px - sx * 0.05, y, 0.0), V3(sx * px - sx * 0.075, y, 0.0), r: 0.0035, eye, sides: 6)
                m.add(Prim.torus(major: 0.0145, minor: 0.0032, segments: 14, sides: 6, material: eye),
                      Xform(translation: V3(sx * px - sx * 0.086, y, 0.0), rotation: FA.q(90, FA.Z)))
                _ = ex
                FGate.slab(&m, V3(0.01, y * 0.1 + 0.05, 0.002), V3(sx * px - sx * 0.04, y - 0.04, 0.046), rust)
            }
        }
        // Rope runs: path with a catenary-like sag, three-strand lay, knotted over each eye, one tail hanging free.
        for (i, y) in ys.enumerated() {
            let x0 = -px + 0.086, x1 = px - 0.086
            var pts: [V3] = []
            let n = 54
            for k in 0...n {
                let t = Float(k) / Float(n)
                let x = x0 + (x1 - x0) * t
                let sy = (i == 0 ? sag.x : sag.y)
                pts.append(V3(x, y - sy * 4 * t * (1 - t), 0.0))
            }
            // Wrap over the eyes: extend past each ring with a short loop-back.
            var all = [V3(x0 - 0.05, y + 0.02, 0.0), V3(x0 - 0.02, y + 0.012, 0.0)] + pts + [V3(x1 + 0.02, y + 0.012, 0.0), V3(x1 + 0.05, y + 0.02, 0.0)]
            if i == 1 { all.insert(V3(x0 + 0.012, y - 0.2, 0.0), at: 0); all.insert(V3(x0 + 0.008, y - 0.12, 0.0), at: 1); all.insert(V3(x0 - 0.01, y - 0.04, 0.0), at: 2) }
            // Three strands wound around the rope axis: 70 mm lay, 7 mm strands.
            var dist: Float = 0
            var prev = all[0]
            var phases: [Float] = []
            for p in all { dist += simd_distance(p, prev); prev = p; phases.append(dist / 0.07 * 2 * .pi) }
            for strand in 0..<3 {
                let off = Float(strand) / 3 * 2 * .pi
                var sp: [V3] = []
                for (j, p) in all.enumerated() {
                    let a = phases[j] + off
                    sp.append(p + V3(0, cos(a), sin(a)) * 0.0066)
                }
                m.add(Prim.tube(sp, radii: Array(repeating: 0.0072, count: sp.count), sides: 6, seamTile: 0.08, material: rope, capEnd: true))
            }
            m.add(Prim.tube(all, radii: Array(repeating: 0.0062, count: all.count), sides: 6, seamTile: 0.08, material: rope, capEnd: true))
            // Knot beads and whipping at the eye ends.
            for x in [x0 - 0.0, x1 + 0.0] {
                FC.bead(&m, r: 0.016, at: V3(x, y + 0.012, 0.0), rope, sub: 3)
            }
        }
        // Wear: a bleached salt band at the post tops and drips of tar on the lower posts.
        groundAO(&m, height: 0.2, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
