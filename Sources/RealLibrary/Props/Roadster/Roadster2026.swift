import simd
import Foundation

/// Roadster 2026 at 1:1: 4.30 x 2.00 x 1.20 m low wedge coupe, silver-white clearcoat, tinted glass,
/// full-width red tail bar, four wheels and four corner cold-gas thruster nozzles as named parts.
/// Front is +Z, left is +X, origin at ground center.
public struct Roadster2026: RealArticulated {
    public static let id = "roadster-2026"
    public static let summary = "Roadster 2026 at 1:1: silver-white wedge coupe, tinted glass, red tail bar, wheel-fl/fr/rl/rr and thruster-fl/fr/rl/rr parts."
    public static let tags = ["prop", "vehicle", "articulated"]
    public static let budget = 30000
    public static let author = "realityhd"

    /// Wheelbase in meters.
    public var wheelbase: Float = 2.80
    /// Overall length in meters.
    public var length: Float = 4.30
    /// Overall width in meters (no mirrors).
    public var width: Float = 2.00
    /// Roof height in meters.
    public var height: Float = 1.20
    /// Front overhang in meters.
    public var frontOverhang: Float = 0.95
    /// Tire radius in meters.
    public var tireRadius: Float = 0.36
    /// Body paint key.
    public var paint: MaterialKey = "paint.car-clearcoat-worn:E6E8EA"
    public init() {}

