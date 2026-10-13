import simd
import Foundation

/// Twin-over-twin bunk bed, 105 x 170 x 210 cm: four square posts with caps, side rails and plywood decks, upper
/// guard rails with a ladder gap, a side ladder with round rungs, two 94 x 190 cm mattresses with piping, duvets
/// with drape and pillows. Headboard end at -Z, ladder on +X.
public struct BunkBed: RealAsset {
    public static let id = "bunk-bed"
    public static let summary = "Twin-over-twin pine bunk bed: four posts, guard rails, ladder, two mattresses with duvets and pillows."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "interior", "fabric"]
    public static let budget = 9600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.2, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.05, 1.7, 2.1)
    /// Frame lumber.
    public var wood: MaterialKey = "wood.beech-stained"
    /// Lower duvet cover.
    public var lowerDuvet: MaterialKey = "fabric.linen:8FA5B8"
    /// Upper duvet cover.
    public var upperDuvet: MaterialKey = "fabric.linen:B7A58B"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let s32 = UInt32(truncatingIfNeeded: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, L = size.z
        let post: Float = 0.065, railT: Float = 0.03
        let px = W / 2 - post / 2, pz = L / 2 - post / 2
        let mW: Float = 0.94, mL: Float = 1.9
        let lowDeck: Float = 0.34, upDeck: Float = 1.12
        let mH: Float = 0.17
        // Posts with square caps.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(post, H - 0.02, post), radius: 0.006, bevelSegments: 1, material: wood),
                  Xform(translation: V3(sx * px, (H - 0.02) / 2, sz * pz)))
            m.add(Prim.roundedBox(V3(post, 0.02, post), radius: 0.008, bevelSegments: 1, material: wood),
                  Xform(translation: V3(sx * px, H - 0.01, sz * pz)))
        }}
        // Deck frames: side rails along Z, end rails along X, plywood deck on ledgers.
        let innerX = px - post / 2, innerZ = pz - post / 2
        for deck in [lowDeck, upDeck] {
            for sx: Float in [-1, 1] {
                let (b, x) = lumber(from: V3(sx * (innerX - railT / 2), deck - 0.09, -innerZ), to: V3(sx * (innerX - railT / 2), deck - 0.09, innerZ),
                                   width: 0.18, thick: railT, up: V3(sx, 0, 0), bevel: 0.004, material: wood)
                m.add(b, x)
            }
            for sz: Float in [-1, 1] {
                let (b, x) = lumber(from: V3(-innerX, deck - 0.09, sz * (innerZ - railT / 2)), to: V3(innerX, deck - 0.09, sz * (innerZ - railT / 2)),
                                   width: 0.18, thick: railT, up: V3(0, 0, sz), bevel: 0.004, material: wood)
                m.add(b, x)
            }
            m.add(cuboid(V3(2 * innerX - 2 * railT, 0.018, 2 * innerZ - 2 * railT), material: "wood.plywood"), Xform(translation: V3(0, deck - 0.009, 0)))
            // Cross slats under the deck.
            for k in 0..<6 {
                let z = -innerZ + 0.2 + Float(k) * (2 * innerZ - 0.4) / 5
                m.add(Prim.roundedBox(V3(2 * innerX - 2 * railT, 0.02, 0.07), radius: 0.003, bevelSegments: 1, material: wood),
                      Xform(translation: V3(0, deck - 0.028, z)))
            }
            for sx: Float in [-1, 1] {
                m.add(cuboid(V3(2 * innerZ - 2 * railT, 0.025, 0.025), material: wood),
                      Xform(translation: V3(sx * (innerX - railT - 0.0125), deck - 0.0305, 0), rotation: simd_quatf(degrees: 90, axis: .up)))
            }
        }
        // Carriage bolts through each post at deck rail height.
        if detail {
            for deck in [lowDeck, upDeck] { for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                for dy: Float in [-0.05, -0.13] {
                    m.add(Prim.lathe([V2(0, 0), V2(0.011, 0), V2(0.011, 0.0015), V2(0.007, 0.003), V2(0, 0.0034)], segments: 6, seamTile: 0.03, material: "metal.steel"),
                          Xform(translation: V3(sx * (W / 2 - 0.0025), deck + dy, sz * pz), rotation: facing(V3(sx, 0, 0))))
                }
            }}}
        }
        // Upper guard rails: two rails per side, ladder gap on +X side.
        let top = upDeck + mH
        for (y0, h) in [(top + 0.05, Float(0.14)), (top + 0.27, Float(0.07))] {
            let yc = y0 + h / 2 - 0.05 + 0.05
            for sx: Float in [-1, 1] {
                let z0: Float = sx < 0 ? -innerZ : -innerZ, z1: Float = sx < 0 ? innerZ : -0.05
                let (b, x) = lumber(from: V3(sx * (innerX - railT / 2), yc, z0), to: V3(sx * (innerX - railT / 2), yc, z1), width: h, thick: railT, up: V3(sx, 0, 0), bevel: 0.004, material: wood)
                m.add(b, x)
            }
            for sz: Float in [-1, 1] {
                let (b, x) = lumber(from: V3(-innerX, yc, sz * (innerZ - railT / 2)), to: V3(innerX, yc, sz * (innerZ - railT / 2)), width: h, thick: railT, up: V3(0, 0, sz), bevel: 0.004, material: wood)
                m.add(b, x)
            }
        }
        // Side ladder: two stiles flush with the post faces, round rungs.
        let lz0: Float = 0.12, lz1: Float = 0.55
        let stileX = W / 2 - 0.0125
        for z in [lz0, lz1] {
            m.add(Prim.roundedBox(V3(0.025, upDeck + 0.18, 0.04), radius: 0.006, bevelSegments: 1, material: wood),
                  Xform(translation: V3(stileX, (upDeck + 0.18) / 2 + 0.0, z)))
        }
        var y: Float = 0.22
        while y < upDeck + 0.08 {
            m.add(Prim.cylinder(radius: 0.016, height: lz1 - lz0, bevel: 0.002, segments: 8, bevelSegments: 1, material: "wood.pine-aged"),
                  Xform(translation: V3(stileX, y, lz0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            _ = 0
            y += 0.24
        }
        // Bedding on both bunks.
        for (i, (deck, duvet)) in [(lowDeck, lowerDuvet), (upDeck, upperDuvet)].enumerated() {
            let mz = -innerZ + railT + mL / 2 + 0.005 - 0.0
            let mTop = deck + mH
            m.add(Prim.roundedBox(V3(mW, mH, mL), radius: 0.04, bevelSegments: 2, material: "fabric.linen:EFECE5"),
                  Xform(translation: V3(0, deck + mH / 2, mz - 0.01)))
            if detail {
                for yy in [mTop - 0.04, deck + 0.04] {
                    m.add(Prim.sweep(Shape2D.circle(0.004, segments: 6), along: BedroomKit.plan(mW + 0.002, mL + 0.002, y: yy, z: mz - 0.01, r: 0.04),
                                     closedPath: true, caps: false, material: "fabric.linen:EFECE5"))
                }
            }
            let dl: Float = mL - 0.5
            m.add(BedroomKit.drape(width: mW, length: dl, thick: 0.08, hang: 0.2, material: duvet, subdivisions: detail ? 8 : 5, wrinkle: 0.04, seed: s32 &+ UInt32(i) &* 11, skirt: 0.12, pleat: 0.2),
                  Xform(translation: V3(0, mTop - 0.008 + 0.0, mz - 0.01 + mL / 2 - dl / 2 + 0.0)))
            m.add(BedroomKit.pillow(width: 0.6, depth: 0.4, height: 0.14, material: "fabric.linen:F7F5F0", subdivisions: detail ? 5 : 3, seed: s32 &+ 3 &+ UInt32(i)),
                  Xform(translation: V3(0, mTop + 0.075, -innerZ + railT + 0.24), rotation: simd_quatf(degrees: -10 + rng.float(-2...2), axis: V3(1, 0, 0))))
        }
        groundAO(&m, height: 0.2, floor: 0.55)
        return m
    }

    /// Board between two points with softened edges (single bevel step); `up` is the face normal along thickness.
    func lumber(from a: V3, to b: V3, width: Float, thick: Float, up: V3, bevel: Float, material: MaterialKey) -> (Surface, Xform) {
        let d = b - a, len = simd_length(d), x = d / len
        var y = up - x * simd_dot(up, x)
        y = simd_length(y) < 1e-4 ? x.anyPerpendicular : simd_normalize(y)
        let z = simd_cross(x, y)
        return (Prim.roundedBox(V3(len, thick, width), radius: bevel, bevelSegments: 1, material: material),
                Xform(translation: (a + b) / 2, rotation: simd_quatf(simd_float3x3(x, y, z))))
    }
}
