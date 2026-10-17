import simd
import Foundation

/// Elevon control surface, 1.0 m span x 0.3 m chord, as it mounts behind a wing's rear spar: a tapered
/// carbon surface with a round hinge nose and aluminium end ribs swings on a steel hinge pin carried by
/// three machined brackets on a spar stub. A control horn with a pushrod clevis rides on top. Deflects
/// -25 to +25 degrees (positive raises the trailing edge). Span along X, chord toward -Z.
public struct Elevon: RealArticulated {
    public static let id = "elevon"
    public static let summary = "Elevon control surface, 1.0 x 0.3 m: tapered carbon airfoil hinged on three aluminium brackets with a control horn, deflecting -25 to +25 degrees."
    public static let tags = ["prop", "aerospace", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 30, distance: 1.1, studio: true)

    /// Span (m).
    public var span: Float = 1.0
    /// Chord from hinge line to trailing edge (m).
    public var chord: Float = 0.29
    /// Hinge nose radius (m).
    public var noseRadius: Float = 0.019
    /// Deflection limit either way (degrees).
    public var travel: Float = 25
    public var skin: MaterialKey = "composite.carbon"
    public var fittings: MaterialKey = "metal.aluminum-brushed"
    public var fastener: MaterialKey = "metal.steel"
    public init() {}

