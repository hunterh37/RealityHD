import simd
import Foundation

/// Giant airborne moon jellyfish, 22 m bell diameter: translucent bell (64-station lathe, 48 radial) with
/// eight radial canals, a frilled rim of 16 hinged lappets, an emissive gonad ring, cyan and violet
/// bioluminescent spots, four 20 m oral arms and forty tapered 30 m trailing tentacles.
/// Origin at the bell centre, opening faces -Y, up +Y (bell apex at +4.5 m, tentacle tips near -34.5 m).
/// Joints: `pulse` 0...1 (bell lifts and the rim lappets fold in), `glow` 0...1 (spots brighten above 0.5),
/// `drift` -1...1 (tentacles trail sideways along X), `arms` 0...1 (oral arms unfurl outward).
public struct SkyJellyfish: RealArticulated {
    public static let id = "sky-jellyfish"
    public static let summary = "Giant sky jellyfish, 22 m translucent bell with frilled rim, glowing gonad ring, cyan and violet spots, four oral arms and forty trailing tentacles; pulse, glow, drift and arms joints."
    public static let tags = ["prop", "creature", "fantasy", "glowing", "glass", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: -6, distance: 1.6)

    /// Bell diameter at the rim (m).
    public var bellDiameter: Float = 22
    /// Bell height, apex to rim lip (m).
    public var bellHeight: Float = 9
    /// Oral arm length (m).
    public var armLength: Float = 20
    /// Trailing tentacle length (m).
    public var tentacleLength: Float = 30
    /// Bell and rim tint (translucent plastic hex suffix).
    public var bellMaterial: MaterialKey = "plastic.translucent:BFE4EE"
    /// Radial canal tint.
    public var canalMaterial: MaterialKey = "plastic.translucent:D9A8F2"
    /// Oral arm tint.
    public var armMaterial: MaterialKey = "plastic.translucent:D6B4F0"
    /// Tentacle tint.
    public var tentacleMaterial: MaterialKey = "plastic.translucent:A9DDF0"
    /// Gonad ring, violet emissive.
    public var gonadMaterial: MaterialKey = "emissive.die-tensor"
    /// Cyan spots at glow below 0.5, and above it.
    public var cyanDim: MaterialKey = "emissive.holo-grid"
    public var cyanBright: MaterialKey = "emissive.holo-plane"
    /// Violet spots.
    public var violetSpot: MaterialKey = "emissive.die-tensor"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        var rng = SeededRNG(seed: seed)
        let R = bellDiameter / 2, H = bellHeight, yBot = -H / 2
        let stations = 64, skirt = 19, radial = 48, sectors = 16

        // Bell profile, rim (i = 0) to apex (i = 63): ellipse with a slight flare, stations bunch at the rim.
        func phi(_ i: Int) -> Float { (.pi / 2) * pow(Float(i) / Float(stations - 1), 1.35) }
        func radius(_ i: Int) -> Float { i == stations - 1 ? 0 : R * pow(cos(phi(i)), 0.9) * (1 + 0.05 * pow(1 - Float(i) / Float(stations - 1), 3)) }
        func height(_ i: Int) -> Float { yBot + H * sin(phi(i)) }
        func surfacePoint(phi p: Float, az a: Float, inset: Float = 1) -> V3 {
            let r = R * pow(max(cos(p), 0), 0.9) * inset
            return V3(r * cos(a), yBot + H * sin(p) * inset, -r * sin(a))
        }

