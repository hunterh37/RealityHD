import simd
import Foundation

/// BroccoliHead: everyday pantry, vegetable. A supermarket broccoli crown standing on its cut stalk:
/// a thick pale stalk with a fibrous cut base (`food.broccoli-flesh`), two trimmed leaf stubs, eight
/// primary branches that fork into twelve floret clusters packed into a domed head. Each cluster is a
/// lumpy dome of sub-florets (cellular bumps) over the bead texture of `food.broccoli`; one cluster has
/// yellowed slightly. LOD1 drops the leaf stubs and halves the cluster density.
public struct BroccoliHead: RealAsset {
    public static let id = "broccoli-head"
    public static let summary = "Broccoli crown, 13 cm: thick stalk with cut base and leaf stubs, forked branches, twelve lumpy floret clusters in a dome."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 26, distance: 1.2, studio: true)

    /// Head diameter (m).
    public var crown: Float = 0.13
    /// Stalk length below the first branch (m).
    public var stalk: Float = 0.06
    /// Floret material key.
    public var skin: MaterialKey = "food.broccoli"
    /// Yellowing floret material key.
    public var aged: MaterialKey = "food.broccoli:7A8A3A"
    /// Stalk and branch material key.
    public var accent: MaterialKey = "food.broccoli-stem"
    /// Cut stalk face material key.
    public var cutFace: MaterialKey = "food.broccoli-flesh"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, edge: 0.0041, hi: true), level(seed, edge: 0.008, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, edge: Float, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: seed)
        let W = crown / 2, H = stalk
        var stems = Surface(material: accent), buds = Surface(material: skin), old = Surface(material: aged)
        // Stalk: slightly leaning, flared at the cut, ridged lengthwise.
        let lean = V3(rng.float(-0.004...0.004), 0, rng.float(-0.004...0.004))
        let mainP = catmull([V3(0, 0.0005, 0), V3(0, H * 0.5, 0) + lean * 0.5, V3(0, H, 0) + lean], per: 4)
        var main = FoodMesh.tube(mainP, radii: mainP.indices.map { 0.0175 - 0.004 * Float($0) / Float(mainP.count - 1) }, sides: hi ? 22 : 12,
                                 endBulge: 0.02, seamTile: 0.03, material: accent)
        main.displace { p, _ in 0.0005 * sin(atan2(p.z, p.x) * 9) + 0.0003 * Noise.perlin(p * 150, seed: sd) }
        stems.append(main)
        // Cut base: a pale fibrous disc just under the stalk end.
        var m = Model(name: Self.id)
        m.add(Prim.cylinder(radius: 0.0168, height: 0.0008, bevel: 0.0003, segments: hi ? 28 : 14, material: cutFace), Xform(translation: V3(0, 0.0001, 0)))
        // Floret clusters on a dome: a top centre, an inner ring of four, an outer ring of seven.
        let domeC = V3(0, H + 0.022, 0) + lean
        var centers: [(V3, Float)] = [(domeC + V3(0, 0.034, 0), 0.021)]
        let ph = rng.float(0...6.28)
        for k in 0..<4 {
            let a = ph + Float(k) / 4 * 2 * .pi + rng.float(-0.2...0.2)
            centers.append((domeC + V3(W * 0.38 * cos(a), 0.024 + rng.float(-0.003...0.003), W * 0.38 * sin(a)), rng.float(0.019...0.022)))
        }
        for k in 0..<7 {
            let a = ph + 0.4 + Float(k) / 7 * 2 * .pi + rng.float(-0.15...0.15)
            centers.append((domeC + V3(W * 0.66 * cos(a), 0.0 + rng.float(-0.004...0.004), W * 0.66 * sin(a)), rng.float(0.017...0.021)))
        }
        let agedIndex = 5 + rng.int(0...6)
        // Primary branches: eight from the stalk top; each cluster hangs off the nearest one.
        var forks: [V3] = []
        for k in 0..<8 {
            let a = ph + Float(k) / 8 * 2 * .pi
            forks.append(V3(0, H + 0.004, 0) + lean + V3(cos(a), 0, sin(a)) * W * 0.32 + V3(0, 0.008, 0))
        }
        let top = V3(0, H - 0.004, 0) + lean
        for f in forks {
            let br = catmull([top, (top + f) / 2 + V3(0, 0.002, 0), f], per: 3)
            stems.append(FoodMesh.tube(br, radii: br.indices.map { 0.0068 - 0.0016 * Float($0) / Float(br.count - 1) }, sides: hi ? 10 : 7,
                                       endBulge: 0.4, seamTile: 0.03, material: accent))
        }
        for (i, c) in centers.enumerated() {
            let r = c.1 * 1.38
            let anchor = forks.min { simd_distance($0, c.0) < simd_distance($1, c.0) } ?? top
            let end = c.0 - V3(0, r * 0.35, 0)
            let br = catmull([anchor, (anchor + end) / 2 + V3(0, 0.003, 0), end], per: 3)
            stems.append(FoodMesh.tube(br, radii: br.indices.map { 0.0052 - 0.0016 * Float($0) / Float(br.count - 1) }, sides: hi ? 9 : 6,
                                       endBulge: 0.4, seamTile: 0.03, material: accent))
            // Cluster dome: lumpy rounded top, flatter underside, tilted outward.
            var dome = FoodMesh.revolve(edge: edge, seamTile: 0.05, material: skin) { t in
                let a = Float.pi * t
                return V2(r * sin(a) * (1 + 0.08 * sin(a * 2)), -r * 0.6 * cos(a) * (t < 0.5 ? 0.7 : 1.0))
            }
            let out = V3(c.0.x - domeC.x, 0, c.0.z - domeC.z)
            let ol = simd_length(out)
            let axis = ol > 1e-4 ? simd_normalize(V3(out.z, 0, -out.x)) : V3(1, 0, 0)
            let tilt = simd_quatf(angle: -ol / W * 0.95, axis: axis)
            let k0 = UInt32(i)
            dome.deform { p in c.0 + tilt.act(p) }
            dome.displace { p, n in
                // Sub-florets: rounded cells; the bead texture comes from the material.
                let w = Noise.worley(p * 140, seed: sd &+ 20 &+ k0)
                let cell = 0.0026 * (0.55 - min(1, w.f1 * 1.15))
                let lumps = cell + 0.0006 * Noise.perlin(p * 300, seed: sd &+ 9)
                let up = simd_dot(n, simd_normalize(c.0 - domeC + V3(0, 0.04, 0)))
                return up > -0.1 ? lumps : lumps * 0.3
            }
            if i == agedIndex { old.append(dome) } else { buds.append(dome) }
        }
        // Trimmed leaf stubs on the stalk.
        if hi {
            for k in 0..<2 {
                let a = ph + Float(k) * 2.6 + 1
                let d = V3(cos(a), 0, sin(a))
                let s0 = V3(0, H * (0.35 + 0.25 * Float(k)), 0) + d * 0.014
                let path = [s0, s0 + d * 0.008 + V3(0, 0.006, 0), s0 + d * 0.013 + V3(0, 0.014, 0)]
                var stub = FoodMesh.tube(path, radii: [0.0042, 0.0034, 0.0028], sides: 9, endBulge: 0.05, seamTile: 0.03, material: accent)
                stub.deform { p in
                    // Flatten into a petiole: thin across, wide along the stalk.
                    let side = V3(-d.z, 0, d.x)
                    let off = p - s0
                    let across = simd_dot(off, side)
                    return p - side * across * 0.45
                }
                stems.append(stub)
                m.add(Prim.cylinder(radius: 0.0024, height: 0.0005, bevel: 0.0002, segments: 12, material: cutFace),
                      Xform(translation: path[2], rotation: facing(simd_normalize(path[2] - path[1]))))
            }
        }
        m.add(stems)
        m.add(buds)
        if !old.isEmpty { m.add(old) }
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.012, floor: 0.6)
        return m
    }
}
