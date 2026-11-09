import simd
import Foundation

/// Hand of five ripe Cavendish bananas lying on a counter. Each finger is a curved five-ridged shell
/// (ridges fade toward the ends) that narrows into a green-brown pedicel; pedicels root in a crown band
/// with a cut, fibrous peduncle stub. Fingers sit side by side in two rows, nested like a real hand,
/// each with its own length, curvature and roll, and end in a dark dried blossom tip.
/// LOD1 halves the shell density and drops the cut-face disc.
public struct BananaBunch: RealAsset {
    public static let id = "banana-bunch"
    public static let summary = "Hand of five ripe bananas, 21 cm: curved five-ridged fingers in two nested rows, green-brown crown and cut stalk, dark blossom tips."
    public static let tags = ["prop", "grocery", "food", "fruit", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 32, distance: 1.2, studio: true)

    /// Finger length along the curve (m).
    public var length: Float = 0.19
    /// Finger max radius (m).
    public var radius: Float = 0.0175
    /// Bend radius of a finger (m); smaller curves more.
    public var bend: Float = 0.2
    /// Peel material key.
    public var peel: MaterialKey = "food.banana-peel"
    /// Crown, pedicel and stalk material key.
    public var crown: MaterialKey = "food.stem-green:6E6A38"
    /// Pedicel (finger neck) material key: peel shading to green.
    public var neck: MaterialKey = "food.banana-peel:B4B44A"
    /// Stalk cut face material key.
    public var cut: MaterialKey = "food.stem-green:B0A276"
    /// Blossom tip material key.
    public var tip: MaterialKey = "food.banana-tip"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, edge: 0.0042, hi: true), level(seed, edge: 0.0085, hi: false)], switchDistances: [2.5])
    }

    /// One finger along +Y (stem end y = 0), bent toward +X on an arc of radius `rb`.
    func finger(_ L: Float, _ r: Float, _ rb: Float, edge: Float, roll: Float, seed: UInt32) -> Surface {
        var s = FoodMesh.sections(edge: edge, length: L, seamTile: 0.06, material: peel) { t in
            // Narrow neck into the pedicel, full body, tapered blunt blossom end.
            let neck = smoothstep(0.0, 0.2, t)
            let tipT = 1 - smoothstep(0.8, 1.0, t)
            let rr = r * (0.48 + 0.52 * neck) * (0.28 + 0.72 * pow(tipT, 0.6))
            return (rr, rr, 2, .zero)
        }
        s.deform { p in
            let t = p.y / L
            let th = atan2(p.z, p.x) + roll
            let fade = smoothstep(0.08, 0.3, t) * (1 - smoothstep(0.85, 0.98, t))
            // Five ridges: flats between them sink a little.
            let k = 1 - 0.06 * fade * (0.5 - 0.5 * cos(5 * th))
            let x = p.x * k, z = p.z * k
            let phi = p.y / rb
            return V3(rb * (1 - cos(phi)) - x * cos(phi), rb * sin(phi) + x * sin(phi), z)
        }
        s.displace { p, _ in 0.00025 * Noise.fbm(p * 70, octaves: 2, seed: seed) }
        return ProduceKit.weldTangents(s)
    }

    func level(_ seed: UInt64, edge: Float, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var neckS = Surface(material: neck), peelS = Surface(material: peel), crownS = Surface(material: crown), tipS = Surface(material: tip)
        // (lateral z, row, yaw degrees): lower row of three, upper row of two nested in the grooves.
        let layout: [(Float, Float, Float)] = [(-0.037, 0, -7), (0, 0, 0), (0.037, 0, 7), (-0.019, 1, -4), (0.019, 1, 4)]
        let rowLift: Float = radius * 1.75
        var bases: [V3] = []
        for (i, (lz, row, yaw)) in layout.enumerated() {
            var r = rng.fork(i)
            let L = length * r.float(0.92...1.04) * (row > 0 ? 0.97 : 1)
            let rb = bend * r.float(0.88...1.12)
            let rr = radius * r.float(0.95...1.05)
            var f = finger(L, rr, rb, edge: edge, roll: r.float(0...1.2), seed: UInt32(truncatingIfNeeded: seed) &+ UInt32(i * 7))
            // Local +Y (length) -> world -X, local +X (bend) -> world +Y; pitch so the belly is lowest.
            let phiMax = L / rb
            let pitch = simd_quatf(angle: phiMax * 0.45, axis: V3(0, 0, 1))
            let toWorld = simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))
            let rot = simd_quatf(angle: (yaw + r.float(-2...2)) * .pi / 180, axis: V3(0, 1, 0)) * pitch * toWorld
            let base = V3(0, row * rowLift, lz)
            f.deform { p in base + rot.act(p) }
            peelS.append(f)
            bases.append(base)
            // Pedicel: from the crown into the finger neck.
            let neck = base + rot.act(V3(rb * (1 - cos(0.012 / rb)), rb * sin(0.012 / rb), 0))
            let root = V3(0.012, row * rowLift * 0.8 + 0.006, lz * 0.85)
            let ped = catmull([root, (root + neck) / 2 + V3(0, 0.002, 0), neck], per: 3)
            neckS.append(FoodMesh.tube(ped, radii: ped.indices.map { 0.0095 - 0.0032 * Float($0) / Float(ped.count - 1) }, sides: hi ? 10 : 6, endBulge: 0.9, seamTile: 0.03, material: self.neck))
            // Blossom tip: dried dark nub on the blunt end.
            let phi = L / rb
            let tipP = base + rot.act(V3(rb * (1 - cos(phi)), rb * sin(phi), 0))
            let dir = rot.act(V3(sin(phi), cos(phi), 0))
            tipS.append(FoodMesh.tube([tipP - dir * 0.004, tipP + dir * 0.0015], radii: [0.0052, 0.0034], sides: hi ? 10 : 6, endBulge: 0.5, seamTile: 0.02, material: tip))
        }
        // Crown band: the cushion the pedicels grow from, and the cut peduncle stub angled back and up.
        let zs = bases.map(\.z)
        let zMin = (zs.min() ?? 0) * 0.85, zMax = (zs.max() ?? 0) * 0.85
        let band = catmull([V3(0.014, 0.008, zMin), V3(0.02, rowLift * 0.55, 0), V3(0.014, 0.008, zMax)], per: 6)
        crownS.append(FoodMesh.tube(band, radii: band.indices.map { i in 0.011 - 0.003 * abs(Float(i) / Float(band.count - 1) - 0.5) * 2 },
                                    sides: hi ? 12 : 7, endBulge: 0.6, seamTile: 0.04, material: crown))
        let stalkA = V3(0.02, rowLift * 0.5, 0), stalkB = V3(0.038, rowLift * 0.85 + 0.004, rng.float(-0.004...0.004))
        crownS.append(FoodMesh.tube([stalkA, (stalkA + stalkB) / 2, stalkB], radii: [0.0125, 0.0118, 0.0112], sides: hi ? 12 : 7, endBulge: 0.02, seamTile: 0.04, material: crown))
        m.add(peelS)
        m.add(neckS)
        m.add(crownS)
        m.add(tipS)
        if hi {
            // Pale fibrous cut face on the stalk end.
            let n = simd_normalize(stalkB - stalkA)
            m.add(Prim.cylinder(radius: 0.0098, height: 0.0008, bevel: 0.0003, segments: 16, material: cut),
                  Xform(translation: stalkB + n * 0.0002, rotation: facing(n)))
        }
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.012, floor: 0.6)
        ProduceKit.weldAO(&m)
        return m
    }
}
