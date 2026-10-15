import simd
import Foundation

/// Brewer Fountain: 1868 Lienard bronze fountain cast in Paris, dark olive bronze with verdigris streaks, wet granite basin. Parts: granite basin with coping, water surface, pedestal with four seated figures (Neptune, Amphitrite, Acis, Galatea), lower bowl, middle stem with dolphins, upper bowl, top spout.
public struct BrewerFountain: RealAsset {
    public static let id = "brewer-fountain"
    public static let summary = "Brewer Fountain, 6.7 m bronze tiered fountain in a 12 m granite basin: four seated figures, two bowls and a top spout."
    public static let tags = ["prop", "park", "outdoor", "urban", "metal", "stone", "water", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall height to the top of the finial (m).
    public var height: Float = 6.7
    /// Outer radius of the granite basin (m).
    public var basinRadius: Float = 6.0
    /// Olive-brown cast bronze.
    public var bronze: MaterialKey = "metal.bronze-cast:3E4232"
    /// Verdigris where water runs: bowls and the wet plinth.
    public var verdigris: MaterialKey = "metal.copper-patina:6A8F7C"
    /// Basin coping granite.
    public var granite: MaterialKey = "stone.granite-curb"
    /// Pool and falling water.
    public var water: MaterialKey = "glass.water-clear:2E4744"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let k = height / 6.7, R = basinRadius, b = bronze
        // Granite basin: floor, inner wall, rounded coping, outer face.
        m.add(Prim.lathe([V2(0, 0.03), V2(R - 0.42, 0.03), V2(R - 0.42, 0.47), V2(R - 0.4, 0.53), V2(R - 0.36, 0.55),
                          V2(R - 0.06, 0.55), V2(R - 0.01, 0.52), V2(R, 0.47), V2(R, 0)], segments: 56, seamTile: 0.6, material: granite))
        // Coping joints.
        for j in 0..<16 {
            let a = Float(j) / 16 * 2 * .pi
            m.add(cuboid(V3(0.012, 0.012, 0.38), material: "concrete.rough:5A5852"), Xform(translation: V3(sin(a), 0, cos(a)) * (R - 0.2) + V3(0, 0.552, 0), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0))))
        }
        // Pool floor stained dark under the water, then the water.
        m.add(Prim.cylinder(radius: R - 0.43, height: 0.01, bevel: 0.002, segments: 32, bevelSegments: 1, material: "concrete.rough:2F3431"), Xform(translation: V3(0, 0.035, 0)))
        m.add(Prim.cylinder(radius: R - 0.425, height: 0.33, bevel: 0.002, segments: 72, bevelSegments: 1, material: water), Xform(translation: V3(0, 0.05, 0)))
        // Bronze base rising from the water: molded rock plinth carrying the four figures.
        m.add(turned([(0, 0.04), (2.4, 0.04), (2.45, 0.5), (2.35, 0.62), (2.38, 0.7), (2.25, 0.78), (0, 0.78)], segments: 48, material: verdigris))
        let figs: [StatueKit.Attribute] = [.trident, .shell, .branch, .shell]
        for i in 0..<4 {
            let a = Float(i) * .pi / 2 + .pi / 4
            StatueKit.seated(&m, at: V3(sin(a), 0, cos(a)) * 1.45 + V3(0, 0.77, 0), yaw: a * 180 / .pi, h: 2.7 * k, mat: b,
                             attribute: figs[i], helmet: false, seed: seed &+ UInt64(i))
        }
        // Central pedestal: base drum, waisted shaft with a bead, flaring into the lower bowl.
        let y0: Float = 0.78
        m.add(turned([(0, 0), (0.85, 0), (0.85, 0.15), (0.7, 0.25), (0.62, 0.6), (0.5, 1.0), (0.45, 1.3), (0.55, 1.36), (0.45, 1.42),
                      (0.42, 1.7), (0.6, 1.85), (0.95, 1.92), (0, 1.92)].map { ($0.0 * k, $0.1 * k) }, segments: 32, material: b),
              Xform(translation: V3(0, y0, 0)))
        // Lower bowl: shallow shell with a rolled, scalloped lip.
        let by = y0 + 1.9 * k, bR: Float = 1.8 * k
        var bowl = Prim.lathe([V2(0.9 * k, by - 0.02), V2(1.3 * k, by + 0.14 * k), V2(1.68 * k, by + 0.32 * k), V2(bR, by + 0.42 * k),
                               V2(bR + 0.03, by + 0.5 * k), V2(bR - 0.04, by + 0.53 * k), V2(bR - 0.12, by + 0.48 * k),
                               V2(1.3 * k, by + 0.38 * k), V2(0.3 * k, by + 0.3 * k), V2(0, by + 0.3 * k)], segments: 56, seamTile: 0.5, material: verdigris)
        bowl.displace { p, n in
            let r = simd_length(V2(p.x, p.z))
            return r > 1.2 * k ? 0.035 * sin(atan2(p.z, p.x) * 16) * saturate((r - 1.2 * k) / 0.5) : 0
        }
        m.add(bowl)
        // Water in the lower bowl and the sheet falling from its lip.
        m.add(Prim.cylinder(radius: bR - 0.13, height: 0.05, bevel: 0.002, segments: 48, bevelSegments: 1, material: water), Xform(translation: V3(0, by + 0.38 * k, 0)))
        streams(&m, from: bR + 0.03, lipY: by + 0.5 * k, to: 0.38, count: 10)
        // Stem with four dolphins diving head down around it.
        let sy = by + 0.3 * k, sH: Float = 1.55 * k
        m.add(turned([(0, 0), (0.42, 0), (0.3, 0.12), (0.22, 0.5), (0.2, 1.1), (0.28, 1.4), (0.4, sH), (0, sH)].map { ($0.0 * k, $0.1) }, segments: 24, material: b),
              Xform(translation: V3(0, sy, 0)))
        for i in 0..<4 {
            let a = Float(i) * .pi / 2
            let d = V3(sin(a), 0, cos(a)), up = V3(0, 1, 0)
            let pts = [d * 0.3 + up * (sy + 1.45 * k), d * 0.62 + up * (sy + 1.2 * k), d * 0.7 + up * (sy + 0.7 * k), d * 0.55 + up * (sy + 0.25 * k), d * 0.68 + up * (sy + 0.06)]
            let path = catmull(pts, per: 3)
            let radii = path.indices.map { j -> Float in
                let t = Float(j) / Float(path.count - 1)
                return (0.05 + 0.11 * sin(min(1, t * 1.6) * .pi * 0.9) + 0.07 * smoothstep(0.85, 1, t)) * k
            }
            m.add(Prim.tube(path, radii: radii, sides: 9, seamTile: 0.3, material: b))
            // Tail fluke.
            m.add(Prim.superellipsoid(V3(0.32, 0.05, 0.14) * k, exponent: 2.2, subdivisions: 2, material: b),
                  Xform(translation: pts[0] + up * 0.05, rotation: simd_quatf(angle: a, axis: up)))
        }
        // Upper bowl.
        let uy = sy + sH, uR: Float = 1.15 * k
        var ub = Prim.lathe([V2(0.3 * k, uy - 0.02), V2(0.8 * k, uy + 0.1 * k), V2(uR, uy + 0.26 * k), V2(uR + 0.03, uy + 0.32 * k),
                             V2(uR - 0.06, uy + 0.34 * k), V2(0.6 * k, uy + 0.24 * k), V2(0, uy + 0.22 * k)], segments: 48, seamTile: 0.5, material: verdigris)
        ub.displace { p, _ in
            let r = simd_length(V2(p.x, p.z))
            return r > 0.8 * k ? 0.025 * sin(atan2(p.z, p.x) * 12) * saturate((r - 0.8 * k) / 0.35) : 0
        }
        m.add(ub)
        streams(&m, from: uR + 0.03, lipY: uy + 0.32 * k, to: by + 0.42 * k, count: 10)
        // Crowning urn and spout up to the full height.
        let ty = uy + 0.22 * k, tH = height - ty
        m.add(turned([(0, 0), (0.3, 0), (0.22, 0.08), (0.14, 0.2), (0.16, 0.3), (0.3, 0.45), (0.28, 0.6), (0.12, 0.7), (0.1, 0.8),
                      (0.18, 0.86), (0.08, 0.92), (0.05, 1.0), (0, 1.0)].map { ($0.0 * k, $0.1 * tH) }, segments: 24, material: b),
              Xform(translation: V3(0, ty, 0)))
        // Jet spilling from the spout over the urn.
        m.add(Prim.tube([V3(0, height - 0.05, 0), V3(0, height + 0.0, 0)], radii: [0.03, 0.02], sides: 6, seamTile: 0.2, material: water))
        ArchTrimKit.weather(&m, seed: seed, amount: 0.35)
        groundAO(&m, height: 0.5, floor: 0.55)
        return LODModel(ArchTrimKit.ground(m))
    }

    /// Thin arcing streams spilling over a bowl lip into the basin below.
    func streams(_ m: inout Model, from r: Float, lipY: Float, to y1: Float, count: Int) {
        for i in 0..<count {
            let a = (Float(i) + 0.5) / Float(count) * 2 * .pi
            let d = V3(sin(a), 0, cos(a))
            let pts = [d * r + V3(0, lipY, 0), d * (r + 0.12) + V3(0, lipY - 0.08, 0), d * (r + 0.22) + V3(0, (lipY + y1) / 2, 0), d * (r + 0.26) + V3(0, y1, 0)]
            m.add(Prim.tube(pts, radii: [0.035, 0.03, 0.025, 0.03], sides: 5, seamTile: 0.2, material: water))
        }
    }
}
