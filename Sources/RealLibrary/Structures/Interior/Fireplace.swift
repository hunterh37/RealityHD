import simd
import Foundation

/// Interior fireplace, 1.8 x 1.3 x 0.45 m: limestone surround with oak mantel shelf, firebrick firebox, marble hearth slab, cast-iron grate with three logs, chimney breast hint above. Wall-backed: back face at z = -depth / 2, front toward +Z, base at y = 0.
public struct Fireplace: RealAsset {
    public static let id = "fireplace"
    public static let summary = "Interior fireplace, 1.8 x 1.3 x 0.45 m: limestone surround, oak mantel, firebrick firebox with grate and logs, marble hearth."
    public static let tags = ["structure", "floorplan", "interior", "stone", "wall"]
    public static let budget = 9_600
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Width is the mantel shelf, depth includes the hearth.
    public var size = V3(1.8, 1.3, 0.45)
    /// Surround and chimney breast stone.
    public var stone: MaterialKey = "stone.limestone"
    /// Mantel shelf wood.
    public var wood: MaterialKey = "wood.oak:8F643A"
    /// Hearth slab.
    public var hearth: MaterialKey = "stone.marble-honed"
    /// Firebox lining.
    public var firebrick: MaterialKey = "brick.common:C9A47A"
    /// Grate and andirons.
    public var iron: MaterialKey = "metal.cast-iron-worn"
    public init() {}

    private func box(_ m: inout Model, _ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.004, _ q: simd_quatf? = nil) {
        let rr = min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2)
        m.add(Prim.roundedBox(sz, radius: rr, bevelSegments: 1, material: key),
              Xform(translation: c, rotation: q ?? simd_quatf(angle: 0, axis: V3(0, 1, 0))))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z
        let zb = -d / 2                                   // wall plane
        // Vertical layout.
        let hearthH: Float = 0.05
        let openW: Float = 0.9, openH: Float = 0.74
        let openTop = hearthH + openH                     // 0.79
        let lintelH: Float = 0.25
        let shelfH: Float = 0.06
        let shelfBot = openTop + lintelH                  // 1.04
        let shelfTop = shelfBot + shelfH                  // 1.10
        let surroundW: Float = 1.5
        let surroundD: Float = 0.2                        // wall plane to surround face
        let zf = zb + surroundD                           // surround front face

        // Hearth slab: marble, proud of the surround, with a slightly smaller step under it.
        box(&m, V3(1.7, hearthH, d), V3(0, hearthH / 2, 0), hearth, r: 0.006)
        // Surround legs with a stepped inner trim, header course and keystone.
        let legW = (surroundW - openW) / 2               // 0.3
        for s: Float in [-1, 1] {
            let lx = s * (openW / 2 + legW / 2)
            box(&m, V3(legW, openTop - hearthH + 0.002, surroundD), V3(lx, hearthH + (openTop - hearthH) / 2, zb + surroundD / 2), stone, r: 0.005)
            // Slim raised trim on the opening edge.
            box(&m, V3(0.035, openH + 0.01, 0.014), V3(s * (openW / 2 + 0.0175 - 0.002), hearthH + openH / 2, zf + 0.006), stone, r: 0.003)
            // Plinth block at the foot of each leg.
            box(&m, V3(legW + 0.04, 0.1, surroundD + 0.02), V3(lx, hearthH + 0.05, zb + (surroundD + 0.02) / 2), stone, r: 0.005)
        }
        box(&m, V3(surroundW, lintelH, surroundD), V3(0, openTop + lintelH / 2 - 0.001, zb + surroundD / 2), stone, r: 0.005)
        box(&m, V3(openW + 0.07, 0.035, 0.014), V3(0, openTop - 0.012, zf + 0.006), stone, r: 0.003)
        box(&m, V3(0.18, lintelH - 0.04, 0.012), V3(0, openTop + lintelH / 2, zf + 0.005), stone, r: 0.004)
        // Panel joints in the limestone: thin dark reveals.
        let joint: MaterialKey = "stone.limestone-sooted"
        for s: Float in [-1, 1] {
            box(&m, V3(0.003, lintelH - 0.01, 0.003), V3(s * 0.285, openTop + lintelH / 2, zf + 0.001), joint, r: 0.0008)
            box(&m, V3(0.003, 0.58, 0.003), V3(s * 0.6, 0.45, zf + 0.001), joint, r: 0.0008)
        }
        // Mantel shelf: oak slab on two corbels, front edge softened.
        let shelfD: Float = 0.3
        box(&m, V3(w, shelfH, shelfD), V3(0, shelfBot + shelfH / 2, zb + shelfD / 2), wood, r: 0.01)
        for s: Float in [-1, 1] {
            box(&m, V3(0.09, 0.09, 0.26), V3(s * 0.68, shelfBot - 0.045 + 0.002, zb + 0.13 + 0.015), wood, r: 0.008)
        }
        // Chimney breast hint: stone block above the shelf with a raised panel, flue cap line at the top.
        let breastW: Float = 1.2, breastD: Float = 0.14
        box(&m, V3(breastW, h - shelfTop + 0.002, breastD), V3(0, shelfTop + (h - shelfTop) / 2 - 0.001, zb + breastD / 2), stone, r: 0.004)
        box(&m, V3(0.9, 0.1, 0.012), V3(0, shelfTop + 0.1, zb + breastD + 0.005), stone, r: 0.004)
        box(&m, V3(breastW + 0.04, 0.022, breastD + 0.02), V3(0, h - 0.011, zb + (breastD + 0.02) / 2), stone, r: 0.004)

