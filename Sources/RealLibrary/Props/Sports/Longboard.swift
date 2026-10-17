import simd
import Foundation

/// Downhill drop-through speedboard, 1.00 m x 0.245 m: maple core with carbon skins, black griptape, two
/// 150 mm reverse-kingpin aluminum trucks (0.70 m wheelbase) and four 75 mm 80A urethane wheels on 608 bearings.
/// Origin at the deck centre on the ground, deck along X, axles along Z.
public struct Longboard: RealAsset {
    public static let id = "longboard"
    public static let summary = "Downhill speedboard 1:1: 100 cm drop-through maple/carbon deck, griptape, two reverse-kingpin trucks, four 75 mm orange wheels, bearings, bushings."
    public static let tags = ["prop", "sports", "wood", "metal", "rubber", "outdoor"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 28, distance: 0.85, studio: true)

    /// Deck length in meters.
    public var length: Float = 1.0
    /// Deck width in meters.
    public var width: Float = 0.245
    /// Distance between the two truck axles in meters.
    public var wheelbase: Float = 0.70
    /// Wheel diameter in meters.
    public var wheelDiameter: Float = 0.075
    /// Wheel urethane.
    public var wheel: MaterialKey = "plastic.orange"
    /// Wheel hub core.
    public var core: MaterialKey = "plastic.black"
    /// Anodized truck finish.
    public var truck: MaterialKey = "metal.painted:1A1A1D"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hl = length / 2, hw = width / 2
        let thick: Float = 0.011, wr = wheelDiameter / 2
        let deckBottom = wr + 0.0035         // middle of the deck sits 3.5 mm over the wheel tops
        let cutHalfX: Float = 0.035, cutHalfZ: Float = 0.0612
        let truckX = wheelbase / 2

