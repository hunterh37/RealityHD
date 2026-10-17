import simd
import Foundation

/// Tiered maple rack of 30 ml dropper paint bottles: two stepped side cheeks, three shelves stepping up
/// toward the back, each with a front lip and a riser board, four bottles per shelf. Bottles are white
/// plastic with the paint color showing through the lower body, a printed label band, a dropper nozzle and
/// a white screw cap. Story detail: paint dribbled down several caps and a dried paint ring on the top shelf.
public struct PaintBottleRack: RealAsset {
    public static let id = "paint-bottle-rack"
    public static let summary = "Tiered wooden rack of twelve 30 ml dropper paint bottles in mixed colors, three stepped rows of four."
    public static let tags = ["prop", "workshop", "wood", "container", "plastic"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 0.8, studio: true)

    /// Overall rack width X (m).
    public var width: Float = 0.25
    /// Rack depth Z (m).
    public var depth: Float = 0.13
    /// Shelf rise per tier (m).
    public var rise: Float = 0.032
    /// Bottle body radius (m).
    public var bottleRadius: Float = 0.0155
    /// Bottle height to the cap top (m).
    public var bottleHeight: Float = 0.072
    /// Paint colors, front-left to back-right (sRGB hex).
    public var colors: [UInt32] = [0xC0262D, 0xE8762B, 0xF2C230, 0x8DBA3A, 0x2E8B57, 0x1E5FA8,
                                   0x5B3A8E, 0xD94F8A, 0xF5F1E6, 0x202020, 0x8A5A2B, 0xB9C2C7]
    /// Rack wood.
    public var wood: MaterialKey = "wood.lumber-maple"
    /// Bottle plastic.
    public var bottlePlastic: MaterialKey = "plastic.frosted"
    public init() {}

    func hex(_ c: UInt32) -> String { String(format: "%06X", c) }

