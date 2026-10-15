import simd
import Foundation

/// Herringbone brick infill: a Tudor Revival half-timbered bay. Weathered oak posts, head rail and sill
/// (pegged mortise and tenon joints with proud oak trenails) frame brick nogging laid at 45 degrees in
/// herringbone, 215 x 50 mm handmade faces in 10 mm lime joints, cut at the frame. The nogging sits 15 mm
/// back from the timber face; the sill carries a weathered top and the timbers show checks.
public struct HerringboneBrickInfill: RealAsset {
    public static let id = "herringbone-brick-infill"
    public static let summary = "Herringbone brick infill, 0.8 m square: 45-degree herringbone brick nogging set in lime mortar inside a pegged weathered oak frame."
    public static let tags = ["prop", "architecture", "facade", "wood", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 2.0)

    /// Overall size (m).
    public var size = V3(0.8, 0.8, 0.1)
    /// Timber member width on the face.
    public var timber: Float = 0.1
    /// Brick face length and height (handmade Tudor brick).
    public var brickLength: Float = 0.215
    /// Brick face height.
    public var brickHeight: Float = 0.05
    /// Mortar joint.
    public var joint: Float = 0.01
    /// Nogging set-back from the timber face.
    public var setBack: Float = 0.015
    /// Oak material.
    public var oak: MaterialKey = "wood.cedar-weathered:6A6253"
    /// Brick material.
    public var brick: MaterialKey = "brick.unit-red"
    /// Mortar material.
    public var mortar: MaterialKey = "brick.mortar-lime"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z - 0.004, t = timber, j = joint
        // Frame: posts full height, sill and head rail tenoned between them (1 mm shadow gap at shoulders).
        FA.box(&m, V3(H, t, D), V3(-W / 2 + t / 2, H / 2, -D / 2), oak, r: 0.011, rot: FA.q(90, FA.Z))   // grain vertical
        FA.box(&m, V3(H, t, D), V3(W / 2 - t / 2, H / 2, -D / 2), oak, r: 0.011, rot: FA.q(90, FA.Z))
        FA.box(&m, V3(W - 2 * t - 0.002, t, D - 0.004), V3(0, t / 2, -D / 2 - 0.002), oak, r: 0.011)
        FA.box(&m, V3(W - 2 * t - 0.002, t * 0.9, D - 0.004), V3(0, H - t * 0.45, -D / 2 - 0.002), oak, r: 0.011)
        // Checks (drying splits) on the post faces.
        for (k, x) in [Float(-W / 2 + t * 0.42), W / 2 - t * 0.6].enumerated() {
            var r = rng.fork(900 + k)
            let y0 = r.float(0.15...0.3), len = r.float(0.25...0.4)
            FA.box(&m, V3(0.0035, len, 0.012), V3(x, y0 + len / 2, -0.004), "wood.cedar-weathered:3A342C", r: 0.0012)
        }
        // Trenails: two per joint, proud 4 mm, through each post into sill and head tenons.
        for sx in [Float(-1), 1] {
            for yc in [t / 2, H - t * 0.45] {
                for dy in [Float(-0.025), 0.025] {
                    var r = rng.fork(Int(yc * 1000) + Int(dy * 1000) + Int(sx))
                    let c = V3(sx * (W / 2 - t / 2), yc + dy, -0.004)
                    m.add(Prim.cylinder(radius: 0.011, height: 0.008, bevel: 0.002, segments: 9, bevelSegments: 1, material: "wood.endgrain-weathered"),
                          Xform(translation: c, rotation: FA.q(90, FA.X) * FA.q(r.float(0...60), FA.Y)))
                }
            }
        }
        // Opening.
        let ox0 = -W / 2 + t, ox1 = W / 2 - t, oy0 = t, oy1 = H - t * 0.9
        let front = -setBack, bd: Float = D - setBack - 0.012
        FM.mortar(&m, w: ox1 - ox0 + 0.004, h: oy1 - oy0 + 0.004, y0: oy0 - 0.002, recess: setBack + 0.005, back: D - 0.01, mortar)
        // Herringbone lattice (L x Wb bricks incl. joints), rotated 45 degrees so the zigzag runs horizontally.
        let L = brickLength + j, Wb = brickHeight + j
        let rot = simd_float2x2(V2(cos(Float.pi / 4), sin(Float.pi / 4)), V2(-sin(Float.pi / 4), cos(Float.pi / 4)))
        let cx = (ox0 + ox1) / 2, cy = (oy0 + oy1) / 2
        let reds: [MaterialKey] = [brick, brick, "brick.unit-red-dark", "brick.unit-red-light", "brick.unit-header"]
        var n = 0
        for a in -4...4 {
            for k in -14...14 {
                let ox = Float(a) * L + Float(k) * Wb, oy = -Float(a) * L + Float(k) * Wb
                for (u0, v0, du, dv) in [(ox, oy, L, Wb), (ox, oy + Wb, Wb, L)] {
                    let rect = [V2(u0 + j / 2, v0 + j / 2), V2(u0 + du - j / 2, v0 + j / 2), V2(u0 + du - j / 2, v0 + dv - j / 2), V2(u0 + j / 2, v0 + dv - j / 2)]
                    // Handmade bricks: each unit sits a fraction of a degree off true.
                    var jr = rng.fork(5000 + n), mid = V2(u0 + du / 2, v0 + dv / 2), tw = jr.float(-0.012...0.012)
                    let world = rect.map { p -> V2 in
                        let d = p - mid; let q = V2(d.x * cos(tw) - d.y * sin(tw), d.x * sin(tw) + d.y * cos(tw)) + mid
                        return rot * q + V2(cx, cy) }
                    let poly = FM.clip(world, minX: ox0 + j / 2, maxX: ox1 - j / 2, minY: oy0 + j / 2, maxY: oy1 - j / 2)
                    guard poly.count >= 3, abs(FM.area(poly)) > 0.0006 else { continue }
                    n += 1
                    var r = rng.fork(n)
                    FM.prism(&m, poly, front: front + r.float(-0.002...0.0015), depth: bd, r.pick(reds), bevel: 0.003)
                }
            }
        }
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
