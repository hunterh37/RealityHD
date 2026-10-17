import simd
import Foundation

/// Gravity-feed dual-action airbrush laid on its side on the bench, as one sets it down between coats:
/// 13.6 mm polished chrome barrel with a knurled handle end, head cap, tapered nozzle cap and crown needle
/// cap; a 7 ml gravity cup with a rolled rim and push-on lid; the dual-action trigger with a finger pad;
/// the air valve below it with a hex hose nut and a short black braided hose stub lying on the bench.
/// Story detail: dried red paint inside the cup and on the crown cap.
public struct Airbrush: RealAsset {
    public static let id = "airbrush"
    public static let summary = "Gravity-feed dual-action airbrush set on its side: chrome body, lidded color cup, trigger, crown cap, braided hose stub."
    public static let tags = ["prop", "workshop", "tool", "handheld", "metal"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 35, distance: 1.0, studio: true)

    /// Barrel length from the handle end to the needle tip (m).
    public var length: Float = 0.158
    /// Barrel radius (m).
    public var barrelRadius: Float = 0.0068
    /// Cup radius (m).
    public var cupRadius: Float = 0.011
    /// Body metal.
    public var chrome: MaterialKey = "metal.chrome"
    /// Hose braid.
    public var hose: MaterialKey = "fabric.nylon:1C1C1C"
    /// Paint residue color (sRGB hex).
    public var paintColor: UInt32 = 0xB3201C
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        // Build upright: barrel along +X (nozzle forward), cup up (+Y), valve down; then lay on its side.
        var u = Model(name: Self.id)
        let rb = barrelRadius, L = length
        let paint: MaterialKey = "plastic.gloss:" + String(format: "%06X", paintColor)
        let toX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
        // Barrel lathe (profile along the axis), rear at x = 0.
        let barrel: [V2] = [V2(0, 0), V2(0.0045, 0), V2(0.0056, 0.0008), V2(0.0058, 0.006), V2(0.006, 0.0068), V2(0.0063, 0.008),
                            V2(0.0063, 0.056), V2(0.006, 0.058), V2(rb - 0.0004, 0.0605), V2(rb, 0.062), V2(rb, 0.117), V2(rb - 0.0006, 0.119),
                            V2(0.006, 0.121), V2(0.006, 0.128), V2(0.0055, 0.13), V2(0.0042, 0.142), V2(0.0036, 0.145), V2(0.0044, 0.1458),
                            V2(0.0044, 0.152), V2(0.0034, 0.1545), V2(0.0014, 0.1565), V2(0.0008, L)]
        u.add(Prim.lathe(barrel, segments: 28, seamTile: 0.05, material: chrome), Xform(rotation: toX))
        // Knurled band on the handle end and seam ring at the head.
        u.add(Prim.lathe([V2(0.0059, 0.0012), V2(0.00605, 0.0016), V2(0.00605, 0.0052), V2(0.0059, 0.0056)], segments: 28, seamTile: 0.02, material: "metal.knurl-chrome"), Xform(rotation: toX))
        // Crown cap paint.
        u.add(Prim.lathe([V2(0.0045, 0.1468), V2(0.00455, 0.1475), V2(0.00455, 0.1505), V2(0.0045, 0.151)], segments: 28, seamTile: 0.02, material: paint), Xform(rotation: toX))

