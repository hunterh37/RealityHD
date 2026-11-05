import simd
import Foundation

/// Carbon-fibre quadcopter, 0.85 m motor-to-motor diagonal with four 10 in props, X frame, four arms with motors, gimbal camera
/// under the nose, two landing skids and an emissive LED ring under the body. Origin at the centre of mass, front +Z, up +Y.
/// Joints: `spin` 0...1 (props turn one revolution, alternating direction), `tilt` -1...1 (body pitches +-20 degrees, positive is
/// nose down, the gimbal counter-rotates to stay level) and `led` 0...1 (ring off below 0.02, dim to 0.5, full above, with lights).
public struct DroneQuad: RealArticulated {
    public static let id = "drone-quad"
    public static let summary = "Carbon-fibre quadcopter, 0.85 m span: four arms with motors, 10 in props, gimbal camera, skids and an emissive LED ring with joints spin, tilt, led."
    public static let tags = ["prop", "vehicle", "aerospace", "drone", "gadget", "articulated"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.1, studio: true)

    /// Frame, arms, plates and legs.
    public var carbon: MaterialKey = "composite.carbon"
    /// Plates, clamps, mounts.
    public var hardware: MaterialKey = "metal.anodized-black"
    /// Motor bells.
    public var bell: MaterialKey = "metal.anodized-gunmetal"
    /// Propeller blades.
    public var blade: MaterialKey = "plastic.matte:1A1B1D"
    /// Battery and camera housing.
    public var housing: MaterialKey = "plastic.matte:1C1C1E"
    /// Lens glass.
    public var lens: MaterialKey = "glass.tinted"
    /// Skid feet.
    public var foot: MaterialKey = "rubber"
    /// LED ring colour at full intensity (recolour knob).
    public var led: MaterialKey = "emissive.led-green:2BE6FF"
    /// LED ring colour at half intensity.
    public var ledDim: MaterialKey = "emissive.led-green:0B5B66"
    /// LED ring when off.
    public var ledOff: MaterialKey = "glass.led-lens"
    /// Front arm tip lights.
    public var navFront: MaterialKey = "emissive.signal-white"
    /// Rear arm tip lights.
    public var navRear: MaterialKey = "emissive.signal-red"
    public init() {}

    private static let reach: Float = 0.30
    private static let armY: Float = 0.02
    private static let propY: Float = 0.100
    private static let propLen: Float = 0.1195
    private static let ringY: Float = -0.034
    private static let gimbalPivot = V3(0, -0.052, 0.125)

    private struct Rng {
        var s: UInt64
        mutating func f() -> Float {
            s = s &* 6364136223846793005 &+ 1442695040888963407
            return Float((s >> 40) & 0xFFFFFF) / Float(0x1000000)
        }
    }

    /// Propeller blade outline in XY, root at x = 0.010, tip rounded at x = 0.127.
    private static func bladeOutline() -> [V2] {
        let root: Float = 0.010
        let n = 14
        var low: [V2] = [], high: [V2] = []
        for i in 0...n {
            let t = Float(i) / Float(n)
            let w = 0.0062 + 0.0108 * sin(.pi * pow(t, 0.62)) * (1 - 0.35 * t)
            let x = root + propLen * t
            low.append(V2(x, -w * 0.82))
            high.append(V2(x, w * 1.12))
        }
        let tx = root + propLen
        let r: Float = 0.006
        let cy: Float = (-0.0051 + 0.0069) / 2
        var arc: [V2] = []
        for k in 1..<5 {
            let a = Float(k) / 5 * .pi
            arc.append(V2(tx + sin(a) * r, cy - cos(a) * r))
        }
        return low + arc + high.reversed()
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0)
        var rng = Rng(s: seed &* 2654435761 &+ 71)