        // Pulse: the dome, canals and everything hung from it rise up to 1 m as the bell contracts.
        rig.part("pulse", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 1.4))
        rig.part("drift", pivot: .zero, joint: Joint(.prismatic, axis: V3(1, 0, 0), range: -1...1, duration: 2.5))
        rig.part("arms", pivot: .zero, joint: Joint(.prismatic, axis: V3(0, 0, 1), range: 0...1, duration: 2.0))
        rig.part("glow", pivot: .zero, joint: Joint(.prismatic, axis: V3(0, 0, 1), range: 0...1, duration: 1.2))

        // MARK: dome (stations skirt...63 outer, 12-station sub-umbrella, canals)
        let dome = (skirt..<stations).map { V2(radius($0), height($0)) }
        rig.add(Prim.lathe(dome, segments: radial, seamTile: 1.0, material: bellMaterial), to: "pulse")
        var inner: [V2] = []
        for j in 0..<12 {
            let p = phi(skirt) + (.pi / 2 - phi(skirt)) * Float(j) / 11
            let r = j == 11 ? 0 : R * pow(cos(p), 0.9) * 0.93
            inner.append(V2(r, yBot + H * sin(p) * 0.93 - 0.2))
        }
        rig.add(Prim.lathe(inner, segments: radial, seamTile: 1.0, material: bellMaterial), to: "pulse")
        for k in 0..<8 {
            let a = Float(k) * .pi / 4
            let pts = (0..<14).map { j -> V3 in surfacePoint(phi: phi(skirt) + (1.25 - phi(skirt)) * Float(j) / 13, az: a, inset: 0.975) }
            let radii = (0..<14).map { 0.16 - 0.08 * Float($0) / 13 }
            rig.add(Prim.tube(pts, radii: radii, sides: 6, seamTile: 0.2, material: canalMaterial), to: "pulse")
        }

        // MARK: frilled rim, 16 lappets that fold inward with `pulse`
        let sStep: Float = 2 * .pi / Float(sectors)
        for k in 0..<sectors {
            let name = "lappet\(k)"
            let mid = (Float(k) + 0.5) * sStep
            let tangent = V3(sin(mid), 0, cos(mid))
            let pivot = V3(radius(skirt) * cos(mid), height(skirt), -radius(skirt) * sin(mid))
            rig.part(name, parent: "pulse", pivot: pivot,
                     joint: Joint(.revolute, axis: tangent, range: 0...32, duration: 1.4, mimic: .init("pulse", ratio: 32)))
            var s = Surface(material: bellMaterial)
            let cols = radial / sectors + 1, row = UInt32(cols)
            for i in 0...skirt {
                let w = pow(1 - Float(i) / Float(skirt), 2)
                for c in 0..<cols {
                    let a = Float(k) * sStep + sStep * Float(c) / Float(cols - 1)
                    let frill = 1 + 0.035 * w * sin(24 * a)
                    let r = radius(i) * frill
                    let y = height(i) - 0.22 * w * abs(sin(12 * a))
                    s.add(V3(r * cos(a), y, -r * sin(a)), V3(cos(a), 0, -sin(a)), V2(a * R, Float(i) * 0.25))
                }
            }
            for i in 0..<skirt { for c in 0..<(cols - 1) {
                let b = UInt32(i) * row + UInt32(c)
                s.quad(b, b + 1, b + row + 1, b + row)
            }}
            s.recomputeNormals()
            s.computeTangents()
            rig.add(s, to: name)
        }

        // MARK: glow part: gonad ring and spots, option 0 dim, option 1 bright (larger, brighter cyan)
        rig.part("spots", parent: "pulse", pivot: .zero, joint: .fixed, options: 2)
        for o in 0..<2 {
            rig.add(Prim.torus(major: 3.0, minor: 0.55, segments: 40, sides: 8, minorY: 0.35 + 0.1 * Float(o), material: gonadMaterial),
                    Xform(translation: V3(0, 0.6, 0)), to: "spots", option: o)
        }
        var spotRNG = rng.fork(7)
        for n in 0..<20 {
            let p = spotRNG.float(0.45...1.28), a = spotRNG.float(0...(2 * .pi))
            let pos = surfacePoint(phi: p, az: a, inset: 1.004)
            let normal = V3(cos(a) * cos(p) * 0.9, sin(p) * 0.9 + 0.2, -sin(a) * cos(p) * 0.9).normalized
            let rot = simd_quatf(from: .up, to: normal)
            let size = spotRNG.float(0.45...0.9)
            for o in 0..<2 {
                let r = size * (o == 1 ? 1.35 : 1)
                let mat: MaterialKey = n % 2 == 0 ? (o == 1 ? cyanBright : cyanDim) : violetSpot
                rig.add(Prim.lathe([V2(0, 0.1), V2(r * 0.7, 0.08), V2(r, 0)], segments: 8, seamTile: 0.2, material: mat),
                        Xform(translation: pos, rotation: rot), to: "spots", option: o)
            }
        }
        rig.optionLinks = [RigOptionLink(part: "spots", joint: "glow", thresholds: [0.5])]
        rig.lights = [
            RigLight(name: "cyan-glow", part: "spots", option: 1, position: V3(0, -1, 0), direction: V3(0, -1, 0),
                     color: V3(0.2, 0.8, 1), intensity: 6000, attenuationRadius: 45),
            RigLight(name: "violet-core", part: "spots", option: 0, position: V3(0, 0.6, 0), direction: V3(0, -1, 0),
                     color: V3(0.6, 0.25, 1), intensity: 1500, attenuationRadius: 25),
        ]

        // MARK: oral arms, 20 m, unfurl outward with `arms`
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            let tangent = V3(sin(a), 0, cos(a))
            let top: Float = -1.0, n = 14
            let name = "arm\(k)"
            rig.part(name, parent: "pulse", pivot: V3(1.6 * cos(a), top, -1.6 * sin(a)),
                     joint: Joint(.revolute, axis: tangent, range: -32...0, duration: 2.0, mimic: .init("arms", ratio: -32)))
            let ph = rng.float(0...(2 * .pi))
            let path = (0..<n).map { j -> V3 in
                let t = Float(j) / Float(n - 1)
                let sway = 0.9 * sin(t * 5 + ph) * t
                return V3(1.6 * cos(a) + sway * cos(a + 1.2), top - armLength * t, -1.6 * sin(a) - sway * sin(a + 1.2))
            }
            let radii = (0..<n).map { 0.75 * pow(1 - Float($0) / Float(n), 0.8) + 0.12 }
            rig.add(Prim.tube(path, radii: radii, sides: 8, seamTile: 0.3, material: armMaterial,
                              rippling: { t, v in 1 + 0.28 * sin(t * 6 * .pi + v * 0.9) }), to: name)
        }

        // MARK: trailing tentacles, 40 tapered tubes 30 m long, all swing with `drift`
        rig.part("tentacles", parent: "pulse", pivot: V3(0, yBot, 0),
                 joint: Joint(.revolute, axis: V3(0, 0, 1), range: -14...14, duration: 2.5, mimic: .init("drift", ratio: 14)))
        for k in 0..<40 {
            let a = Float(k) * 2 * .pi / 40
            let r0 = R * 0.96
            let ph = rng.float(0...(2 * .pi)), amp = rng.float(0.4...1.4), len = rng.vary(tentacleLength, 0.07)
            let n = 8
            let path = (0..<n).map { j -> V3 in
                let t = Float(j) / Float(n - 1)
                let curl = amp * sin(t * 6 + ph) * t * 2
                return V3(r0 * cos(a) * (1 - 0.55 * t) + curl, yBot - len * t, -r0 * sin(a) * (1 - 0.55 * t) + curl * 0.6)
            }
            let radii = (0..<n).map { 0.22 * pow(1 - Float($0) / Float(n), 1.2) + 0.03 }
            rig.add(Prim.tube(path, radii: radii, sides: 6, seamTile: 0.2, material: tentacleMaterial), to: "tentacles")
        }

        rig.states = [
            RigState("rest"),
            RigState("pulse", ["pulse": 1]),
            RigState("glow", ["glow": 1], options: ["spots": 1]),
            RigState("drift-left", ["drift": -1]),
            RigState("drift-right", ["drift": 1]),
            RigState("bloom", ["pulse": 0.5, "glow": 1, "arms": 1, "drift": 0.4], options: ["spots": 1]),
        ]
        return rig
    }
}