        // Firebox: floor, back wall, side walls (splayed), roof, all firebrick,.
        let fbD = surroundD - 0.01
        let fbBack = zb + 0.02
        box(&m, V3(openW, 0.025, fbD), V3(0, hearthH + 0.0125, zb + fbD / 2 + 0.005), firebrick, r: 0.003)
        // Back wall in two tints: clean firebrick low, flame-sooted above the grate.
        let sootBrick: MaterialKey = "brick.common:6E5C4C"
        let lowH: Float = 0.3
        box(&m, V3(openW - 0.14, lowH, 0.03), V3(0, hearthH + lowH / 2, fbBack + 0.005), firebrick, r: 0.003)
        box(&m, V3(openW - 0.14, openH - lowH, 0.03), V3(0, hearthH + lowH + (openH - lowH) / 2, fbBack + 0.005), sootBrick, r: 0.003)
        for s: Float in [-1, 1] {
            let q = simd_quatf(degrees: s * 14, axis: V3(0, 1, 0))
            box(&m, V3(0.03, openH, 0.2), V3(s * (openW / 2 - 0.045), hearthH + openH / 2, zb + 0.115), firebrick, r: 0.003, q)
        }
        box(&m, V3(openW, 0.03, fbD), V3(0, openTop - 0.015 + 0.001, zb + fbD / 2 + 0.005), sootBrick, r: 0.003)
        // Course lines: raised mortar-colored joints on the back wall.
        let mortar: MaterialKey = "concrete.rough:8A8176"
        for i in 1..<10 {
            box(&m, V3(openW - 0.14, 0.004, 0.004), V3(0, hearthH + 0.025 + Float(i) * 0.072, fbBack + 0.0215), mortar, r: 0.0008)
        }

        // Grate: cast-iron cradle with legs, front rail, cross bars and andiron posts.
        let gx: Float = 0.3, gy: Float = hearthH + 0.025 + 0.09
        let gz0 = zb + 0.065, gz1 = zb + 0.17
        for sx: Float in [-1, 1] {
            for z in [gz0, gz1] {
                box(&m, V3(0.018, 0.09, 0.018), V3(sx * gx, hearthH + 0.025 + 0.045, z), iron, r: 0.004)
            }
        }
        for z in [gz0, gz1] {
            box(&m, V3(gx * 2 + 0.02, 0.014, 0.016), V3(0, gy, z), iron, r: 0.004)
        }
        for i in 0..<6 {
            let x = -gx + Float(i) * (gx * 2 / 5)
            box(&m, V3(0.012, 0.012, gz1 - gz0 + 0.016), V3(x, gy + 0.001, (gz0 + gz1) / 2), iron, r: 0.003)
        }
        for sx: Float in [-1, 1] {
            let ax = sx * (gx + 0.03)
            m.add(Prim.cylinder(radius: 0.011, height: 0.24, bevel: 0.004, segments: 12, material: iron),
                  Xform(translation: V3(ax, hearthH + 0.025, gz1 + 0.02)))
            m.add(Prim.superellipsoid(V3(0.04, 0.04, 0.04), exponent: 2, subdivisions: 6, material: iron),
                  Xform(translation: V3(ax, hearthH + 0.025 + 0.255, gz1 + 0.02)))
        }
        // Logs: two charred-bark lower logs and one on top, lying along X.
        func log(_ r: Float, _ len: Float, _ c: V3, _ yaw: Float, _ key: MaterialKey) {
            let q = simd_quatf(degrees: yaw, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(0, 0, 1))
            m.add(Prim.cylinder(radius: r, height: len, bevel: 0.008, segments: 16, material: key, grainVertical: true),
                  Xform(translation: c, rotation: q))
        }
        let ly = gy + 0.007
        log(0.05, 0.56, V3(-0.01 + rng.float(-0.02...0.02), ly + 0.05, gz0 + 0.01), rng.float(-4...4), "wood.deadwood")
        log(0.055, 0.5, V3(0.02 + rng.float(-0.02...0.02), ly + 0.055, gz1 - 0.01), rng.float(-5...5), "wood.pine-aged")
        log(0.045, 0.48, V3(0.0, ly + 0.145, (gz0 + gz1) / 2), rng.float(-8...8), "wood.charred")
        // Ash bed under the grate.
        m.add(Prim.superellipsoid(V3(0.5, 0.03, 0.17), exponent: 2.5, subdivisions: 8, material: "concrete.rough:6C6862"),
              Xform(translation: V3(0, hearthH + 0.03, (gz0 + gz1) / 2)))

        groundAO(&m)
        return LODModel(m)
    }
}
