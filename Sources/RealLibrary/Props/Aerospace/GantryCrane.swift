import simd
import Foundation

/// Portable hangar gantry crane, 4 m span: yellow I-beam on two A-frame end legs with base beams and
/// locking casters, a geared trolley that runs along the beam (`trolley`, slide x) and a chain hoist
/// whose hook block lowers (`hook`, slide y). Load chain telescopes between hoist and hook.
public struct GantryCrane: RealArticulated {
    public static let id = "gantry-crane"
    public static let summary = "Portable gantry crane, 4 m span: yellow I-beam on A-frame legs with casters, sliding trolley and chain hoist with a lowering hook block."
    public static let tags = ["prop", "aerospace", "interior", "industrial", "articulated", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.05)

    public var span: Float = 4
    public var beamHeight: Float = 3.6
    public var baseDepth: Float = 1.9
    public var paint: MaterialKey = "metal.signal-yellow"
    public var steel: MaterialKey = "metal.galvanized"
    public var chainMat: MaterialKey = "metal.steel"
    public var hoistPaint: MaterialKey = "metal.painted:B3201C"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [15])
        let hs = span / 2, H = beamHeight, hd = baseDepth / 2
        for l in 0..<2 {
            let sides = l == 0 ? 10 : 6
            var m = Model(name: Self.id)
            // I-beam: flanges and web
            let bl = span + 0.4
            for y in [H - 0.01, H - 0.29] {
                m.add(Prim.roundedBox(V3(bl, 0.02, 0.16), radius: 0.004, bevelSegments: 1, material: paint), Xform(translation: V3(0, y, 0)))
            }
            m.add(Prim.roundedBox(V3(bl, 0.26, 0.012), radius: 0.003, bevelSegments: 1, material: paint), Xform(translation: V3(0, H - 0.15, 0)))
            for x in [-hs, hs] {
                // end plate, A-frame legs, base beam, braces, casters
                m.add(Prim.roundedBox(V3(0.24, 0.04, 0.3), radius: 0.006, bevelSegments: 1, material: paint), Xform(translation: V3(x, H - 0.32, 0)))
                for z in [-hd + 0.12, hd - 0.12] {
                    m.add(Prim.tube([V3(x, H - 0.34, 0), V3(x, 0.3, z)], radii: [0.045, 0.045], sides: sides, seamTile: 0.3, material: paint), .identity)
                    caster(&m, at: V3(x, 0, z * 1.05), height: 0.2, wheelRadius: 0.07, frame: steel, wheel: "rubber", hub: steel)
                }
                m.add(Prim.roundedBox(V3(0.12, 0.1, baseDepth), radius: 0.008, bevelSegments: 1, material: paint), Xform(translation: V3(x, 0.25, 0)))
                m.add(Prim.tube([V3(x, 1.3, -hd * 0.6), V3(x, 1.3, hd * 0.6)], radii: [0.025, 0.025], sides: sides, seamTile: 0.3, material: paint), .identity)
                if l == 0 {
                    for k in 0..<4 {
                        hexBolt(&m, at: V3(x - 0.08 + Float(k % 2) * 0.16, H - 0.3, -0.1 + Float(k / 2) * 0.2), normal: V3(0, -1, 0), size: 0.016, material: steel)
                    }
                    // capacity stencil plate on the beam web
                    m.add(Prim.roundedBox(V3(0.4, 0.12, 0.004), radius: 0.001, bevelSegments: 1, material: "label.hazard"),
                          Xform(translation: V3(x * 0.6, H - 0.15, 0.009)))
                }
            }
            rig.base[l] = m
        }
        // trolley: side plates and four wheels riding the bottom flange, hoist body under it
        rig.part("trolley", pivot: V3(0, H - 0.3, 0), joint: .slide(axis: V3(1, 0, 0), -(hs - 0.4)...(hs - 0.4)))
        rig.part("hook", parent: "trolley", pivot: V3(0.035, H - 1.05, 0), joint: .slide(axis: V3(0, 1, 0), -1.6...0))
        for z in [Float(-0.1), 0.1] {
            rig.add(Prim.roundedBox(V3(0.26, 0.2, 0.012), radius: 0.004, bevelSegments: 1, material: hoistPaint), Xform(translation: V3(0, H - 0.34, z)), to: "trolley")
            for x in [Float(-0.08), 0.08] {
                rig.add(Prim.cylinder(radius: 0.04, height: 0.025, bevel: 0.004, segments: 14, material: steel),
                        Xform(translation: V3(x, H - 0.27, z * 0.65), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "trolley")
            }
        }
        rig.add(Prim.roundedBox(V3(0.12, 0.08, 0.22), radius: 0.008, bevelSegments: 1, material: hoistPaint), Xform(translation: V3(0, H - 0.47, 0)), to: "trolley")
        // chain hoist body: drum housing and gear cover
        rig.add(Prim.superellipsoid(V3(0.26, 0.3, 0.22), exponent: 3, subdivisions: 6, material: hoistPaint), Xform(translation: V3(0, H - 0.68, 0)), to: "trolley")
        rig.add(Prim.cylinder(radius: 0.13, height: 0.06, bevel: 0.01, segments: 18, material: hoistPaint),
                Xform(translation: V3(0, H - 0.68, 0.1), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "trolley")
        // load chain: nine short segments that spread out as the hook lowers (each mimics the hook)
        let c0 = H - 0.83, segN = 9, segL: Float = 0.24
        for k in 0..<segN {
            rig.part("chain\(k)", parent: "trolley", pivot: V3(0.035, c0, 0),
                     joint: Joint(.prismatic, axis: V3(0, 1, 0), range: -1.6...0, mimic: .init("hook", ratio: Float(k) / Float(segN - 1))))
            rig.add(links(from: V3(0.035, c0, 0), down: segL), to: "chain\(k)", lods: 0...0)
            rig.add(Prim.tube([V3(0.035, c0, 0), V3(0.035, c0 - segL, 0)], radii: [0.01, 0.01], sides: 4, seamTile: 0.1, material: chainMat), to: "chain\(k)", lods: 1...1)
        }
        // hand chain loop hanging beside the hoist
        for z in [Float(0.11), 0.17] {
            rig.add(Prim.tube([V3(0.12, c0 + 0.08, z), V3(0.12, 1.2, z)], radii: [0.006, 0.006], sides: 5, seamTile: 0.02, material: chainMat), to: "trolley")
        }
        // hook block and hook
        let hy = H - 1.07
        rig.add(Prim.roundedBox(V3(0.1, 0.16, 0.08), radius: 0.02, bevelSegments: 2, material: "metal.signal-yellow"), Xform(translation: V3(0.035, hy - 0.08, 0)), to: "hook")
        rig.add(Prim.torus(major: 0.06, minor: 0.016, segments: 16, sides: 8, arc: 1.5 * .pi, material: "metal.cast-iron"),
                Xform(translation: V3(0.035, hy - 0.24, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: 45, axis: V3(0, 1, 0))), to: "hook")
        rig.add(Prim.tube([V3(0.035, hy - 0.16, 0), V3(0.035, hy - 0.19, 0)], radii: [0.016, 0.016], sides: 8, seamTile: 0.1, material: "metal.cast-iron"), to: "hook")
        rig.states = [RigState("parked", ["trolley": -(hs - 0.6), "hook": 0]), RigState("centered", ["trolley": 0, "hook": -0.6]),
                      RigState("lowered", ["trolley": 0, "hook": -1.6])]
        groundAO(&rig, height: 0.3)
        return rig
    }

    /// Low-poly load chain: alternating oval links (64 tris each) hanging straight down.
    func links(from top: V3, down length: Float) -> Surface {
        let wire: Float = 0.007, pitch: Float = 0.042
        var s = Surface(material: chainMat)
        let link = Prim.torus(major: 0.016, minor: wire, segments: 8, sides: 4, material: chainMat)
        let n = Int(length / pitch)
        for i in 0..<n {
            s.append(link, Xform(translation: top - V3(0, pitch * (Float(i) + 0.5), 0), rotation: simd_quatf(degrees: Float(i % 2) * 90, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(1, 0, 0)), scale: V3(1.6, 1, 1)))
        }
        return s
    }
}
