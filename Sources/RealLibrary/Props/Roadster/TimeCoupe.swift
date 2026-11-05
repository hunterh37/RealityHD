import simd
import Foundation

/// Time coupe at 1:1: 4.20 x 1.85 x 1.16 m gullwing coupe in brushed stainless with a louvered rear
/// window, exposed flux conduits, a glowing coil module on the tail, amber rear vents, rubber tyres on
/// 15 in wheels and hover-conversion hubs. Generic original design, no brand marks.
/// Front is +Z, left is +X, origin at ground center.
///
/// Joints: `body` lifts 0...0.25 m (hover) and drives `fold-*` (wheels fold flat, 360 deg per m);
/// `door-l` 0...70 deg (`door-r` mimics); `steer-fl` -30...30 deg (`steer-fr` mimics);
/// `wheel-fl` 0...3600 deg spin (other wheels mimic).
public struct TimeCoupe: RealArticulated {
    public static let id = "time-coupe"
    public static let summary = "Time coupe at 1:1: brushed stainless gullwing coupe, louvered rear glass, flux conduits, glowing coils and vents, folding hover wheels."
    public static let tags = ["prop", "vehicle", "articulated", "metal", "stainless", "glass", "rubber", "light"]
    public static let budget = 30000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 1.2)

    /// Wheelbase in meters.
    public var wheelbase: Float = 2.45
    /// Overall length in meters.
    public var length: Float = 4.20
    /// Roof height in meters.
    public var height: Float = 1.16
    /// Front overhang in meters.
    public var frontOverhang: Float = 0.85
    /// Tyre outer radius in meters (15 in rim plus sidewall).
    public var tireRadius: Float = 0.30
    /// Body panel key.
    public var panel: MaterialKey = "metal.stainless"
    /// Glass key.
    public var glass: MaterialKey = "glass.lens-coated:0E1822"
    public init() {}

    static let corners = ["fl", "fr", "rl", "rr"]

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [14])
        let zF = length / 2, zR = -length / 2
        let zFA = zF - frontOverhang, zRA = zFA - wheelbase
        let R = tireRadius, track: Float = 1.58
        let archR: Float = 0.35, tireW: Float = 0.26
        let wellY: Float = 0.30
        let dark: MaterialKey = "plastic.matte:121315"
        // Profile keys in meters from the nose (x = zF - z): half-width, sill, deck (beltline), roof.
        let hwKeys: [(Float, Float)] = [(0, 0.62), (0.1, 0.78), (0.5, 0.88), (1.0, 0.925), (1.9, 0.91), (2.8, 0.90), (3.5, 0.925), (3.95, 0.92), (4.2, 0.84)]
        let topKeys: [(Float, Float)] = [(0, 0.40), (0.12, 0.54), (0.6, 0.70), (1.0, 0.76), (1.5, 0.78), (2.2, 0.80), (3.2, 0.82), (3.7, 0.86), (4.1, 0.84), (4.2, 0.78)]
        let botKeys: [(Float, Float)] = [(0, 0.22), (0.1, 0.16), (0.5, 0.12), (4.2, 0.12)]
        let roofKeys: [(Float, Float)] = [(1.3, 0.80), (1.9, 1.04), (2.5, height), (3.1, height - 0.02), (3.6, 1.04), (3.9, 0.92), (4.05, 0.86), (4.1, 0.84)]
        func X(_ z: Float) -> Float { zF - z }
        func section(_ z: Float) -> CK.Section { .init(halfWidth: CK.curve(hwKeys, X(z)), bottom: CK.curve(botKeys, X(z)), top: CK.curve(topKeys, X(z))) }
        func belt(_ z: Float) -> Float { section(z).top }
        func roofY(_ z: Float) -> Float { max(belt(z) + 0.01, CK.curve(roofKeys, X(z))) }
        func wBelt(_ z: Float) -> Float { section(z).halfWidth * 0.80 }
        func wTop(_ z: Float) -> Float { wBelt(z) * 0.72 }
        func stations(_ a: Float, _ b: Float, _ c: Int) -> [Float] { (0...c).map { a + (b - a) * Float($0) / Float(c) } }
        func smooth(_ a: Float, _ b: Float, _ v: Float) -> Float { let t = min(1, max(0, (v - a) / (b - a))); return t * t * (3 - 2 * t) }
        func archY(_ z: Float) -> Float {
            var y: Float = 0
            for za in [zFA, zRA] { let dz = abs(z - za); if dz < archR { y = max(y, R + (archR * archR - dz * dz).squareRoot()) } }
            return y
        }
        // Cockpit well: the deck sinks to wellY between the cowl and the tail deck.
        func wellFactor(_ z: Float) -> Float { smooth(1.35, 1.75, X(z)) * (1 - smooth(3.3, 3.7, X(z))) }
        func bodyRing(_ z: Float, points: Int) -> [V3] {
            let ay = archY(z), s = section(z)
            let mid = (s.top + s.bottom) / 2, h = (s.top - s.bottom) / 2
            let depth = (s.top - wellY) * wellFactor(z)
            return CK.ring(s, z: z, n: 5, tumble: 0.06, points: points).map { p in
                var q = p
                q.x *= 1 - 0.07 * min(1, max(0, (0.30 - p.y) / 0.19))
                if ay > p.y { q.y = p.y + smooth(0.50, 0.70, abs(p.x)) * (ay - p.y) }
                if depth > 0 && p.y > mid {
                    q.y -= depth * (1 - smooth(0.56, 0.70, abs(p.x))) * smooth(0.6, 0.9, (p.y - mid) / h)
                }
                return q
            }
        }
        func bodyStations(_ base: Int, step: Float) -> [Float] {
            var s = stations(zF, zR, base)
            for za in [zFA, zRA] {
                s.append(za + archR + 0.004)
                var d = archR
                while d > -archR { s.append(za + d); d -= step }
                s.append(za - archR); s.append(za - archR - 0.004)
            }
            return s.filter { $0 <= zF && $0 >= zR }.sorted(by: >).reduce(into: [Float]()) { if let l = $0.last, l - $1 < 0.002 { return }; $0.append($1) }
        }
        /// Height of the upper body surface at lateral x (for trim that rides the shoulder).
        func shoulderY(_ z: Float, _ x: Float) -> Float {
            let s = section(z), mid = (s.top + s.bottom) / 2
            let r = bodyRing(z, points: 96).filter { $0.y > mid }
            return r.min(by: { abs($0.x - x) < abs($1.x - x) })?.y ?? s.top
        }
        func crown(_ z: Float, _ f: Float, _ o: Float) -> V3 {
            let b = belt(z) - 0.05, H = max(0.006, roofY(z) - b), th = Float.pi * f
            let c = cos(th), sn = max(0, sin(th))
            let yy = H * pow(sn, 2 / 3), w = wBelt(z) + (wTop(z) - wBelt(z)) * (yy / H)
            return V3((w + o) * copysign(pow(abs(c), 2 / 3), c), b + yy + o * sn, z)
        }
        func strip(_ z: Float, _ a0: Float, _ a1: Float, points: Int, outset: Float, thick: Float) -> [V3] {
            CK.crownStrip(z: z, belt: belt(z) - 0.05, roof: roofY(z), wBelt: wBelt(z), wTop: wTop(z), n: 3, a0: a0, a1: a1, points: points, outset: outset, thick: thick)
        }
        func fullGlass(_ z: Float, points: Int, o: Float) -> [V3] {
            CK.cabinRing(z: z, belt: belt(z) - 0.05, roof: roofY(z), wBelt: wBelt(z), wTop: wTop(z), n: 3, points: points, outset: o)
        }
        /// Thin lower door skin on side `sx`: outer arc of the body ring between the sill line and the beltline.
        func skin(_ z: Float, sx: Float, points: Int) -> [V3] {
            let s = section(z)
            let r = bodyRing(z, points: points)
            let idx = r.indices.filter { r[$0].x * sx > 0.02 && r[$0].y < s.top - 0.045 && r[$0].y > 0.34 }
            guard let k0 = idx.first, let k1 = idx.last, k1 > k0 + 1 else { return [] }
            func off(_ k: Int, _ d: Float) -> V3 {
                let a = r[max(0, k - 1)], b = r[min(r.count - 1, k + 1)]
                let t = V3(b.x - a.x, b.y - a.y, 0)
                let n = V3(-t.y, t.x, 0).normalized
                return V3(r[k].x + n.x * d, r[k].y + n.y * d, z)
            }
            let outer = (k0...k1).map { off($0, 0.010) }
            let inner = (k0...k1).reversed().map { off($0, -0.012) }
            return outer + inner
        }
        func ringPath(center c: V3, radius rad: Float, steps: Int = 48) -> [V3] {
            (0...steps).map { i in let a = Float(i) / Float(steps) * 2 * .pi; return c + V3(0, rad * cos(a), rad * sin(a)) }
        }
        let toX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))

        // ---- Body (hover joint: lifts the whole car; wheels, doors and steering hang off it) ----
        rig.part("body", pivot: V3(0, 0.5, 0), joint: .slide(axis: V3(0, 1, 0), 0...0.25, duration: 1.8))
        for l in 0..<2 {
            let lo = l...l
            let pts = l == 0 ? 36 : 20
            rig.add(Prim.loft(bodyStations(l == 0 ? 64 : 22, step: l == 0 ? 0.06 : 0.12).map { bodyRing($0, points: pts) }, capStart: true, capEnd: true, material: panel), to: "body", lods: lo)

            // Cabin zones: windscreen (X 1.30...1.95), door bay (1.95...3.35), rear glass (3.35...3.90).
            let wsN = l == 0 ? 10 : 5, doorN = l == 0 ? 14 : 8, rgN = l == 0 ? 10 : 5
            let ringPts = l == 0 ? 20 : 12
            rig.add(Prim.loft(stations(zF - 1.30, zF - 1.95, wsN).map { fullGlass($0, points: ringPts, o: 0.02) }, capStart: true, capEnd: true, material: glass), to: "body", lods: lo)
            rig.add(Prim.loft(stations(zF - 3.35, zF - 3.90, rgN).map { fullGlass($0, points: ringPts, o: 0.02) }, capStart: true, capEnd: true, material: glass), to: "body", lods: lo)
            // Centre roof panel between the doors, stainless over a glass T-bar.
            rig.add(Prim.loft(stations(zF - 1.95, zF - 3.35, doorN).map { strip($0, 0.36, 0.64, points: l == 0 ? 8 : 5, outset: 0.014, thick: 0.02) }, capStart: true, capEnd: true, material: panel), to: "body", lods: lo)
        }
        // Louvers over the rear glass: tilted stainless fins that follow the crown.
        for i in 0..<12 {
            let z = zF - 3.42 - Float(i) * 0.038
            rig.add(Prim.loft([strip(z, 0.12, 0.88, points: 10, outset: 0.034, thick: 0.006), strip(z - 0.026, 0.12, 0.88, points: 10, outset: 0.012, thick: 0.006)],
                              capStart: true, capEnd: true, material: panel), to: "body", lods: 0...0)
        }
        // Rocker strips and front splitter.
        for sx: Float in [-1, 1] {
            rig.add(cuboid(V3(0.03, 0.045, zFA - zRA - 2 * archR - 0.1), material: dark), Xform(translation: V3(sx * 0.86, 0.15, (zFA + zRA) / 2)), to: "body")
        }
        rig.add(cuboid(V3(1.2, 0.02, 0.05), material: dark), Xform(translation: V3(0, 0.12, zF - 0.02)), to: "body")
        // Nose intake and headlamps.
        rig.add(cuboid(V3(0.9, 0.05, 0.012), material: dark), Xform(translation: V3(0, 0.30, zF + 0.002)), to: "body")
        for sx: Float in [-1, 1] {
            let lp = V3(sx * 0.58, 0.56, zF - 0.42)
            let q = simd_quatf(angle: .pi / 2 - 0.12, axis: V3(1, 0, 0))
            for l in 0..<2 {
                rig.add(Prim.lathe([V2(0.085, -0.03), V2(0.095, -0.03), V2(0.095, 0.01), V2(0.085, 0.012)], segments: l == 0 ? 28 : 14, material: "metal.chrome"), Xform(translation: lp, rotation: q), to: "body", lods: l...l)
                rig.add(Prim.lathe([V2(0.0, 0.0), V2(0.08, 0.0), V2(0.08, 0.006), V2(0.0, 0.016)], segments: l == 0 ? 28 : 14, material: "emissive.lamp-white"), Xform(translation: lp + V3(0, 0, 0.01), rotation: q), to: "body", lods: l...l)
                rig.add(Prim.lathe([V2(0.0, 0.018), V2(0.082, 0.008), V2(0.083, 0.012), V2(0.0, 0.024)], segments: l == 0 ? 28 : 14, material: "glass.clear"), Xform(translation: lp + V3(0, 0, 0.012), rotation: q), to: "body", lods: l...l)
            }
        }
        // Tail: dark panel strip, red lamp bar, two amber vent banks with louver fins.
        rig.add(cuboid(V3(1.3, 0.015, 0.01), material: "emissive.tail-bar-red"), Xform(translation: V3(0, 0.66, zR - 0.004)), to: "body")
        for sx: Float in [-1, 1] {
            let cx = sx * 0.46, cy: Float = 0.38
            rig.add(cuboid(V3(0.50, 0.17, 0.006), material: "emissive.flux-vent"), Xform(translation: V3(cx, cy, zR - 0.003)), to: "body")
            for (w, h, dx, dy) in [(0.56, 0.02, Float(0), Float(0.095)), (0.56, 0.02, 0, -0.095), (0.02, 0.17, 0.27, 0), (0.02, 0.17, -0.27, 0)] as [(Float, Float, Float, Float)] {
                rig.add(cuboid(V3(w, h, 0.014), material: "metal.steel"), Xform(translation: V3(cx + dx, cy + dy, zR - 0.007)), to: "body")
            }
            for k in 0..<7 {
                rig.add(cuboid(V3(0.48, 0.012, 0.024), material: dark),
                        Xform(translation: V3(cx, cy - 0.07 + Float(k) * 0.0233, zR - 0.014), rotation: simd_quatf(angle: 0.45, axis: V3(1, 0, 0))), to: "body", lods: 0...0)
            }
        }
        // Flux coil module on the tail deck: glowing core, copper coil rings, steel end housings.
        let mz: Float = zR + 0.17, my: Float = 0.935
        rig.add(cuboid(V3(1.0, 0.025, 0.22), material: panel), Xform(translation: V3(0, 0.875, mz)), to: "body")
        for l in 0..<2 {
            rig.add(Prim.tube([V3(-0.42, my, mz), V3(0.42, my, mz)], radii: [0.055, 0.055], sides: l == 0 ? 28 : 12, seamTile: 0.1, material: "emissive.flux-coil"), to: "body", lods: l...l)
            for k in -2...2 {
                let t = Prim.tube(ringPath(center: V3(Float(k) * 0.14, my, mz), radius: 0.085, steps: l == 0 ? 32 : 18),
                                  radii: Array(repeating: 0.019, count: (l == 0 ? 32 : 18) + 1), sides: l == 0 ? 10 : 6, seamTile: 0.06, material: "metal.copper", capEnd: false)
                rig.add(t, to: "body", lods: l...l)
            }
            for sx: Float in [-1, 1] {
                let hp: [V2] = [V2(0, 0), V2(0.105, 0), V2(0.105, 0.075), V2(0.09, 0.088), V2(0, 0.088)]
                rig.add(Prim.lathe(hp, segments: l == 0 ? 36 : 14, material: panel), Xform(translation: V3(sx * 0.40, my, mz), rotation: simd_quatf(angle: sx > 0 ? -.pi / 2 : .pi / 2, axis: V3(0, 0, 1))), to: "body", lods: l...l)
            }
        }
        // Flux conduits: stainless main line and a copper return along each shoulder, ending in port collars.
        for sx: Float in [-1, 1] {
            let lines: [(Float, Float, Float, MaterialKey)] = [(0, -1.32, 0.016, panel), (-0.036, -1.12, 0.011, "metal.copper")]
            for (xo, zEnd, rad, mat) in lines {
                var path: [V3] = []
                let n = 24, z0 = mz - 0.02
                for i in 0...n {
                    let t = Float(i) / Float(n), z = z0 + (zEnd - z0) * t
                    let x = 0.52 + (0.80 - 0.52 + xo) * smooth(0, 0.55, t)
                    let ys = shoulderY(z, x) + rad + 0.004
                    let y = my + (ys - my) * smooth(0, 0.5, t)
                    path.append(V3(sx * x, y, z))
                }
                rig.add(Prim.tube(path, radii: Array(repeating: rad, count: path.count), sides: 10, seamTile: 0.08, material: mat), to: "body", lods: 0...0)
                let lite = path.enumerated().filter { $0.offset % 3 == 0 || $0.offset == path.count - 1 }.map { $0.element }
                rig.add(Prim.tube(lite, radii: Array(repeating: rad, count: lite.count), sides: 8, seamTile: 0.08, material: mat), to: "body", lods: 1...1)
                if let e = path.last {
                    rig.add(Prim.superellipsoid(V3(rad * 4.2, rad * 4.2, 0.05), exponent: 3, subdivisions: 8, material: "metal.chrome"), Xform(translation: e), to: "body")
                }
            }
        }
        // Hover emitters under each corner (visible once the body lifts).
        for (ex, ez) in [(0.45, 1.0), (-0.45, 1.0), (0.45, -1.0), (-0.45, -1.0)] as [(Float, Float)] {
            rig.add(Prim.lathe([V2(0, 0), V2(0.115, 0), V2(0.115, 0.024), V2(0, 0.024)], segments: 20, material: "emissive.flux-coil"), Xform(translation: V3(ex, 0.098, ez)), to: "body")
            rig.add(Prim.lathe([V2(0.115, 0), V2(0.15, 0), V2(0.15, 0.03), V2(0.115, 0.03)], segments: 20, material: "metal.steel"), Xform(translation: V3(ex, 0.095, ez)), to: "body")
        }
        // Interior: carpet, two bucket seats, dash, steering wheel.
        rig.add(cuboid(V3(1.08, 0.008, 1.55), material: "rubber.floor-mat"), Xform(translation: V3(0, wellY + 0.004, zF - 2.55)), to: "body", lods: 0...0)
        for sx: Float in [-1, 1] {
            let sz = zF - 2.70
            rig.add(Prim.superellipsoid(V3(0.46, 0.14, 0.52), exponent: 4, subdivisions: 5, material: "leather.black"), Xform(translation: V3(sx * 0.30, 0.40, sz)), to: "body", lods: 0...0)
            rig.add(Prim.superellipsoid(V3(0.46, 0.56, 0.12), exponent: 4, subdivisions: 5, material: "leather.black"),
                    Xform(translation: V3(sx * 0.30, 0.66, sz - 0.25), rotation: simd_quatf(angle: -0.22, axis: V3(1, 0, 0))), to: "body", lods: 0...0)
            rig.add(Prim.superellipsoid(V3(0.20, 0.14, 0.09), exponent: 3, subdivisions: 4, material: "leather.black"),
                    Xform(translation: V3(sx * 0.30, 0.99, sz - 0.31), rotation: simd_quatf(angle: -0.22, axis: V3(1, 0, 0))), to: "body", lods: 0...0)
        }
        rig.add(Prim.roundedBox(V3(1.10, 0.34, 0.42), radius: 0.03, material: "leather.black"), Xform(translation: V3(0, 0.50, zF - 1.52)), to: "body", lods: 0...0)
        rig.add(cuboid(V3(0.56, 0.012, 0.02), material: "emissive.flux-coil"), Xform(translation: V3(0.30, 0.672, zF - 1.62)), to: "body", lods: 0...0)
        let sw = V3(0.30, 0.70, zF - 1.95)
        rig.add(Prim.tube((0...40).map { i in let a = Float(i) / 40 * 2 * .pi; return sw + V3(0.15 * cos(a), 0.15 * sin(a), 0) },
                          radii: Array(repeating: 0.014, count: 41), sides: 12, seamTile: 0.05, material: "leather.black", capEnd: false), to: "body", lods: 0...0)
        rig.add(Prim.tube([sw, V3(0.30, 0.64, zF - 1.76)], radii: [0.016, 0.016], sides: 10, seamTile: 0.05, material: "metal.steel"), to: "body", lods: 0...0)

        // ---- Gullwing doors: glass side window plus lower skin, hinged on the roof edge ----
        let dz0 = zF - 1.95, dz1 = zF - 3.35, dzm = (dz0 + dz1) / 2
        for sx: Float in [1, -1] {
            let name = sx > 0 ? "door-l" : "door-r"
            let hinge = crown(dzm, sx > 0 ? 0.36 : 0.64, 0)
            let joint: Joint = sx > 0 ? .hinge(axis: V3(0, 0, 1), 0...70, duration: 1.4)
                                      : Joint(.revolute, axis: V3(0, 0, -1), range: 0...70, duration: 1.4, mimic: .init("door-l"))
            rig.part(name, parent: "body", pivot: hinge, joint: joint)
            for l in 0..<2 {
                let n = l == 0 ? 14 : 8
                let st = stations(dz0, dz1, n)
                let (f0, f1): (Float, Float) = sx > 0 ? (0.0, 0.36) : (0.64, 1.0)
                rig.add(Prim.loft(st.map { strip($0, f0, f1, points: l == 0 ? 12 : 6, outset: 0.022, thick: 0.016) }, capStart: true, capEnd: true, material: glass), to: name, lods: l...l)
                let rings = st.map { skin($0, sx: sx, points: l == 0 ? 48 : 28) }
                if rings.allSatisfy({ $0.count == rings[0].count && $0.count > 3 }) {
                    rig.add(Prim.loft(rings, capStart: true, capEnd: true, material: panel), to: name, lods: l...l)
                }
            }
            let hx = CK.sideX(section(dzm - 0.45), y: 0.60, n: 5, tumble: 0.06) + 0.012
            rig.add(cuboid(V3(0.012, 0.025, 0.16), material: dark), Xform(translation: V3(sx * hx, 0.62, dzm - 0.45)), to: name)
        }

        // ---- Wheels: steer (front), fold flat for hover, spin ----
        let spec = CK.WheelSpec(tireRadius: R, tireWidth: tireW, rimRadius: 0.19, lugs: 5, pcdRadius: 0.05715, spokes: 5,
                                rim: "metal.stainless", rubber: "rubber.tire-worn")
        for (ci, c) in Self.corners.enumerated() {
            let sx: Float = ci % 2 == 0 ? 1 : -1
            let front = ci < 2
            let ctr = V3(sx * track / 2, R, front ? zFA : zRA)
            var parent = "body"
            if front {
                rig.part("steer-\(c)", parent: "body", pivot: ctr,
                         joint: ci == 0 ? .hinge(axis: .up, -30...30, duration: 1.0) : Joint(.revolute, axis: .up, range: -30...30, duration: 1.0, mimic: .init("steer-fl")))
                parent = "steer-\(c)"
            }
            rig.part("fold-\(c)", parent: parent, pivot: ctr,
                     joint: Joint(.revolute, axis: V3(0, 0, sx), range: 0...90, duration: 1.8, mimic: .init("body", ratio: 360)))
            let name = "wheel-\(c)"
            rig.part(name, parent: "fold-\(c)", pivot: ctr,
                     joint: ci == 0 ? .hinge(axis: V3(1, 0, 0), 0...3600, duration: 4) : Joint(.revolute, axis: V3(1, 0, 0), range: 0...3600, duration: 4, mimic: .init("wheel-fl")))
            let x = Xform(translation: ctr, rotation: sx > 0 ? .identity : simd_quatf(angle: .pi, axis: .up))
            let face = tireW / 2 - 0.03
            for l in 0..<2 {
                for s in CK.wheel(spec, lod: l) { rig.add(s, x, to: name, lods: l...l) }
                // Hover-conversion hub: glowing flux ring and eight steel fins on the outer face.
                rig.add(Prim.lathe([V2(0.052, 0), V2(0.078, 0), V2(0.078, 0.008), V2(0.052, 0.008)], segments: l == 0 ? 32 : 16, material: "emissive.flux-coil")
                    .transformed(Xform(translation: V3(face + 0.004, 0, 0), rotation: toX)), x, to: name, lods: l...l)
                for i in 0..<spec.lugs { for s in CK.lug(at: CK.lugPosition(spec, i), lod: l) { rig.add(s, x, to: name, lods: l...l) } }
            }
            for f in 0..<8 {
                let a = Float(f) * .pi / 4
                rig.add(cuboid(V3(0.010, 0.07, 0.018), material: "metal.steel").transformed(
                            Xform(translation: V3(face + 0.01, 0.115 * cos(a), 0.115 * sin(a)), rotation: simd_quatf(angle: a, axis: V3(1, 0, 0)))),
                        x, to: name, lods: 0...0)
            }
        }

        // ---- Lights ----
        for sx: Float in [-1, 1] {
            rig.lights.append(RigLight(name: "headlamp-\(sx > 0 ? "l" : "r")", kind: .spot(inner: 18, outer: 42), part: "body", position: V3(sx * 0.58, 0.56, zF - 0.30),
                                       direction: V3(0, -0.10, 1), color: V3(1, 0.95, 0.85), intensity: 1200, attenuationRadius: 9))
        }
        rig.lights.append(RigLight(name: "flux-glow", part: "body", position: V3(0, my + 0.1, mz), color: V3(0.4, 0.72, 1), intensity: 350, attenuationRadius: 3))
        rig.lights.append(RigLight(name: "vent-glow", part: "body", position: V3(0, 0.38, zR - 0.15), color: V3(1, 0.45, 0.1), intensity: 250, attenuationRadius: 2.5))

        groundAO(&rig, height: 0.25)
        rig.states = [
            RigState("parked"),
            RigState("doors-open", ["door-l": 70]),
            RigState("rolling", ["wheel-fl": 360, "steer-fl": 8]),
            RigState("hover", ["body": 0.25, "wheel-fl": 180]),
        ]
        return rig
    }
}