    static let corners = ["fl", "fr", "rl", "rr"]

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [16])
        let zF = length / 2, zR = -length / 2
        let zFA = zF - frontOverhang, zRA = zFA - wheelbase
        let R = tireRadius, track: Float = 1.62
        let archR: Float = 0.40, tireW: Float = 0.30
        let glass: MaterialKey = "glass.lens-coated:07090D"
        // Profile keys in meters from the nose (x = zF - z): half-width, sill, deck (beltline), roof.
        let hwKeys: [(Float, Float)] = [(0, 0.70), (0.1, 0.90), (0.5, 0.96), (0.95, 1.0), (1.8, 0.93), (2.6, 0.93), (3.3, 0.99), (3.75, 1.0), (4.15, 0.96), (4.3, 0.88)]
        let topKeys: [(Float, Float)] = [(0, 0.38), (0.1, 0.55), (0.5, 0.72), (0.95, 0.84), (1.5, 0.85), (2.4, 0.84), (3.3, 0.82), (3.75, 0.86), (4.1, 0.84), (4.3, 0.80)]
        let botKeys: [(Float, Float)] = [(0, 0.22), (0.1, 0.15), (0.5, 0.11), (4.3, 0.11)]
        let roofKeys: [(Float, Float)] = [(1.5, 0.85), (2.1, height), (3.0, 1.12), (3.9, 0.95), (4.1, 0.86), (4.15, 0.84)]
        func X(_ z: Float) -> Float { zF - z }
        func section(_ z: Float) -> CK.Section { .init(halfWidth: CK.curve(hwKeys, X(z)), bottom: CK.curve(botKeys, X(z)), top: CK.curve(topKeys, X(z))) }
        func belt(_ z: Float) -> Float { section(z).top }
        func roofY(_ z: Float) -> Float { max(belt(z) + 0.01, CK.curve(roofKeys, X(z))) }
        func wBelt(_ z: Float) -> Float { section(z).halfWidth * 0.80 }
        func stations(_ a: Float, _ b: Float, _ c: Int) -> [Float] { (0...c).map { a + (b - a) * Float($0) / Float(c) } }
        func archY(_ z: Float) -> Float {
            var y: Float = 0
            for za in [zFA, zRA] { let dz = abs(z - za); if dz < archR { y = max(y, R + (archR * archR - dz * dz).squareRoot()) } }
            return y
        }
        func smooth(_ a: Float, _ b: Float, _ v: Float) -> Float { let t = min(1, max(0, (v - a) / (b - a))); return t * t * (3 - 2 * t) }
        func bodyRing(_ z: Float, points: Int) -> [V3] {
            let ay = archY(z)
            return CK.ring(section(z), z: z, n: 5, tumble: 0.06, points: points).map { p in
                var q = p
                q.x *= 1 - 0.07 * min(1, max(0, (0.30 - p.y) / 0.19))
                if ay > p.y { q.y = p.y + smooth(0.50, 0.70, abs(p.x)) * (ay - p.y) }
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

        rig.part("body", pivot: V3(0, 0.5, 0), joint: .fixed)
        for l in 0..<2 {
            let lo = l...l
            let pts = l == 0 ? 44 : 20
            rig.add(Prim.loft(bodyStations(l == 0 ? 30 : 14, step: l == 0 ? 0.04 : 0.1).map { bodyRing($0, points: pts) }, capStart: true, capEnd: true, material: paint), to: "body", lods: lo)
            let gz = stations(zF - 1.5, zF - 4.05, l == 0 ? 20 : 8)
            func gring(_ z: Float, _ o: Float) -> [V3] {
                let b = belt(z) - 0.05, H = max(0.01, roofY(z) + o - b), w0 = wBelt(z) + o, w1 = min(0.70, wBelt(z)) + o
                var out: [V3] = []
                let up = (l == 0 ? 28 : 14) - 2
                for k in 0...up {
                    let th = Float.pi * Float(k) / Float(up)
                    let c = cos(th), sn = max(0, sin(th))
                    let yy = H * pow(sn, 2 / 3)
                    let w = w0 + (w1 - w0) * (yy / H)
                    out.append(V3(w * copysign(pow(abs(c), 2 / 3), c), b + yy, z))
                }
                out.append(V3(-w0 * 0.5, b, z))
                return Array(out.reversed())
            }
            rig.add(Prim.loft(gz.map { gring($0, 0.022) }, capStart: true, capEnd: true, material: glass), to: "body", lods: lo)
        }
        // Wear: dark road-grime rocker strips and arch lips (edge darkening), front splitter lip.
        for sx: Float in [-1, 1] {
            rig.add(cuboid(V3(0.03, 0.05, zFA - zRA - 2 * archR - 0.1), material: "plastic.matte:2B2A28"), Xform(translation: V3(sx * 0.86, 0.14, (zFA + zRA) / 2)), to: "body")
        }
        rig.add(cuboid(V3(1.5, 0.025, 0.05), material: "plastic.matte:2B2A28"), Xform(translation: V3(0, 0.1, zF - 0.02)), to: "body")
        // Rear: black diffuser below 0.35 m with four round nozzles, plate at 0.45 m, thin emissive tail bar inside body width.
        rig.add(cuboid(V3(1.3, 0.21, 0.03), material: "plastic.matte:0A0B0C"), Xform(translation: V3(0, 0.245, zR + 0.004)), to: "body")
        for k in 1..<6 { rig.add(cuboid(V3(0.012, 0.19, 0.034), material: "plastic.matte:1C1D1F"), Xform(translation: V3(-0.65 + Float(k) * 0.2167, 0.245, zR - 0.002)), to: "body") }
        for (i, _) in "RDSTR".enumerated() {
            rig.add(cuboid(V3(0.04, 0.06, 0.004), material: "plastic.matte:15161A"), Xform(translation: V3(-0.2 + Float(i) * 0.1, 0.45, zR - 0.017)), to: "body")
        }
        rig.add(cuboid(V3(1.48, 0.03, 0.02), material: "emissive.tail-bar-red"), Xform(translation: V3(0, 0.70, zR - 0.004)), to: "body")
        rig.add(cuboid(V3(0.5, 0.12, 0.012), material: "metal.painted:EDEDED"), Xform(translation: V3(0, 0.45, zR - 0.012)), to: "body")
        for nx: Float in [-0.45, -0.15, 0.15, 0.45] {
            let tube: [V2] = [V2(0.0, 0.0), V2(0.045, 0.0), V2(0.045, 0.06), V2(0.032, 0.06), V2(0.0, 0.05)]
            rig.add(Prim.lathe(tube, segments: 16, material: "metal.painted:1A1B1D"), Xform(translation: V3(nx, 0.235, zR + 0.02), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))), to: "body")
        }
        for sx: Float in [-1, 1] {
            rig.add(cuboid(V3(0.06, 0.02, 0.014), material: "emissive.lamp-white"), Xform(translation: V3(sx * 0.34, 0.45, zR - 0.004)), to: "body")
            rig.add(cuboid(V3(0.36, 0.026, 0.03), material: "emissive.lamp-white"), Xform(translation: V3(sx * 0.52, 0.42, zF - 0.035)), to: "body")
        }

        let spec = CK.WheelSpec(tireRadius: R, tireWidth: tireW, rimRadius: 0.25, lugs: 5, pcdRadius: 0.05715, spokes: 5,
                                rim: "metal.painted:2A2B2D", rubber: "rubber.tire-worn")
        for (ci, c) in Self.corners.enumerated() {
            let sx: Float = ci % 2 == 0 ? 1 : -1
            let z = ci < 2 ? zFA : zRA
            let ctr = V3(sx * track / 2, R, z)
            let name = "wheel-\(c)"
            rig.part(name, parent: "body", pivot: ctr, joint: .hinge(axis: V3(1, 0, 0), -3600...3600, duration: 4))
            let x = Xform(translation: ctr, rotation: sx > 0 ? .identity : simd_quatf(angle: .pi, axis: .up))
            for l in 0..<2 { for s in CK.wheel(spec, lod: l) { rig.add(s, x, to: name, lods: l...l) } }
            // Flush turbine cover on the outer face.
            let fins: [V2] = [V2(0.0, 0.0), V2(0.24, 0.0), V2(0.24, 0.012), V2(0.0, 0.03)]
            let ox: Float = 0.118
            rig.add(Prim.lathe(fins, segments: 24, material: "metal.painted:2A2B2D"), Xform(translation: ctr + V3(sx * ox, 0, 0), rotation: simd_quatf(angle: sx > 0 ? -.pi / 2 : .pi / 2, axis: V3(0, 0, 1))), to: name)
            for f in 0..<12 {
                let a = Float(f) * .pi / 6
                rig.add(cuboid(V3(0.012, 0.19, 0.03), material: "metal.painted:1A1B1D"),
                        Xform(translation: ctr + V3(sx * (ox + 0.02), 0, 0), rotation: simd_quatf(angle: a, axis: V3(1, 0, 0)) * simd_quatf(angle: 0.35, axis: V3(0, 1, 0))), to: name)
            }
            // Thruster nozzle under the corner, bell opening downward.
            let tn = "thruster-\(c)"
            let tp = V3(sx * 0.45, 0.16, ci < 2 ? zF - 0.4 : zR + 0.4)
            rig.part(tn, parent: "body", pivot: tp, joint: .fixed)
            let bell: [V2] = [V2(0.0, 0.03), V2(0.05, 0.03), V2(0.05, 0.0), V2(0.085, -0.07), V2(0.07, -0.07), V2(0.04, -0.03), V2(0.0, -0.03)]
            for l in 0..<2 {
                rig.add(Prim.lathe(bell, segments: l == 0 ? 16 : 8, material: "metal.painted:1A1B1D"), Xform(translation: tp), to: tn, lods: l...l)
                rig.add(Prim.lathe([V2(0.0, -0.068), V2(0.065, -0.068), V2(0.065, -0.072), V2(0.0, -0.072)], segments: l == 0 ? 12 : 6, material: "emissive.thruster-cyan"),
                        Xform(translation: tp), to: tn, lods: l...l)
            }
        }
        groundAO(&rig, height: 0.25)
        rig.states = [RigState("parked"), RigState("rolling", ["wheel-fl": 180, "wheel-fr": 180, "wheel-rl": 180, "wheel-rr": 180])]
        return rig
    }
}
