import simd
import Foundation

/// Small-rocket launch pad, 12 m square, deck 1 m above grade. A flame trench runs from under the mount
/// out the +X edge with a curved steel deflector; a painted steel launch-mount ring stands on four legs
/// over the trench with hold-down clamps. Scorch fans, yellow deck markings, sealed expansion joints,
/// cast cable-trench covers and tie-down rings.
public struct LaunchPad: RealAsset {
    public static let id = "launch-pad"
    public static let summary = "Small-rocket launch pad, 12 m square: concrete deck over a flame trench with steel deflector, launch mount ring with hold-down clamps, scorch and markings."
    public static let tags = ["prop", "aerospace", "outdoor", "concrete", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 215, elevation: 22, distance: 1.0)

    /// Deck size (square) and height above grade in meters.
    public var size: Float = 12
    public var deckHeight: Float = 1
    /// Flame trench width; mount ring outer size and height above the deck.
    public var trenchWidth: Float = 2.4
    public var ringSize: Float = 3
    public var ringHeight: Float = 1.2
    public var deck: MaterialKey = "concrete.rough"
    public var mountPaint: MaterialKey = "metal.enamel:BDB6A6"
    public var steel: MaterialKey = "metal.galvanized"
    public var scorch: MaterialKey = "ablative.char-light"
    public var marking: MaterialKey = "paint.lane-yellow"
    public init() {}

