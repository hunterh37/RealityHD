import simd
import Foundation

/// Cheese block: 12 cm long, 5 cm tall, 8 cm deep aged cheddar sealed in red wax. Built as a cheese core
/// inside a 1.4 mm wax shell, so every wax wound shows real cheese under it: the knife-cut end is a flat
/// face of paste (`food.cheddar`, knife drag ridges) framed by the wax rim, a chipped top corner lifts
/// the wax off the paste, a thumbprint dents the top, the dip leaves a soft seam ridge round the middle
/// and a pooled wax foot along the base. A paper sticker with a printed name sits on top.
/// LOD1 halves both shells and drops the sticker print.
public struct CheeseBlock: RealAsset {
    public static let id = "cheese-block"
    public static let summary = "Wax-sealed aged cheddar, 12 cm: red dipped wax over a cheese core, knife-cut end, chipped corner, thumb dent, seam, sticker."
    public static let tags = ["prop", "interior", "pantry", "food", "container"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 26, distance: 1.2, studio: true)

    /// Overall size in meters (x length, y height, z depth).
    public var size = V3(0.12, 0.05, 0.08)
    /// Wax shell thickness (m).
    public var wall: Float = 0.0014
    /// Wax coat key.
    public var wax: MaterialKey = "plastic.gloss:A3141A"
    /// Cheese paste key.
    public var cheese: MaterialKey = "food.cheddar"
    /// Sticker paper and ink keys.
    public var paper: MaterialKey = "paper.sheet:EFE6CE"
    public var ink: MaterialKey = "plastic.matte:2A2420"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, edge: 0.0034, hi: true), level(seed, edge: 0.007, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, edge: Float, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: seed)
        let h = size / 2
        let xCut = h.x
        // Story points: thumb dent on the top, chipped wax at the far top corner.
        let thumb = V3(rng.float(0.018...0.03), h.y, rng.float(-0.012...0.012))
        let chip = V3(-h.x + 0.007, h.y - 0.002, h.z - 0.006)
        let seamY = rng.float(-0.004...0.004)
        func dents(_ p: V3) -> Float {
            let dt = simd_length((p - thumb) * V3(1, 0, 1.25))
            let thumbD = dt < 0.011 ? -0.0011 * pow(1 - dt / 0.011, 2) * smoothstep(h.y * 0.5, h.y, p.y) : 0
            return thumbD
        }
        // Cheese core: flat knife-cut end at +X with drag ridges.
        var core = FoodMesh.box(size - V3(0, 2 * wall, 2 * wall), radius: 0.005, edge: edge * 2.2, extra: [[], [], []], material: cheese)
        core.deform { p in
            var q = p
            if p.x > xCut - 0.006 { q.x = xCut - 0.006 + (p.x - (xCut - 0.006)) * 0.02 + 0.0058 }
            return q + V3(0, h.y, 0)
        }
        core.displace { p, n in
            if n.x > 0.7 { return 0.00012 * sin(p.z * 2300 + 3 * Noise.perlin(p * 300, seed: sd)) + 0.00015 * Noise.perlin(p * 500, seed: sd &+ 1) }
            return dents(p) * 0.6
        }
        // Wax shell: dipped, slightly pillowed, ends flush with the cut just behind the paste.
        var shell = FoodMesh.box(size, radius: 0.0055, edge: edge, extra: [[], [seamY], []], material: wax)
        shell.deform { p in
            var q = p
            if p.x > xCut - 0.006 { q.x = xCut - 0.006 + (p.x - (xCut - 0.006)) * 0.02 + 0.0052 }
            // Pillowing of the dip and a slight sag along the length.
            let bx = 1 - pow(p.x / h.x, 2)
            q.y += 0.0008 * bx * (1 - pow(p.z / h.z, 2)) * (p.y > 0 ? 1 : 0)
            q.z *= 1 + 0.012 * bx * (1 - pow(p.y / h.y, 2))
            return q + V3(0, h.y, 0)
        }
        shell.displace { p, n in
            var d = 0.00035 * Noise.fbm(p * 90, octaves: 3, seed: sd &+ 2)
            // Dip seam: a soft raised line where the second dip met the first.
            if abs(n.y) < 0.6 { d += 0.0004 * exp(-pow((p.y - h.y - seamY) / 0.0012, 2)) }
            // Pooled wax foot along the base.
            d += 0.0007 * (1 - smoothstep(0.0, 0.004, p.y)) * (0.6 + 0.4 * Noise.perlin(p * 120, seed: sd &+ 3))
            d += dents(p)
            // Chipped corner: wax flaked away down past the paste.
            let c = simd_length((p - chip - V3(0, h.y, 0)) * V3(0.8, 1.3, 1)) + 0.0015 * Noise.perlin(p * 400, seed: sd &+ 4)
            if c < 0.009 { d -= 0.0026 * smoothstep(0, 1, (0.009 - c) / 0.003) }
            return d
        }
        var m = Model(name: Self.id)
        m.add(core)
        m.add(shell)
        // Sticker: thin paper card with the cheese name, slightly skewed.
        let skew = simd_quatf(degrees: rng.float(-6...6), axis: V3(0, 1, 0))
        let st = V3(-0.018, size.y + 0.0011, -0.008)
        m.add(Prim.roundedBox(V3(0.05, 0.0004, 0.032), radius: 0.00015, bevelSegments: 1, material: paper), Xform(translation: st, rotation: skew))
        if hi {
            let face = skew * simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))
            GroceryKit.printSmooth(&m, "CHEDDAR", height: 0.007, at: st + skew.act(V3(0, 0.00025, 0.004)), ink, rot: face, maxWidth: 0.042, weight: 1.2)
            GroceryKit.printSmooth(&m, "AGED 9 MO", height: 0.0035, at: st + skew.act(V3(0, 0.00025, 0.0115)), ink, rot: face, maxWidth: 0.03, weight: 1.0)
        }
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.01, floor: 0.6)
        return m
    }
}
