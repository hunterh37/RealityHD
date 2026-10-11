import simd
import Foundation

/// Leather wall-hugger recliner in the upright pose, 92 x 102 x 97 cm: seven-channel stitched back and
/// headrest, pillow arms with piped fronts, a sagging seat cushion, the footrest folded under the seat
/// front as a padded panel, a side release handle on the right arm and a black plastic base rail.
public struct ReclinerChair: RealAsset {
    public static let id = "recliner-chair"
    public static let summary = "Leather recliner, upright: channel-stitched back, pillow arms, closed footrest front, side release handle."
    public static let tags = ["prop", "floorplan", "living", "furniture", "leather", "interior"]
    public static let budget = 9600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.1, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.92, 1.02, 0.97)
    /// Frame leather.
    public var leather: MaterialKey = "leather.oxblood"
    /// Seat, headrest and arm-top leather (worn).
    public var wornLeather: MaterialKey = "leather.oxblood-worn"
    /// Base rail and handle plastic.
    public var plastic: MaterialKey = "plastic.black"
    /// Handle wood insert.
    public var wood: MaterialKey = "wood.walnut"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, H = size.y
        let armW: Float = 0.2, baseH: Float = 0.07, armTop: Float = 0.66
        let armD = D - 0.24, armZ = D / 2 - armD / 2 - 0.01
        let inner = W - 2 * armW - 0.01
        // Base rail (black plastic) and frame box.
        m.add(Prim.roundedBox(V3(W - 0.14, baseH, D - 0.12), radius: 0.015, bevelSegments: 2, material: plastic),
              Xform(translation: V3(0, baseH / 2, -0.01)))
        m.add(Prim.roundedBox(V3(inner + 0.03, 0.3, D - 0.08), radius: 0.03, bevelSegments: 3, material: leather),
              Xform(translation: V3(0, baseH + 0.15 - 0.01, -0.005)))
        // Pillow arms.
        let armOutline = Shape2D.roundedRect(armW, armTop - baseH, radius: 0.098, segments: 5).map { V2($0.x, $0.y + (armTop + baseH) / 2) }
        for s: Float in [-1, 1] {
            let ax = s * (W / 2 - armW / 2 - 0.012)
            m.add(Prim.extrude(armOutline, depth: armD, bevel: 0.03, bevelSegments: 2, material: leather), Xform(translation: V3(ax, 0, armZ)))
            if detail {
                let pipe = Shape2D.roundedRect(armW - 0.045, armTop - baseH - 0.05, radius: 0.07, segments: 4)
                    .map { V3(ax + $0.x, (armTop + baseH) / 2 + $0.y, armZ + armD / 2 + 0.0005) }
                m.add(Prim.sweep(Shape2D.circle(0.0035, segments: 5), along: pipe, closedPath: true, caps: false, material: leather))
                let seam = (0...14).map { V3(ax + s * (armW / 2 - 0.035), armTop - 0.01, armZ - armD / 2 + 0.08 + Float($0) / 14 * (armD - 0.16)) }
                m.add(stitches(along: seam, normal: { _ in .up }, pitch: 0.02, thread: 0.0008, material: leather))
            }
        }
        // Seat cushion with sag.
        let cw = inner - 0.006, cd: Float = 0.58, ct: Float = 0.15
        var seat = Prim.superellipsoid(V3(cw, ct, cd), exponent: 5, subdivisions: detail ? 7 : 4, material: wornLeather)
        let sag = rng.float(0.016...0.024)
        seat.deform { p in
            let fx = p.x / (cw / 2), fz = p.z / (cd / 2)
            let dip = max(0, 1 - fx * fx) * max(0, 1 - pow(fz - 0.05, 2)) * (p.y > 0 ? 1 : 0.2)
            return p - V3(0, dip * sag + pow(abs(fx), 3) * pow(abs(fz), 3) * (p.y > 0 ? 0.01 : 0), 0)
        }
        let seatCY: Float = 0.385, seatCZ: Float = 0.06
        m.add(seat, Xform(translation: V3(0, seatCY, seatCZ)))
        if detail {
            for sign: Float in [1] {
                let yy = sign * (ct / 2 - 0.014)
                let k = pow(max(0, 1 - pow(abs(yy) / (ct / 2), 5)), 1.0 / 5)
                let ring = Shape2D.roundedRect(cw * k - 0.002, cd * k - 0.002, radius: 0.05, segments: 2)
                    .map { V3($0.x, seatCY + yy - sag * 0.1, seatCZ - $0.y) }
                m.add(Prim.sweep(Shape2D.circle(0.0045, segments: 5), along: ring, closedPath: true, caps: false, material: wornLeather))
            }
        }
        // Closed footrest: padded panel folded under the seat front.
        m.add(Prim.roundedBox(V3(inner - 0.02, 0.27, 0.1), radius: 0.035, bevelSegments: 3, material: leather),
              Xform(translation: V3(0, 0.215, D / 2 - 0.115), rotation: simd_quatf(degrees: -4, axis: V3(1, 0, 0))))
        if detail {
            let hem = (0...16).map { V3(-(inner - 0.1) / 2 + Float($0) / 16 * (inner - 0.1), 0.13, D / 2 - 0.063) }
            m.add(stitches(along: hem, normal: { _ in V3(0, 0, 1) }, pitch: 0.02, thread: 0.0008, material: leather))
            for y in [0.19, 0.25] as [Float] {
                let ln = (0...16).map { V3(-(inner - 0.1) / 2 + Float($0) / 16 * (inner - 0.1), y, D / 2 - 0.062) }
                m.add(stitches(along: ln, normal: { _ in V3(0, 0, 1) }, pitch: 0.025, thread: 0.0008, material: leather))
            }
        }
        // Shadow gap where the footrest meets the seat.
        m.add(Prim.roundedBox(V3(inner - 0.03, 0.012, 0.07), radius: 0.004, bevelSegments: 1, material: plastic),
              Xform(translation: V3(0, 0.343, D / 2 - 0.1)))
        // Channel-stitched back and headrest: seven tall channel rolls on a leaning back frame.
        let lean: Float = -10
        let q = simd_quatf(degrees: lean, axis: V3(1, 0, 0))
        let backW = W - 0.05, backH: Float = 0.62
        let backBase = V3(0, 0.40, -D / 2 + 0.215)
        m.add(Prim.roundedBox(V3(backW, backH, 0.07), radius: 0.035, bevelSegments: 3, material: leather),
              Xform(translation: backBase + q.act(V3(0, backH / 2, -0.06)), rotation: q))
        // Rear lower body under the back.
        m.add(Prim.roundedBox(V3(W - 0.06, 0.34, 0.3), radius: 0.03, bevelSegments: 3, material: leather),
              Xform(translation: V3(0, baseH + 0.17 - 0.01, -D / 2 + 0.16)))
        let n = 7, chW = backW / Float(n)
        for i in 0..<n {
            let cx = (Float(i) - Float(n - 1) / 2) * chW
            let mat = i == 3 ? wornLeather : leather
            var ch = Prim.superellipsoid(V3(chW + 0.004, backH, 0.13), exponent: 3.4, subdivisions: detail ? 5 : 4, material: mat)
            ch.deform { p in V3(p.x, p.y, p.z + (p.y > backH * 0.32 ? 0.012 * (p.y / backH - 0.32) : 0)) }
            m.add(ch, Xform(translation: backBase + q.act(V3(cx, backH / 2, 0.0)), rotation: q))
            if detail && i > 0 {
                let line = (0...20).map { j -> V3 in
                    let y = 0.03 + Float(j) / 20 * (backH - 0.06)
                    return backBase + q.act(V3(cx - chW / 2, y, 0.052))
                }
                m.add(stitches(along: line, normal: { _ in q.act(V3(0, 0, 1)) }, pitch: 0.025, thread: 0.0008, material: leather))
            }
        }
        // Headrest pillow.
        var head = Prim.superellipsoid(V3(0.5, 0.2, 0.1), exponent: 3.2, subdivisions: detail ? 6 : 4, material: wornLeather)
        head.deform { p in V3(p.x, p.y, p.z + 0.012 * (1 - pow(p.x / 0.25, 2))) }
        m.add(head, Xform(translation: backBase + q.act(V3(0, backH - 0.11, 0.095)), rotation: q))
        // Side release handle on the right arm: black lever with a walnut grip.
        let hx = W / 2 - 0.012, hz: Float = 0.16
        m.add(Prim.roundedBox(V3(0.012, 0.05, 0.16), radius: 0.005, bevelSegments: 2, material: plastic), Xform(translation: V3(hx, 0.4, hz)))
        m.add(Prim.roundedBox(V3(0.02, 0.03, 0.09), radius: 0.01, bevelSegments: 2, material: wood), Xform(translation: V3(hx + 0.006, 0.4, hz + 0.03)))
        // Glides.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.022, height: 0.012, bevel: 0.003, segments: 12, bevelSegments: 1, material: plastic),
                  Xform(translation: V3(sx * (W / 2 - 0.1), 0, sz * (D / 2 - 0.12))))
        }}
        groundAO(&m, height: 0.2, floor: 0.5)
        return m
    }
}
