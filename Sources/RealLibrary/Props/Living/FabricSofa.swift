import simd
import Foundation

/// Three-seat track-arm fabric sofa, 215 x 84 x 95 cm: square track arms with piped front panels, a
/// stitched back rail, three welted loose seat cushions with a sitting sag, three leaning back cushions
/// and four tapered walnut legs on mounting plates.
public struct FabricSofa: RealAsset {
    public static let id = "fabric-sofa"
    public static let summary = "Three-seat fabric sofa, 2.15 m: track arms, loose seat and back cushions with welts, tapered walnut legs."
    public static let tags = ["prop", "floorplan", "living", "furniture", "fabric", "wood", "interior"]
    public static let budget = 9500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.15, 0.84, 0.95)
    /// Cushion fabric.
    public var cushionFabric: MaterialKey = "fabric.linen:6E7276"
    /// Frame and arm fabric (a shade darker than the cushions).
    public var frameFabric: MaterialKey = "fabric.linen:5F6367"
    /// Leg wood.
    public var legWood: MaterialKey = "wood.walnut"
    /// Arm width in meters.
    public var armWidth: Float = 0.16
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    /// Loose cushion thin along Y with a perimeter welt top and bottom.
    func cushion(w: Float, t: Float, d: Float, sag: Float, exponent: Float, detail: Bool) -> Surface {
        var s = Prim.superellipsoid(V3(w, t, d), exponent: exponent, subdivisions: detail ? 7 : 4, material: cushionFabric)
        s.deform { p in
            let fx = p.x / (w / 2), fz = p.z / (d / 2)
            let dip = max(0, 1 - fx * fx) * max(0, 1 - pow(fz - 0.1, 2)) * (p.y > 0 ? 1 : 0.2)
            // Slumped fill: corners pull down, a soft crease crosses the cushion front.
            let corner = pow(abs(fx), 3) * pow(abs(fz), 3) * (p.y > 0 ? 0.012 : 0)
            let crease = (p.y > 0 ? 1 : 0) * exp(-pow((fz - 0.62) * 9, 2)) * 0.006 * (1 - fx * fx)
            return p - V3(0, dip * sag + corner + crease, 0)
        }
        if detail {
            for sign: Float in [1, -1] {
                let yy = sign * (t / 2 - 0.016)
                let k = pow(max(0, 1 - pow(abs(yy) / (t / 2), exponent)), 1 / exponent)
                let ring = Shape2D.roundedRect(w * k - 0.002, d * k - 0.002, radius: 0.04, segments: 2)
                    .map { V3($0.x, yy - (sign > 0 ? sag * 0.1 : 0), -$0.y) }
                s.append(Prim.sweep(Shape2D.circle(0.0045, segments: 5), along: ring, closedPath: true, caps: false, material: cushionFabric))
            }
        }
        return s
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let armW = armWidth, legH: Float = 0.14, deckTop: Float = 0.27, armTop: Float = 0.62, backFrameD: Float = 0.15
        let inner = W - 2 * armW
        // Deck (seat base) and back rail.
        m.add(Prim.roundedBox(V3(inner + 0.02, deckTop - legH, D), radius: 0.015, bevelSegments: 2, material: frameFabric),
              Xform(translation: V3(0, (legH + deckTop) / 2, 0)))
        m.add(Prim.roundedBox(V3(inner + 0.02, armTop - deckTop + 0.03, backFrameD), radius: 0.04, bevelSegments: 3, material: frameFabric),
              Xform(translation: V3(0, (deckTop + armTop + 0.03) / 2, -D / 2 + backFrameD / 2)))
        // Track arms.
        for s: Float in [-1, 1] {
            let ax = s * (W / 2 - armW / 2)
            m.add(Prim.roundedBox(V3(armW, armTop - legH, D), radius: 0.028, bevelSegments: 3, material: frameFabric),
                  Xform(translation: V3(ax, (legH + armTop) / 2, 0)))
            if detail {
                // Piped front panel on the arm face and a seam along the arm top.
                let r = Shape2D.roundedRect(armW - 0.05, armTop - legH - 0.06, radius: 0.012, segments: 3)
                    .map { V3(ax + $0.x, (legH + armTop) / 2 + $0.y, D / 2 + 0.0008) }
                m.add(Prim.sweep(Shape2D.circle(0.003, segments: 5), along: r, closedPath: true, caps: false, material: frameFabric))
                let seam = (0...12).map { V3(ax + s * (armW / 2 - 0.045), armTop + 0.0005, -D / 2 + 0.05 + Float($0) / 12 * (D - 0.1)) }
                m.add(stitches(along: seam, normal: { _ in .up }, pitch: 0.02, thread: 0.0008, material: frameFabric))
            }
        }
        // Back rail stitching along the top.
        if detail {
            let top = (0...20).map { V3(-inner / 2 + 0.03 + Float($0) / 20 * (inner - 0.06), armTop + 0.03 + 0.0005, -D / 2 + backFrameD / 2) }
            m.add(stitches(along: top, normal: { _ in .up }, pitch: 0.02, thread: 0.0008, material: frameFabric))
        }
        // Three seat and three back cushions.
        let gap: Float = 0.006
        let cw = (inner - gap * 2) / 3
        let seatD = D - backFrameD - 0.02
        for i in 0..<3 {
            let cx = (Float(i) - 1) * (cw + gap)
            let sag = rng.float(0.012...0.022)
            // Lived-in: the middle cushion is pulled forward and turned a degree.
            let pull: Float = i == 1 ? 0.012 : rng.float(0...0.004)
            m.add(cushion(w: cw, t: 0.16, d: seatD, sag: sag, exponent: 5.5, detail: detail),
                  Xform(translation: V3(cx, deckTop + 0.08 - 0.002, -D / 2 + backFrameD + 0.005 + seatD / 2 + pull),
                        rotation: simd_quatf(degrees: i == 1 ? 1.2 : rng.float(-0.4...0.4), axis: .up)))
            let lean = i == 2 ? rng.float(78...79) : rng.float(80.5...82)
            m.add(cushion(w: cw, t: 0.2, d: 0.44, sag: -0.012, exponent: 4.2, detail: detail),
                  Xform(translation: V3(cx, 0.619, -D / 2 + backFrameD + 0.06), rotation: simd_quatf(degrees: lean, axis: V3(1, 0, 0))))
        }
        // Tapered walnut legs with mount plates.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let base = V3(sx * (W / 2 - 0.11), 0, sz * (D / 2 - 0.1))
            let out = V3(sx * 0.018, 0, sz * 0.018)
            let sq = { (h: Float) in Shape2D.roundedRect(h, h, radius: 0.004, segments: 1) }
            let leg = Prim.loft([Prim.ring(sq(0.024), y: 0, offset: base + out), Prim.ring(sq(0.032), y: 0.07, offset: base + out * 0.5),
                                 Prim.ring(sq(0.042), y: legH - 0.008, offset: base)], capStart: true, capEnd: true, material: legWood)
            m.add(leg)
            m.add(Prim.roundedBox(V3(0.07, 0.008, 0.07), radius: 0.002, bevelSegments: 1, material: "metal.brushed-nickel"),
                  Xform(translation: base + V3(0, legH - 0.004, 0)))
        }}
        groundAO(&m, height: 0.2, floor: 0.5)
        return m
    }
}
