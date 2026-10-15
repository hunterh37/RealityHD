import simd
import Foundation

/// Mid-century bar cart, 80 x 90 x 45 cm: aged-brass tube frame on four casters (front pair braked), two
/// walnut-framed smoked-glass trays (the upper with a brass gallery rail), a looped push handle at the +X end, a lower
/// bottle rack, and a decanter, bottles, tumblers and an ice bucket set out on the trays.
public struct BarCart: RealAsset {
    public static let id = "bar-cart"
    public static let summary = "Bar cart, 0.8 x 0.9 x 0.45 m: aged-brass frame, two glass trays with walnut trim, push handle, casters, bottles and glassware."
    public static let tags = ["prop", "floorplan", "dining", "furniture", "metal", "glass", "wood", "interior"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 20, distance: 1.7, studio: true)

    /// Overall size in meters (x width, y height to the handle top, z depth); the open side faces +Z.
    public var size = V3(0.8, 0.9, 0.45)
    /// Frame tube radius.
    public var tubeRadius: Float = 0.0095
    /// Height of the top tray glass above the floor.
    public var topTrayY: Float = 0.7
    /// Height of the lower tray glass above the floor.
    public var lowerTrayY: Float = 0.2
    /// Frame metal.
    public var frameMaterial: MaterialKey = "metal.brass-aged"
    /// Tray frame wood.
    public var woodMaterial: MaterialKey = "wood.walnut"
    /// Tray glass.
    public var glassMaterial: MaterialKey = "glass.tinted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, R = tubeRadius
        let brass = frameMaterial
        let sides = detail ? 10 : 6
        let px = W / 2 - 0.04, pz = D / 2 - 0.045          // post centers

        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.002) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: detail ? 2 : 1, material: mat), Xform(translation: p).jittered(&rng, deg: 0.05, offset: 0.0002))
        }
        func rod(_ pts: [V3], r: Float = R, mat: MaterialKey? = nil) {
            m.add(Prim.tube(pts, radii: [Float](repeating: r, count: pts.count), sides: sides, seamTile: 0.08, material: mat ?? brass))
        }
        func rrPath(_ w: Float, _ d: Float, _ rad: Float, y: Float) -> [V3] {
            var p: [V3] = []
            for (cx, cz, a0) in [(w / 2 - rad, d / 2 - rad, Float(0)), (-(w / 2 - rad), d / 2 - rad, 90), (-(w / 2 - rad), -(d / 2 - rad), 180), (w / 2 - rad, -(d / 2 - rad), 270)] {
                for k in 0...4 {
                    let a = (a0 + Float(k) * 22.5) * .pi / 180
                    p.append(V3(cx + rad * cos(a), y, cz + rad * sin(a)))
                }
            }
            return p
        }

        // Casters: front pair braked (yaw differs), rear swivel.
        let casterH: Float = 0.075
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                caster(&m, at: V3(sx * px, 0, sz * pz), height: casterH, wheelRadius: 0.027, yaw: sz > 0 ? 0 : 90,
                       frame: "metal.chrome", wheel: "rubber", hub: "metal.brass")
            }
        }
        // Four corner posts from the casters to just above the top tray, brass ferrule at each foot.
        let postTop = topTrayY + 0.012
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let x = sx * px, z = sz * pz
                rod([V3(x, casterH, z), V3(x, postTop, z)])
                m.add(Prim.cylinder(radius: R * 1.35, height: 0.022, bevel: 0.0025, segments: sides, bevelSegments: 1, seamTile: 0.08, material: brass),
                      Xform(translation: V3(x, casterH - 0.004, z)))
                m.add(Prim.cylinder(radius: R * 1.25, height: 0.012, bevel: 0.0025, segments: sides, bevelSegments: 1, seamTile: 0.08, material: brass),
                      Xform(translation: V3(x, postTop - 0.002, z)))
            }
        }
        // Push handle: the two +X posts continue up and bend over into a U-loop (rail at 0.9 m).
        let hx = px, top = size.y - R
        let loop: [V3] = [V3(hx, postTop, -pz), V3(hx, top - 0.06, -pz), V3(hx, top - 0.018, -pz + 0.006), V3(hx, top, -pz + 0.04),
                          V3(hx, top, pz - 0.04), V3(hx, top - 0.018, pz - 0.006), V3(hx, top - 0.06, pz), V3(hx, postTop, pz)]
        rod(catmull(loop, per: 6))
        // Handle grip wrap: leather-tan sleeve at center.
        m.add(Prim.cylinder(radius: R * 1.55, height: 0.2, bevel: 0.003, segments: sides, bevelSegments: 1, seamTile: 0.08, material: "leather.tan"),
              Xform(translation: V3(hx, top, 0.1), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        // Trays: walnut frame around smoked glass, mounted between posts with brass cross rails underneath.
        func tray(y: Float, gallery: Bool) {
            let tw = W - 0.002, td = D - 0.002
            let fw: Float = 0.028, fh: Float = 0.026
            box(V3(tw, fh, fw), V3(0, y - fh / 2 + 0.004, td / 2 - fw / 2), woodMaterial)
            box(V3(tw, fh, fw), V3(0, y - fh / 2 + 0.004, -td / 2 + fw / 2), woodMaterial)
            box(V3(fw, fh, td - 2 * fw + 0.004), V3(tw / 2 - fw / 2, y - fh / 2 + 0.004, 0), woodMaterial)
            box(V3(fw, fh, td - 2 * fw + 0.004), V3(-tw / 2 + fw / 2, y - fh / 2 + 0.004, 0), woodMaterial)
            // Glass pane in the rabbet, 6 mm, plus a brass under-rail pair.
            m.add(Prim.roundedBox(V3(tw - 2 * fw + 0.016, 0.006, td - 2 * fw + 0.016), radius: 0.0015, bevelSegments: 1, material: glassMaterial),
                  Xform(translation: V3(0, y - 0.002, 0)))
            for sz: Float in [-1, 1] { rod([V3(-px, y - fh - 0.004, sz * pz), V3(px, y - fh - 0.004, sz * pz)], r: 0.006) }
            if gallery {
                m.add(Prim.sweep(Shape2D.circle(0.0045, segments: sides), along: rrPath(tw - 0.01, td - 0.01, 0.03, y: y + 0.052), closedPath: true, caps: false, material: brass))
                for (sx, sz) in [(-1, -1), (1, -1), (-1, 1), (1, 1), (0, -1), (0, 1)] as [(Float, Float)] {
                    let x = sx * (tw / 2 - 0.012), z = sz * (td / 2 - 0.012)
                    rod([V3(x, y + 0.004, z), V3(x, y + 0.052, z)], r: 0.0035)
                }
            }
        }
        tray(y: topTrayY, gallery: true)
        tray(y: lowerTrayY, gallery: false)
        // Bottle rack on the lower tray: two brass rails at the back holding bottles.
        let rackY = lowerTrayY + 0.06
        rod([V3(-px + 0.04, rackY, -pz + 0.04), V3(-0.05, rackY, -pz + 0.04)], r: 0.004)
        rod([V3(-px + 0.04, lowerTrayY + 0.004, -pz + 0.04), V3(-px + 0.04, rackY, -pz + 0.04)], r: 0.004)
        rod([V3(-0.05, lowerTrayY + 0.004, -pz + 0.04), V3(-0.05, rackY, -pz + 0.04)], r: 0.004)

        // Lathe helpers for glassware (profile r, y from the base).
        func lathe(_ prof: [V2], _ mat: MaterialKey, at p: V3, seg: Int? = nil) {
            m.add(Prim.lathe(prof, segments: seg ?? (detail ? 16 : 8), seamTile: 0.1, material: mat), Xform(translation: p))
        }
        func bottle(_ p: V3, h: Float, r: Float, glass: MaterialKey, label: MaterialKey = "paint.field-white") {
            let neckR = r * 0.3, shoulder = h * 0.58
            lathe([V2(0.0001, 0), V2(r * 0.92, 0), V2(r, 0.004), V2(r, shoulder), V2(r * 0.9, shoulder + 0.02), V2(neckR * 1.4, shoulder + 0.06), V2(neckR, shoulder + 0.09), V2(neckR, h - 0.012),
                   V2(neckR * 1.12, h - 0.01), V2(neckR * 1.12, h), V2(0.0001, h)], glass, at: p)
            lathe([V2(r + 0.0006, h * 0.18), V2(r + 0.0006, h * 0.5), V2(r - 0.001, h * 0.5), V2(r - 0.001, h * 0.18)], label, at: p)
        }
        func tumbler(_ p: V3, h: Float = 0.09, r: Float = 0.036) {
            lathe([V2(0.0001, 0.0), V2(r * 0.8, 0), V2(r * 0.82, 0.012), V2(r * 0.86, 0.012), V2(r * 0.92, h), V2(r * 0.95, h), V2(r * 0.9, h), V2(r * 0.8, 0.014), V2(0.0001, 0.014)], "glass.clear", at: p)
        }
        let topG = topTrayY + 0.004
        // Top tray: decanter, two bottles, tumblers on a small tray, ice bucket.
        bottle(V3(-0.27, topG, -0.08), h: 0.19, r: 0.036, glass: "glass.emerald", label: "paper.sheet")
        bottle(V3(-0.19, topG, 0.05), h: 0.17, r: 0.03, glass: "glass.tinted", label: "paper.sheet")
        lathe([V2(0.0001, 0), V2(0.045, 0), V2(0.062, 0.025), V2(0.07, 0.07), V2(0.058, 0.11), V2(0.026, 0.14), V2(0.019, 0.17), V2(0.021, 0.18), V2(0.0001, 0.18)], "glass.clear", at: V3(-0.07, topG, -0.04))
        lathe([V2(0.0001, 0.18), V2(0.021, 0.18), V2(0.027, 0.19), V2(0.013, 0.2), V2(0.0001, 0.2)], "glass.clear", at: V3(-0.07, topG, -0.04), seg: detail ? 12 : 8)
        for (x, z) in [(0.09, -0.05), (0.15, 0.04)] as [(Float, Float)] {
            tumbler(V3(x, topG, z))
            lathe([V2(0.0001, 0.014), V2(0.027, 0.014), V2(0.03, 0.05), V2(0.0001, 0.05)], "plastic.amber", at: V3(x, topG, z), seg: detail ? 14 : 8)
        }
        // Ice bucket: stainless-lined walnut-banded pail with lid ring.
        lathe([V2(0.0001, 0), V2(0.07, 0), V2(0.088, 0.03), V2(0.095, 0.11), V2(0.098, 0.13), V2(0.09, 0.13), V2(0.084, 0.03), V2(0.0001, 0.015)], "metal.chrome", at: V3(0.24, topG, 0.0))
        lathe([V2(0.0950, 0.05), V2(0.0958, 0.05), V2(0.0958, 0.075), V2(0.0950, 0.075)], brass, at: V3(0.24, topG, 0.0))
        // Lower tray: bottles standing in the rack, a bar book and a pitcher.
        let lowG = lowerTrayY + 0.004
        for (i, h) in [Float(0.3), 0.27, 0.32].enumerated() {
            bottle(V3(-px + 0.0 + Float(i) * 0.075 + 0.05, lowG, -pz + 0.065), h: h, r: 0.03, glass: i == 1 ? "glass.tinted" : "glass.emerald", label: "paper.sheet")
        }
        lathe([V2(0.0001, 0), V2(0.055, 0), V2(0.05, 0.1), V2(0.045, 0.19), V2(0.0001, 0.19)], "ceramic.stoneware", at: V3(0.1, lowG, 0.02))
        // Chrome cocktail shaker (body, cap, strainer top) and two lemons.
        lathe([V2(0.0001, 0), V2(0.03, 0), V2(0.04, 0.03), V2(0.042, 0.1), V2(0.036, 0.19), V2(0.036, 0.2), V2(0.0001, 0.2)], "metal.chrome", at: V3(-0.02, lowG, 0.06))
        lathe([V2(0.0001, 0.2), V2(0.036, 0.2), V2(0.03, 0.225), V2(0.012, 0.24), V2(0.01, 0.255), V2(0.0001, 0.26)], "metal.chrome", at: V3(-0.02, lowG, 0.06), seg: detail ? 14 : 8)
        for (x, z) in [(0.19, 0.08), (0.145, 0.1)] as [(Float, Float)] {
            m.add(Prim.superellipsoid(V3(0.07, 0.05, 0.05), exponent: 2.2, subdivisions: detail ? 2 : 1, material: "plastic.gloss:E4C52A"), Xform(translation: V3(x, lowG + 0.025, z)))
        }
        box(V3(0.14, 0.03, 0.1), V3(0.25, lowG + 0.015, -0.03), "book.cloth", r: 0.002)
        box(V3(0.135, 0.004, 0.096), V3(0.25, lowG + 0.012, -0.03), "paper.sheet", r: 0.0005)
        groundAO(&m, height: 0.1, floor: 0.6)
        return m
    }
}
