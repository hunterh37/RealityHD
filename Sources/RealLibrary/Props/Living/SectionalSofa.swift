import simd
import Foundation

/// L-shaped sectional sofa, 290 x 85 x 170 cm: left track arm, a long run with three welted seat cushions
/// and a chaise on the right (`chaiseLeft` mirrors it), a stitched back rail, four leaning back cushions
/// and six tapered walnut legs on mounting plates.
public struct SectionalSofa: RealAsset {
    public static let id = "sectional-sofa"
    public static let summary = "L-shaped sectional, 2.9 m: left track arm, chaise on the right, welted loose cushions, tapered walnut legs."
    public static let tags = ["prop", "floorplan", "living", "furniture", "fabric", "interior"]
    public static let budget = 11500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 1.2, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.9, 0.85, 1.7)
    /// Put the chaise on the left instead of the right.
    public var chaiseLeft = false
    /// Cushion fabric.
    public var cushionFabric: MaterialKey = "fabric.linen:6E7276"
    /// Frame and arm fabric.
    public var frameFabric: MaterialKey = "fabric.linen:5F6367"
    /// Leg wood.
    public var legWood: MaterialKey = "wood.walnut"
    /// Arm width in meters.
    public var armWidth: Float = 0.16
    /// Chaise width in meters.
    public var chaiseWidth: Float = 0.95
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func cushion(w: Float, t: Float, d: Float, sag: Float, exponent: Float, detail: Bool) -> Surface {
        var s = Prim.superellipsoid(V3(w, t, d), exponent: exponent, subdivisions: detail ? 7 : 4, material: cushionFabric)
        s.deform { p in
            let fx = p.x / (w / 2), fz = p.z / (d / 2)
            let dip = max(0, 1 - fx * fx) * max(0, 1 - pow(fz - 0.1, 2)) * (p.y > 0 ? 1 : 0.2)
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
        let sg: Float = chaiseLeft ? -1 : 1            // +1: chaise on +X
        let armW = armWidth, legH: Float = 0.14, deckTop: Float = 0.27, armTop: Float = 0.62, backFrameD: Float = 0.15
        let runD: Float = 0.95                          // depth of the long run
        let zBack = -D / 2, zRunFront = zBack + runD
        let cwid = chaiseWidth
        let leftEdge = -W / 2, chaiseX0 = W / 2 - cwid
        let seatX0 = leftEdge + armW
        let seatSpan = chaiseX0 - seatX0                 // three cushions here
        func X(_ x: Float) -> Float { x * sg }
        // Deck of the long run and of the chaise, back rail along the whole width.
        m.add(Prim.roundedBox(V3(W - armW + 0.02, deckTop - legH, runD), radius: 0.015, bevelSegments: 2, material: frameFabric),
              Xform(translation: V3(X(armW / 2), (legH + deckTop) / 2, zBack + runD / 2)))
        let chD = D - runD
        m.add(Prim.roundedBox(V3(cwid, deckTop - legH, chD + 0.02), radius: 0.015, bevelSegments: 2, material: frameFabric),
              Xform(translation: V3(X(chaiseX0 + cwid / 2), (legH + deckTop) / 2, zRunFront + chD / 2 - 0.01)))
        m.add(Prim.roundedBox(V3(W - armW + 0.02, armTop - deckTop + 0.03, backFrameD), radius: 0.04, bevelSegments: 3, material: frameFabric),
              Xform(translation: V3(X(armW / 2), (deckTop + armTop + 0.03) / 2, zBack + backFrameD / 2)))
        // Track arm on the long-run end.
        let ax = leftEdge + armW / 2
        m.add(Prim.roundedBox(V3(armW, armTop - legH, runD), radius: 0.028, bevelSegments: 3, material: frameFabric),
              Xform(translation: V3(X(ax), (legH + armTop) / 2, zBack + runD / 2)))
        if detail {
            let r = Shape2D.roundedRect(armW - 0.05, armTop - legH - 0.06, radius: 0.012, segments: 3)
                .map { V3(X(ax) + $0.x, (legH + armTop) / 2 + $0.y, zRunFront + 0.0008) }
            m.add(Prim.sweep(Shape2D.circle(0.003, segments: 5), along: r, closedPath: true, caps: false, material: frameFabric))
            let seam = (0...12).map { V3(X(ax) - sg * (armW / 2 - 0.045), armTop + 0.0005, zBack + 0.05 + Float($0) / 12 * (runD - 0.1)) }
            m.add(stitches(along: seam, normal: { _ in .up }, pitch: 0.02, thread: 0.0008, material: frameFabric))
            // Piped seam on the chaise end and back rail stitching.
            let end = (0...16).map { V3(X(chaiseX0) + sg * (0.04 + Float($0) / 16 * (cwid - 0.08)), deckTop - 0.06, D / 2 + 0.0008) }
            m.add(stitches(along: end, normal: { _ in V3(0, 0, 1) }, pitch: 0.02, thread: 0.0008, material: frameFabric))
            let top = (0...30).map { V3(X(leftEdge + armW + 0.03 + Float($0) / 30 * (W - armW - 0.06)), armTop + 0.03 + 0.0005, zBack + backFrameD / 2) }
            m.add(stitches(along: top, normal: { _ in .up }, pitch: 0.02, thread: 0.0008, material: frameFabric))
        }
        let gap: Float = 0.006
        // Long-run seat cushions and back cushions.
        let cw = (seatSpan - gap * 2) / 3
        let seatD = runD - backFrameD - 0.01
        var backCenters: [(Float, Float)] = []
        for i in 0..<3 {
            let cx = seatX0 + cw / 2 + Float(i) * (cw + gap)
            let pull: Float = i == 1 ? 0.012 : rng.float(0...0.004)
            m.add(cushion(w: cw, t: 0.16, d: seatD, sag: rng.float(0.012...0.022), exponent: 5.5, detail: detail),
                  Xform(translation: V3(X(cx), deckTop + 0.078, zBack + backFrameD + 0.005 + seatD / 2 + pull),
                        rotation: simd_quatf(degrees: i == 1 ? 1.2 : rng.float(-0.4...0.4), axis: .up)))
            backCenters.append((cx, cw))
        }
        // Chaise seat cushion, longer than a normal seat.
        let chSeatD = D - backFrameD - 0.012
        m.add(cushion(w: cwid - gap, t: 0.16, d: chSeatD, sag: 0.016, exponent: 5.5, detail: detail),
              Xform(translation: V3(X(chaiseX0 + cwid / 2 + gap / 2), deckTop + 0.078, zBack + backFrameD + 0.005 + chSeatD / 2)))
        backCenters.append((chaiseX0 + cwid / 2 + gap / 2, cwid - gap))
        for (i, bc) in backCenters.enumerated() {
            let lean = i == 3 ? rng.float(78...79) : rng.float(80.5...82)
            m.add(cushion(w: bc.1, t: 0.2, d: 0.44, sag: -0.012, exponent: 4.2, detail: detail),
                  Xform(translation: V3(X(bc.0), 0.626, zBack + backFrameD + 0.06), rotation: simd_quatf(degrees: lean, axis: V3(1, 0, 0))))
        }
        // Six tapered legs.
        let sq = { (h: Float) in Shape2D.roundedRect(h, h, radius: 0.004, segments: 1) }
        var legPts: [(Float, Float)] = [(leftEdge + 0.11, zBack + 0.1), (leftEdge + 0.11, zRunFront - 0.1), (chaiseX0 + 0.55 * cwid - cwid / 2 - 0.35, zBack + 0.1),
                                        (W / 2 - 0.11, zBack + 0.1), (chaiseX0 + 0.11, D / 2 - 0.1), (W / 2 - 0.11, D / 2 - 0.1)]
        legPts[2] = (chaiseX0 - 0.03, zBack + 0.1)
        for (lx, lz) in legPts {
            let base = V3(X(lx), 0, lz)
            let out = V3(sg * (lx < 0 ? -0.018 : 0.018), 0, lz > 0 ? 0.018 : -0.018)
            m.add(Prim.loft([Prim.ring(sq(0.024), y: 0, offset: base + out), Prim.ring(sq(0.032), y: 0.07, offset: base + out * 0.5),
                             Prim.ring(sq(0.042), y: legH - 0.008, offset: base)], capStart: true, capEnd: true, material: legWood))
            m.add(Prim.roundedBox(V3(0.07, 0.008, 0.07), radius: 0.002, bevelSegments: 1, material: "metal.brushed-nickel"),
                  Xform(translation: base + V3(0, legH - 0.004, 0)))
        }
        groundAO(&m, height: 0.2, floor: 0.5)
        return m
    }
}
