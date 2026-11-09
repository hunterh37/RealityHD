import simd
import Foundation

/// Graduation mortarboard without a tassel: a 245 mm square, 3 mm stiff board wrapped in polyester satin
/// (rolled 2 mm edges), a stitched six-panel skull cap 190 x 200 x 75 mm open at the bottom with a gathered
/// elastic hem band, and an 18 mm covered button on the board centre. Origin at the base centre of the
/// skull cap, +Y up, front +Z. Board and skull share the `fabric.gown` slot, the button has its own slot.
/// Anchors: `cap.button` (button top, the tassel attach point), `cap.board` (board top centre), `cap.skull` (origin).
public struct GraduationCap: RealAnchored {
    public static let id = "graduation-cap"
    public static let summary = "Graduation mortarboard: fabric-covered 245 mm board, stitched skull cap with elastic hem, covered centre button; no tassel (anchor cap.button)."
    public static let tags = ["prop", "fashion", "apparel", "handheld", "graduation", "headwear"]
    public static let budget = 16_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 26, distance: 0.62, studio: true)

    /// Board side and thickness (m).
    public var boardSize: Float = 0.245
    public var boardThickness: Float = 0.003
    /// Skull cap width (X), depth (Z) and height (m).
    public var skullWidth: Float = 0.19
    public var skullDepth: Float = 0.20
    public var skullHeight: Float = 0.075
    /// Covered button diameter (m).
    public var buttonDiameter: Float = 0.018
    /// Fabric color (sRGB hex). The default black uses the untinted keys.
    public var color: UInt32 = 0x111114
    public init() {}

    var fabric: MaterialKey { color == 0x111114 ? "fabric.gown" : MaterialKey(stringLiteral: String(format: "fabric.gown:%06X", color)) }
    var buttonKey: MaterialKey { color == 0x111114 ? "fabric.gown-button" : MaterialKey(stringLiteral: String(format: "fabric.gown-button:%06X", color)) }

    /// Button top in asset space (origin at skull base centre, +Y up).
    public var buttonTop: V3 { V3(0, skullHeight + boardThickness + buttonDiameter / 3, 0) }

    public static var anchors: [String: RealAnchor] {
        let c = Self()
        return ["cap.button": RealAnchor(c.buttonTop, direction: V3(0, 1, 0)),
                "cap.board": RealAnchor(V3(0, c.skullHeight + c.boardThickness, 0), direction: V3(0, 1, 0)),
                "cap.skull": RealAnchor(.zero, direction: V3(0, -1, 0))]
    }

    /// Superellipse point of the skull outline; angle 0 is +X, pi/2 is -Z.
    private func skullPoint(_ a: Float, _ b: Float, _ n: Float, _ t: Float) -> V2 {
        let c = cos(t), s = sin(t), e = 2 / n
        return V2(a * (c < 0 ? -1 : 1) * pow(abs(c), e), b * (s < 0 ? -1 : 1) * pow(abs(s), e))
    }

    /// Skull profile: (height, half width scale, half depth scale, exponent).
    private var profile: [(Float, Float, Float, Float)] {
        let h = skullHeight
        return [(0, 1, 1, 2.2), (0.16 * h, 1, 1, 2.25), (0.40 * h, 0.990, 0.990, 2.4), (0.66 * h, 0.962, 0.965, 2.7),
                (0.86 * h, 0.918, 0.925, 3.0), (0.97 * h, 0.885, 0.893, 3.3), (h - 0.0004, 0.870, 0.880, 3.4)]
    }

    private func skullRing(_ i: Int, scale: Float, n: Int, ripple: (Float) -> Float = { _ in 1 }) -> [V3] {
        let (y, sa, sb, e) = profile[i]
        let a = skullWidth / 2 * sa * scale, b = skullDepth / 2 * sb * scale
        return (0..<n).map { k in
            let t = Float(k) / Float(n) * 2 * .pi
            let p = skullPoint(a, b, e, t) * ripple(t)
            return V3(p.x, y, -p.y)
        }
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed   // deterministic: anchors are exact
        var m = Model(name: Self.id)
        let n = 128
        let H = skullHeight, T = boardThickness, S = boardSize

        // Skull: outer satin shell, inner lining 2 mm in, closed at the top under the board.
        let outer = profile.indices.map { skullRing($0, scale: 1, n: n) }
        m.add(Prim.loft(outer, capStart: false, capEnd: true, material: fabric))
        let inner = profile.indices.reversed().map { skullRing($0, scale: 0.979, n: n) }
        m.add(Prim.loft(inner, capStart: true, capEnd: false, material: fabric))

        // Elastic hem band: gathered (48 soft ruffles), rolled top and bottom edges, closes the shell lip.
        let gather: (Float) -> Float = { t in 1 + 0.0045 * sin(48 * t) }
        let hemY: [(Float, Float)] = [(0.0000, 0.979), (0.0000, 1.006), (0.0016, 1.013), (0.0110, 1.013), (0.0130, 1.004)]
        let hemRings: [[V3]] = hemY.map { (y, s) in
            (0..<n).map { k in
                let t = Float(k) / Float(n) * 2 * .pi
                let g = s > 1 ? gather(t) : 1
                let p = skullPoint(skullWidth / 2 * s, skullDepth / 2 * s, 2.2, t) * g
                return V3(p.x, y, -p.y)
            }
        }
        m.add(Prim.loft(hemRings, material: fabric))

        // Six panel seams from the hem to the crown: a welted ridge with saddle stitches either side.
        for j in 0..<6 {
            let t = Float(j) / 6 * 2 * .pi + .pi / 6
            var path: [V3] = []
            for i in 1..<profile.count {
                let (y, sa, sb, e) = profile[i]
                let p = skullPoint(skullWidth / 2 * sa * 1.001, skullDepth / 2 * sb * 1.001, e, t)
                path.append(V3(p.x, max(y, 0.014), -p.y))
            }
            path = catmull(path, per: 6)
            m.add(Prim.sweep(Shape2D.circle(0.0011, segments: 8), along: path, caps: false, material: fabric))
            let normal: (V3) -> V3 = { p in simd_normalize(V3(p.x, 0.15, p.z)) }
            for side: Float in [-1, 1] {
                let off = path.map { p -> V3 in
                    let r = simd_normalize(V3(p.x, 0, p.z))
                    return p + simd_cross(V3(0, 1, 0), r) * (0.0030 * side) - r * 0.0002
                }
                m.add(stitches(along: off, normal: normal, pitch: 0.0032, thread: 0.00045, material: fabric))
            }
        }
        // Hem stitch line just above the band.
        let hemPath: [V3] = (0..<n).map { k in
            let t = Float(k) / Float(n) * 2 * .pi
            let p = skullPoint(skullWidth / 2 * 1.0125, skullDepth / 2 * 1.0125, 2.2, t) * gather(t)
            return V3(p.x, 0.0118, -p.y)
        }
        m.add(stitches(along: hemPath + [hemPath[0]], normal: { simd_normalize(V3($0.x, 0, $0.z)) },
                       pitch: 0.0034, thread: 0.0005, material: fabric))

        // Board: stiff 3 mm core wrapped in satin, 1.4 mm rounded edges, a rolled fabric edge bead that
        // drapes 1 mm past the core, and a faint centre sag where the fabric is pulled over the board.
        var board = Prim.roundedBox(V3(S, T, S), radius: 0.0014, bevelSegments: 4, material: fabric)
        board.deform { p in
            let r = max(abs(p.x), abs(p.z)) / (S / 2)
            return V3(p.x, p.y - 0.0006 * (1 - r * r), p.z)
        }
        m.add(board, Xform(translation: V3(0, H + T / 2, 0)))
        let e = S / 2 - 0.0004, cr: Float = 0.006
        var rim: [V3] = []
        for c in 0..<4 {
            let a0 = Float(c) * .pi / 2
            let cx = (c == 0 || c == 3 ? 1 : -1) * (e - cr), cz = (c < 2 ? 1 : -1) * (e - cr)
            for k in 0...6 {
                let a = a0 + Float(k) / 6 * .pi / 2
                rim.append(V3(cx + cos(a) * cr, H + T * 0.45, cz + sin(a) * cr))
            }
        }
        m.add(Prim.sweep(Shape2D.circle(0.0019, ry: 0.0021, segments: 12), along: rim, up: V3(0, 1, 0),
                         closedPath: true, caps: false, material: fabric))

        // Covered button: domed, fabric pulled into a soft underside.
        let r = buttonDiameter / 2, bh = buttonDiameter / 3
        let prof: [V2] = [V2(0, bh), V2(r * 0.45, bh * 0.97), V2(r * 0.78, bh * 0.82), V2(r * 0.95, bh * 0.55),
                          V2(r, bh * 0.28), V2(r * 0.94, bh * 0.06), V2(r * 0.80, 0)]
        m.add(Prim.lathe(prof.reversed(), segments: 64, seamTile: 0.02, material: buttonKey), Xform(translation: V3(0, H + T, 0)))

        var lod = LODModel(m)
        for (k, a) in Self.anchors { lod.anchors[k] = Xform(translation: a.position) }
        return lod
    }
}
