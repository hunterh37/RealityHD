import simd
import Foundation

/// Spare siphon cloth filter lying on the table: off-white flannel wrapped over a 55 mm stainless disc frame,
/// the drawstring gathered under it with two tied ends, a pale coffee stain at the centre, and a 0.12 m ball
/// chain curled beside it ending in the coil spring and hook.
public struct SiphonClothFilter: RealAsset {
    public static let id = "siphon-cloth-filter"
    public static let summary = "Spare siphon cloth filter: flannel-wrapped steel disc, gathered drawstring, ball chain and spring hook lying beside it."
    public static let tags = ["prop", "kitchen", "fabric", "metal", "handheld"]
    public static let budget = 8500
    public static let author = "realityhd"

    /// Flannel pad radius (m).
    public var radius: Float = 0.029
    public var cloth: MaterialKey = "paper.exam:E9E1D2"
    public var stain: MaterialKey = "paper.exam:B89C7C"
    public var cord: MaterialKey = "fabric.linen:D8CDB8"
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let c = V3(-0.025, 0, 0)
        let lift: Float = 0.0025, h: Float = 0.0075
        // Flannel pad with a soft weave ripple.
        var pad = Prim.lathe(siphonPad(radius: radius, height: h), segments: 40, seamTile: 0.08, material: cloth)
        let ph = rng.float(0...6)
        pad.displace { p, _ in p.y > h * 0.6 ? 0.00018 * (sin(p.x * 170 + ph) * sin(p.z * 150 + 2 * ph) + 0.6 * sin((p.x - p.z) * 260 + ph)) : 0 }
        pad.uvs = pad.positions.map { V2($0.x + $0.y * 0.7, $0.z - $0.y * 0.5) }; pad.computeTangents()
        m.add(pad, Xform(translation: c + V3(0, lift, 0)))
        // Coffee stain on top, off centre.
        let st = siphonPad(radius: 0.013, height: 0.0003).map { V2($0.x, $0.y) }
        var sd = Prim.lathe(st, segments: 20, seamTile: 0.05, material: stain)
        sd.uvs = sd.positions.map { V2($0.x, $0.z) }; sd.computeTangents()
        m.add(sd,
              Xform(translation: c + V3(rng.float(-0.003...0.003), lift + h * 1.08 - 0.0001, rng.float(-0.003...0.003))))
        // Stainless frame edge peeking at the rim, centre boss.
        m.add(Prim.torus(major: radius - 0.0015, minor: 0.0008, segments: 32, sides: 5, material: steel), Xform(translation: c + V3(0, lift + 0.0005, 0)))
        m.add(Prim.cylinder(radius: 0.0035, height: 0.0024, bevel: 0.0006, segments: 14, material: steel), Xform(translation: c + V3(0, lift + h * 1.05, 0)))
        // Gathered skirt and drawstring under the pad.
        var skirt = Prim.torus(major: radius * 0.72, minor: 0.0028, segments: 32, sides: 6, material: cloth)
        skirt.displace { p, n in 0.0007 * sin(atan2(p.z, p.x) * 18) * max(0, n.y + 0.3) }
        m.add(skirt, Xform(translation: c + V3(0, 0.0028, 0)))
        // Drawstring ends tied in a knot and trailing onto the table toward -Z.
        let kn = c + V3(0.004, 0.0012, -radius * 0.75)
        m.add(Prim.cubeSphere(subdivisions: 2, material: cord) { $0 * V3(0.0028, 0.0018, 0.0024) }, Xform(translation: kn))
        for s: Float in [-1, 1] {
            let path = catmull([kn, kn + V3(0.006 * s, -0.0003, -0.006), kn + V3(0.01 * s + 0.004, -0.0004, -0.013), kn + V3(0.008 * s + 0.01, -0.0004, -0.019)], per: 4)
            m.add(Prim.tube(path, radii: path.map { _ in 0.0008 }, sides: 6, seamTile: 0.02, material: cord))
        }
        // Ball chain curled on the table from the pad rim.
        let start = c + V3(radius - 0.002, 0.0011, 0.004)
        let curl = [V3(0.012, 0.0011, 0.012), V3(0.03, 0.0011, 0.022), V3(0.048, 0.0011, 0.012), V3(0.05, 0.0011, -0.006), V3(0.038, 0.0011, -0.018)]
        var path = [start] + curl
        path = resample(catmull(path, per: 3), spacing: 0.0026)
        var len: Float = 0
        var last = path[0]
        for p in path {
            len += simd_length(p - last); last = p
            if len > 0.105 { break }
            m.add(Prim.cubeSphere(subdivisions: 3, material: steel) { $0 * 0.0011 }, Xform(translation: p))
        }
        // Spring and hook at the chain end, lying along the last chain direction.
        let end = last, dir = simd_normalize(path[min(path.count - 1, path.firstIndex(of: last)! )] - path[max(0, path.firstIndex(of: last)! - 2)])
        let q = simd_quatf(from: V3(0, 1, 0), to: V3(dir.x, 0, dir.z))
        m.add(Prim.helix(radius: 0.0034, pitch: 0.0011, turns: 13, wire: 0.00045, perTurn: 10, sides: 4, material: steel),
              Xform(translation: end + V3(0, 0.0034, 0) + V3(dir.x, 0, dir.z) * 0.001, rotation: q))
        let tip = end + V3(dir.x, 0, dir.z) * 0.0155
        var hook: [V3] = [V3(0, 0, 0), V3(0, 0.006, 0)]
        for i in 0...6 { let a = Float.pi + Float(i) / 6 * Float.pi; hook.append(V3(0.0025 * cos(a) + 0.0025, 0.009 + 0.0024 * -sin(a), 0)) }
        m.add(Prim.tube(hook, radii: hook.map { _ in 0.0005 }, sides: 5, seamTile: 0.05, material: steel),
              Xform(translation: tip + V3(0, 0.0034, 0), rotation: q))
        groundAO(&m, height: 0.01, floor: 0.7)
        return LODModel(m)
    }
}
