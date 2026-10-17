import simd
import Foundation

/// Hub-style pop-up ground blind, hexagonal, 1.52 m across the flats and 1.78 m to the roof peak: billowed camo
/// canvas walls with leaf-print appliques, four shoot-through windows (two open with propped flaps, two closed),
/// a door standing ajar, black fiberglass hub poles, mud-stained hem, tie-down ropes and stakes.
public struct GroundBlind: RealAsset {
    public static let id = "ground-blind"
    public static let summary = "Hexagonal pop-up ground blind, 1.52 m across: camo canvas walls, propped window flaps, ajar door, hub poles, ropes, stakes."
    public static let tags = ["prop", "hunting", "outdoor", "fabric"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.1)

    /// Distance across the flats in meters.
    public var flatToFlat: Float = 1.52
    /// Eave and peak heights in meters.
    public var eave: Float = 1.52
    public var peak: Float = 1.78
    /// Base canvas color (sRGB hex).
    public var canvasColor: UInt32 = 0x6E7549
    public init() {}

    /// Flat panel in local XY facing +Z, billowing outward between its edges like stretched fabric.
    static func panel(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, len: Float, h: Float, billow: Float,
                      cell: Float = 0.2, mat: MaterialKey) -> Surface {
        var s = Surface(material: mat)
        let nu = max(1, Int(((x1 - x0) / cell).rounded(.up))), nv = max(1, Int(((y1 - y0) / cell).rounded(.up)))
        func z(_ x: Float, _ y: Float) -> Float { billow * sin(.pi * x / len) * pow(sin(.pi * min(max(y / h, 0.02), 0.98)), 0.6) }
        var idx = [[UInt32]](repeating: [], count: nv + 1)
        for j in 0...nv {
            for i in 0...nu {
                let x = x0 + (x1 - x0) * Float(i) / Float(nu), y = y0 + (y1 - y0) * Float(j) / Float(nv)
                idx[j].append(s.add(V3(x, y, z(x, y)), V3(0, 0, 1), V2(x, y)))
            }
        }
        for j in 0..<nv { for i in 0..<nu { s.quad(idx[j][i], idx[j][i + 1], idx[j + 1][i + 1], idx[j + 1][i]) } }
        s.recomputeNormals(); s.computeTangents()
        return s
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let side = flatToFlat / sqrt(3)               // hexagon side = circumradius
        let R = side, H = eave
        let canvas = "fabric.blind:" + HuntCampKit.hex(canvasColor)
        let dark = "fabric.blind:2A2E1E", mud = "fabric.blind:3A3226"
        let leafTints = ["fabric.blind:55713A", "fabric.blind:9A8B5A", "fabric.blind:7C8A4C", "fabric.blind:7A5E3C", "fabric.blind:B3A874"]
        let pole = "plastic.black"
        let billow: Float = 0.03
        func corner(_ i: Int) -> V3 { let a = Float(i) * .pi / 3; return V3(cos(a) * R, 0, sin(a) * R) }
        // Walls i = 0...5 sit between corner i and i+1, centered at 30 + 60 i degrees; wall 1 faces +Z (door).
        enum Kind { case plain, windowOpen, windowClosed, door }
        let kinds: [Kind] = [.windowOpen, .door, .windowClosed, .windowOpen, .plain, .windowClosed]
        for i in 0..<6 {
            let a = corner(i), b = corner(i + 1)
            let mid = (a + b) / 2, n = simd_normalize(mid)
            let x = simd_normalize(simd_cross(V3(0, 1, 0), n))
            let rot = simd_quatf(simd_float3x3(x, V3(0, 1, 0), n))
            let o = mid - x * (R / 2)
            let wall = Xform(translation: o, rotation: rot)
            func addPanel(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, _ mt: MaterialKey? = nil) {
                m.add(GroundBlind.panel(x0, x1, y0, y1, len: R, h: H, billow: billow, mat: mt ?? canvas), wall)
            }
            // Openings in local meters.
            var hole: (Float, Float, Float, Float)? = nil
            switch kinds[i] {
            case .door: hole = (0.11, R - 0.11, 0, 1.30)
            case .windowOpen: hole = (0.14, R - 0.14, 0.66, 1.08)
            default: break
            }
            if let h = hole {
                addPanel(0, R, h.3, H)
                if h.2 > 0 { addPanel(0, R, 0, h.2) }
                addPanel(0, h.0, h.2, h.3); addPanel(h.1, R, h.2, h.3)
            } else { addPanel(0, R, 0, H) }
            // Mud-stained hem.
            m.add(GroundBlind.panel(0, R, 0, 0.2, len: R, h: H, billow: billow + 0.004, cell: 0.25, mat: mud), wall)
            // Seam bars around the closed windows and a zip seam on the plain wall.
            func seam(_ p: V3, _ q: V3) {
                let (s, t) = board(from: wall.point(p), to: wall.point(q), width: 0.008, thick: 0.004, up: n, bevel: 0.001, material: dark)
                m.add(s, t)
            }
            func zb(_ x: Float, _ y: Float) -> Float { billow * sin(.pi * x / R) * pow(sin(.pi * min(max(y / H, 0.02), 0.98)), 0.6) + 0.004 }
            if kinds[i] == .windowClosed {
                let c: [(Float, Float)] = [(0.14, 0.66), (R - 0.14, 0.66), (R - 0.14, 1.08), (0.14, 1.08)]
                for k in 0..<4 { let p = c[k], q = c[(k + 1) % 4]; seam(V3(p.0, p.1, zb(p.0, p.1)), V3(q.0, q.1, zb(q.0, q.1))) }
            }
            if kinds[i] == .plain { seam(V3(R / 2, 0.12, zb(R / 2, 0.12)), V3(R / 2, 1.30, zb(R / 2, 1.30))) }
            // Leaf-print appliques over the canvas, kept out of the openings.
            var lr = rng.fork(i + 1)
            for k in 0..<21 {
                let lx = lr.float(0.05...(R - 0.05)), ly = lr.float(0.14...(H - 0.08))
                if let h = hole, lx > h.0 - 0.04, lx < h.1 + 0.04, ly > h.2 - 0.04, ly < h.3 + 0.04 { continue }
                if kinds[i] == .windowClosed, lx > 0.1, lx < R - 0.1, ly > 0.62, ly < 1.12 { continue }
                let l = lr.float(0.1...0.22), w = l * lr.float(0.32...0.5)
                let leaf = Prim.extrude(HuntCampKit.leaf(l, w), depth: 0.002, bevel: 0.0006, bevelSegments: 1, material: leafTints[(k + i) % leafTints.count])
                let p = wall.point(V3(lx, ly, zb(lx, ly) - 0.002))
                m.add(leaf, Xform(translation: p, rotation: wall.rotation * simd_quatf(degrees: lr.float(0...360), axis: V3(0, 0, 1))))
            }
            // Black mesh behind open windows; propped flaps. Dark interior behind the door.
            switch kinds[i] {
            case .windowOpen:
                let h = hole!
                m.add(GroundBlind.panel(h.0, h.1, h.2, h.3, len: R, h: H, billow: 0, cell: 0.2, mat: "fabric.curtain-mesh:0B0D09"), wall * Xform(translation: V3(0, 0, -0.03)))
                // Flap hinged on the window head, propped 30 degrees above horizontal with a fiberglass rod.
                let fw = h.1 - h.0
                let flap = GroundBlind.panel(0, fw, -0.44, 0, len: fw, h: 0.44, billow: 0.012, cell: 0.12, mat: canvas)
                let hinge = wall.point(V3(h.0, h.3 + 0.01, zb(h.0, h.3) + 0.004))
                m.add(flap, Xform(translation: hinge, rotation: wall.rotation * simd_quatf(degrees: -120, axis: V3(1, 0, 0))))
                let tip = wall.point(V3(h.0 + fw / 2, h.3 + 0.01 + 0.22, zb(h.0, h.3) + 0.38))
                HuntCampKit.rod(&m, wall.point(V3(h.0 + fw / 2, h.2 - 0.02, zb(h.0, h.2))), tip, r: 0.004, sides: 6, mat: pole)
            case .door:
                let h = hole!
                m.add(GroundBlind.panel(h.0, h.1, 0, h.3, len: R, h: H, billow: 0, cell: 0.3, mat: "fabric.nylon:0C0E0A"), wall * Xform(translation: V3(0, 0, -0.1)))
                // Door flap hinged on the right edge, swung open 58 degrees.
                let dw = h.1 - h.0
                let doorX = Xform(translation: wall.point(V3(h.1, 0, zb(h.1, 0.1))), rotation: wall.rotation * simd_quatf(degrees: 58, axis: V3(0, 1, 0)))
                let door = GroundBlind.panel(0, dw, 0, h.3, len: dw, h: h.3, billow: 0.02, cell: 0.14, mat: canvas)
                m.add(door.transformed(Xform(translation: V3(-dw, 0, 0))), doorX)
                m.add(GroundBlind.panel(0, dw, 0, 0.11, len: dw, h: h.3, billow: 0.024, cell: 0.2, mat: mud).transformed(Xform(translation: V3(-dw, 0, 0))), doorX)
                for k in 0..<5 {
                    let lx = lr.float(0.05...(dw - 0.05)), ly = lr.float(0.15...(h.3 - 0.08))
                    let l = lr.float(0.07...0.15)
                    let leaf = Prim.extrude(HuntCampKit.leaf(l, l * 0.42), depth: 0.002, bevel: 0.0006, bevelSegments: 1, material: leafTints[k % leafTints.count])
                    let bz = 0.02 * sin(.pi * lx / dw) * pow(sin(.pi * min(max(ly / h.3, 0.02), 0.98)), 0.6)
                    m.add(leaf, Xform(translation: doorX.point(V3(lx - dw, ly, bz - 0.0)), rotation: doorX.rotation * simd_quatf(degrees: lr.float(0...360), axis: V3(0, 0, 1))))
                }
            default: break
            }
        }
        // Roof: six panels from the eave to the peak, billowed up between the hub poles, with a seam at each corner.
        let apex = V3(0, peak, 0)
        for i in 0..<6 {
            let a = corner(i), b = corner(i + 1)
            var s = Surface(material: canvas)
            let nu = 6, nv = 4
            var idx = [[UInt32]](repeating: [], count: nv + 1)
            for j in 0...nv {
                for k in 0...nu {
                    let u = Float(k) / Float(nu), v = Float(j) / Float(nv)
                    let base = a + (b - a) * u
                    var p = (base + V3(0, H, 0)) * (1 - v) + apex * v
                    let lift: Float = 0.03 * sin(Float.pi * u) * sin(Float.pi * min(v + 0.1, 1)) * (1 - v * 0.5)
                    p.y += lift
                    idx[j].append(s.add(p, V3(0, 1, 0), V2(p.x, p.z)))
                }
            }
            for j in 0..<nv { for k in 0..<nu { s.quad(idx[j][k], idx[j + 1][k], idx[j + 1][k + 1], idx[j][k + 1]) } }
            s.recomputeNormals()
            if let nrm = s.normals.first, nrm.y < 0 { s = s.flipped() }
            s.computeTangents()
            m.add(s)
            // Leaf appliques on the roof.
            var lr = rng.fork(40 + i)
            for k in 0..<5 {
                let u = lr.float(0.1...0.9), v = lr.float(0.1...0.7)
                let base = a + (b - a) * u
                var p = (base + V3(0, H, 0)) * (1 - v) + apex * v
                let lift: Float = 0.03 * sin(Float.pi * u) * sin(Float.pi * min(v + 0.1, 1)) * (1 - v * 0.5)
                p.y += lift + 0.002
                let l = lr.float(0.08...0.18)
                let leaf = Prim.extrude(HuntCampKit.leaf(l, l * 0.42), depth: 0.002, bevel: 0.0006, bevelSegments: 1, material: leafTints[(k + i) % leafTints.count])
                var nrm = simd_normalize(simd_cross(b - a, apex - (a + b) / 2))
                if nrm.y < 0 { nrm = -nrm }
                let q = simd_quatf(from: V3(0, 0, 1), to: nrm)
                m.add(leaf, Xform(translation: p, rotation: q * simd_quatf(degrees: lr.float(0...360), axis: V3(0, 0, 1))))
            }
        }
        // Hub poles: black fiberglass from each corner base, up the corner seam, arcing to the peak hub.
        for i in 0..<6 {
            let c = corner(i), out = simd_normalize(c)
            HuntCampKit.rod(&m, c + out * 0.012 + V3(0, 0.03, 0), c + out * 0.014 + V3(0, H, 0), r: 0.0075, sides: 8, mat: pole, seamTile: 0.05)
            let rid = [c + out * 0.014 + V3(0, H, 0), V3(c.x * 0.5, (H + peak) / 2 + 0.03, c.z * 0.5), apex + V3(0, 0.012, 0)]
            let path = catmull(rid, per: 4)
            m.add(Prim.tube(path, radii: path.map { _ in 0.0075 }, sides: 8, seamTile: 0.05, material: pole))
            // Corner ferrule at the base with a stake loop.
            m.add(Prim.cylinder(radius: 0.011, height: 0.04, bevel: 0.002, segments: 10, material: "plastic.black"), Xform(translation: c + out * 0.014))
        }
        m.add(Prim.cylinder(radius: 0.06, height: 0.025, bevel: 0.008, segments: 20, material: pole), Xform(translation: apex + V3(0, 0.0, 0)))
        // Tie-down ropes from three eave corners to stakes, with a slide tensioner.
        for i in [1, 3, 5] {
            let c = corner(i), out = simd_normalize(c)
            let top = c + out * 0.02 + V3(0, H - 0.1, 0)
            let stake = c + out * 0.24
            let rope = catmull([top, top + (stake - top) * 0.4 + V3(0, -0.02, 0), stake + V3(0, 0.02, 0)], per: 6)
            m.add(Prim.tube(rope, radii: rope.map { _ in 0.0032 }, sides: 6, seamTile: 0.03, material: "fabric.webbing:A0916A"))
            let mid = top + (stake - top) * 0.55 + V3(0, -0.07, 0)
            m.add(Prim.roundedBox(V3(0.03, 0.006, 0.014), radius: 0.002, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: mid, rotation: simd_quatf(from: V3(1, 0, 0), to: simd_normalize(stake - top))))
            // Stake: wire hook driven in at 55 degrees, loop visible above the dirt.
            m.add(Prim.torus(major: 0.012, minor: 0.0025, segments: 12, sides: 6, material: "metal.galvanized"), Xform(translation: stake + V3(0, 0.012, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            HuntCampKit.rod(&m, stake + V3(0, 0.012, 0), stake + out * 0.05 + V3(0, 0.0, 0), r: 0.0028, sides: 6, mat: "metal.galvanized")
        }
        groundAO(&m, height: 0.35, floor: 0.7)
        return LODModel(m)
    }
}

private func * (a: Xform, b: Xform) -> Xform {
    Xform(translation: a.point(b.translation), rotation: a.rotation * b.rotation, scale: a.scale * b.scale)
}