        // Drivers first so mimics resolve.
        _ = rig.part("spin", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.2))
        _ = rig.part("tilt", pivot: .zero, joint: .hinge(axis: X, -1...1, duration: 0.8))
        _ = rig.part("led", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 0.5))

        _ = rig.part("tiltBody", pivot: .zero, joint: Joint(.revolute, axis: X, range: -30...30, mimic: .init("tilt", ratio: 20)))
        _ = rig.part("gimbal", parent: "tiltBody", pivot: Self.gimbalPivot, joint: Joint(.revolute, axis: X, range: -30...30, mimic: .init("tilt", ratio: -20)))
        _ = rig.part("ledRing", parent: "tiltBody", pivot: .zero, joint: .fixed, options: 3)
        rig.optionLinks = [RigOptionLink(part: "ledRing", joint: "led", thresholds: [0.02, 0.5])]

        let corners: [(Float, Float)] = [(1, 1), (-1, 1), (1, -1), (-1, -1)]
        var pitchJitter: [Float] = []
        var phaseJitter: [Float] = []
        for (i, c) in corners.enumerated() {
            let dir: Float = (c.0 * c.1) > 0 ? 1 : -1
            _ = rig.part("prop\(i)", parent: "tiltBody", pivot: V3(c.0 * Self.reach, Self.propY, c.1 * Self.reach),
                         joint: Joint(.revolute, axis: Y, range: -360...360, mimic: .init("spin", ratio: 360 * dir)))
            pitchJitter.append(11 + rng.f() * 3)
            phaseJitter.append(rng.f() * 90)
        }

        let outline = Self.bladeOutline()
        let bellMat = bell, hw = hardware, cf = carbon

        for l in 0..<2 {
            func sg(_ a: Int, _ b: Int) -> Int { l == 0 ? a : b }
            func add(_ s: Surface, _ x: Xform = .identity, to part: String = "tiltBody", option: Int = 0) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }

            // Body shell, belly plate, deck, battery.
            add(Prim.superellipsoid(V3(0.20, 0.07, 0.30), exponent: 3, subdivisions: sg(10, 6), material: cf), Xform(translation: V3(0, 0.02, -0.005)))
            add(Prim.roundedBox(V3(0.17, 0.012, 0.23), radius: 0.005, bevelSegments: sg(2, 1), material: hw), Xform(translation: V3(0, -0.026, 0)))
            add(Prim.roundedBox(V3(0.13, 0.006, 0.19), radius: 0.003, bevelSegments: sg(2, 1), material: cf), Xform(translation: V3(0, 0.057, -0.01)))
            add(Prim.roundedBox(V3(0.095, 0.045, 0.185), radius: 0.008, bevelSegments: sg(3, 1), material: housing), Xform(translation: V3(0, -0.0655, -0.012)))
            add(Prim.roundedBox(V3(0.098, 0.012, 0.03), radius: 0.003, bevelSegments: sg(2, 1), material: hw), Xform(translation: V3(0, -0.0655, 0.03)))
            // Nose canopy with camera window.
            add(Prim.superellipsoid(V3(0.12, 0.05, 0.075), exponent: 2.6, subdivisions: sg(7, 4), material: housing), Xform(translation: V3(0, 0.014, 0.135)))
            add(Prim.roundedBox(V3(0.06, 0.012, 0.004), radius: 0.002, bevelSegments: 1, material: lens), Xform(translation: V3(0, 0.014, 0.1705)))
            // GPS puck on a short mast, rear.
            add(Prim.cylinder(radius: 0.003, height: 0.045, bevel: 0.001, segments: sg(12, 8), bevelSegments: 1, material: hw), Xform(translation: V3(0, 0.06, -0.12)))
            add(Prim.cylinder(radius: 0.032, height: 0.011, bevel: 0.004, segments: sg(32, 16), bevelSegments: sg(2, 1), material: housing), Xform(translation: V3(0, 0.103, -0.12)))
            // Belly plate standoffs holding the LED ring.
            for k in 0..<4 {
                let a = Float(k) * .pi / 2
                let d = V3(sin(a), 0, cos(a))
                add(Prim.roundedBox(V3(0.012, 0.006, 0.026), radius: 0.002, bevelSegments: 1, material: hw),
                    Xform(translation: V3(d.x * 0.1, Self.ringY, d.z * 0.1), rotation: simd_quatf(angle: a, axis: Y)))
            }

            // LED ring in three states.
            for (o, m) in [(0, ledOff), (1, ledDim), (2, led)] {
                add(Prim.torus(major: 0.12, minor: 0.0055, segments: sg(64, 32), sides: sg(14, 8), material: m), Xform(translation: V3(0, Self.ringY, 0)), to: "ledRing", option: o)
            }

            // Arms, motors, nav lights, props.
            for (i, c) in corners.enumerated() {
                let sx = c.0, sz = c.1
                let tip = V3(sx * Self.reach, Self.armY, sz * Self.reach)
                let root = V3(sx * 0.065, Self.armY, sz * 0.075)
                let dir = (tip - root).normalized
                let q = simd_quatf(from: Y, to: dir)
                add(Prim.tube([root, tip], radii: [0.0115, 0.0115], sides: sg(24, 10), seamTile: 0.25, material: cf, capEnd: true))
                for (t, len) in [(Float(0.22), Float(0.034)), (0.93, 0.02)] {
                    let p = root + (tip - root) * t - dir * (len / 2)
                    add(Prim.cylinder(radius: 0.0155, height: len, bevel: 0.0025, segments: sg(24, 12), bevelSegments: sg(2, 1), material: hw), Xform(translation: p, rotation: q))
                }
                // Motor mount plate and stator.
                add(Prim.roundedBox(V3(0.046, 0.006, 0.046), radius: 0.004, bevelSegments: sg(2, 1), material: hw), Xform(translation: V3(tip.x, Self.armY + 0.0105 + 0.003, tip.z), rotation: simd_quatf(angle: .pi / 4, axis: Y)))
                add(Prim.cylinder(radius: 0.0165, height: 0.031, bevel: 0.002, segments: sg(24, 12), bevelSegments: sg(1, 1), material: hw), Xform(translation: V3(tip.x, Self.armY + 0.0165, tip.z)))
                // Nav light under the motor.
                add(Prim.superellipsoid(V3(0.016, 0.009, 0.016), exponent: 2, subdivisions: sg(4, 2), material: sz > 0 ? navFront : navRear), Xform(translation: V3(tip.x, Self.armY - 0.0115, tip.z)))

                // Prop: bell, hub, spinner, two blades.
                let part = "prop\(i)"
                let pp = V3(tip.x, 0, tip.z)
                add(Prim.cylinder(radius: 0.0215, height: 0.032, bevel: 0.003, segments: sg(32, 14), bevelSegments: sg(2, 1), material: bellMat), Xform(translation: V3(pp.x, Self.armY + 0.0475, pp.z)), to: part)
                add(Prim.cylinder(radius: 0.0135, height: 0.012, bevel: 0.002, segments: sg(24, 12), bevelSegments: sg(1, 1), material: hw), Xform(translation: V3(pp.x, Self.propY - 0.006, pp.z)), to: part)
                let spinner: [V2] = [V2(0, 0), V2(0.0125, 0), V2(0.0112, 0.006), V2(0.0082, 0.012), V2(0.0042, 0.0165), V2(0, 0.0185)]
                add(Prim.lathe(spinner, segments: sg(24, 12), seamTile: 0.25, material: bellMat), Xform(translation: V3(pp.x, Self.propY + 0.006, pp.z)), to: part)
                let lay = simd_quatf(degrees: -90, axis: X)
                for b in 0..<2 {
                    let yaw = simd_quatf(degrees: Float(b) * 180 + phaseJitter[i], axis: Y)
                    let pitch = simd_quatf(degrees: pitchJitter[i], axis: X)
                    add(Prim.extrude(outline, depth: 0.0032, bevel: 0.0011, bevelSegments: sg(2, 1), material: blade),
                        Xform(translation: V3(pp.x, Self.propY, pp.z), rotation: yaw * pitch * lay), to: part)
                }
            }

            // Gimbal camera under the nose.
            let gp = Self.gimbalPivot
            add(Prim.roundedBox(V3(0.03, 0.018, 0.03), radius: 0.004, bevelSegments: sg(2, 1), material: hw), Xform(translation: V3(0, -0.04, 0.125)), to: "gimbal")
            for s: Float in [1, -1] {
                add(Prim.roundedBox(V3(0.006, 0.05, 0.016), radius: 0.002, bevelSegments: 1, material: hw), Xform(translation: V3(s * 0.027, gp.y - 0.022, gp.z + 0.0)), to: "gimbal")
            }
            let cam = V3(0, gp.y - 0.028, gp.z + 0.005)
            add(Prim.superellipsoid(V3(0.048, 0.048, 0.056), exponent: 2, subdivisions: sg(8, 4), material: housing), Xform(translation: cam), to: "gimbal")
            let fwd = simd_quatf(degrees: 90, axis: X)
            add(Prim.cylinder(radius: 0.0185, height: 0.02, bevel: 0.002, segments: sg(32, 14), bevelSegments: sg(2, 1), material: hw), Xform(translation: cam + V3(0, 0, 0.022), rotation: fwd), to: "gimbal")
            add(Prim.cylinder(radius: 0.0135, height: 0.004, bevel: 0.0008, segments: sg(32, 14), bevelSegments: 1, material: lens), Xform(translation: cam + V3(0, 0, 0.0425), rotation: fwd), to: "gimbal")

            // Landing skids: carbon struts and bars with rubber feet.
            for sx: Float in [1, -1] {
                for sz: Float in [1, -1] {
                    let a = V3(sx * 0.07, -0.042, sz * 0.095)
                    let b = V3(sx * 0.15, -0.147, sz * 0.095)
                    add(Prim.tube([a, (a + b) / 2, b], radii: [0.0055, 0.0055, 0.0055], sides: sg(16, 8), seamTile: 0.25, material: cf, capEnd: true))
                }
                var bar: [V3] = []
                let n = 10
                for k in 0...n {
                    let t = Float(k) / Float(n)
                    let z = -0.19 + 0.38 * t
                    let lift = pow(abs(2 * t - 1), 8) * 0.03
                    bar.append(V3(sx * 0.15, -0.15 + lift, z))
                }
                add(Prim.tube(bar, radii: bar.map { _ in 0.0075 }, sides: sg(20, 10), seamTile: 0.25, material: cf, capEnd: true))
                for sz: Float in [1, -1] {
                    add(Prim.superellipsoid(V3(0.02, 0.018, 0.075), exponent: 2.4, subdivisions: sg(5, 3), material: foot), Xform(translation: V3(sx * 0.15, -0.1535, sz * 0.095)))
                }
            }

            // Lights: ring glow below the body.
            if l == 0 {
                rig.lights.append(RigLight(name: "ringFull", part: "ledRing", option: 2, position: V3(0, -0.07, 0),
                                           direction: V3(0, -1, 0), color: V3(0.1, 0.85, 1), intensity: 320, attenuationRadius: 4))
                rig.lights.append(RigLight(name: "ringDim", part: "ledRing", option: 1, position: V3(0, -0.07, 0),
                                           direction: V3(0, -1, 0), color: V3(0.03, 0.3, 0.38), intensity: 70, attenuationRadius: 2))
            }
        }

        rig.states = [
            RigState("rest"),
            RigState("armed", ["led": 0.4]),
            RigState("hover", ["led": 1, "spin": 0.5]),
            RigState("forward", ["led": 1, "spin": 0.25, "tilt": 1]),
            RigState("backward", ["led": 1, "spin": 0.75, "tilt": -1]),
            RigState("show", ["led": 1]),
        ]
        rig.defaultState = "show"
        return rig
    }
}
