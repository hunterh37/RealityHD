import simd
import Foundation

/// Archery shooting table: club range tournament table: 1.8 x 0.75 m top at 0.90 m, chamfered plank top, felt mat strip, worn varnish, rear lip so bows do not roll. Parts: table top, canvas mat, legs, cross braces, lower shelf, bow rail, arrow tube slots, hooks.
public struct BowTable: RealAsset {
    public static let id = "bow-table"
    public static let summary = "Archery shooting table, 2.4 m: pine plank top with canvas mat, stained legs, lower shelf, rear lip and arrow tube slots."
    public static let tags = ["prop", "archery", "furniture", "wood", "outdoor"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.4, 0.9, 0.8)
    /// Top surface height (mat top) in meters.
    public var topY: Float = 0.90
    /// Rear lip height above the top in meters.
    public var lipHeight: Float = 0.02
    /// Material keys.
    public var topMaterial: MaterialKey = "wood.lumber-pine"
    public var frameMaterial: MaterialKey = "wood.pine-aged"
    public var shelfMaterial: MaterialKey = "wood.pine-aged"
    public var matMaterial: MaterialKey = "fabric.canvas:4F5F45"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2
        func pl(_ l: Float, _ w: Float, _ t: Float, bevel: Float, material: MaterialKey) -> Surface {
            Prim.roundedBox(V3(l, t, w), radius: bevel, bevelSegments: 1, material: material)
        }
        let matT: Float = 0.003, plankT: Float = 0.035
        let plankTop = topY - matT
        let legX: Float = hx - 0.10, legZ: Float = hz - 0.06
        let rot90 = simd_quatf(degrees: 90, axis: V3(0, 1, 0))

