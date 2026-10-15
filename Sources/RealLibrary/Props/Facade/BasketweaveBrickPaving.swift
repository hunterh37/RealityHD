import simd
import Foundation

/// Basketweave brick paving tile, 2 x 2 m: 20 x 10 x 6 cm clay brick pavers laid in pairs that
/// alternate direction every 20 cm, inside a stretcher-course border, on a sand bed with swept
/// joints, mixed tones, a stained brick or two and moss creeping in from the edge joint.
public struct BasketweaveBrickPaving: RealAsset {
    public static let id = "basketweave-brick-paving"
    public static let summary = "Basketweave brick paving tile, 2 x 2 m: clay brick pavers laid in alternating pairs inside a stretcher border, sand joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Basketweave cell (two bricks side by side), m.
    public var cell: Float = 0.2
    /// Brick thickness (m).
    public var thickness: Float = 0.06
    /// Joint gap (m).
    public var joint: Float = 0.006
    /// Brick tones (sRGB hex), Victorian stock-brick reds and browns.
    public var tones: [UInt32] = [0x9C4A36, 0x86422F, 0xAA5C44, 0x74392A, 0x8F5640]
    /// Brick material (tinted per tone).
    public var brick: MaterialKey = "paver.clay"
    /// Stained brick variant.
    public var stained: MaterialKey = "paver.clay-stained"
    /// Joint sand.
    public var sand: MaterialKey = "ground.sand"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let g = joint, top = size.y, hx = size.x / 2, hz = size.z / 2, half = cell / 2
        let keys = tones.map { "\(brick):\(String(format: "%06X", $0))" }
        func lay(_ cx: Float, _ cz: Float, _ w: Float, _ d: Float) {
            let sunk: Float = rng.chance(0.05) ? 0.004 : 0
            let mat = rng.chance(0.05) ? stained : rng.pick(keys)
            FPK.piece(&m, FPK.rect(cx, cz, w - g, d - g, yaw: rng.float(-0.006...0.006)), top: top + rng.float(-0.0015...0.0015) - sunk,
                      thick: thickness, bevel: 0.004, mat, tilt: 0.35, rng: &rng)
        }
        // Stretcher border, one brick wide, running along every edge.
        var p = -hx
        while p < hx - 0.01 { let q = min(hx, p + cell); lay((p + q) / 2, -hz + half / 2, q - p, half); lay((p + q) / 2, hz - half / 2, q - p, half); p = q }
        p = -hz + half
        while p < hz - half - 0.01 { let q = min(hz - half, p + cell); lay(-hx + half / 2, (p + q) / 2, half, q - p); lay(hx - half / 2, (p + q) / 2, half, q - p); p = q }
        // Basketweave field.
        let ix0 = -hx + half, iz0 = -hz + half
        let n = Int(((size.x - cell) / cell).rounded(.down))
        for j in 0..<n { for i in 0..<n {
            let cx = ix0 + (Float(i) + 0.5) * cell, cz = iz0 + (Float(j) + 0.5) * cell
            let horizontal = (i + j) % 2 == 0
            for k in 0..<2 {
                let o = (Float(k) - 0.5) * half
                if horizontal { lay(cx, cz + o, cell, half) } else { lay(cx + o, cz, half, cell) }
            }
        }}
        // Leftover strip when the field does not divide evenly: half-bricks.
        let used = Float(n) * cell, rem = (size.x - cell) - used
        if rem > 0.02 {
            for j in 0..<n { lay(ix0 + used + rem / 2, iz0 + (Float(j) + 0.5) * cell, rem, cell) }
        }
        for k in 0..<16 {
            var rr = rng.fork(800 + k)
            let side = rr.int(0...3), a = rr.float(-0.85...0.85), len = rr.float(0.03...0.08)
            let pt: V2 = side == 0 ? V2(a, -hz + half) : side == 1 ? V2(a, hz - half) : side == 2 ? V2(-hx + half, a) : V2(hx - half, a)
            FPK.moss(&m, at: pt, y: top - 0.006, len: len, alongX: side < 2)
        }
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: top - 0.012, sand, r: 0.003)
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: "paver.clay"), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
