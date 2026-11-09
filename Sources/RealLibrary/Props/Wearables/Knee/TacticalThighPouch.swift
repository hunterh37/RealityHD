import simd
import Foundation

/// Tactical drop-leg thigh pouch on the outer left thigh (centre 18 cm above the knee): coyote webbing 14 x 19 cm pouch with a
/// side-release flap, two MOLLE webbing rows with bartacks, a stitched backing panel with a bound edge, three black elastic leg
/// straps with side-release buckles (the lowest wraps just above the knee, fed by two webbing drop tabs). The cloth is dust
/// stained toward the hem, the flap is sun bleached, the webbing ends fray, and a silver duct tape repair with a lifting corner
/// covers a torn seam on the front.
public struct TacticalThighPouch: RealAsset {
    public static let id = "tactical-thigh-pouch"
    public static let summary = "Worn tactical drop-leg thigh pouch: coyote flap pouch, MOLLE rows, bound panel, elastic leg straps with buckles, duct tape repair."
    public static let tags = ["prop", "wearable", "worn", "fabric", "plastic", "military"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 70, elevation: 8, distance: 0.9, ground: false, studio: true)

    /// Pouch cloth.
    public var cloth: MaterialKey = "fabric.webbing:76674A"
    /// Elastic leg straps.
    public var strapMat: MaterialKey = "fabric.webbing:1C1D1A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias L = LegKit
        let nf: (V3) -> V3 = { L.nrm($0) }
        let th0 = Float.pi / 2
        let yc: Float = 0.185
        let sew: MaterialKey = "fabric.knit:4C4332"
        /// Local pouch coordinates: x arc across the front-outer thigh, y up from the pouch centre, z = height above the limb.
        func lp(_ x: Float, _ y: Float, _ z: Float) -> V3 {
            let yy = yc + y
            return L.P(th0 + x / (L.R(yy) + 0.0085), yy, z)
        }
        let panelTop: Float = 0.0100, pc: Float = 0.025
        func pouchZ(_ x: Float, _ y: Float) -> Float {
            let v = 1 - pow(abs(x) / 0.070, 4.5) - pow(abs(y) / 0.095, 4.5)
            return panelTop + pc + pc * pow(max(v, 0), 1 / 4.5)
        }
        let flapC: Float = 0.054, flapZc: Float = panelTop + pc + 0.004
        func flapZ(_ x: Float, _ y: Float) -> Float {
            let v = 1 - pow(abs(x) / 0.073, 5) - pow(abs(y - flapC) / 0.041, 5)
            return flapZc + 0.028 * pow(max(v, 0), 0.2)
        }

        // Leg straps: black elastic rings, side-release buckles on the front. The lowest sits just above the knee.
        let st: Float = 0.0030
        for (y, w) in [(Float(0.292), Float(0.040)), (0.078, 0.040), (0.000, 0.045)] {
            let f = L.K.frames(L.ring(y: y, off: 0.0030, count: 44), normal: nf, closed: true)
            var band = L.K.ribbon(f, width: w, thick: st, radius: 0.0012, segments: 1, closed: true, material: strapMat)
            band.displace { p, _ in 0.00025 * Noise.fbm(p * 150, octaves: 2) }
            m.add(band)
            let th: Float = -0.75
            let a = L.P(th, y, 0.0030 + st / 2 + 0.0022), n = nf(a), tg = L.tangent(th)
            let q = L.K.basis(tg, n)
            m.add(Prim.roundedBox(V3(0.026, 0.0050, w - 0.006), radius: 0.0014, bevelSegments: 1, material: "plastic.black"), Xform(translation: a - tg * 0.0135, rotation: q))
            m.add(Prim.roundedBox(V3(0.026, 0.0062, w - 0.002), radius: 0.0016, bevelSegments: 1, material: "plastic.matte:222326"), Xform(translation: a + tg * 0.0135, rotation: q))
            let tail = (0...8).map { k -> V3 in
                let ang: Float = th - 0.25 - 0.45 * Float(k) / 8
                return L.P(ang, y, 0.0030 + st + 0.0012)
            }
            m.add(L.K.ribbon(L.K.frames(tail, normal: nf), width: w - 0.004, thick: 0.0022, radius: 0.0008, segments: 1, material: strapMat))
            ArmKit.fray(&m, rng: &rng, from: [tail.last!], dir: { _ in -tg }, count: 6, length: 0.003...0.008, radius: 0.0004, material: strapMat)
        }
        // Webbing drop tabs from the panel down to the lowest strap.
        for x: Float in [-0.038, 0.038] {
            let path = (0...10).map { k -> V3 in
                let y = 0.052 - 0.058 * Float(k) / 10
                return L.P(th0 + x / 0.0690, y, 0.0058)
            }
            m.add(L.K.ribbon(L.K.frames(path, normal: nf), width: 0.022, thick: 0.0022, radius: 0.0008, segments: 1, material: cloth))
            let bx = L.P(th0 + x / 0.0690, 0.014, 0.0072)
            rivet(&m, at: bx, normal: nf(bx), radius: 0.0034, segments: 10, material: "metal.nickel-worn")
        }

        // Backing panel and its bound edge.
        var panel = ShoulderKit.shell(cols: 18, rows: 26, thick: 0.0030, centre: V3(0, 0, 0), material: cloth) { u, v in lp((2 * u - 1) * 0.079, -0.013 + (2 * v - 1) * 0.1275, panelTop) }
        panel.displace { p, _ in 0.0003 * Noise.fbm(p * 120, octaves: 2) }
        m.add(panel)
        let bindPts = Shape2D.roundedRect(0.158, 0.255, radius: 0.007, segments: 3).map { lp($0.x, -0.013 + $0.y, panelTop - 0.0015) }
        m.add(Prim.tube(bindPts + [bindPts[0]], radii: (0...bindPts.count).map { _ in 0.0032 }, sides: 6, seamTile: 0.012, material: "fabric.webbing:2E2B22", capEnd: false))

