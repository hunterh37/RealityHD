import simd
import Foundation

/// Permeable grass paver grid: architectural facade customizer, Contemporary. 400 mm concrete
/// grass-crete units, each a 3 x 3 lattice of open pockets with chamfered webs, filled with soil and
/// growing grass tufts; worn rims and a few bare pockets where wheels run.
public struct PermeableGrassPaverGrid: RealAsset {
    public static let id = "permeable-grass-paver-grid"
    public static let summary = "Permeable grass paver tile, 2 x 2 m: 400 mm concrete lattice units with open pockets of soil and growing grass, chamfered webs, worn rims."
    public static let tags = ["prop", "architecture", "facade", "ground", "concrete"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.12, 2.0)
    /// Unit edge (m).
    public var unit: Float = 0.4
    /// Pockets per unit side.
    public var pockets = 3
    /// Web width (m).
    public var web: Float = 0.032
    /// Height of the concrete lattice (m).
    public var latticeHeight: Float = 0.075
    /// Concrete material.
    public var concrete: MaterialKey = "concrete.rough:8E8A82"
    /// Soil fill.
    public var soil: MaterialKey = "soil.sod"
    /// Short grass thatch over the soil.
    public var thatch: MaterialKey = "grass.lawn-thatch"
    /// Grass blade material.
    public var grass: MaterialKey = "grass.lawn"
    /// Fraction of pockets with grass.
    public var grassFraction: Float = 0.85
    public init() {}

    /// Web bar along X with chamfered top edges, base at y = 0.
    private func webBar(length: Float, width: Float, height: Float, material: MaterialKey) -> Surface {
        let w = width / 2, c: Float = 0.006
        let section = [V2(-w, 0), V2(w, 0), V2(w, height - c), V2(w - c, height), V2(-w + c, height), V2(-w, height - c)]
        var e = Prim.extrude(section, depth: length, bevel: 0, bevelSegments: 0, material: material)
        e = e.transformed(Xform(rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
        return e
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = Int(size.x / unit + 0.5), nz = Int(size.z / unit + 0.5)
        let lh = latticeHeight
        let gap: Float = 0.004
        let pitch = (unit - gap - web) / Float(pockets)
        var grassSurf = Surface(material: grass)
        for i in 0..<n { for j in 0..<nz {
            var r = rng.fork(i * 17 + j)
            let c = V2(-size.x / 2 + unit * (Float(i) + 0.5), -size.z / 2 + unit * (Float(j) + 0.5))
            let side = unit - gap
            let tone = String(format: "%06X", [0x8E8A82, 0x84807A, 0x98938A][r.int(0...2)])
            let key = concrete.split(separator: ":").first.map(String.init)! + ":" + tone
            let yOff = r.float(-0.002...0.002)
            // Webs along X and Z, chamfered tops.
            for k in 0...pockets {
                let o = -side / 2 + web / 2 + Float(k) * pitch
                let wv = (k == 0 || k == pockets) ? web : web * 1.1
                m.add(webBar(length: side, width: wv, height: lh, material: key),
                      Xform(translation: V3(c.x, yOff, c.y + o)))
                m.add(webBar(length: side - 0.004, width: wv, height: lh - 0.002, material: key),
                      Xform(translation: V3(c.x + o, yOff, c.y), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            }
            // Pockets: soil level and grass.
            for a in 0..<pockets { for b in 0..<pockets {
                var q = r.fork(100 + a * 7 + b)
                let pc = c + V2(-side / 2 + web + pitch * (Float(a) + 0.5) - web / 2, -side / 2 + web + pitch * (Float(b) + 0.5) - web / 2)
                let soilTop = lh - 0.02 + 0.004 * sin(pc.x * 9 + 1.3) * sin(pc.y * 7 + 0.4)
                // Wheel track down x ~ -0.4 leaves pockets bare.
                let inTrack = abs(pc.x + 0.45) < 0.16
                if q.chance(inTrack ? 0.15 : grassFraction) {
                    var t = PlantKit.Tuft()
                    t.count = q.int(13...17)
                    t.height = q.float(0.045...0.062)
                    t.radius = (pitch - web) * 0.36
                    t.segments = 2
                    t.width = 0.004...0.007
                    t.lean = 0.05...0.3
                    grassSurf.append(PlantKit.tuft(t, at: V3(pc.x, soilTop, pc.y), rng: &q, material: grass))
                }
            }}
        }}
        m.add(grassSurf, Xform())
        // Soil fill sheet in the pockets, humped and uneven.
        let soilSheet = Prim.terrain(size: V2(size.x - 0.01, size.z - 0.01), segments: 30, material: soil) { p in
            lh - 0.02 + 0.004 * sin(p.x * 9 + 1.3) * sin(p.y * 7 + 0.4) - (abs(p.x + 0.45) < 0.16 ? 0.006 : 0)
        }
        m.add(soilSheet, Xform())
        // Thatch of short grass over the soil outside the wheel track.
        for half in [(-1.0 as Float, -0.61 as Float), (-0.29 as Float, 1.0 as Float)] {
            let w = (half.1 - half.0) * size.x / 2 - 0.006, cx = (half.0 + half.1) / 2 * size.x / 2
            var th = Prim.terrain(size: V2(w, size.z - 0.01), segments: 14, material: thatch) { p in
                lh - 0.017 + 0.004 * sin((p.x + cx) * 9 + 1.3) * sin(p.y * 7 + 0.4)
            }
            th.uvs = th.uvs.map { $0 + V2(cx, 0) }; th.computeTangents()
            m.add(th, Xform(translation: V3(cx, 0, 0)))
        }
        // Soil and gravel bedding under the lattice.
        m.add(Prim.roundedBox(V3(size.x - 0.004, 0.03, size.z - 0.004), radius: 0.002, bevelSegments: 1, material: "ground.gravel"),
              Xform(translation: V3(0, 0.015, 0)))
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, lh, size.z), radius: 0.004, bevelSegments: 1, material: soil), Xform(translation: V3(0, lh / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
