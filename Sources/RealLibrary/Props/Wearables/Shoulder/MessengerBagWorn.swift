import simd
import Foundation

/// Waxed canvas messenger bag carried at the left hip on a 45 mm strap that runs over the shoulder: front and back legs go
/// down to leather-wrapped D-rings on the bag ends. Wide flap with leather binding and stitching, two leather buckle
/// straps with brass roller buckles, box-pleat front pocket with a stitched leather patch, leather grab handle, padded
/// shoulder section and a slider adjuster. Bag local frame: X width, Y height, Z outward (+X in the shoulder frame).
public struct MessengerBagWorn: RealAsset {
    public static let id = "messenger-bag-worn"
    public static let summary = "Worn waxed canvas messenger bag: flap with buckle straps, pleat pocket, strap over the shoulder."
    public static let tags = ["prop", "wearable", "worn", "fabric", "leather", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 10, distance: 1.6, ground: false, studio: true)

    /// Waxed canvas shell.
    public var shell: MaterialKey = "fabric.canvas:8F8D64"
    /// Strap webbing.
    public var webbing: MaterialKey = "fabric.webbing:2C2B22"
    /// Leather binding, straps and handle.
    public var leather: MaterialKey = "leather.oxblood-worn"
    /// Roller buckles, rings and rivets.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Strap padding.
    public var pad: MaterialKey = "fabric.nylon:25272A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        let thread: MaterialKey = "fabric.canvas:C8B98C"
        let W: Float = 0.40, H: Float = 0.31, D: Float = 0.11
        let a = W / 2, b = H / 2, c = D / 2
        let ne: Float = 5
        let C = V3(0.092, -0.40, 0)
        let bagQ = K.basis(V3(0, 0, -1), V3(0, 1, 0))

        func sgnp(_ x: Float, _ e: Float) -> Float { (x < 0 ? -1 : 1) * pow(abs(x), e) }
        func sScale(_ x: Float) -> Float { pow(max(1e-4, 1 - pow(abs(x / a), ne)), 1 / ne) }
        func sec(_ x: Float, _ phi: Float) -> V3 {
            let s = sScale(x)
            return V3(x, b * s * sgnp(cos(phi), 2 / ne), c * s * sgnp(sin(phi), 2 / ne))
        }
        func grad(_ p: V3) -> V3 {
            simd_normalize(V3(sgnp(p.x / a, ne - 1) / a, sgnp(p.y / b, ne - 1) / b, sgnp(p.z / c, ne - 1) / c))
        }
        func frontZ(_ x: Float, _ y: Float) -> Float {
            let r = 1 - pow(abs(x / a), ne) - pow(abs(y / b), ne)
            return r > 0 ? c * pow(r, 1 / ne) : 0
        }
        func lifted(_ p: V3, _ l: Float) -> V3 { p + grad(p) * l }

        // ---- Bag body ----
        var bag = Model(name: "bag")
        bag.add(Prim.superellipsoid(V3(W, H, D), exponent: ne, subdivisions: 8, material: shell) { d in
            1 + 0.010 * sin(d.x * 11) * sin(d.y * 8)
        })
        // Gusset seam: piping and double stitching around the mid plane.
        func se(_ t: Float) -> V3 { V3((cos(t) < 0 ? -1 : 1) * pow(abs(cos(t)), 2 / ne) * a, (sin(t) < 0 ? -1 : 1) * pow(abs(sin(t)), 2 / ne) * b, 0) }
        let seam = (0..<84).map { se(2 * Float.pi * Float($0) / 84) }
        bag.add(Prim.sweep(Shape2D.circle(0.0026, segments: 5), along: seam, up: V3(0, 0, 1), closedPath: true, caps: false, material: "fabric.webbing:1F1E18"))
        for side: Float in [1] {
            let pts = (0...140).map { k -> V3 in var p = se(2 * Float.pi * Float(k % 140) / 140); p.z = side * 0.0058; return p }
            bag.add(K.stitch(along: pts, normal: { V3($0.x / (a * a), $0.y / (b * b), 0).normalized }, pitch: 0.011, thread: 0.0005, material: thread))
        }

