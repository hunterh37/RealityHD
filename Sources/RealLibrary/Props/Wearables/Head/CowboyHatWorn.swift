import simd
import Foundation

/// Cattleman cowboy hat worn on an average adult head, origin at head centre, tipped 6 degrees forward: fur
/// felt crown 118 mm tall with a centre dent and pinched front, 92 mm brim curled up hard at the sides with
/// a bound edge and two rows of stitching, oxblood leather hat band with a sweat stain above it, nickel
/// belt-buckle style band buckle and four domed conchos.
public struct CowboyHatWorn: RealAsset {
    public static let id = "cowboy-hat-worn"
    public static let summary = "Worn cattleman cowboy hat: creased felt crown, curled bound brim, leather band with buckle and conchos."
    public static let tags = ["prop", "wearable", "worn", "headwear", "fabric", "leather", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 1.0, ground: false, studio: true)

    /// Fur felt.
    public var felt: MaterialKey = "fabric.felt:7F6446"
    /// Grosgrain brim binding.
    public var binding: MaterialKey = "fabric.grosgrain:2E2118"
    /// Hat band leather.
    public var band: MaterialKey = "leather.oxblood-worn"
    /// Band hardware.
    public var nickel: MaterialKey = "metal.nickel-worn"
    /// Brim width past the crown (m).
    public var brimWidth: Float = 0.092
    /// Side curl of the brim (m).
    public var curl: Float = 0.042
    public init() {}

    static func shellLoop(_ outer: [V2], wall: Float) -> [V2] {
        var inner: [V2] = []
        for i in outer.indices {
            let a = outer[max(0, i - 1)], b = outer[min(outer.count - 1, i + 1)]
            let d = b - a, l = max(simd_length(d), 1e-6)
            let n = V2(d.y, -d.x) / l
            inner.append(V2(max(0, outer[i].x - n.x * wall), outer[i].y - n.y * wall))
        }
        return outer + inner.reversed() + [outer[0]]
    }