        // MARK: deck as a grid with truck cutouts, concave and kick tails
        func halfWidth(_ x: Float) -> Float {
            let r: Float = 0.12, d = max(0, abs(x) - (hl - r))
            return hw * max(0.18, powf(max(0, 1 - powf(d / r, 2.6)), 1 / 2.6))
        }
        func topY(_ x: Float, _ z: Float) -> Float {
            let k = max(0, abs(x) - 0.38) / 0.12
            let cz = z / hw
            return deckBottom + thick + 0.007 * cz * cz + 0.022 * k * k
        }
        var xs = Set<Float>()
        func addX(_ v: Float) { xs.insert((v * 10_000).rounded() / 10_000) }
        for i in -10...10 { addX(Float(i) * 0.05) }
        for s: Float in [-1, 1] { addX(s * (truckX - cutHalfX)); addX(s * (truckX + cutHalfX)); addX(s * (truckX - 0.075)); addX(s * (truckX + 0.075))
            for k in 1...8 { addX(s * (hl - Float(k) * 0.01)) } }
        let xl = xs.filter { abs($0) <= hl }.sorted()
        let ts: [Float] = [-1, -0.8, -0.6, -0.5, -0.25, 0, 0.25, 0.5, 0.6, 0.8, 1]
        let nx = xl.count - 1, nz = ts.count - 1
        func inHole(_ cx: Float, _ cz: Float) -> Bool { abs(abs(cx) - truckX) < cutHalfX - 0.0001 && abs(cz) < cutHalfZ }
        func point(_ i: Int, _ j: Int) -> V3 { let x = xl[i], z = ts[j] * halfWidth(x); return V3(x, topY(x, z), z) }
        var keep = [[Bool]](repeating: [Bool](repeating: false, count: nz), count: nx)
        for i in 0..<nx { for j in 0..<nz {
            let cx = (xl[i] + xl[i + 1]) / 2, cz = (ts[j] + ts[j + 1]) / 2 * halfWidth(cx)
            keep[i][j] = !inHole(cx, cz)
        }}
        var top = Surface(material: "plastic.dash"), bot = Surface(material: "composite.carbon"), edge = Surface(material: "wood.plywood-edge")
        func vert(_ s: inout Surface, _ i: Int, _ j: Int, down: Bool) -> UInt32 {
            var p = point(i, j); if down { p.y -= thick }
            let c: Float = 0.0015
            if i == 0 || i == nx { p.x -= (p.x > 0 ? c : -c) }
            if j == 0 || j == nz { p.z -= (p.z > 0 ? c : -c) }
            return s.add(p, down ? V3(0, -1, 0) : .up, V2(p.x, p.z))
        }
        for i in 0..<nx { for j in 0..<nz where keep[i][j] {
            let a = vert(&top, i, j, down: false), b = vert(&top, i + 1, j, down: false), c = vert(&top, i + 1, j + 1, down: false), d = vert(&top, i, j + 1, down: false)
            top.quad(a, d, c, b)
            let e = vert(&bot, i, j, down: true), f = vert(&bot, i + 1, j, down: true), g = vert(&bot, i + 1, j + 1, down: true), h = vert(&bot, i, j + 1, down: true)
            bot.quad(e, f, g, h)
        }}
        top.recomputeNormals(weldSeams: false); bot.recomputeNormals(weldSeams: false)
        for (s, up) in [(0, true), (1, false)] {
            var sf = s == 0 ? top : bot
            let dot = sf.normals.reduce(0) { $0 + $1.y }
            if (dot > 0) != up { for k in stride(from: 0, to: sf.indices.count, by: 3) { sf.indices.swapAt(k + 1, k + 2) }; sf.recomputeNormals(weldSeams: false) }
            sf.computeTangents()
            if s == 0 { top = sf } else { bot = sf }
        }
        // Edge walls wherever a kept cell has no kept neighbour.
        func kept(_ i: Int, _ j: Int) -> Bool { i >= 0 && j >= 0 && i < nx && j < nz && keep[i][j] }
        var run: Float = 0
        for i in 0..<nx { for j in 0..<nz where keep[i][j] {
            let sides: [(Int, Int, Int, Int, Int, Int)] = [(i, j, i + 1, j, 0, -1), (i, j + 1, i + 1, j + 1, 0, 1), (i, j, i, j + 1, -1, 0), (i + 1, j, i + 1, j + 1, 1, 0)]
            for (ai, aj, bi, bj, di, dj) in sides where !kept(i + di, j + dj) {
                let pa = point(ai, aj), pb = point(bi, bj)
                let out = simd_normalize(V3(Float(di) * 1, 0, Float(dj)))
                var pn = out
                if di != 0 { pn = V3(Float(di), 0, 0) }
                let len = simd_length(pb - pa)
                let hole = (i + di >= 0 && j + dj >= 0 && i + di < nx && j + dj < nz) && !keep[i + di][j + dj]
                let c: Float = hole ? 0 : 0.0015
                let v0 = edge.add(pa - V3(0, c, 0), pn, V2(run, pa.y)), v1 = edge.add(pb - V3(0, c, 0), pn, V2(run + len, pb.y))
                let v2 = edge.add(pb - V3(0, thick - c, 0), pn, V2(run + len, pb.y - thick)), v3 = edge.add(pa - V3(0, thick - c, 0), pn, V2(run, pa.y - thick))
                let n = simd_cross(pb - pa, V3(0, -1, 0))
                if simd_dot(n, pn) >= 0 { edge.quad(v0, v1, v2, v3) } else { edge.quad(v3, v2, v1, v0) }
                if !hole {
                    // 1.5 mm chamfers top and bottom between the inset deck faces and the wall.
                    let inward = -pn * c
                    for (y0, y1) in [(Float(0), c), (thick, thick - c)] {
                        let a0 = pa + inward - V3(0, y0, 0), b0 = pb + inward - V3(0, y0, 0), a1 = pa - V3(0, y1, 0), b1 = pb - V3(0, y1, 0)
                        let cn = simd_normalize(pn + V3(0, y0 == 0 ? 1 : -1, 0))
                        let w0 = edge.add(a0, cn, V2(run, 0)), w1 = edge.add(b0, cn, V2(run + len, 0)), w2 = edge.add(b1, cn, V2(run + len, c)), w3 = edge.add(a1, cn, V2(run, c))
                        let nn = simd_cross(b0 - a0, a1 - a0)
                        if simd_dot(nn, cn) >= 0 { edge.quad(w0, w1, w2, w3) } else { edge.quad(w3, w2, w1, w0) }
                    }
                }
                run += len
            }
        }}
        edge.computeTangents()
        m.add(top); m.add(bot); m.add(edge)

        // Grip-tape edge: thin black rim, 1 mm proud is below visibility; sticker under the deck as the story detail.
        // Sticker on the grip near the tail.
        m.add(Prim.roundedBox(V3(0.06, 0.0006, 0.022), radius: 0.0003, bevelSegments: 1, material: "plastic.white"),
              Xform(translation: V3(-0.17, topY(-0.17, 0.0) + 0.0003, 0.02), rotation: simd_quatf(degrees: 7, axis: .up)))
        m.add(Prim.roundedBox(V3(0.16, 0.0006, 0.05), radius: 0.0003, bevelSegments: 1, material: "plastic.white"),
              Xform(translation: V3(0.02, deckBottom - thick - 0.0004 + thick * 0, 0.0), rotation: simd_quatf(degrees: 0.8, axis: .up)))