        // ---- Front pocket with a box pleat ----
        let px: Float = 0.158, pyTop: Float = -0.055, pyBot: Float = -0.140
        func pocketPt(_ u: Float, _ v: Float) -> V3 {
            let x = (u - 0.5) * 2 * px, y = pyTop + (pyBot - pyTop) * v
            let eU = abs(2 * u - 1), eV = abs(2 * v - 1)
            let edge = 1 - 0.7 * pow(max(eU, eV), 7)
            let pleat = 0.0045 * (1 - smoothstep(0.008, 0.017, abs(x)))
            let z = frontZ(x, y)
            return lifted(V3(x, y, z), 0.0034 * edge + 0.0015 + pleat)
        }
        bag.add(ShoulderKit.shell(cols: 18, rows: 6, thick: 0.004, centre: .zero, material: shell) { u, v in pocketPt(u, v) })
        let po = (0...48).map { k -> V3 in
            let t = Float(k) / 48
            let corner: (Float, Float) = t < 0.25 ? (0.04 + 0.92 * t / 0.25, 0.93) : t < 0.5 ? (0.96, 0.93 - 0.86 * (t - 0.25) / 0.25) : t < 0.75 ? (0.96 - 0.92 * (t - 0.5) / 0.25, 0.07) : (0.04, 0.07 + 0.86 * (t - 0.75) / 0.25)
            var p = pocketPt(corner.0, corner.1); p = lifted(p, 0.0004); return p
        }
        bag.add(K.stitch(along: po, normal: { grad($0) }, pitch: 0.006, thread: 0.0005, material: thread))
        for sx: Float in [-0.016, 0.016] {
            let pp = (0...10).map { k -> V3 in lifted(V3(sx, pyTop - 0.012 - 0.07 * Float(k) / 10, frontZ(sx, pyTop - 0.012 - 0.07 * Float(k) / 10)), 0.0085) }
            bag.add(K.stitch(along: pp, normal: { grad($0) }, pitch: 0.006, thread: 0.0005, material: thread))
        }
        // Leather label patch with rivets on the pocket.
        let lx: Float = 0.105, ly: Float = -0.112
        let lpC = V3(lx, ly, frontZ(lx, ly) + 0.0045)
        let ln = grad(V3(lx, ly, frontZ(lx, ly)))
        let lq = simd_quatf(from: V3(0, 0, 1), to: ln)
        bag.add(Prim.extrude(Shape2D.roundedRect(0.046, 0.026, radius: 0.002, segments: 3), depth: 0.0022, bevel: 0.0007, bevelSegments: 2, material: leather), Xform(translation: lpC, rotation: lq))
        let lr = Shape2D.roundedRect(0.040, 0.020, radius: 0.0012, segments: 2)
        bag.add(K.stitch(along: (lr + [lr[0]]).map { lpC + lq.act(V3($0.x, $0.y, 0.0014)) }, normal: { _ in ln }, pitch: 0.0032, thread: 0.0004, material: thread))
        for sx: Float in [-0.015, 0.015] { rivet(&bag, at: lpC + lq.act(V3(sx, 0, 0.0014)), normal: ln, radius: 0.0026, segments: 6, material: brass) }

        // ---- Flap: wraps the top and covers the upper two thirds of the front ----
        func yb(_ x: Float) -> Float { -0.080 + 0.045 * pow(abs(2 * x / W), 4) }
        func phiEnd(_ x: Float) -> Float {
            let s = sScale(x)
            let r = min(0.96, abs(yb(x)) / (b * s))
            return acos(-pow(r, ne / 2))
        }
        let flapLift: Float = 0.0058
        func flapPt(_ u: Float, _ v: Float, _ lift: Float = 0) -> V3 {
            let x = (u - 0.5) * W * 0.985
            let ph = -0.20 + (phiEnd(x) + 0.20) * v
            return lifted(sec(x, ph), flapLift + lift)
        }
        bag.add(ShoulderKit.shell(cols: 26, rows: 12, thick: 0.0032, centre: .zero, material: shell) { u, v in flapPt(u, v) })
        // Leather binding around the visible edge, stitch lines, and a taped corner.
        var edgePath: [V3] = []
        for k in 0...10 { edgePath.append(flapPt(0, 0.35 + 0.65 * Float(k) / 10, 0.0006)) }
        for k in 1...36 { edgePath.append(flapPt(Float(k) / 36, 1, 0.0006)) }
        for k in 1...10 { edgePath.append(flapPt(1, 1 - 0.65 * Float(k) / 10, 0.0006)) }
        bag.add(Prim.tube(edgePath, radii: edgePath.map { _ in 0.0030 }, sides: 5, seamTile: 0.01, material: leather, capEnd: false))
        var stPath: [V3] = []
        for k in 0...10 { stPath.append(flapPt(0.012, 0.35 + 0.60 * Float(k) / 10, 0.0034)) }
        for k in 1...36 { stPath.append(flapPt(0.012 + 0.976 * Float(k) / 36, 0.94, 0.0034)) }
        for k in 1...10 { stPath.append(flapPt(0.988, 0.94 - 0.59 * Float(k) / 10, 0.0034)) }
        bag.add(K.stitch(along: stPath, normal: { grad($0) }, pitch: 0.008, thread: 0.0005, material: thread))

