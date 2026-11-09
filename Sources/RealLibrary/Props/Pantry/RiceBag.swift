import simd
import Foundation

/// Rice bag, 2 lb: printed gloss polyethylene pillow pack 19 cm wide and 31.5 cm tall, standing on its filled
/// base. Front and back film panels bulge with the rice and pinch to a flat serrated heat seal at the top,
/// with fin seals down both sides and a flat gusset base. The film carries crinkles and folds that fan from
/// the top corners. Printed design (invented brand PADDY) over the upper panel, a green product band below
/// with a white keyline. A few grains have escaped at the base.
public struct RiceBag: RealAsset {
    public static let id = "rice-bag"
    public static let summary = "Rice bag: printed gloss PE pillow pack, crinkled film, serrated top heat seal, side fin seals, product band, spilled grains."
    public static let tags = ["prop", "interior", "pantry", "plastic"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Bag width, body height (to the seal) and filled depth at the base (m).
    public var bagWidth: Float = 0.19
    public var bagHeight: Float = 0.29
    public var bagDepth: Float = 0.07
    /// Printed film (brand field tint) and the band film.
    public var print: MaterialKey = "pkg.carton-gloss:2E7D4F"
    public var film: MaterialKey = "plastic.gloss:2C7A4C"
    public var brand = "PADDY"
    public var line = "JASMINE"
    /// Grains spilled beside the base.
    public var grains = 18
    public init() {}

    func halfW(_ y: Float) -> Float { bagWidth / 2 - 0.004 * sin(.pi * min(1, y / bagHeight)) }
    func halfD(_ y: Float) -> Float { 0.0012 + (bagDepth / 2 - 0.0012) * pow(1 - smoothstep(0.08, bagHeight, y), 0.75) }

    /// Film crinkle: soft folds fanning from the top corners plus fine wrinkles, stronger high on the bag.
    func crinkle(_ x: Float, _ y: Float, _ side: Float) -> Float {
        let hy = y / bagHeight, ph: Float = side > 0 ? 0 : 1.7
        var c: Float = 0.0011 * sin(x * 62 + y * 31 + ph) * sin(y * 47 - x * 19 + ph * 2)
        for cx: Float in [-1, 1] {
            let dx = x - cx * bagWidth / 2, dy = y - bagHeight
            let ang = atan2(dy, dx * cx)
            c += 0.0016 * sin(ang * 9 + ph) * exp(-(dx * dx + dy * dy) / 0.006)
        }
        c += 0.0007 * sin(x * 140 + sin(y * 60) * 2 + ph) * smoothstep(0.5, 1, hy)
        return 1.4 * c * (0.4 + 0.6 * hy)
    }

    func surfZ(_ x: Float, _ y: Float, _ side: Float) -> Float {
        let a = halfW(y), b = halfD(y), u = min(1, abs(x) / a)
        let z = b * pow(max(0, 1 - pow(u, 3.2)), 1 / 3.2)
        return z + crinkle(x, y, side) * min(1, z / 0.004)
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, hi: true), make(seed: seed, hi: false)], switchDistances: [3])
    }

    func make(seed: UInt64, hi: Bool) -> Model {
        typealias K = GroceryKit
        var m = Model(name: Self.id)
        let H = bagHeight, bandH: Float = 0.1, pc = hi ? 30 : 10
        for side: Float in [1, -1] {
            func pos(_ s: Float, _ y: Float) -> V3 {
                let a = halfW(y), x = side * a * sin(.pi * (s - 0.5))
                return V3(x, y, side * surfZ(x, y, side))
            }
            // Printed upper panel: one texture tile (design rows 0.32...1) on 0.19 x 0.19 m.
            m.add(K.sheet(cols: pc, rows: hi ? 28 : 10, uSpan: 0.19, vSpan: -0.19, v0: 0.19, print) { s, t in pos(s, bandH + t * (H - bandH)) })
            m.add(K.sheet(cols: pc, rows: hi ? 10 : 4, uSpan: 0.19, vSpan: bandH, film) { s, t in pos(s, t * bandH) })
            if hi {
                // White keyline at the band edge.
                m.add(K.sheet(cols: pc, rows: 1, uSpan: 0.19, vSpan: 0.002, "plastic.gloss:F4F4F0") { s, t in
                    let p = pos(s, bandH - 0.001 + t * 0.002); return p + V3(0, 0, side * 0.0003) })
            }
        }
        // Gusset base.
        m.add(K.sheet(cols: pc, rows: hi ? 6 : 2, uSpan: 0.19, vSpan: bagDepth, film) { s, t in
            let a = halfW(0), x = a * sin(.pi * (0.5 - s)), zz = surfZ(x, 0, 1)
            return V3(x, 0, zz - t * 2 * zz)
        })
        // Serrated top heat seal and side fin seals.
        m.add(K.sealBand(w: bagWidth - 0.004, h: 0.026, t: 0.0026, teeth: hi ? 70 : 6, film) { x in 0.0008 * sin(x * 30) }, Xform(translation: V3(0, H - 0.001, 0)))
        for sx: Float in [-1, 1] {
            m.add(K.sealBand(w: 0.006, h: H - 0.004, t: 0.0018, teeth: 1, film), Xform(translation: V3(sx * (halfW(H / 2) - 0.0005), 0.002, 0)))
        }
        if hi {
            let face: (Float, Float) -> Float = { x, y in surfZ(x, y, 1) }
            let px = -bagWidth / 2 + 0.7 * 0.19, py: (Float) -> Float = { bandH + ($0 - 0.32) / 0.68 * (H - bandH) }
            K.printOn(&m, brand, height: 0.02, x: px, y: py(0.815), "paper.sheet:FFFFFF", maxWidth: 0.082, weight: 1.35, lift: 0.0007, surfaceZ: face)
            K.printOn(&m, line, height: 0.012, x: px, y: py(0.69), "paper.sheet:FFFFFF", maxWidth: 0.085, weight: 1.2, lift: 0.0007, surfaceZ: face)
            K.printOn(&m, "LONG GRAIN RICE", height: 0.0095, x: 0, y: 0.056, "paper.sheet:FFFFFF", maxWidth: 0.15, weight: 1.15, lift: 0.0007, surfaceZ: face)
            K.printOn(&m, "NET WT 2 LB", height: 0.007, x: 0, y: 0.03, "paper.sheet:F2D24A", maxWidth: 0.1, weight: 1.0, lift: 0.0007, surfaceZ: face)
            // Spilled grains.
            var rng = SeededRNG(seed: seed &+ 3)
            for _ in 0..<grains {
                let p = V3(rng.float(-0.08...0.09), 0.0011, rng.float(0.037...0.05))
                m.add(Prim.superellipsoid(V3(0.0068, 0.0019, 0.0021), exponent: 2.2, subdivisions: 2, material: "plastic.matte:F1EDE2"),
                      Xform(translation: p, rotation: simd_quatf(angle: rng.float(0...3.1), axis: .up)))
            }
        }
        groundAO(&m, height: 0.03, floor: 0.7)
        return m
    }
}
