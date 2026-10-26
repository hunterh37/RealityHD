import simd
import Foundation

/// Curved concrete retaining wall: architectural facade customizer, Contemporary. Board-formed panels
/// follow a shallow plan arc over a plinth, with precast coping, a sealed expansion joint, weep holes
/// and form-tie holes.
public struct CurvedConcreteRetainingWall: RealAsset {
    public static let id = "curved-concrete-retaining-wall"
    public static let summary = "Curved concrete retaining wall 3.0 m: board-formed panels on a plinth with precast coping, a sealed expansion joint, weep holes and form-tie holes."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, distance: 4.0)

    /// Chord length in meters.
    public var length: Float = 2.98
    /// Plan sagitta (arc rise) in meters.
    public var sagitta: Float = 0.075
    /// Overall height to the top of the coping in meters.
    public var height: Float = 1.2
    /// Wall thickness in meters.
    public var thickness: Float = 0.19
    /// Wall concrete.
    public var concrete: MaterialKey = "concrete.smooth"
    /// Stained concrete at the base.
    public var stained: MaterialKey = "concrete.river-algae"
    public init() {}

    func z(_ x: Float) -> Float { sagitta * (x / (length / 2)) * (x / (length / 2)) }
    func yaw(_ x: Float) -> Float { atan2(2 * sagitta * x / ((length / 2) * (length / 2)), 1) * 180 / .pi }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = 8, panelW = (length - 0.02) / Float(n)
        let plinthH: Float = 0.06, copeH: Float = 0.06, boardH: Float = 0.1
        let bodyH = height - plinthH - copeH
        let boards = Int((bodyH / 0.135).rounded())
        let bh = bodyH / Float(boards)
        for i in 0..<n {
            let left = -length / 2 + Float(i) * panelW + (i >= n / 2 ? 0.02 : 0)
            let xc = left + panelW / 2
            let q = FA.q(-yaw(xc), FA.Y)
            let zc = z(xc)
            func put(_ size: V3, _ y: Float, _ dz: Float, _ mat: MaterialKey, r: Float = 0.004) {
                m.add(Prim.roundedBox(size, radius: min(r, min(size.x, min(size.y, size.z)) * 0.4), bevelSegments: 1, material: mat),
                      Xform(translation: V3(xc, y, zc) + q.act(V3(0, 0, dz)), rotation: q))
            }
            // Plinth and dark core visible in the panel joints.
            put(V3(panelW + 0.004, plinthH, thickness + 0.025), plinthH / 2, 0, i % 2 == 1 ? stained : concrete, r: 0.006)
            put(V3(panelW + 0.01, bodyH, thickness - 0.012), plinthH + bodyH / 2, 0, "concrete.sealed-dark", r: 0.002)
            put(V3(panelW - 0.006, bodyH - 0.004, 0.0095), plinthH + bodyH / 2, -(thickness / 2 - 0.00475), concrete, r: 0.003)
            // Form-tie holes on a 0.5 m grid, set into both faces.
            if true {
                for ty in [0.4, 0.9] as [Float] {
                    for s: Float in [1] {
                        m.add(Prim.cylinder(radius: 0.0125, height: 0.006, bevel: 0.001, segments: 10, bevelSegments: 1, material: "concrete.sealed-void"),
                              Xform(translation: V3(xc, ty, zc) + q.act(V3(0, 0, s * (thickness / 2 - 0.001))), rotation: q * FA.q(90 * s, FA.X)))
                    }
                }
            }
            // Weep hole pipe stubs at the base of every third panel.
            if i % 2 == 1 {
                for s: Float in [1] {
                    m.add(Prim.cylinder(radius: 0.03, height: 0.03, bevel: 0.003, segments: 14, bevelSegments: 1, material: "concrete.sealed-void"),
                          Xform(translation: V3(xc, plinthH + 0.12, zc) + q.act(V3(0, 0, s * (thickness / 2 - 0.004))), rotation: q * FA.q(90 * s, FA.X)))
                }
            }
            // Precast coping with a bevelled top and drip.
            put(V3(panelW + 0.012, copeH, thickness + 0.026), height - copeH / 2, 0, i % 5 == 2 ? stained : "concrete.rough", r: 0.008)
        }
        // Board-formed lifts run across panel joints in pairs of panels, staggered per row, each board proud by a random fraction of a millimetre.
        for b in 0..<boards {
            let y = plinthH + (Float(b) + 0.5) * bh
            for half in 0..<2 {
                let off = (b + half) % 2
                var groups: [[Int]] = []
                var k = 0
                if off == 1 { groups.append([0]); k = 1 }
                while k < n / 2 { groups.append(k + 1 < n / 2 ? [k, k + 1] : [k]); k += 2 }
                for g in groups {
                    let idx = g.map { half * (n / 2) + $0 }
                    let lefts = idx.map { -length / 2 + Float($0) * panelW + ($0 >= n / 2 ? 0.02 : 0) }
                    let x0 = lefts.first! + 0.003, x1 = lefts.last! + panelW - 0.003
                    let xc = (x0 + x1) / 2
                    let damp = b < 2 || (b == boards - 1 && idx[0] % 3 == 0)
                    let mat: MaterialKey = damp && (idx[0] + b) % 2 == 0 ? stained : (rng.chance(0.3) ? "concrete.rough" : concrete)
                    let q = FA.q(-yaw(xc), FA.Y)
                    let d: Float = 0.022
                    let proud = rng.float(-0.0012...0.0016)
                    m.add(Prim.roundedBox(V3(x1 - x0, bh - 0.003, d), radius: 0.0025, bevelSegments: 1, material: mat),
                          Xform(translation: V3(xc, y, z(xc)) + q.act(V3(0, 0, thickness / 2 - d / 2 + proud)), rotation: q))
                }
            }
        }
        // Rain streaks below the coping joints and weep-hole stains on the face.
        for i in 1..<n {
            let xj = -length / 2 + Float(i) * panelW + (i >= n / 2 ? 0.02 : 0)
            if i == n / 2 { continue }
            let q = FA.q(-yaw(xj), FA.Y)
            let sh = rng.float(0.12...0.38)
            m.add(Prim.roundedBox(V3(rng.float(0.02...0.04), sh, 0.003), radius: 0.0015, bevelSegments: 1, material: "concrete.river-algae"),
                  Xform(translation: V3(xj, height - copeH - sh / 2 - 0.012, z(xj)) + q.act(V3(0, 0, thickness / 2 + 0.0015)), rotation: q))
        }
        for i in 0..<n where i % 2 == 1 {
            let xc = -length / 2 + (Float(i) + 0.5) * panelW + (i >= n / 2 ? 0.02 : 0)
            let q = FA.q(-yaw(xc), FA.Y)
            m.add(Prim.roundedBox(V3(0.06, 0.16, 0.004), radius: 0.0015, bevelSegments: 1, material: "concrete.river-algae"),
                  Xform(translation: V3(xc, plinthH + 0.04, z(xc)) + q.act(V3(0, 0, thickness / 2 + 0.0015)), rotation: q))
        }
        // Expansion joint sealant strip in the centre, dark and set 5 mm back.
        let sq = FA.q(-yaw(0), FA.Y)
        m.add(Prim.roundedBox(V3(0.02, bodyH, thickness - 0.008), radius: 0.002, bevelSegments: 1, material: "concrete.sealed-void"),
              Xform(translation: V3(0, plinthH + bodyH / 2, z(0)), rotation: sq))
        m = FE.seat(m)
        groundAO(&m, height: 0.12, floor: 0.6)
        return LODModel(m)
    }
}