        // Buckle straps from the flap onto the pocket, each ending in a tapered tail through a brass roller buckle.
        for sx: Float in [-0.092, 0.092] {
            let u0 = 0.5 + sx / (W * 0.985)
            var sp: [V3] = []
            let x = sx
            let phA = -0.20 + (phiEnd(x) + 0.20) * 0.30, phB = phiEnd(x) + 0.30
            for k in 0...16 {
                let t = Float(k) / 16
                let ph = phA + (phB - phA) * t
                let past = smoothstep(phiEnd(x) - 0.25, phiEnd(x) + 0.3, ph)
                sp.append(lifted(sec(x, ph), flapLift + 0.0032 * (1 - past * 0.55) + 0.0004))
            }
            _ = u0
            let nf: (V3) -> V3 = { grad($0) }
            let sf = K.frames(sp, normal: nf)
            bag.add(K.ribbon(sf, width: 0.030, thick: 0.0036, radius: 0.0012, segments: 1, widthScale: { 1 - 0.5 * smoothstep(0.86, 1.0, $0) }, material: leather))
            bag.add(K.stitch(along: K.offset(sf, w: 0.0105, n: 0.0021), normal: nf, pitch: 0.007, thread: 0.0005, material: thread))
            bag.add(K.stitch(along: K.offset(sf, w: -0.0105, n: 0.0021), normal: nf, pitch: 0.007, thread: 0.0005, material: thread))
            // Roller buckle on a short leather tab sewn to the pocket.
            let by: Float = -0.094
            let bp = V3(x, by, frontZ(x, by) + 0.0025)
            let bn = grad(V3(x, by, frontZ(x, by)))
            let bq = simd_quatf(from: V3(0, 0, 1), to: bn)
            bag.add(Prim.extrude(Shape2D.roundedRect(0.030, 0.044, radius: 0.0025, segments: 3), depth: 0.0030, bevel: 0.0008, bevelSegments: 2, material: leather),
                    Xform(translation: bp + bq.act(V3(0, -0.012, 0)), rotation: bq))
            bag.add(ShoulderKit.ring(0.036, 0.030, wire: 0.0021, radius: 0.0055, sides: 6, material: sx < 0 ? "metal.nickel-worn" : brass), Xform(translation: bp + bq.act(V3(0, 0.002, 0.0055)), rotation: bq))
            bag.add(Prim.tube([bp + bq.act(V3(-0.018, 0.0, 0.0056)), bp + bq.act(V3(0.018, 0.0, 0.0056))], radii: [0.0017, 0.0017], sides: 6, seamTile: 0.01, material: brass))
            rivet(&bag, at: bp + bq.act(V3(0, -0.028, 0.0014)), normal: bn, radius: 0.0028, segments: 6, material: brass)
            rivet(&bag, at: bp + bq.act(V3(0, -0.020, 0.0014)), normal: bn, radius: 0.0028, segments: 6, material: brass)
        }