    /// Closed section in (chord x, thickness y), hinge at the origin, chord toward +x.
    func section(_ n: Int) -> [V2] {
        let r = noseRadius, te: Float = 0.0018
        var pts: [V2] = []
        // Upper surface TE -> tangent point, nose arc over the front, lower surface back to the TE.
        let k = n
        for i in 0..<k { let t = Float(i) / Float(k); pts.append(V2(chord - t * chord, te + (r - te) * pow(t, 0.9))) }
        for i in 0...n { let a = Float.pi / 2 + Float(i) / Float(n) * .pi; pts.append(V2(cos(a) * r, sin(a) * r)) }
        for i in 1..<k { let t = 1 - Float(i) / Float(k); pts.append(V2(chord - t * chord, -(te + (r - te) * pow(t, 0.9)))) }
        return pts
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let hy: Float = 0.031, zr: Float = 0.018           // hinge height; spar stub depth ahead of the hinge
        let half = span / 2
        let z0 = (chord - (noseRadius + zr + 0.02)) / 2   // centres the assembly on Z

        // Spar stub: aluminium channel ahead of the hinge, brackets reaching back to the pin.
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 2 : 1
            m.add(Prim.roundedBox(V3(span + 0.02, 0.058, 0.012), radius: 0.003, bevelSegments: bs, material: fittings),
                  Xform(translation: V3(0, 0.029, z0 + noseRadius + zr)))
            for z: Float in [0, 1] {
                m.add(Prim.roundedBox(V3(span + 0.02, 0.004, 0.026), radius: 0.0015, bevelSegments: 1, material: fittings),
                      Xform(translation: V3(0, z * 0.054 + 0.002, z0 + noseRadius + zr + 0.008)))
            }
            for x in [-half + 0.08, 0, half - 0.08] {
                // Bracket: plate from the spar to the pin, round eye around the pin.
                let reach = noseRadius + zr + 0.002
                m.add(Prim.roundedBox(V3(0.008, 0.026, reach), radius: 0.003, bevelSegments: bs, material: fittings),
                      Xform(translation: V3(x, hy, z0 + reach / 2)))
                m.add(Prim.cylinder(radius: 0.009, height: 0.009, bevel: 0.0015, segments: l == 0 ? 14 : 8, material: fittings),
                      Xform(translation: V3(x - 0.0045, hy, z0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))))
                if l == 0 {
                    hexBolt(&m, at: V3(x, 0.042, z0 + noseRadius + zr + 0.006), normal: V3(0, 0, 1), size: 0.006, material: fastener)
                    hexBolt(&m, at: V3(x, 0.016, z0 + noseRadius + zr + 0.006), normal: V3(0, 0, 1), size: 0.006, material: fastener)
                }
            }
            // Hinge pin through the nose, heads at both ends.
            m.add(Prim.cylinder(radius: 0.003, height: span + 0.024, bevel: 0.0008, segments: l == 0 ? 10 : 6, material: fastener),
                  Xform(translation: V3(-half - 0.012, hy, z0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))))
            rig.base[l] = m
        }

        // Surface: lofted section, end ribs, shallow skin joggle line at 40 % chord.
        rig.part("surface", pivot: V3(0, hy, z0), joint: .hinge(axis: V3(1, 0, 0), -travel...travel, duration: 0.45))
        for l in 0..<2 {
            let sec = section(l == 0 ? 12 : 5)
            func ring(_ x: Float) -> [V3] { sec.map { V3(x, hy + $0.y, -$0.x + z0) } }
            let gaps: [Float] = [-half + 0.004, -half + 0.075, -half + 0.085, -0.005, 0.005, half - 0.085, half - 0.075, half - 0.004]
            // Surface in three bays split by the bracket cut-outs.
            for b in stride(from: 0, to: gaps.count, by: 2) {
                rig.add(Prim.loft([ring(gaps[b]), ring((gaps[b] + gaps[b + 1]) / 2), ring(gaps[b + 1])], capStart: true, capEnd: true, material: skin),
                        to: "surface", lods: l...l)
            }
            // Fill the narrow bracket slots behind the nose so only the nose is notched.
            let aft = sec.filter { $0.x > noseRadius * 1.6 }
            for x in [-half + 0.08, 0, half - 0.08] {
                rig.add(Prim.loft([aft.map { V3(x - 0.007, hy + $0.y, -$0.x + z0) }, aft.map { V3(x + 0.007, hy + $0.y, -$0.x + z0) }], capStart: true, capEnd: true, material: skin),
                        to: "surface", lods: l...l)
            }
            // Aluminium end ribs.
            for s: Float in [-1, 1] {
                rig.add(Prim.extrude(Shape2D.offset(sec, 0.0012), depth: 0.004, bevel: 0.001, bevelSegments: 1, material: fittings),
                        Xform(translation: V3(s * (half - 0.002), hy, z0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0))), to: "surface", lods: l...l)
            }
        }
        // Control horn on the upper skin with a clevis and a pushrod stub.
        var horn = Model(name: Self.id)
        let hx = -half + 0.2, hz: Float = -0.05 + z0
        let topY = hy + noseRadius * 0.82
        horn.add(Prim.extrude([V2(-0.03, 0), V2(0.035, 0), V2(0.004, 0.055), V2(-0.008, 0.055)], depth: 0.004, bevel: 0.0012, bevelSegments: 1, material: fittings),
                 Xform(translation: V3(hx, topY, hz), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0))))
        horn.add(Prim.roundedBox(V3(0.03, 0.004, 0.07), radius: 0.0015, bevelSegments: 1, material: fittings),
                 Xform(translation: V3(hx, topY - 0.001, hz)))
        for dz: Float in [-0.025, 0.025] { rivet(&horn, at: V3(hx + 0.01, topY + 0.001, hz + dz), normal: .up, radius: 0.0025, material: fastener) }
        horn.add(Prim.roundedBox(V3(0.014, 0.012, 0.016), radius: 0.003, bevelSegments: 1, material: fastener),
                 Xform(translation: V3(hx, topY + 0.05, hz + 0.004)))
        horn.add(Prim.tube([V3(hx, topY + 0.05, hz + 0.012), V3(hx, topY + 0.05, hz + 0.12)], radii: [0.003, 0.003], sides: 8, seamTile: 0.02, material: fastener, capEnd: true),
                 Xform.identity.jittered(&rng, deg: 0.2, offset: 0))
        rig.add(horn, to: "surface", lod: 0)

        rig.states = [RigState("neutral"), RigState("up", ["surface": travel]), RigState("down", ["surface": -travel])]
        groundAO(&rig, height: 0.05, floor: 0.6)
        return rig
    }
}