        // MARK: trucks and wheels
        func axisZ(_ s: Surface, _ at: V3) -> (Surface, Xform) { (s, Xform(translation: at, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))) }
        let axleY = wr
        for sx: Float in [-1, 1] {
            let cx = sx * truckX
            let plateY = topY(cx, 0) + 0.0012
            // Baseplate on top of the deck, over the cutout.
            m.add(Prim.extrude(Shape2D.rounded(Shape2D.rect(0.078, 0.108), radius: 0.012), depth: 0.0045, bevel: 0.0012, bevelSegments: 2, material: truck),
                  Xform(translation: V3(cx, plateY + 0.00225, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            for bx: Float in [-1, 1] { for bz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0052, height: 0.0035, bevel: 0.0008, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: V3(cx + bx * 0.027, plateY + 0.0045, bz * 0.0206)))
                // Locknut under the deck.
                m.add(Prim.cylinder(radius: 0.0052, height: 0.005, bevel: 0.0008, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: V3(cx + bx * 0.027, deckBottom - 0.0055, bz * 0.0206)))
            }}
            // Hanger: pivot boss through the cutout, tapered arms to the axle.
            m.add(Prim.roundedBox(V3(0.046, 0.034, 0.058), radius: 0.006, bevelSegments: 2, material: "metal.aluminum-brushed"), Xform(translation: V3(cx, axleY + 0.016, 0)))
            for sz: Float in [-1, 1] {
                let arm = Prim.lathe([V2(0, 0), V2(0.0150, 0), V2(0.0150, 0.004), V2(0.0112, 0.050), V2(0.0092, 0.0535), V2(0.0088, 0.0535), V2(0, 0.0535)], segments: 14, material: truck)
                m.add(arm, Xform(translation: V3(cx, axleY + 0.002, sz * 0.027), rotation: simd_quatf(degrees: sz * 90, axis: V3(1, 0, 0))))
            }
            // Pivot cup and kingpin leaning toward the board centre, bushings and washers on the stack.
            let tilt = simd_quatf(degrees: -sx * 38, axis: V3(0, 0, 1))
            let kp = V3(cx, axleY + 0.036, 0)
            m.add(Prim.cylinder(radius: 0.0048, height: 0.062, bevel: 0.001, segments: 12, bevelSegments: 1, material: "metal.steel"), Xform(translation: kp, rotation: tilt))
            func stack(_ y: Float, _ r: Float, _ h: Float, _ mat: MaterialKey) {
                let q = tilt.act(V3(0, y, 0))
                m.add(Prim.cylinder(radius: r, height: h, bevel: 0.0015, segments: 14, bevelSegments: 1, material: mat), Xform(translation: kp + q, rotation: tilt))
            }
            stack(0.004, 0.0135, 0.018, "rubber.silicone-gray")
            stack(0.022, 0.0125, 0.0015, "metal.steel")
            stack(0.0235, 0.0125, 0.016, "rubber.silicone-gray")
            stack(0.0395, 0.0115, 0.0015, "metal.steel")
            stack(0.056, 0.0075, 0.007, "metal.screw-zinc")
            // Axle and wheels.
            let axle = Prim.cylinder(radius: 0.0040, height: 0.215, bevel: 0.0006, segments: 10, bevelSegments: 1, material: "metal.steel")
            m.add(axle, Xform(translation: V3(cx, axleY, -0.1075), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            for sz: Float in [-1, 1] {
                let wz = sz * 0.1055, ww: Float = 0.042
                // Urethane tire with rounded lips, 22 mm bearing seat, hub core.
                let r = wr, lip: Float = 0.009
                let tire: [V2] = [V2(0.0225, 0), V2(r - lip - 0.003, 0), V2(r - 0.004, 0.0012), V2(r - 0.0012, 0.004), V2(r, lip), V2(r, ww - lip), V2(r - 0.0012, ww - 0.004), V2(r - 0.004, ww - 0.0012), V2(r - lip - 0.003, ww), V2(0.0225, ww)]
                m.add(Prim.lathe(tire, segments: 32, seamTile: 0.1, material: wheel), Xform(translation: V3(cx, axleY, wz - ww / 2), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                let hub: [V2] = [V2(0.0110, 0.004), V2(0.0235, 0.004), V2(0.0235, 0.0315), V2(0.0110, 0.0315)]
                m.add(Prim.lathe(hub, segments: 20, seamTile: 0.1, material: core), Xform(translation: V3(cx, axleY, wz - ww / 2), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                for side: Float in [0, 1] {
                    // 608 bearing: 22 mm outer, 8 mm bore, 7 mm wide, shielded.
                    let bz = wz - ww / 2 + (side == 0 ? 0.0035 : ww - 0.0105)
                    let brg: [V2] = [V2(0.0045, 0), V2(0.0108, 0), V2(0.0110, 0.0005), V2(0.0110, 0.0065), V2(0.0108, 0.007), V2(0.0045, 0.007)]
                    m.add(Prim.lathe(brg, segments: 16, seamTile: 0.1, material: "metal.chrome"), Xform(translation: V3(cx, axleY, bz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
                // Lock nut outboard, spacer inboard.
                m.add(Prim.cylinder(radius: 0.0075, height: 0.0065, bevel: 0.0012, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: V3(cx, axleY, sz * 0.1055 + sz * ww / 2 + (sz > 0 ? 0.0 : -0.0065)), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                m.add(Prim.cylinder(radius: 0.0085, height: 0.002, bevel: 0.0004, segments: 14, bevelSegments: 1, material: "metal.steel"),
                      Xform(translation: V3(cx, axleY, sz * (0.1055 - ww / 2) - (sz > 0 ? 0.0 : 0.002)), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
        }
        _ = rng.float()
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