    func bottle(color: UInt32, drip: Bool, lite: Bool, rng: inout SeededRNG) -> Model {
        let sg = lite ? 10 : 16
        var m = Model(name: "bottle")
        let r = bottleRadius, H = bottleHeight
        let paint: MaterialKey = "plastic.gloss:" + hex(color)
        let fill: Float = H * rng.float(0.5...0.62)
        // Lower body: paint seen through the translucent wall.
        m.add(Prim.lathe([V2(0, 0), V2(r - 0.0015, 0), V2(r - 0.0003, 0.0004), V2(r, 0.0018), V2(r, fill)], segments: sg, seamTile: 0.1, material: paint))
        // Upper body, shoulder and neck: white plastic.
        let shoulder = H * 0.66
        m.add(Prim.lathe([V2(r, fill), V2(r, shoulder), V2(r * 0.93, shoulder + 0.004), V2(r * 0.62, shoulder + 0.008), V2(0.0072, shoulder + 0.01), V2(0.0072, shoulder + 0.012)],
                         segments: sg, seamTile: 0.1, material: bottlePlastic))
        // Label band with a color stripe.
        m.add(Prim.lathe([V2(r + 0.0002, 0.014), V2(r + 0.0003, 0.0145), V2(r + 0.0003, 0.03), V2(r + 0.0002, 0.0305)], segments: sg, seamTile: 0.1, material: "plastic.matte:EFEBE0"))
        if !lite {
            m.add(Prim.lathe([V2(r + 0.00035, 0.026), V2(r + 0.00035, 0.029)], segments: sg, seamTile: 0.1, material: "plastic.matte:" + hex(color)))
            m.add(Prim.lathe([V2(r + 0.00035, 0.016), V2(r + 0.00035, 0.018)], segments: sg, seamTile: 0.1, material: "plastic.matte:2A2A2A"))
        }
        // Dropper cap: flared skirt, tapering cone, small flat tip.
        let c0 = shoulder + 0.011, c1 = H
        m.add(Prim.lathe([V2(0.0072, c0 - 0.0004), V2(0.0094, c0), V2(0.0096, c0 + 0.0015), V2(0.0094, c0 + 0.009), V2(0.0086, c0 + 0.0105),
                          V2(0.0052, c1 - 0.0025), V2(0.0042, c1 - 0.0006), V2(0.0034, c1), V2(0, c1)], segments: sg, seamTile: 0.05, material: "plastic.matte:F4F2EC"))
        if drip && !lite {
            // Dried paint blob on the cap tip, running onto the cone.
            m.add(Prim.superellipsoid(V3(0.0092, 0.0036, 0.0088), exponent: 2.4, subdivisions: 5, material: paint), Xform(translation: V3(0.0006, c1 - 0.0004, 0)))
        }
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, lite: false), level(seed: seed, lite: true)], switchDistances: [2])
    }

    func level(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, D = depth, cheek: Float = 0.010, shelfT: Float = 0.010, tierD = D / 3
        let inner = W - 2 * cheek - 0.002
        // Shelf tops (front tier 0 is lowest).
        let top: [Float] = (0..<3).map { 0.016 + Float($0) * rise }
        // Tier z bands: front at +Z.
        let zc: [Float] = (0..<3).map { D / 2 - tierD * (Float($0) + 0.5) }

        // Side cheeks: stepped outline in (u = -z, y), extruded along X.
        // Walk from the back bottom up the back edge, then down the steps to the front.
        var cheekOutline: [V2] = [V2(D / 2, 0), V2(D / 2, top[2] + 0.014)]
        for i in (0..<3).reversed() {
            if i < 2 { cheekOutline.append(V2(-(D / 2 - tierD * Float(i + 1)), top[i] + 0.014)) }
            cheekOutline.append(V2(-(D / 2 - tierD * Float(i)), top[i] + 0.014))
        }
        cheekOutline.append(V2(-D / 2, 0))
        cheekOutline = Shape2D.rounded(cheekOutline, radius: 0.003, segments: 2)
        for s in [Float(-1), 1] {
            m.add(Prim.extrude(cheekOutline, depth: cheek, bevel: 0.0012, bevelSegments: 1, material: wood),
                  Xform(translation: V3(s * (W / 2 - cheek / 2), 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0))))
        }
        for i in 0..<3 {
            // Shelf board and riser below its front edge.
            m.add(plank(inner, tierD - 0.002, shelfT, bevel: 0.0015, material: wood), Xform(translation: V3(0, top[i] - shelfT / 2, zc[i])))
            m.add(plank(inner, top[i] - shelfT - 0.001, 0.008, bevel: 0.0012, material: wood),
                  Xform(translation: V3(0, (top[i] - shelfT) / 2, zc[i] + tierD / 2 - 0.006), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            // Front lip keeps bottles from sliding out.
            m.add(plank(inner, 0.006, 0.006, bevel: 0.0015, material: wood), Xform(translation: V3(0, top[i] + 0.003, zc[i] + tierD / 2 - 0.004)))
        }
        // Back board.
        m.add(plank(inner, top[2] + 0.004, 0.006, bevel: 0.0012, material: wood),
              Xform(translation: V3(0, (top[2] + 0.004) / 2, -D / 2 + 0.003), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))

        // Bottles: four per tier.
        let pitch = inner / 4
        for i in 0..<3 {
            for k in 0..<4 {
                let idx = i * 4 + k
                var br = rng.fork(idx)
                let b = bottle(color: colors[idx % colors.count], drip: br.chance(0.4), lite: lite, rng: &br)
                let x0: Float = -inner / 2 + pitch * (Float(k) + 0.5); let x = x0 + br.float(-0.002...0.002)
                let z = zc[i] - 0.002 + br.float(-0.002...0.002)
                m.add(b, Xform(translation: V3(x, top[i] + 0.0002, z), rotation: simd_quatf(angle: br.float(0...6.28), axis: V3(0, 1, 0))))
            }
        }
        // Dried paint ring on the top shelf between bottles.
        m.add(Prim.lathe([V2(bottleRadius - 0.0012, 0), V2(bottleRadius + 0.0004, 0.0002), V2(bottleRadius + 0.0012, 0)], segments: 22, seamTile: 0.05, material: "plastic.gloss:5B3A8E"),
              Xform(translation: V3(-inner / 2 + pitch * 2, top[2] + 0.0001, zc[2] + 0.009)))
        // Paint smears on the shelf fronts where bottles get pulled out.
        for k in 0..<5 {
            let i = k % 3, c = colors[(k * 5 + 1) % colors.count]
            let x: Float = rng.float(-inner / 2 + 0.02...inner / 2 - 0.02)
            m.add(Prim.superellipsoid(V3(rng.float(0.004...0.009), 0.0004, rng.float(0.003...0.005)), exponent: 2.2, subdivisions: 2, material: "plastic.gloss:" + hex(c)),
                  Xform(translation: V3(x, top[i] + 0.00005, zc[i] + rng.float(-0.012...0.004))))
        }
        groundAO(&m)
        return m
    }
}