        // Canvas repair patch with a zigzag stitch on the pocket.
        let rx: Float = -0.085, ry: Float = -0.105
        let rpC = V3(rx, ry, frontZ(rx, ry) + 0.0040)
        let rn = grad(V3(rx, ry, frontZ(rx, ry)))
        let rq = simd_quatf(from: V3(0, 0, 1), to: rn)
        bag.add(Prim.extrude(Shape2D.roundedRect(0.052, 0.036, radius: 0.001, segments: 2), depth: 0.0020, bevel: 0.0005, bevelSegments: 1, material: "fabric.canvas:5C6745"), Xform(translation: rpC, rotation: rq))
        let zz = (0...16).map { k -> V3 in rpC + rq.act(V3(-0.022 + 0.044 * Float(k) / 16, (k % 2 == 0 ? 0.0145 : -0.0145), 0.0014)) }
        bag.add(K.stitch(along: zz, normal: { _ in rn }, pitch: 0.003, thread: 0.0004, material: "fabric.canvas:D9CFA8"))
        let rr = Shape2D.roundedRect(0.047, 0.031, radius: 0.0008, segments: 1)
        bag.add(K.stitch(along: (rr + [rr[0]]).map { rpC + rq.act(V3($0.x, $0.y, 0.0014)) }, normal: { _ in rn }, pitch: 0.0035, thread: 0.0004, material: "fabric.canvas:D9CFA8"))
        // Leather grab handle on the top of the flap.
        func topAt(_ x: Float) -> Float { b * sScale(x) + flapLift + 0.0032 }
        var hp: [V3] = []
        for x in stride(from: Float(-0.075), through: -0.052, by: 0.0115) { hp.append(V3(x, topAt(x), 0.0)) }
        for k in 1..<10 { let t = Float.pi - Float.pi * Float(k) / 10; hp.append(V3(cos(t) * 0.05, topAt(0.05) + 0.0035 + sin(t) * 0.030, 0)) }
        for x in stride(from: Float(0.052), through: 0.075, by: 0.0115) { hp.append(V3(x, topAt(x), 0.0)) }
        let hf = K.frames(hp, normal: { _ in V3(0, 0, 1) }).map { f -> K.Frame in var q = f; q.w = V3(0, 0, 1); q.n = simd_cross(q.t, q.w); return q }
        bag.add(K.ribbon(hf, width: 0.026, thick: 0.0046, radius: 0.0016, segments: 1, material: leather))
        for sx: Float in [-1, 1] {
            let cx = sx * 0.064, cy = topAt(cx) + 0.0026
            for sz: Float in [-0.0075, 0.0075] { for dx: Float in [-0.0075, 0.0075] {
                rivet(&bag, at: V3(cx + dx, cy, sz), normal: V3(0, 1, 0), radius: 0.0026, segments: 6, material: brass)
            }}
        }
        // Leather-wrapped D-ring tabs on both ends.
        for sx: Float in [-1, 1] {
            let xe = sx * a * 0.995
            bag.add(Prim.extrude(Shape2D.roundedRect(0.038, 0.052, radius: 0.004, segments: 3), depth: 0.0042, bevel: 0.001, bevelSegments: 2, material: leather),
                    Xform(translation: V3(xe + sx * 0.005, 0.06, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            bag.add(ShoulderKit.ring(0.034, 0.040, wire: 0.0030, radius: 0.012, sides: 6, material: brass),
                    Xform(translation: V3(xe + sx * 0.026, 0.066, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            for dy: Float in [0.048, 0.072] { rivet(&bag, at: V3(xe - sx * 0.0006, dy, 0.0), normal: V3(sx, 0, 0), radius: 0.0030, segments: 6, material: brass) }
        }
        // Luggage tag hanging from the handle.
        bag.add(Prim.tube([V3(-0.060, topAt(-0.060) + 0.004, 0), V3(-0.066, topAt(-0.066) - 0.01, 0.002), V3(-0.066, topAt(-0.066) - 0.022, 0.006)], radii: [0.0010, 0.0010, 0.0010], sides: 4, seamTile: 0.01, material: "fabric.canvas:D9CFA8", capEnd: false))
        bag.add(Prim.extrude(Shape2D.roundedRect(0.026, 0.040, radius: 0.004, segments: 3), depth: 0.0018, bevel: 0.0005, bevelSegments: 1, material: "leather.tan"),
                Xform(translation: V3(-0.066, topAt(-0.066) - 0.044, 0.010), rotation: simd_quatf(degrees: 14, axis: V3(1, 0, 0))))
        m.add(bag, Xform(translation: C, rotation: bagQ))

        // ---- Strap over the shoulder to the end D-rings ----
        let tw: Float = 0.045, tt: Float = 0.0046
        func attach(_ zs: Float) -> V3 { V3(C.x, C.y + 0.066, zs * (a + 0.026 + 0.004)) }
        let over = ShoulderKit.over(x: 0.012, off: 0.0133, steps: 12, legY: -0.12, legSpread: 0.0, legSteps: 3)
        var ctrl: [V3] = []
        ctrl.append(attach(1)); ctrl.append(V3(0.075, -0.30, 0.155)); ctrl.append(V3(0.045, -0.22, 0.095))
        ctrl += over
        ctrl.append(V3(0.045, -0.22, -0.095)); ctrl.append(V3(0.075, -0.30, -0.155)); ctrl.append(attach(-1))
        let nOver = over.count
        let frontCh = catmull(Array(ctrl[0..<3]) + [over[0]], per: 4)
        let backCh = catmull([over[nOver - 1]] + Array(ctrl[(3 + nOver)...]), per: 4)
        let path = frontCh + Array(over.dropFirst()) + Array(backCh.dropFirst())
        let nf: (V3) -> V3 = { ShoulderKit.bodyNormal($0) }
        let sf = K.frames(path, normal: nf)
        m.add(K.ribbon(sf, width: tw, thick: tt, radius: 0.0015, segments: 1, material: webbing))
        m.add(K.stitch(along: Array(K.offset(sf, w: 0.0165, n: tt / 2 + 0.0003)), normal: nf, pitch: 0.02, thread: 0.0007, material: thread))
        m.add(K.stitch(along: Array(K.offset(sf, w: -0.0165, n: tt / 2 + 0.0003)), normal: nf, pitch: 0.02, thread: 0.0007, material: thread))
        // Padded shoulder section.
        let padPts = ShoulderKit.over(x: 0.012, off: 0.0058, steps: 12).dropFirst(1).dropLast(1)
        let pf = K.frames(Array(padPts), normal: nf)
        m.add(K.ribbon(pf, width: 0.080, thick: 0.0105, radius: 0.0048, segments: 3, widthScale: { 0.82 + 0.18 * sin(Float.pi * $0) }, material: pad))
        for off: Float in [-0.026, 0.0, 0.026] {
            m.add(K.stitch(along: K.offset(pf, w: off, n: 0.0053), normal: nf, pitch: 0.0055, thread: 0.0005, material: thread))
        }
        // Sun-faded strip along the top of the strap.
        let faded = Array(over.dropFirst(1).dropLast(1))
        let ff = K.frames(faded, normal: nf).map { f -> K.Frame in var q = f; q.p += q.n * (tt / 2 + 0.0004); return q }
        m.add(K.ribbon(ff, width: 0.036, thick: 0.0008, radius: 0.0003, segments: 1, material: "fabric.webbing:5D5A46"))
        // Leather wraps at both D-rings.
        for rng in [0...3, (sf.count - 4)...(sf.count - 1)] {
            let wr = sf[rng].map { f -> K.Frame in var q = f; q.p += q.n * (tt / 2 + 0.0012); return q }
            m.add(K.ribbon(wr, width: tw + 0.004, thick: 0.0026, radius: 0.001, segments: 1, material: leather))
        }
        // Slider adjuster on the front leg.
        let fi = sf.firstIndex { $0.p.y > -0.24 } ?? 10
        let f1 = sf[fi]
        let sq = K.basis(f1.t, f1.w)
        m.add(ShoulderKit.ring(0.056, 0.020, wire: 0.0022, radius: 0.004, sides: 6, material: brass), Xform(translation: f1.p + f1.n * (tt + 0.0014), rotation: K.basis(f1.w, f1.t)))
        m.add(Prim.tube([V3(-0.027, 0, 0), V3(0.027, 0, 0)], radii: [0.0022, 0.0022], sides: 8, seamTile: 0.01, material: brass), Xform(translation: f1.p + f1.n * (tt + 0.0014), rotation: K.basis(f1.w, f1.t)))
        _ = sq
        return LODModel(m)
    }
}
