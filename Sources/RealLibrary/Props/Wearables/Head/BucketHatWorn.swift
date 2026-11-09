import simd
import Foundation

/// Cotton canvas bucket hat worn on an average adult head, origin at head centre: tapered crown with a
/// stitched flat top, 62 mm downward-sloping brim quilted with five rows of channel stitching and a wavy
/// worn edge, six metal vent eyelets, stitched leather patch on the front and a chin cord with a cord lock.
public struct BucketHatWorn: RealAsset {
    public static let id = "bucket-hat-worn"
    public static let summary = "Worn khaki canvas bucket hat: quilted drooping brim, stitched crown, brass eyelets, leather patch, chin cord."
    public static let tags = ["prop", "wearable", "worn", "headwear", "fabric", "leather"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 0.85, ground: false, studio: true)

    /// Hat canvas.
    public var canvas: MaterialKey = "fabric.canvas:B9A982"
    /// Eyelet metal.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Patch leather.
    public var patch: MaterialKey = "leather.tan:6B4426"
    /// Chin cord.
    public var cord: MaterialKey = "fabric.nylon:2B2A26"
    /// Brim width past the crown (m).
    public var brimWidth: Float = 0.062
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let oval: Float = 1.2625, yb: Float = 0.040, th: Float = 0.0032
        func skullX(_ y: Float) -> Float { let t = (y - 0.02) / 0.095; return 0.08 * sqrt(max(0, 1 - t * t)) }
        let rc0 = skullX(yb) + 0.0075
        let H: Float = 0.082, top = yb + H, shoulder: Float = 0.012, w = brimWidth
        func crownR(_ y: Float) -> Float { rc0 - 0.012 * (y - yb) / H + 0.0012 * (1 - (y - yb) / H) }
        func brimY(_ r: Float) -> Float { let u = max(0, (r - rc0) / w); return yb - 0.031 * pow(u, 1.7) }
        // Quilting rows: dips in both faces of the brim.
        let rows: [Float] = [0.18, 0.34, 0.5, 0.66, 0.82].map { rc0 + w * $0 }
        func groove(_ r: Float) -> Float { rows.reduce(0) { $0 + 0.0008 * exp(-pow((r - $1) / 0.0011, 2)) } }
        var rs: [Float] = [rc0 - 0.002, rc0 + 0.004]
        for r in rows { rs += [r - 0.0025, r, r + 0.0025] }
        rs.append(rc0 + w)
        var loop: [V2] = []
        // Brim underside, root to edge.
        for r in rs { loop.append(V2(r, brimY(r) - th / 2 - groove(r))) }
        // Rolled edge.
        let ce = V2(rc0 + w, brimY(rc0 + w))
        for i in 1...5 { let a = -Float.pi / 2 + Float(i) / 6 * .pi; loop.append(ce + V2(cos(a), sin(a)) * (th / 2)) }
        // Brim top, edge to root.
        for r in rs.reversed() { loop.append(V2(r, brimY(r) + th / 2 - groove(r))) }
        // Crown outer wall.
        for k in 1...5 {
            let y = yb + th / 2 + (H - shoulder - th / 2) * Float(k) / 5
            loop.append(V2(crownR(y), y))
        }
        // Top shoulder and flat top to the axis.
        let sc = V2(crownR(top - shoulder) - shoulder, top - shoulder)
        let rSh = crownR(top - shoulder)
        for k in 1...4 { let a = Float(k) / 4 * .pi / 2; loop.append(V2(rSh - shoulder + shoulder * cos(a), sc.y + shoulder * sin(a))) }
        for k in 1...3 { let r = (rSh - shoulder) * (1 - Float(k) / 3); loop.append(V2(r, top)) }
        // Inner top, shoulder and wall back to the hem.
        for k in 1...3 { let r = (rSh - shoulder - th) * Float(k) / 3; loop.append(V2(r, top - th)) }
        for k in 1...3 { let a = Float.pi / 2 - Float(k) / 3 * .pi / 2; loop.append(V2(rSh - shoulder - th + (shoulder + th * 0.2) * cos(a), sc.y + (shoulder - th) * sin(a))) }
        for k in 1...4 {
            let y = (top - shoulder) - (top - shoulder - yb) * Float(k) / 4
            loop.append(V2(crownR(y) - th, y))
        }
        loop.append(loop[0])
        var hat = Prim.lathe(loop, segments: 64, seamTile: 0.04, material: canvas)
        let phase = rng.float(0...6.28)
        hat.deform { p in
            let r = simd_length(V2(p.x, p.z)), a = atan2(p.x, p.z)
            var y = p.y
            if r < rc0 + 0.004 && p.y > yb + 0.012 {
                let k = 1 + 0.006 * sin(5 * a + 28 * p.y + phase) * smoothstep(yb + 0.012, yb + 0.05, p.y)
                return V3(p.x * k, y, p.z * k * oval)
            }
            if r > rc0 + 0.004 { y += 0.0045 * sin(5 * a + phase) * min(1, (r - rc0) / w) }
            return V3(p.x, y, p.z * oval)
        }
        m.add(hat)
        // Grime and sweat ring on the lower crown where the hat is handled.
        var grime = Prim.lathe([V2(crownR(yb + 0.004) + 0.0004, yb + 0.004), V2(crownR(yb + 0.022) + 0.0004, yb + 0.022), V2(crownR(yb + 0.022) + 0.0012, yb + 0.0225), V2(crownR(yb + 0.004) + 0.0012, yb + 0.0045), V2(crownR(yb + 0.004) + 0.0004, yb + 0.004)], segments: 64, seamTile: 0.04, material: "fabric.canvas:8A7852")
        grime.deform { p in V3(p.x, p.y, p.z * oval) }
        m.add(grime)
        // Ring stitching: crown top seam and the crown to brim junction.
        func ringPath(_ r: Float, _ y: Float) -> [V3] {
            (0...96).map { k in let a = Float(k) / 96 * 2 * .pi; return V3(r * sin(a), y, r * cos(a) * oval) }
        }
        let thread = "fabric.canvas:D9CDB0"
        var detail = Model(name: "stitching")
        detail.add(stitches(along: ringPath(rSh - shoulder - 0.004, top + 0.0003), normal: { _ in .up }, pitch: 0.0045, thread: 0.0006, material: thread))
        detail.add(stitches(along: ringPath(rc0 + 0.0035, yb + th / 2 + 0.0003), normal: { _ in .up }, pitch: 0.0045, thread: 0.0006, material: thread))
        // Vent eyelets, three per side.
        for sx: Float in [-1, 1] { for deg: Float in [68, 90, 112] {
            let a = deg * .pi / 180, y: Float = 0.098
            let r = crownR(y) + 0.0004
            let pos = V3(sx * r * sin(a), y, r * oval * cos(a))
            let n = simd_normalize(V3(sx * sin(a), 0.12, cos(a) / oval))
            let q = facing(n)
            m.add(Prim.torus(major: 0.0046, minor: 0.0016, segments: 16, sides: 6, material: brass), Xform(translation: pos + n * 0.0006, rotation: q))
            m.add(Prim.cylinder(radius: 0.0034, height: 0.0006, bevel: 0.0002, segments: 14, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: pos + n * 0.0001, rotation: q))
        }}
        // Leather patch on the crown front with stitching.
        let py: Float = 0.07, pr = crownR(py) + 0.0013
        let pp = V3(0, py, pr * oval)
        let pn = simd_normalize(V3(0, 0, 1))
        m.add(Prim.roundedBox(V3(0.038, 0.022, 0.0026), radius: 0.001, bevelSegments: 2, material: patch), Xform(translation: pp))
        var pl: [V3] = []
        for (dx, dy) in [(-0.0165, -0.0095), (0.0165, -0.0095), (0.0165, 0.0095), (-0.0165, 0.0095), (-0.0165, -0.0095)] as [(Float, Float)] {
            pl.append(pp + V3(dx, dy, 0.0015))
        }
        detail.add(stitches(along: pl, normal: { _ in pn }, pitch: 0.003, thread: 0.0005, material: thread))
        m.add(Prim.torus(major: 0.0055, minor: 0.0011, segments: 20, sides: 6, material: "metal.brass-aged"),
              Xform(translation: pp + V3(0, 0, 0.0021), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Chin cord: from the front eyelet on each side down past the jaw to a cord lock under the chin.
        for sx: Float in [-1, 1] {
            let a = 68 * Float.pi / 180
            let e = V3(sx * (crownR(0.098) + 0.0012) * sin(a), 0.098, (crownR(0.098) + 0.0012) * oval * cos(a))
            let path = catmull([e, V3(sx * 0.0925, 0.052, 0.034), V3(sx * 0.0895, -0.02, 0.03), V3(sx * 0.07, -0.088, 0.05),
                                V3(sx * 0.03, -0.118, 0.078), V3(sx * 0.0085, -0.121, 0.0845)], per: 6)
            m.add(Prim.tube(path, radii: path.map { _ in 0.0017 }, sides: 10, seamTile: 0.012, material: cord, capEnd: false))
        }
        m.add(turned([(0, 0), (0.0062, 0), (0.0068, 0.0012), (0.0068, 0.014), (0.006, 0.016), (0, 0.016)], segments: 20, material: "plastic.black"),
              Xform(translation: V3(0, -0.1235, 0.0885), rotation: simd_quatf(degrees: 70, axis: V3(1, 0, 0))))
        var full = m
        full.add(detail)
        return LODModel(levels: [full, m], switchDistances: [4])
    }
}