    /// Mount ring top in asset space (where a rocket's base sits).
    public var mountTop: Float { deckHeight + ringHeight }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)], switchDistances: [60])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let S = size, H = deckHeight, hw = trenchWidth / 2, x0: Float = -1.4
        let bev: Float = 0.04
        // deck: rear slab behind the trench, two side slabs
        m.add(Prim.roundedBox(V3(S / 2 + x0, H, S), radius: bev, bevelSegments: 2, material: deck),
              Xform(translation: V3((-S / 2 + x0) / 2, H / 2, 0)))
        for z in [Float(-1), 1] {
            let w = S / 2 - hw
            m.add(Prim.roundedBox(V3(S / 2 - x0, H, w), radius: bev, bevelSegments: 2, material: deck),
                  Xform(translation: V3((S / 2 + x0) / 2, H / 2, z * (hw + w / 2))))
        }
        // trench floor and the curved deflector (outline in XY, extruded across Z)
        m.add(Prim.roundedBox(V3(S / 2 - x0, 0.1, trenchWidth), radius: 0.02, bevelSegments: 1, material: "concrete.smooth"),
              Xform(translation: V3((S / 2 + x0) / 2, 0.05, 0)))
        let R: Float = 2.6
        var defl: [V2] = [V2(x0 + 0.02, 0.1), V2(x0 + 0.02, H - 0.2)]
        for k in 1...12 {
            let t = Float(k) / 12
            // quarter ellipse: steep under the mount, flattening toward the trench exit
            defl.append(V2(x0 + 0.02 + R * sin(t * .pi / 2), 0.1 + (H - 0.3) * cos(t * .pi / 2)))
        }
        m.add(Prim.extrude(Shape2D.deduped(defl), depth: trenchWidth - 0.04, bevel: 0.01, bevelSegments: 1, material: "metal.heat-tint-cold"),
              .identity)
        // launch mount: square ring on four legs standing on the side slabs
        let rs = ringSize / 2, top = H + ringHeight, beam: Float = 0.3
        for (axis, sgn) in [(0, Float(-1)), (0, 1), (2, -1), (2, 1)] as [(Int, Float)] {
            let along = axis == 0 ? V3(ringSize + beam, beam, beam) : V3(beam, beam, ringSize - beam)
            let pos = axis == 0 ? V3(0, top - beam / 2, sgn * rs) : V3(sgn * rs, top - beam / 2, 0)
            m.add(Prim.roundedBox(along, radius: 0.015, bevelSegments: 1, material: mountPaint), Xform(translation: pos))
        }
        for x in [-rs, rs] { for z in [-rs, rs] {
            let legZ = z * max(1, (hw + 0.35) / rs)
            m.add(Prim.roundedBox(V3(0.24, ringHeight - beam + 0.01, 0.24), radius: 0.012, bevelSegments: 1, material: mountPaint),
                  Xform(translation: V3(x, H + (ringHeight - beam) / 2, legZ)))
            // soot creeping up the leg from the trench side
            m.add(Prim.roundedBox(V3(0.246, 0.45, 0.246), radius: 0.012, bevelSegments: 1, material: scorch),
                  Xform(translation: V3(x, H + 0.225 + 0.02, legZ)))
            m.add(Prim.roundedBox(V3(0.5, 0.03, 0.5), radius: 0.006, bevelSegments: 1, material: steel), Xform(translation: V3(x, H + 0.015, legZ)))
            if detail {
                for (dx, dz) in [(-0.18, -0.18), (0.18, -0.18), (-0.18, 0.18), (0.18, 0.18)] as [(Float, Float)] {
                    hexBolt(&m, at: V3(x + dx, H + 0.03, legZ + dz), normal: V3(0, 1, 0), size: 0.04, material: steel)
                }
            }
        }}
        // hold-down clamps: a hinged arm and a pad on each side of the ring
        for k in 0..<4 {
            let a = Float(k) / 4 * 2 * .pi
            let d = V3(cos(a), 0, sin(a))
            let q = simd_quatf(angle: -a, axis: V3(0, 1, 0))
            m.add(Prim.roundedBox(V3(0.5, 0.14, 0.16), radius: 0.02, bevelSegments: 1, material: "metal.painted:B3201C"),
                  Xform(translation: d * (rs - 0.25) + V3(0, top + 0.07, 0), rotation: q))
            let tangent = simd_cross(d, V3(0, 1, 0))
            m.add(Prim.cylinder(radius: 0.06, height: 0.22, bevel: 0.006, segments: 12, material: steel),
                  Xform(translation: d * (rs - 0.02) + V3(0, top + 0.04, 0) - tangent * 0.11, rotation: facing(tangent)))
        }
        // scorch: dark fans on the deck downstream of the trench and around the mount
        for (cx, r, a) in [(Float(1.4), Float(2.4), Float(0.7))] {
            var disc = Prim.lathe([V2(r, 0), V2(r * 0.75, 0.001), V2(r * 0.4, 0.002), V2(0, 0.003)], segments: 36, seamTile: 0.5, material: scorch)
            // ragged soot edge: radius varies with angle
            let ph = rng.float(0...6)
            disc.deform { p in
                let ang = atan2(p.z, p.x), f = 1 + 0.22 * sin(ang * 5 + ph) + 0.12 * sin(ang * 11 + ph * 2)
                return V3(p.x * f, p.y, p.z * f)
            }
            for z in [Float(-1), 1] {
                var s = disc
                // squash to a fan and fold onto this slab (scorch shows on concrete, not over the trench)
                s.deform { p in V3(p.x, p.y + abs(p.z) * 0.0002, z * abs(p.z) * a) }
                m.add(s, Xform(translation: V3(cx, H + 0.003, z * (hw + 0.02))))
            }
        }
        // yellow edge markings and a hazard line at the trench lip
        for z in [Float(-1), 1] {
            m.add(Prim.roundedBox(V3(S - 0.8, 0.006, 0.15), radius: 0.002, bevelSegments: 1, material: marking),
                  Xform(translation: V3(0, H + 0.003, z * (S / 2 - 0.4))))
            m.add(Prim.roundedBox(V3(S / 2 - x0 - 0.3, 0.006, 0.1), radius: 0.002, bevelSegments: 1, material: marking),
                  Xform(translation: V3((S / 2 + x0) / 2 + 0.15, H + 0.003, z * (hw + 0.2))))
        }
        // expansion joints (sealant strips) across the slabs
        for x in stride(from: -S / 2 + 3, to: S / 2 - 0.5, by: 3) {
            for z in [Float(-1), 1] {
                m.add(Prim.roundedBox(V3(0.025, 0.006, S / 2 - hw - 0.1), radius: 0.002, bevelSegments: 1, material: "asphalt.sealant"),
                      Xform(translation: V3(x, H + 0.001, z * (hw + (S / 2 - hw) / 2))))
            }
        }
        // cable-trench covers along the rear slab, tie-down rings at the deck corners
        if detail {
            for i in 0..<5 {
                m.add(Prim.roundedBox(V3(0.9, 0.025, 0.45), radius: 0.008, bevelSegments: 1, material: "metal.cast-iron"),
                      Xform(translation: V3(-S / 2 + 0.8 + Float(i) * 0.92, H + 0.006, -S / 2 + 1.2)).jittered(&rng))
            }
            for x in [-S / 2 + 0.8, S / 2 - 0.8] { for z in [-S / 2 + 0.8, S / 2 - 0.8] {
                m.add(Prim.torus(major: 0.08, minor: 0.018, segments: 14, sides: 6, arc: .pi, material: steel),
                      Xform(translation: V3(x, H, z), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }}
        }
        groundAO(&m)
        return m
    }
}
