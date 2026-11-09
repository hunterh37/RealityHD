import simd
import Foundation

/// Eighteenth-century pirate tricorn, 0.36 m wide, 0.32 m deep, 0.14 m tall: black wool felt crown with a ribbon
/// band, a 3 mm thick brim turned up on three sides into a triangle with rounded corner points (one point
/// forward, +Z), gold braid trim laid along the brim edge, and a brass cockade button at the front. Base y = 0
/// at the crown hem, up +Y. Anchors: `hat.crown`, `hat.front`, `hat.band`.
public struct PirateTricorn: RealAsset {
    public static let id = "pirate-tricorn"
    public static let summary = "Pirate tricorn hat: black wool felt crown and three-sided turned-up brim, gold braid trim, ribbon band and brass cockade button."
    public static let tags = ["prop", "headwear", "fabric", "antique"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 0.7, studio: true)

    /// Felt body.
    public var felt: MaterialKey = "fabric.felt:17171A"
    /// Hat band.
    public var band: MaterialKey = "fabric.grosgrain:0E0E10"
    /// Braid trim.
    public var braid: MaterialKey = "metal.gold"
    /// Button.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public var anchors: [String: Xform] {
        ["hat.crown": Xform(translation: V3(0, 0.14, 0)), "hat.front": Xform(translation: V3(0, 0.075, 0.2)), "hat.band": Xform(translation: V3(0, 0.03, 0))]
    }

    /// Pick the vertex that maximises `score` and flip `s` if its normal opposes `dir`.
    static func orient(_ s: Surface, score: (V3) -> Float, dir: (V3) -> V3) -> Surface {
        guard let k = s.positions.indices.max(by: { score(s.positions[$0]) < score(s.positions[$1]) }) else { return s }
        return simd_dot(s.normals[k], dir(s.positions[k])) < 0 ? s.flipped() : s
    }

    /// Brim section at angle `a` (0 = front point): (radius, y) polyline from the crown out to the folded rim.
    static func section(_ a: Float, lift: Float = 0) -> [V2] {
        let c = pow(max(0, cos(3 * a)), 1.6)
        let reach = lerp(0.097, 0.197, c), flap = lerp(0.052, 0.006, c)
        let base: Float = 0.046 + lift
        let out = 0.003 + 0.011 * (1 - c)
        return [V2(0.077, base + 0.004), V2(lerp(0.077, reach, 0.35), base + 0.001), V2(lerp(0.077, reach, 0.7), base - 0.001 + 0.004 * c),
                V2(reach, base + 0.002 + 0.004 * c), V2(reach + out * 0.5, base + flap * 0.55), V2(reach + out, base + flap)]
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let cols = 144
        func grid(_ lift: Float, mat: MaterialKey) -> Surface {
            var s = Surface(material: mat)
            let rows = Self.section(0).count
            for k in 0...cols {
                let a = Float(k) / Float(cols) * 2 * .pi
                let sec = Self.section(a, lift: lift)
                for (i, p) in sec.enumerated() {
                    _ = s.add(V3(p.x * sin(a), p.y, p.x * cos(a)), .up, V2(Float(k) / Float(cols) * 1.2, Float(i) * 0.04))
                }
            }
            let r = UInt32(rows)
            for k in 0..<cols { for i in 0..<(rows - 1) {
                let a = UInt32(k) * r + UInt32(i)
                s.quad(a, a + 1, a + r + 1, a + r)
            }}
            s.recomputeNormals(weldSeams: false)
            s.computeTangents()
            return s
        }
        // Top face of the brim, underside 3 mm below, rim edge between them.
        let top = Self.orient(grid(0, mat: felt), score: { $0.y + 0.001 * simd_length(V2($0.x, $0.z)) }, dir: { _ in V3(0, 1, 0) })
        var under = grid(-0.003, mat: felt)
        under = Self.orient(under, score: { -$0.y }, dir: { _ in V3(0, -1, 0) })
        m.add(top); m.add(under)
        var edge = Surface(material: felt)
        let rows = Self.section(0).count
        for k in 0...cols {
            let a = Float(k) / Float(cols) * 2 * .pi
            for lift in [Float(0), -0.003] {
                let p = Self.section(a, lift: lift)[rows - 1]
                _ = edge.add(V3(p.x * sin(a), p.y, p.x * cos(a)), .up, V2(Float(k) / Float(cols) * 1.2, lift == 0 ? 0 : 0.003))
            }
        }
        for k in 0..<cols { let i = UInt32(k) * 2; edge.quad(i, i + 2, i + 3, i + 1) }
        edge.recomputeNormals(weldSeams: false); edge.computeTangents()
        m.add(Self.orient(edge, score: { simd_length(V2($0.x, $0.z)) }, dir: { V3($0.x, 0, $0.z) }))
        // Crown: straight hem, slight taper, rounded flat top.
        let crown: [V2] = [V2(0, 0.0), V2(0.0775, 0.0), V2(0.0785, 0.01), V2(0.0775, 0.05), V2(0.0745, 0.095), V2(0.0715, 0.125),
                           V2(0.066, 0.1345), V2(0.056, 0.139), V2(0.04, 0.1405), V2(0.0, 0.1405)]
        m.add(Prim.lathe(crown, segments: 96, seamTile: 0.05, material: felt))
        m.add(Prim.lathe([V2(0.0785, 0.012), V2(0.0805, 0.0125), V2(0.0808, 0.044), V2(0.0805, 0.0475), V2(0.0785, 0.048)], segments: 96, seamTile: 0.05, material: band))
        // Gold braid along the rim, just inside the edge.
        var path: [V3] = [], radii: [Float] = []
        let n = 120
        for k in 0...n {
            let a = Float(k % n) / Float(n) * 2 * .pi
            let sec = Self.section(a)
            let p = sec[rowsEdge(rows)]
            path.append(V3(p.x * sin(a), p.y + 0.0015, p.x * cos(a)) - V3(sin(a), 0, cos(a)) * 0.0012)
            radii.append(0.0026)
        }
        m.add(Prim.tube(path, radii: radii, sides: 16, seamTile: 0.01, material: braid, capEnd: false))
        // Cockade button at the front point.
        let front = Self.section(0)[3]
        m.add(Prim.lathe([V2(0, 0), V2(0.0115, 0), V2(0.0125, 0.002), V2(0.0105, 0.0048), V2(0.0055, 0.0068), V2(0, 0.007)], segments: 48, seamTile: 0.02, material: brass),
              Xform(translation: V3(0, front.y + 0.052 * 0 + 0.016, front.x - 0.004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        groundAO(&m, height: 0.05, floor: 0.7)
        return LODModel(m)
    }
}

private func rowsEdge(_ rows: Int) -> Int { rows - 2 }
