import simd
import Foundation

/// Coffee bag, 340 g: flat-bottom gusseted pouch 12 x 6.5 cm, 22 cm tall, in printed gloss film
/// (invented roaster KESTREL). The filled body bulges and crinkles, the gussets pinch in to a flat serrated
/// top seal with a tear notch, a kraft tin-tie strip runs under the seal with its wire ends folded back, and a
/// one-way degassing valve with vent slots sits high on the front.
public struct CoffeeBag: RealAsset {
    public static let id = "coffee-bag"
    public static let summary = "Coffee bag: printed gloss flat-bottom pouch, crinkled body, serrated top seal, tin tie, degassing valve, tear notch."
    public static let tags = ["prop", "interior", "pantry", "paper", "metal", "plastic"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 15, studio: true)

    /// Bag width (x), height to the seal (y) and depth (z) in meters.
    public var size = V3(0.12, 0.196, 0.065)
    /// Printed film (brand field tint).
    public var print: MaterialKey = "pkg.carton-gloss:3A2418"
    /// Unprinted film for the seal and base.
    public var film: MaterialKey = "metal.aluminum-brushed:3A2A22"
    public var valve: MaterialKey = "plastic.matte:EDEBE4"
    public var tinTie: MaterialKey = "paper.screwbox-kraft"
    public var brand = "KESTREL"
    public var line = "DARK ROAST"
    public init() {}

    func halfD(_ y: Float) -> Float { 0.0012 + (size.z / 2 - 0.0012) * pow(1 - smoothstep(0.13, size.y, y), 0.8) }

    func crinkle(_ x: Float, _ y: Float, _ side: Float) -> Float {
        let hy = y / size.y, ph: Float = side > 0 ? 0.4 : 2.1
        var c: Float = 0.0009 * sin(x * 80 + y * 45 + ph) * sin(y * 66 - x * 30 + ph)
        c += 0.0011 * sin(y * 120 + sin(x * 50 + ph) * 2.5) * smoothstep(0.55, 0.95, hy)
        c += 0.0012 * exp(-pow((abs(x) - size.x / 2 * 0.82) / 0.006, 2)) * sin(y * 90 + ph)
        return 1.5 * c * (0.35 + 0.65 * hy)
    }

    func surfZ(_ x: Float, _ y: Float, _ side: Float) -> Float {
        let a = size.x / 2, u = min(1, abs(x) / a)
        let z = halfD(y) * pow(max(0, 1 - pow(u, 5)), 1 / 5)
        return z + crinkle(x, y, side) * min(1, z / 0.004)
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(hi: true), make(hi: false)], switchDistances: [3])
    }

    func make(hi: Bool) -> Model {
        typealias K = GroceryKit
        var m = Model(name: Self.id)
        let a = size.x / 2, H = size.y
        for side: Float in [1, -1] {
            // Printed body: design x 0.45...1 and rows 0.32...1 of one gloss tile over the whole face.
            m.add(K.sheet(cols: hi ? 36 : 10, rows: hi ? 40 : 10, uSpan: 0.1045, vSpan: -0.19, u0: 0.0855, v0: 0.19, print) { s, t in
                let y = t * H, x = side * a * sin(.pi * (s - 0.5))
                return V3(x, y, side * surfZ(x, y, side))
            })
        }
        // Flat base.
        m.add(K.sheet(cols: hi ? 24 : 8, rows: 4, uSpan: size.x, vSpan: size.z, film) { s, t in
            let x = a * sin(.pi * (0.5 - s)), zz = surfZ(x, 0, 1)
            return V3(x, 0, zz - t * 2 * zz)
        })
        // Serrated top seal.
        m.add(K.sealBand(w: size.x, h: 0.024, t: 0.0024, teeth: hi ? 44 : 6, film) { x in 0.0006 * sin(x * 40) }, Xform(translation: V3(0, H - 0.0012, 0)))
        // Tin tie under the seal: kraft strip, wire ends folded back.
        m.add(Prim.roundedBox(V3(size.x + 0.008, 0.0075, 0.0016), radius: 0.0006, bevelSegments: 1, material: tinTie), Xform(translation: V3(0, H + 0.006, 0.0021)))
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.0075, 0.0075, 0.0014), radius: 0.0006, bevelSegments: 1, material: tinTie),
                  Xform(translation: V3(sx * (a + 0.006), H + 0.006, -0.0005), rotation: simd_quatf(angle: sx * 1.2, axis: .up)))
        }
        // Degassing valve high on the front, tilted to the surface.
        let vy: Float = 0.168, vz = surfZ(0, vy, 1)
        let slope = (surfZ(0, vy + 0.002, 1) - surfZ(0, vy - 0.002, 1)) / 0.004
        let tilt = simd_quatf(angle: atan(slope), axis: V3(1, 0, 0)) * simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))
        let vp: [V2] = [V2(0, 0.0019), V2(0.004, 0.0019), V2(0.0048, 0.0013), V2(0.006, 0.0012), V2(0.0072, 0.0014), V2(0.0084, 0.0009), V2(0.0095, 0.0002), V2(0.0098, 0)]
        m.add(Prim.lathe(vp.reversed(), segments: hi ? 32 : 12, seamTile: 0.05, material: valve), Xform(translation: V3(0, vy, vz), rotation: tilt))
        if hi {
            for k in 0..<3 {
                m.add(Prim.roundedBox(V3(0.0045, 0.0008, 0.0006), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:2A2622"),
                      Xform(translation: V3(0, vy, vz) + tilt.act(V3(0, 0.002, 0)), rotation: tilt * simd_quatf(angle: Float(k) * .pi / 3, axis: .up)))
            }
            // Tear notch on the seal edge.
            m.add(Prim.extrude([V2(0, 0), V2(0.004, 0.002), V2(0, 0.004)], depth: 0.003, bevel: 0, material: "plastic.matte:15110E"),
                  Xform(translation: V3(-a - 0.0001, H + 0.016, 0)))
            let face: (Float, Float) -> Float = { x, y in surfZ(x, y, 1) }
            // Pill at design x 0.70 -> s 0.4545.
            let px = a * sin(.pi * (0.4545 - 0.5)), py: (Float) -> Float = { ($0 - 0.32) / 0.68 * H }
            K.printOn(&m, brand, height: 0.013, x: px, y: py(0.82), "paper.sheet:FFFFFF", maxWidth: 0.08, weight: 1.3, lift: 0.0007, surfaceZ: face)
            K.printOn(&m, line, height: 0.0085, x: px, y: py(0.69), "metal.brass-aged", maxWidth: 0.085, weight: 1.15, lift: 0.0007, surfaceZ: face)
            K.printOn(&m, "WHOLE BEAN 12 OZ", height: 0.0055, x: 0, y: 0.012, "paper.sheet:E9DFC8", maxWidth: 0.09, weight: 1.0, lift: 0.0007, surfaceZ: face)
        }
        groundAO(&m, height: 0.03, floor: 0.7)
        return m
    }
}
