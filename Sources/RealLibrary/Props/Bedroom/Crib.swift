import simd
import Foundation

/// Baby crib, 72 x 100 x 133 cm: four square posts with turned acorn finials, 52 vertical round slats with gaps under
/// 6 cm on all four sides, top rails, lower rails and floor stretchers, a plywood deck, 66 x 127 cm mattress with
/// fitted sheet and a folded blanket. White painted finish with worn teething rails. Head end at -Z.
public struct Crib: RealAsset {
    public static let id = "crib"
    public static let summary = "Baby crib with round slats, four posts with finials, top rails, mattress, fitted sheet and a folded blanket."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "interior", "fabric"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 20, distance: 1.1, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.72, 1.0, 1.33)
    /// Painted frame.
    public var paint: MaterialKey = "wood.painted-shaker"
    /// Paint on the top rails where a teething baby chews.
    public var wornPaint: MaterialKey = "wood.painted-shaker-worn"
    /// Fitted sheet.
    public var sheet: MaterialKey = "fabric.linen:F1ECE0"
    /// Folded blanket.
    public var blanket: MaterialKey = "fabric.linen:C9DAE6"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let s32 = UInt32(truncatingIfNeeded: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, L = size.z
        let post: Float = 0.05
        let px = W / 2 - post / 2, pz = L / 2 - post / 2
        let finialH: Float = 0.05
        let postH = H - finialH
        let railT: Float = 0.026
        let topY: Float = postH - 0.06, botY: Float = 0.30
        // Posts with turned acorn finials.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(post, postH, post), radius: 0.004, bevelSegments: 1, material: paint),
                  Xform(translation: V3(sx * px, postH / 2, sz * pz)))
            m.add(turned([(0, 0), (0.016, 0), (0.019, 0.006), (0.021, 0.014), (0.016, 0.026), (0.008, 0.04), (0, 0.05)],
                         segments: 12, material: paint, grainVertical: true),
                  Xform(translation: V3(sx * px, postH, sz * pz)))
        }}
        // Rails: top (worn), lower deck rails and floor stretchers.
        let innerX = px - post / 2, innerZ = pz - post / 2
        func railX(y: Float, h: Float, z: Float, mat: MaterialKey) {
            m.add(Prim.roundedBox(V3(2 * innerX + 0.004, h, railT), radius: 0.004, bevelSegments: 1, material: mat), Xform(translation: V3(0, y, z)))
        }
        func railZ(y: Float, h: Float, x: Float, mat: MaterialKey) {
            m.add(Prim.roundedBox(V3(railT, h, 2 * innerZ + 0.004), radius: 0.004, bevelSegments: 1, material: mat), Xform(translation: V3(x, y, 0)))
        }
        for s: Float in [-1, 1] {
            railX(y: topY + 0.03, h: 0.06, z: s * (innerZ - railT / 2), mat: wornPaint)
            railZ(y: topY + 0.03, h: 0.06, x: s * (innerX - railT / 2), mat: wornPaint)
            railX(y: botY - 0.03, h: 0.06, z: s * (innerZ - railT / 2), mat: paint)
            railZ(y: botY - 0.03, h: 0.06, x: s * (innerX - railT / 2), mat: paint)
            // Floor stretchers.
            m.add(Prim.roundedBox(V3(0.025, 0.04, 2 * innerZ), radius: 0.004, bevelSegments: 1, material: paint), Xform(translation: V3(s * (px - 0.0), 0.09, 0)))
            m.add(Prim.roundedBox(V3(2 * innerX, 0.04, 0.025), radius: 0.004, bevelSegments: 1, material: paint), Xform(translation: V3(0, 0.09, s * pz)))
        }
        // Round slats on all four sides.
        let slatR: Float = 0.0095, slatLen = topY - botY
        func slat(_ x: Float, _ z: Float) {
            m.add(Prim.lathe([V2(0, 0), V2(slatR, 0), V2(slatR, slatLen), V2(0, slatLen)], segments: detail ? 8 : 6, seamTile: 0.06, material: paint, swapUV: true),
                  Xform(translation: V3(x, botY, z)))
        }
        let nz = 17, nx = 9
        for i in 0..<nz {
            let z = -innerZ + railT + (2 * innerZ - 2 * railT) * (Float(i) + 0.5) / Float(nz)
            slat(innerX - railT / 2, z); slat(-(innerX - railT / 2), z)
        }
        for i in 0..<nx {
            let x = -innerX + railT + (2 * innerX - 2 * railT) * (Float(i) + 0.5) / Float(nx)
            slat(x, innerZ - railT / 2); slat(x, -(innerZ - railT / 2))
        }
        // Mattress deck and bolt heads where rails meet posts.
        let deckY: Float = botY - 0.02
        m.add(cuboid(V3(2 * innerX - 2 * railT, 0.018, 2 * innerZ - 2 * railT), material: "wood.plywood"), Xform(translation: V3(0, deckY, 0)))
        if detail {
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { for y in [topY + 0.03, botY - 0.03] {
                m.add(Prim.lathe([V2(0, 0), V2(0.008, 0), V2(0.008, 0.0012), V2(0.005, 0.0025), V2(0, 0.0028)], segments: 6, seamTile: 0.03, material: "metal.steel"),
                      Xform(translation: V3(sx * (W / 2 - 0.0015), y, sz * pz), rotation: facing(V3(sx, 0, 0))))
            }}}
        }
        // Mattress with piping, fitted sheet, folded blanket.
        let mW = 2 * innerX - 2 * railT - 0.012, mL = 2 * innerZ - 2 * railT - 0.012, mH: Float = 0.12
        m.add(Prim.roundedBox(V3(mW, mH, mL), radius: 0.03, bevelSegments: 2, material: sheet),
              Xform(translation: V3(0, deckY + 0.009 + mH / 2, 0)))
        if detail {
            for yy in [deckY + 0.009 + mH - 0.03, deckY + 0.009 + 0.03] {
                m.add(Prim.sweep(Shape2D.circle(0.0035, segments: 6), along: BedroomKit.plan(mW + 0.001, mL + 0.001, y: yy, z: 0, r: 0.03),
                                 closedPath: true, caps: false, material: sheet))
            }
        }
        let mTop = deckY + 0.009 + mH
        var b = Prim.superellipsoid(V3(mW - 0.06, 0.05, 0.36), exponent: 4, subdivisions: detail ? 6 : 4, material: blanket)
        b.deform { p in
            var q = p
            q.y += (Noise.fbm(V3(p.x * 8, 0, p.z * 8), octaves: 2, seed: s32) - 0.5) * 0.015
            q.x += sin(p.z * 18) * 0.004
            return q
        }
        m.add(b, Xform(translation: V3(0.0, mTop + 0.02, innerZ - 0.3), rotation: simd_quatf(degrees: rng.float(-3...3), axis: .up)))
        // Fitted-sheet corner gather lines on the mattress top.
        groundAO(&m, height: 0.2, floor: 0.55)
        return m
    }
}
