import simd
import Foundation

/// Indian sandstone paving, 2 x 2 m: riven calibrated sandstone 22 mm thick in the four-size patio
/// pack (900x600, 600x600, 600x290, 290x290 mm) laid in a random pattern on a full mortar bed with
/// 10 mm pointed cement joints. Kandla grey and Raj green flags show the typical colour banding; one
/// joint has lost pointing and grown moss.
public struct IndianSandstonePaving: RealAsset {
    public static let id = "indian-sandstone-paving"
    public static let summary = "Indian sandstone paving, 2 x 2 m: riven Kandla grey and Raj green sandstone flags in four calibrated sizes, laid on a mortar bed with pointed cement joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.8, studio: true)

    /// Overall size in meters.
    public var size = V3(2.0, 0.06, 2.0)
    /// Flag thickness (m).
    public var thickness: Float = 0.022
    /// Joint width (m).
    public var joint: Float = 0.01
    /// Tones: Kandla grey, Raj green, buff band, dark grey band.
    public var tones: [UInt32] = [0x9A968A, 0xA09E86, 0xAEA48A, 0x8E8C84, 0x9C9C84]
    /// Flag material.
    public var stone: MaterialKey = "rock.slate"
    /// Pointing mortar.
    public var mortar: MaterialKey = "concrete.smooth:8A8780"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y - 0.003, g = joint, u: Float = 0.3
        let keys = tones.map { "\(stone):\(String(format: "%06X", $0))" }
        // 0.3 m module grid; the sizes are 3x2, 2x2, 2x1, 1x1 modules (minus the joint).
        let nx = 7, nz = 7
        var used = Array(repeating: Array(repeating: false, count: nx), count: nz)
        let shapes: [(Int, Int)] = [(3, 2), (2, 3), (2, 2), (2, 1), (1, 2), (1, 1)]
        var flags: [(Int, Int, Int, Int)] = []
        for j in 0..<nz { for i in 0..<nx where !used[j][i] {
            var opts = shapes.filter { s in
                i + s.0 <= nx && j + s.1 <= nz && (0..<s.1).allSatisfy { dj in (0..<s.0).allSatisfy { di in !used[j + dj][i + di] } }
            }
            if opts.count > 2 && rng.chance(0.35) { opts.removeFirst() }
            let s = opts[0]
            for dj in 0..<s.1 { for di in 0..<s.0 { used[j + dj][i + di] = true } }
            flags.append((i, j, s.0, s.1))
        }}
        let ox = -Float(nx) * u / 2 + rng.float(-0.05...0.05), oz = -Float(nz) * u / 2 + rng.float(-0.05...0.05)
        let hx = size.x / 2 - 0.002, hz = size.z / 2 - 0.002
        for (k, f) in flags.enumerated() {
            let x0 = ox + Float(f.0) * u + g / 2, z0 = oz + Float(f.1) * u + g / 2
            let x1 = x0 + Float(f.2) * u - g, z1 = z0 + Float(f.3) * u - g
            var o = [V2(x0, z0), V2(x1, z0), V2(x1, z1), V2(x0, z1)].map { V2($0.x + rng.float(-0.002...0.002), $0.y + rng.float(-0.002...0.002)) }
            o = FPK.clip(o, x0: -hx, x1: hx, z0: -hz, z1: hz)
            guard o.count >= 3 else { continue }
            // Each flag gets its own tint so the material seed (and riven pattern) breaks at every joint.
            let base = tones[(k * 7 + rng.int(0...4)) % tones.count]
            var jr = rng.fork(7000 + k)
            let j = { (sh: UInt32) -> UInt32 in UInt32(max(0, min(255, Int((base >> sh) & 0xFF) + jr.int(-6...6)))) << sh }
            let key = "\(stone):\(String(format: "%06X", j(16) | j(8) | j(0)))"
            FPK.piece(&m, o, top: top + rng.float(-0.0015...0.0015), thick: thickness, bevel: 0.004, key, tilt: 0.6, rng: &rng)
        }
        // Pointing sits 3 mm below the arris; one joint run has lost it and grown moss.
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: top - 0.003, mortar, r: 0.002)
        GK.box(&m, V3(0, (top - thickness) / 2, 0), V3(size.x - 0.002, top - thickness, size.z - 0.002), "concrete.rough:7E7A70", r: 0.003)
        let mz = oz + u * Float(rng.int(2...5))
        for k in 0..<4 { FPK.moss(&m, at: V2(-0.6 + Float(k) * 0.22 + rng.float(-0.04...0.04), mz), y: top - 0.006, len: rng.float(0.04...0.09), alongX: true) }
        // Lichen rosettes and dirt staining, heavier toward one edge of the patio.
        for k in 0..<36 {
            var r = rng.fork(3000 + k)
            let c = V2(r.float(-0.95...0.95), r.float(-0.95...(-0.2)) * (k % 3 == 0 ? -1 : 1)), rad = r.float(0.004...0.014)
            GK.poly(&m, (0..<8).map { i in let a = Float(i) / 8 * 2 * .pi; return c + V2(cos(a), sin(a)) * rad * (1 + 0.25 * sin(a * 3 + Float(k))) },
                    top: top + 0.0015, k % 4 == 0 ? "concrete.smooth:5E5C52" : "concrete.smooth:B8B8A4", thick: 0.0004)
        }
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: keys[0]), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