        // Top: five planks along X with hairline gaps.
        let pw = size.z / 5
        for i in 0..<5 {
            let z = -hz + pw * (Float(i) + 0.5)
            m.add(pl(size.x, pw - 0.002, plankT, bevel: 0.004, material: topMaterial),
                  Xform(translation: V3(0, plankTop - plankT / 2, z)).jittered(&rng, deg: 0.05, offset: 0.0002))
        }
        // Underside cleats.
        for sx: Float in [-1, 1] {
            m.add(pl(size.z - 0.1, 0.07, 0.03, bevel: 0.003, material: frameMaterial),
                  Xform(translation: V3(sx * (hx - 0.28), plankTop - plankT - 0.015, 0), rotation: rot90))
        }
        // Canvas mat strip.
        m.add(pl(2.1, 0.58, matT, bevel: 0.0008, material: matMaterial),
              Xform(translation: V3(0, plankTop + matT / 2, -0.02)))
        // Rear lip (back edge, z+), outside the clear zone.
        let lipZ = hz - 0.022
        m.add(pl(size.x - 0.02, 0.04, lipHeight, bevel: 0.004, material: topMaterial),
              Xform(translation: V3(0, plankTop + lipHeight / 2, lipZ)))
        // Legs, aprons.
        let legH = plankTop - plankT
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                m.add(pl(legH, 0.06, 0.06, bevel: 0.004, material: frameMaterial),
                      Xform(translation: V3(sx * legX, legH / 2, sz * legZ), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))).jittered(&rng, deg: 0.2, offset: 0.0008))
                // foot chamfer cap
                m.add(Prim.roundedBox(V3(0.066, 0.012, 0.066), radius: 0.004, bevelSegments: 1, material: "wood.weathered"),
                      Xform(translation: V3(sx * legX, 0.006, sz * legZ)))
            }
        }
        let apronY = plankTop - plankT - 0.05
        for sz: Float in [-1, 1] {
            m.add(pl(legX * 2, 0.024, 0.10, bevel: 0.003, material: frameMaterial),
                  Xform(translation: V3(0, apronY, sz * (legZ - 0.003))).jittered(&rng, deg: 0.1, offset: 0.0005))
            m.add(pl(legX * 2, 0.02, 0.07, bevel: 0.003, material: frameMaterial),
                  Xform(translation: V3(0, 0.22, sz * legZ)))
        }
        for sx: Float in [-1, 1] {
            m.add(pl(legZ * 2, 0.024, 0.10, bevel: 0.003, material: frameMaterial),
                  Xform(translation: V3(sx * legX, apronY, 0), rotation: rot90))
            m.add(pl(legZ * 2, 0.02, 0.07, bevel: 0.003, material: frameMaterial),
                  Xform(translation: V3(sx * legX, 0.22, 0), rotation: rot90))
            // end-frame diagonal brace
            let (b, bx) = board(from: V3(sx * legX, 0.26, -legZ + 0.03), to: V3(sx * legX, apronY - 0.03, legZ - 0.03),
                                width: 0.05, thick: 0.02, up: V3(sx, 0, 0), bevel: 0.003, material: frameMaterial)
            m.add(b, bx.jittered(&rng, deg: 0.2, offset: 0.0005))
        }
        // Rear X brace.
        for (a, b) in [(-1, 1), (1, -1)] as [(Float, Float)] {
            let (s, x) = board(from: V3(a * (legX - 0.05), 0.26, legZ + 0.0125), to: V3(b * (legX - 0.05), apronY - 0.04, legZ + 0.0125),
                               width: 0.045, thick: 0.018, up: V3(0, 0, 1), bevel: 0.003, material: frameMaterial)
            m.add(s, x)
        }
        // Lower shelf.
        for i in 0..<3 {
            let w: Float = 0.2
            m.add(pl(legX * 2 - 0.07, w, 0.02, bevel: 0.003, material: shelfMaterial),
                  Xform(translation: V3(0, 0.265, (Float(i) - 1) * (w + 0.002))).jittered(&rng, deg: 0.1, offset: 0.0005))
        }
        // Shelf wear: stain rings, scuff blocks.
        m.add(Prim.torus(major: 0.045, minor: 0.0007, segments: 32, sides: 4, material: "wood.charred"), Xform(translation: V3(-0.45, 0.2757, 0.1)))
        m.add(Prim.torus(major: 0.038, minor: 0.0006, segments: 32, sides: 4, material: "wood.charred"), Xform(translation: V3(0.5, 0.2757, -0.12)))
        m.add(Prim.roundedBox(V3(0.09, 0.012, 0.035), radius: 0.003, bevelSegments: 1, material: "wood.pine-aged"),
              Xform(translation: V3(0.75, 0.281, 0.15), rotation: simd_quatf(degrees: 20, axis: V3(0, 1, 0))))
        // Top wear: ring stains on mat and nicks on the plank margin (flush, no relief above topY).
        for (cx, cz, r) in [(0.45, -0.1, 0.037), (0.38, -0.06, 0.037), (-0.6, 0.12, 0.033)] as [(Float, Float, Float)] {
            m.add(Prim.torus(major: r, minor: 0.0005, segments: 32, sides: 4, material: "wood.charred"),
                  Xform(translation: V3(cx, topY + 0.0003, cz)))
        }
        for i in 0..<9 {
            let sg: Float = i % 2 == 0 ? -1 : 1
            let x = rng.float(-1.1...1.1), z = sg * rng.float(0.31...0.34) + (sg > 0 ? -0.025 : 0)
            m.add(cuboid(V3(rng.float(0.008...0.022), 0.0008, rng.float(0.003...0.007)), material: "wood.charred"),
                  Xform(translation: V3(x, plankTop - 0.0003, z), rotation: simd_quatf(degrees: rng.float(-40...40), axis: V3(0, 1, 0))))
        }
        // Front apron (z-): arrow tube slots and brass bow hooks.
        let frontZ = -(legZ - 0.003) - 0.012
        for i in 0..<4 {
            let x = -0.42 + Float(i) * 0.14 + 0.0
            let xc = x + 0.0
            m.add(Prim.torus(major: 0.026, minor: 0.0035, segments: 20, sides: 6, material: "metal.galvanized"),
                  Xform(translation: V3(xc, apronY, frontZ - 0.002), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.0235, height: 0.004, bevel: 0.0005, segments: 16, bevelSegments: 1, material: "rubber.tire"),
                  Xform(translation: V3(xc, apronY, frontZ - 0.002), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        }
        for sx: Float in [-1, 1] {
            let hx0 = sx * 0.78
            m.add(Prim.roundedBox(V3(0.05, 0.07, 0.004), radius: 0.0015, bevelSegments: 1, material: "metal.brass-aged"),
                  Xform(translation: V3(hx0, apronY, frontZ - 0.002)))
            let pts: [V3] = [V3(0, -0.015, 0), V3(0, -0.015, -0.03), V3(0, -0.012, -0.055), V3(0, 0.003, -0.07), V3(0, 0.025, -0.07), V3(0, 0.04, -0.062)]
            let hp = catmull(pts, per: 6)
            m.add(Prim.tube(hp, radii: [Float](repeating: 0.0065, count: hp.count), sides: 8, seamTile: 0.1, material: "metal.brass-aged"),
                  Xform(translation: V3(hx0, apronY, frontZ - 0.004)))
            for dx: Float in [0.016] {
                hexBolt(&m, at: V3(hx0 + dx, apronY + 0.025, frontZ - 0.004), normal: V3(0, 0, -1), size: 0.006, material: "metal.brass")
            }
        }
        groundAO(&m)
        return LODModel(m)
    }
}
