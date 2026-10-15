import simd
import Foundation

/// Launch service tower, 20 m: square galvanized lattice on concrete footings with grated work platforms
/// and handrails, a caged ladder up one face, a swing-out umbilical arm with hoses, and a red-painted
/// top section carrying a lightning mast and obstruction light. Stands beside `launch-pad`.
public struct LaunchTower: RealAsset {
    public static let id = "launch-tower"
    public static let summary = "Launch service tower, 20 m: galvanized lattice on footings, grated platforms with handrails, caged ladder, umbilical arm with hoses, lightning mast."
    public static let tags = ["prop", "aerospace", "outdoor", "metal", "industrial"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.05)

    /// Tower height to the top platform and lattice width in meters.
    public var height: Float = 20
    public var width: Float = 2.6
    /// Section height of the lattice bays.
    public var bay: Float = 2.5
    /// Platform heights (fractions of the height); the umbilical arm sits on the second.
    public var platforms: [Float] = [0.35, 0.7, 1.0]
    /// Umbilical arm length toward +X (the pad side).
    public var armLength: Float = 3.4
    public var steel: MaterialKey = "metal.galvanized"
    public var paint: MaterialKey = "metal.painted:B3201C"
    public var grate: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)], switchDistances: [80])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = width / 2, H = height, foot: Float = 0.4
        let sides = detail ? 6 : 4
        func rod(_ a: V3, _ b: V3, _ r: Float, _ mat: MaterialKey? = nil) {
            m.add(Prim.tube([a, b], radii: [r, r], sides: sides, seamTile: 0.4, material: mat ?? steel), .identity)
        }
        let corners = [V3(-w, 0, -w), V3(w, 0, -w), V3(w, 0, w), V3(-w, 0, w)]
        // footings
        for c in corners {
            m.add(Prim.roundedBox(V3(0.7, foot, 0.7), radius: 0.03, bevelSegments: 1, material: "concrete.rough"),
                  Xform(translation: V3(c.x, foot / 2, c.z)))
            m.add(Prim.roundedBox(V3(0.36, 0.025, 0.36), radius: 0.005, bevelSegments: 1, material: steel), Xform(translation: V3(c.x, foot + 0.012, c.z)))
        }
        // lattice bays
        let n = max(2, Int((H - foot) / bay + 0.5))
        let bh = (H - foot) / Float(n)
        for s in 0..<n {
            let y0 = foot + Float(s) * bh, y1 = y0 + bh
            let mat = s >= n - 1 ? paint : steel
            for k in 0..<4 {
                let a = corners[k], b = corners[(k + 1) % 4]
                rod(V3(a.x, y0, a.z), V3(a.x, y1, a.z), 0.07, mat)
                rod(V3(a.x, y1, a.z), V3(b.x, y1, b.z), 0.04, mat)
                // X bracing on every face
                rod(V3(a.x, y0, a.z), V3(b.x, y1, b.z), 0.028, mat)
                if detail { rod(V3(b.x, y0, b.z), V3(a.x, y1, a.z), 0.028, mat) }
            }
        }
        // platforms: grating deck overhanging the lattice, toe boards, two-rail handrails
        for f in platforms {
            let y = foot + (H - foot) * f
            let pw = w + 0.7
            m.add(Prim.roundedBox(V3(pw * 2, 0.06, pw * 2), radius: 0.008, bevelSegments: 1, material: grate), Xform(translation: V3(0, y + 0.03, 0)))
            let rails: [(V3, V3)] = [(V3(-pw, 0, -pw), V3(pw, 0, -pw)), (V3(pw, 0, -pw), V3(pw, 0, pw)),
                                    (V3(pw, 0, pw), V3(-pw, 0, pw)), (V3(-pw, 0, pw), V3(-pw, 0, -pw))]
            for (i, (a, b)) in rails.enumerated() {
                // gap in the +X rail where the arm leaves, gap in the -Z rail at the ladder
                let open = (i == 1 && f == platforms[1]) || (i == 0 && f != platforms.last)
                for h in [Float(0.55), 1.1] where !open || h > 2 {
                    rod(a + V3(0, y + 0.06 + h, 0), b + V3(0, y + 0.06 + h, 0), 0.022, "metal.signal-yellow")
                }
                if !open {
                    for t in stride(from: Float(0), through: 1, by: 0.5) {
                        let p = a + (b - a) * t
                        rod(p + V3(0, y + 0.06, 0), p + V3(0, y + 1.16, 0), 0.022, "metal.signal-yellow")
                    }
                    m.add(Prim.roundedBox(V3(abs(b.x - a.x) + 0.02, 0.12, abs(b.z - a.z) + 0.02), radius: 0.004, bevelSegments: 1, material: steel),
                          Xform(translation: (a + b) / 2 + V3(0, y + 0.12, 0)))
                }
            }
        }
        // caged ladder up the -Z face
        let lz = -w - 0.25, top = foot + (H - foot) * (platforms.last ?? 1)
        for x in [Float(-0.22), 0.22] { rod(V3(x, foot, lz), V3(x, top + 1.1, lz), 0.025) }
        if detail {
            for y in stride(from: foot + 0.3, to: top, by: 0.3) { rod(V3(-0.22, y, lz), V3(0.22, y, lz), 0.014) }
            for y in stride(from: Float(2.4), to: top, by: 1.2) {
                let hoop = Prim.torus(major: 0.38, minor: 0.014, segments: 14, sides: 4, arc: .pi, material: steel)
                m.add(hoop, Xform(translation: V3(0, y, lz), rotation: simd_quatf(degrees: 180, axis: V3(0, 1, 0))))
            }
        }
        // umbilical arm: box truss toward +X with hoses drooping to the vehicle
        let ay = foot + (H - foot) * platforms[1] + 0.06
        for dz in [Float(-0.3), 0.3] { for dy in [Float(0), 0.6] {
            rod(V3(w, ay + dy, dz), V3(w + armLength, ay + dy, dz), 0.045, paint)
        }}
        for t in stride(from: Float(0), through: armLength, by: armLength / 4) {
            rod(V3(w + t, ay, -0.3), V3(w + t, ay + 0.6, -0.3), 0.03, paint)
            rod(V3(w + t, ay, 0.3), V3(w + t, ay + 0.6, 0.3), 0.03, paint)
            rod(V3(w + t, ay + 0.6, -0.3), V3(w + t, ay + 0.6, 0.3), 0.03, paint)
        }
        for (i, (dz, r)) in [(Float(-0.15), Float(0.05)), (0.05, 0.035), (0.2, 0.03)].enumerated() {
            let sag = rng.float(0.5...0.8) + Float(i) * 0.1
            let pts = [V3(w + 0.3, ay - 0.02, dz), V3(w + armLength * 0.5, ay - sag, dz), V3(w + armLength + 0.1, ay - 0.35, dz)]
            let path = catmull(pts, per: 6)
            m.add(Prim.tube(path, radii: Array(repeating: r, count: path.count), sides: sides, seamTile: 0.2,
                            material: i == 0 ? "insulation.foil-gold" : "rubber"), .identity)
        }
        // plug plate at the arm tip
        m.add(Prim.roundedBox(V3(0.08, 0.5, 0.6), radius: 0.01, bevelSegments: 1, material: paint),
              Xform(translation: V3(w + armLength + 0.12, ay - 0.2, 0)))
        // lightning mast and obstruction light on top
        rod(V3(0, top + 0.06, 0), V3(0, top + 4, 0), 0.04)
        rod(V3(0, top + 0.06, 0), V3(w * 0.6, top + 1.2, w * 0.6), 0.025)
        rod(V3(0, top + 0.06, 0), V3(-w * 0.6, top + 1.2, -w * 0.6), 0.025)
        m.add(Prim.lathe([V2(0.08, 0), V2(0.08, 0.1), V2(0.05, 0.16), V2(0, 0.17)], segments: 12, seamTile: 0.2, material: "emissive.signal-red"),
              Xform(translation: V3(0, top + 4, 0)))
        groundAO(&m)
        // centre the footprint (tower plus arm) on the origin; the tower axis sits at x = -armLength / 2
        var c = Model(name: Self.id)
        c.add(m, Xform(translation: V3(-armLength / 2, 0, 0)))
        return c
    }
}