    /// Chamfered rectangular ring section, counter clockwise in (radius, y).
    static func section(_ r0: Float, _ r1: Float, _ y0: Float, _ y1: Float, t: Float, c: Float) -> [V2] {
        let ro0 = r0 + t, ro1 = r1 + t
        return [V2(ro0, y0 + c), V2(ro1, y1 - c), V2(ro1 - c, y1), V2(r1 + c, y1), V2(r1, y1 - c), V2(r0, y0 + c),
                V2(r0 + c, y0), V2(ro0 - c, y0), V2(ro0, y0 + c)]
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let oval: Float = 1.2625, yb: Float = 0.040
        func skullX(_ y: Float) -> Float { let t = (y - 0.02) / 0.095; return 0.08 * sqrt(max(0, 1 - t * t)) }
        let rb = skullX(yb) + 0.0105, H: Float = 0.118, rTop: Float = 0.0745, w = brimWidth
        func crownR(_ y: Float) -> Float { rb - (rb - rTop) * (y / H) }   // y above the brim
        let tilt = simd_quatf(degrees: 6, axis: V3(1, 0, 0))
        func put(_ s: Surface, at p: V3 = .zero, rot: simd_quatf = .identity) {
            m.add(s, Xform(translation: tilt.act(p), rotation: tilt * rot))
        }
        let dentPhase = rng.float(0.9...1.1)
        /// Crown deformation in lathe space: pinched front, centre dent running front to back.
        func crease(_ p: V3) -> V3 {
            var q = p
            let u = smoothstep(0.045, 0.118, p.y)
            let zf = smoothstep(-0.3, 1.0, p.z / rb)
            q.x *= 1 - 0.2 * u * zf
            let amp = (0.011 + 0.021 * zf) * dentPhase
            q.y -= amp * exp(-(p.x * p.x) / (2 * 0.017 * 0.017)) * smoothstep(0.075, 0.118, p.y)
            return V3(q.x, q.y, q.z * oval)
        }
        // Crown shell: tapered wall, rounded shoulder, flat top.
        var outer: [V2] = []
        let sh: Float = 0.016
        for k in 0...8 { let y = (H - sh) * Float(k) / 8; outer.append(V2(crownR(y), y)) }
        let sc = V2(crownR(H - sh) - sh, H - sh)
        for k in 1...4 { let a = Float(k) / 4 * .pi / 2; outer.append(V2(sc.x + sh * cos(a), sc.y + sh * sin(a))) }
        for k in 1...6 { outer.append(V2(sc.x * (1 - Float(k) / 6), H)) }
        var crown = Prim.lathe(Self.shellLoop(outer, wall: 0.0035), segments: 64, seamTile: 0.06, material: felt)
        crown.deform { crease($0) }
        put(crown, at: V3(0, yb, 0))
        // Brim: oval, curled up at the sides, dipping front and back, bound edge, two stitch rows.
        let th: Float = 0.0026
        func brimBase(_ r: Float) -> Float { 0.0 - 0.0035 * pow(max(0, (r - rb) / w), 1.5) }
        let rowR: [Float] = [rb + w - 0.0075, rb + w - 0.0125]
        func groove(_ r: Float) -> Float { rowR.reduce(0) { $0 + 0.0006 * exp(-pow((r - $1) / 0.0009, 2)) } }
        var rs: [Float] = [rb - 0.002]
        for k in 1...6 { rs.append(rb + (w - 0.016) * Float(k) / 6) }
        rs += [rowR[1] - 0.002, rowR[1], rowR[1] + 0.002, rowR[0] - 0.002, rowR[0], rowR[0] + 0.002, rb + w - 0.0035, rb + w]
        rs = Array(Set(rs)).sorted()
        var bl: [V2] = []
        for r in rs { bl.append(V2(r, brimBase(r) - th / 2)) }
        let ce = V2(rb + w, brimBase(rb + w))
        for i in 1...4 { let a = -Float.pi / 2 + Float(i) / 5 * .pi; bl.append(ce + V2(cos(a), sin(a)) * (th / 2)) }
        for r in rs.reversed() { bl.append(V2(r, brimBase(r) + th / 2 - groove(r))) }
        bl.append(bl[0])
        func lift(_ p: V3) -> Float {
            let r = simd_length(V2(p.x, p.z))
            let t = max(0, min(1, (r - rb) / w))
            let side = p.x * p.x / max(1e-6, p.x * p.x + p.z * p.z)
            let fz: Float = p.z > 0 ? 0.55 : 1.0
            let up: Float = curl * side
            let down: Float = 0.014 * (1 - side) * fz
            return t * t * (up - down)
        }
        var brim = Prim.lathe(bl, segments: 64, seamTile: 0.06, material: felt)
        brim.deform { p in
            let a = atan2(p.x, p.z), r = simd_length(V2(p.x, p.z))
            let ripple = 0.0024 * sin(7 * a + 1.3) * smoothstep(rb, rb + w, r)
            return V3(p.x, p.y + lift(p) + ripple, p.z * oval)
        }
        put(brim, at: V3(0, yb, 0))
        var bind = Prim.torus(major: rb + w - 0.0008, minor: 0.0027, segments: 64, sides: 6, material: binding)
        bind.deform { p in V3(p.x, p.y + lift(p), p.z * oval) }
        put(bind, at: V3(0, yb + brimBase(rb + w), 0))
        // Leather band with a sweat stain above it.
        let b0: Float = 0.004, b1: Float = 0.031
        var bandS = Prim.lathe(Self.section(crownR(b0) - 0.0002, crownR(b1) - 0.0002, b0, b1, t: 0.0018, c: 0.0007), segments: 64, seamTile: 0.1, material: band)
        bandS.deform { crease($0) }
        put(bandS, at: V3(0, yb, 0))
        var stain = Prim.lathe(Self.section(crownR(b1) - 0.0002, crownR(0.046) - 0.0002, b1 + 0.0004, 0.046, t: 0.0007, c: 0.0003), segments: 64, seamTile: 0.1, material: "fabric.felt:5A4430")
        stain.deform { crease($0) }
        put(stain, at: V3(0, yb, 0))
        // Band buckle on the front, with keeper and tongue.
        let by: Float = 0.0175, bz = (crownR(by) + 0.0021) * oval
        let fr = Shape2D.roundedRect(0.046, 0.0295, radius: 0.007, segments: 4).map { V3($0.x, $0.y, 0) }
        put(Prim.sweep(Shape2D.superellipse(0.0032, 0.0058, exponent: 2.6, segments: 10), along: fr + [fr[0]], up: V3(0, 0, 1), closedPath: true, caps: false, material: nickel),
            at: V3(0, yb + by, bz + 0.0016))
        put(Prim.roundedBox(V3(0.0034, 0.0295, 0.0026), radius: 0.001, bevelSegments: 2, material: nickel), at: V3(0, yb + by, bz + 0.0016))
        put(Prim.roundedBox(V3(0.012, 0.0045, 0.0034), radius: 0.0012, bevelSegments: 2, material: nickel), at: V3(0.01, yb + by, bz + 0.0026))
        put(Prim.roundedBox(V3(0.0085, 0.025, 0.0014), radius: 0.0006, bevelSegments: 1, material: band), at: V3(0.034, yb + by, bz + 0.0004))
        // Domed conchos around the band.
        for deg: Float in [-112, -42, 42, 112] {
            let a = deg * .pi / 180, cy: Float = 0.0175
            let r = crownR(cy) + 0.0019
            let n = simd_normalize(V3(sin(a), 0, cos(a) / oval))
            let prof: [V2] = [V2(0, 0), V2(0.0112, 0), V2(0.0115, 0.0011), V2(0.0098, 0.002), V2(0.0072, 0.0032), V2(0.004, 0.0042), V2(0, 0.0046)]
            put(Prim.lathe(prof, segments: 24, seamTile: 0.03, material: nickel), at: V3(r * sin(a), yb + cy, r * oval * cos(a)), rot: facing(n))
        }
        return LODModel(m)
    }
}