        // Gravity cup above the barrel at x = 0.098.
        let cx: Float = 0.098, R = cupRadius
        let cup: [V2] = [V2(0.0035, 0.004), V2(0.0045, rb - 0.0002), V2(R * 0.7, rb + 0.004), V2(R - 0.0006, rb + 0.008), V2(R, rb + 0.0095),
                         V2(R, rb + 0.024), V2(R + 0.0006, rb + 0.0248), V2(R + 0.0008, rb + 0.0258), V2(R + 0.0002, rb + 0.0264),
                         V2(R - 0.0005, rb + 0.026), V2(R - 0.0005, rb + 0.0096), V2(R * 0.68, rb + 0.0052), V2(0.0028, rb + 0.0012), V2(0, rb + 0.001)]
        u.add(Prim.lathe(cup, segments: 32, seamTile: 0.05, material: chrome), Xform(translation: V3(cx, 0, 0)))
        // Dried paint film in the bottom of the cup.
        u.add(Prim.lathe([V2(0, rb + 0.0016), V2(0.0034, rb + 0.002), V2(R * 0.66, rb + 0.0058), V2(R - 0.0006, rb + 0.0098), V2(R - 0.0006, rb + 0.0104)],
                         segments: 32, seamTile: 0.05, material: paint), Xform(translation: V3(cx, 0, 0)))
        // Push-on lid with a domed top and vent tab.
        let ly = rb + 0.0262
        u.add(Prim.lathe([V2(R - 0.0002, ly - 0.003), V2(R + 0.0011, ly - 0.0029), V2(R + 0.0012, ly), V2(R + 0.0006, ly + 0.0008),
                          V2(R * 0.6, ly + 0.0018), V2(0, ly + 0.0022)], segments: 32, seamTile: 0.05, material: chrome), Xform(translation: V3(cx, 0, 0)))
        u.add(Prim.roundedBox(V3(0.004, 0.0012, 0.0035), radius: 0.0005, bevelSegments: 1, material: chrome), Xform(translation: V3(cx - R - 0.0018, ly - 0.0006, 0)))

        // Trigger: stem through the top of the barrel and a dished finger pad.
        let tx: Float = 0.072
        u.add(Prim.cylinder(radius: 0.0022, height: 0.008, bevel: 0.0004, segments: 14, bevelSegments: 1, material: chrome), Xform(translation: V3(tx, rb - 0.001, 0)))
        u.add(Prim.superellipsoid(V3(0.0085, 0.0028, 0.0078), exponent: 3, subdivisions: 6, material: chrome,
                                  bulge: { d in d.y > 0 ? 1 - 0.25 * max(0, 1 - simd_length(V2(d.x, d.z))) : 1 }),
              Xform(translation: V3(tx - 0.0008, rb + 0.0078, 0)))
        // Air valve below the trigger, hex hose nut.
        u.add(Prim.cylinder(radius: 0.0042, height: 0.017, bevel: 0.0006, segments: 18, bevelSegments: 1, material: chrome), Xform(translation: V3(tx, -rb - 0.0155, 0)))
        u.add(Prim.cylinder(radius: 0.0056, height: 0.006, bevel: 0.0006, segments: 6, bevelSegments: 1, material: "metal.brass"), Xform(translation: V3(tx, -rb - 0.0215, 0)))
        // Braided hose stub: down out of the nut, then lying on the bench (plane z = ground in this frame).
        let ground: Float = -(R + 0.0012)
        let hr: Float = 0.0031
        let ctrl = [V3(tx, -rb - 0.021, 0), V3(tx, -rb - 0.03, -0.001), V3(tx - 0.006, -rb - 0.039, ground * 0.6),
                    V3(tx - 0.024, -rb - 0.045, ground + hr), V3(tx - 0.06, -rb - 0.042, ground + hr), V3(tx - 0.095, -rb - 0.03 + rng.float(-0.003...0.003), ground + hr)]
        let path = catmull(ctrl, per: 6)
        u.add(Prim.tube(path, radii: Array(repeating: hr, count: path.count), sides: 12, seamTile: 0.02, material: hose))
        // Crimp ferrule at the nut and a cut end ring.
        u.add(Prim.cylinder(radius: hr + 0.0006, height: 0.007, bevel: 0.0005, segments: 14, bevelSegments: 1, material: chrome), Xform(translation: V3(tx, -rb - 0.0285, 0)))
        if let end = path.last, path.count > 1 {
            let d = simd_normalize(end - path[path.count - 2])
            u.add(Prim.cylinder(radius: hr + 0.0005, height: 0.006, bevel: 0.0005, segments: 14, bevelSegments: 1, material: "metal.brass"),
                  Xform(translation: end - d * 0.005, rotation: facing(d)))
        }

        // Lay it on its side (cup toward -Z) and seat on y = 0, centred on X/Z.
        let side = u.transformed(Xform(rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
        let b = side.bounds
        var m = Model(name: Self.id)
        m.add(side, Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m)
        return LODModel(m)
    }
}
