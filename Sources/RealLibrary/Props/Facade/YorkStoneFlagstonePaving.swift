import simd
import Foundation

/// York stone flagstone paving tile, 2 x 2 m: riven buff sandstone flags 50-60 mm thick laid in
/// random-length coursed rows on a sand and grit bed, with tight butt joints, slight differential
/// settlement, spalled arrises on a few flags, sooted tones and moss in the joints.
public struct YorkStoneFlagstonePaving: RealAsset {
    public static let id = "york-stone-flagstone-paving"
    public static let summary = "York stone flagstone paving tile, 2 x 2 m: riven buff sandstone flags in random-length courses on a sand bed with mossy joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Flag thickness (m).
    public var thickness: Float = 0.055
    /// Joint gap (m).
    public var joint: Float = 0.012
    /// Course widths are drawn from this range (m).
    public var courseRange: ClosedRange<Float> = 0.32...0.6
    /// Flag lengths are drawn from this range (m).
    public var lengthRange: ClosedRange<Float> = 0.38...0.9
    /// Stone tones (sRGB hex): buff, grey-buff, sooted brown.
    public var tones: [UInt32] = [0xB3A68A, 0x9E957F, 0xA89A78, 0x8A8270, 0xBDB096]
    /// Flag material.
    public var stone: MaterialKey = "stone.sandstone"
    /// Bed and joint fill.
    public var bedding: MaterialKey = "ground.dirt"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let g = joint, top = size.y, hx = size.x / 2, hz = size.z / 2
        let keys = tones.map { "\(stone):\(String(format: "%06X", $0))" }
        var z = -hz
        var courses: [Float] = []
        while z < hz - 0.01 {
            var w = rng.float(courseRange)
            if hz - (z + w) < courseRange.lowerBound * 0.8 { w = hz - z }
            let z0 = z, z1 = min(hz, z + w)
            var x = -hx - rng.float(0...0.3)
            while x < hx - 0.01 {
                var l = rng.float(lengthRange)
                if hx - (x + l) < 0.15 { l = hx - x }
                let x0 = max(-hx, x), x1 = min(hx, x + l)
                // Riven flag: corners nudged a few mm so the edges are not ruled straight.
                var o: [V2] = [V2(x0 + g / 2, z0 + g / 2), V2(x1 - g / 2, z0 + g / 2), V2(x1 - g / 2, z1 - g / 2), V2(x0 + g / 2, z1 - g / 2)]
                o = o.map { V2($0.x + rng.float(-0.003...0.003), $0.y + rng.float(-0.003...0.003)) }
                // Spalled arris: clip one corner off on some flags.
                if rng.chance(0.25) {
                    let ci = rng.int(0...3), a = o[ci], b = o[(ci + 1) % 4], d = o[(ci + 3) % 4]
                    let cut1 = a + simd_normalize(b - a) * rng.float(0.03...0.07), cut2 = a + simd_normalize(d - a) * rng.float(0.02...0.05)
                    var np: [V2] = []
                    for (i, q) in o.enumerated() { if i == ci { np.append(cut2); np.append(cut1) } else { np.append(q) } }
                    o = ci == 0 ? [cut2, cut1, o[1], o[2], o[3]] : np
                }
                let th = thickness * rng.float(0.94...1.06)
                let settle: Float = rng.chance(0.15) ? rng.float(0.002...0.006) : 0
                FPK.piece(&m, o, top: top + rng.float(-0.002...0.002) - settle, thick: th, bevel: 0.006, rng.pick(keys), tilt: 0.6, rng: &rng)
                x += l
            }
            courses.append(z1)
            z = z1
        }
        // Moss and grit along course joints.
        for k in 0..<22 {
            var rr = rng.fork(900 + k)
            guard let cz = courses.dropLast().randomElement(using: &rr) else { break }
            FPK.moss(&m, at: V2(rr.float(-0.9...0.9), cz), y: top - 0.009, len: rr.float(0.04...0.12), alongX: true)
        }
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: top - 0.02, bedding, r: 0.003)
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: stone), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