        // Pouch body: soft box wrapped onto the thigh.
        var body = Prim.superellipsoid(V3(0.140, 0.190, 0.050), exponent: 4.5, subdivisions: 11, material: cloth)
        body.deform { p in lp(p.x, p.y, panelTop + pc + p.z) }
        body.displace { p, _ in 0.0004 * Noise.fbm(p * 100, octaves: 3) }
        m.add(body)
        var flap = Prim.superellipsoid(V3(0.146, 0.082, 0.056), exponent: 5, subdivisions: 11, material: "fabric.webbing:8A7B5C")
        flap.deform { p in lp(p.x, flapC + p.y, flapZc + p.z) }
        flap.displace { p, _ in 0.0004 * Noise.fbm(p * 100, octaves: 3) }
        m.add(flap)
        // Flap stitching and tab with a side-release plug.
        let fs = Shape2D.roundedRect(0.118, 0.056, radius: 0.008, segments: 3).map { q -> V3 in lp(q.x, flapC + q.y + 0.002, flapZ(q.x, flapC + q.y + 0.002) + 0.0003) }
        m.add(stitches(along: fs + [fs[0]], normal: nf, pitch: 0.0060, thread: 0.0004, material: sew))
        let tab = (0...8).map { k -> V3 in
            let y = 0.040 - 0.052 * Float(k) / 8
            return lp(0, y, max(pouchZ(0, y), flapZ(0, y)) + 0.0015)
        }
        m.add(L.K.ribbon(L.K.frames(tab, normal: nf), width: 0.026, thick: 0.0028, radius: 0.0010, segments: 1, material: strapMat))
        let plug = tab.last!
        m.add(Prim.roundedBox(V3(0.030, 0.0070, 0.013), radius: 0.0018, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: plug + nf(plug) * 0.0032, rotation: L.K.basis(L.tangent(th0), nf(plug))))
        let socket = lp(0, -0.014, pouchZ(0, -0.014) + 0.0025)
        m.add(Prim.roundedBox(V3(0.032, 0.0055, 0.014), radius: 0.0016, bevelSegments: 1, material: "plastic.matte:2A2B2D"),
              Xform(translation: socket, rotation: L.K.basis(L.tangent(th0), nf(socket))))

        // MOLLE rows with bartacks.
        for ry: Float in [-0.040, -0.070] {
            let path = (0...24).map { k -> V3 in
                let x = -0.058 + 0.116 * Float(k) / 24
                let loop = 0.0016 * pow(sin(x / 0.0254 * Float.pi), 2)
                return lp(x, ry, pouchZ(x, ry) + 0.0014 + loop)
            }
            m.add(L.K.ribbon(L.K.frames(path, normal: nf), width: 0.0210, thick: 0.0020, radius: 0.0008, segments: 1, material: "fabric.webbing:6A5D43"))
            for k in 0...4 {
                let x = -0.0508 + 0.0254 * Float(k)
                let p = lp(x, ry, pouchZ(x, ry) + 0.0026)
                m.add(Prim.roundedBox(V3(0.0030, 0.0008, 0.019), radius: 0.0003, bevelSegments: 1, material: sew),
                      Xform(translation: p, rotation: L.K.basis(L.tangent(th0), nf(p))))
            }
            ArmKit.fray(&m, rng: &rng, from: [path[0], path[24]], dir: { p in L.tangent(th0) * (p == path[0] ? -1 : 1) }, count: 6, length: 0.003...0.008, radius: 0.0004, material: "fabric.webbing:6A5D43")
        }
        // Silver duct tape repair over a torn seam, one corner lifting.
        func tp(_ u: Float, _ v: Float, _ lift: Float) -> V3 {
            let x = -0.062 + 0.044 * u, y = 0.004 - 0.032 * v
            let peel = pow(max(0, (1 - u) + (1 - v) - 1.40), 1.3) * 0.016
            return lp(x, y, pouchZ(x, y) + lift + peel)
        }
        m.add(ShoulderKit.shell(cols: 10, rows: 8, thick: 0.0006, centre: V3(0, 0, 0), material: "plastic.gloss:AEB1B5") { u, v in tp(u, v, 0.0016) })
        for k in 0..<3 {
            let pts = (0...8).map { j in tp(0.04 + 0.9 * Float(j) / 8, 0.24 * Float(k + 1) + 0.0, 0.0024) }
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0003 }, sides: 3, seamTile: 0.01, material: "plastic.matte:6E7176", capEnd: false))
        }

        // Dust and mud toward the hem, bleached patches on the flap and upper body, oil darkening at the edges.
        for _ in 0..<5 {
            let x = rng.float(-0.060...0.060), y = rng.float(-0.092...(-0.012))
            let p = lp(x, y, pouchZ(x, y) + 0.0002)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.022...0.044), aspect: rng.float(0.5...0.9), layers: ["fabric.webbing:6B5C40", "fabric.webbing:5A4C34", "fabric.webbing:4C402B"])
        }
        for _ in 0..<3 {
            let x = rng.float(-0.060...0.060), y = rng.float(0.018...0.085)
            let p = lp(x, y, flapZ(x, y) + 0.0002)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.022...0.040), aspect: rng.float(0.5...0.9), layers: ["fabric.webbing:93845F", "fabric.webbing:A29473"])
        }
        return LODModel(m)
    }
}
