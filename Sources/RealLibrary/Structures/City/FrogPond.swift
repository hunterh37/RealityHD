import simd
import Foundation

/// Frog Pond: Boston Common wading pool in summer: worn granite coping, faded blue paint, 15 cm of water, black low railing. Parts: oval granite coping, blue painted concrete floor, shallow water surface, central spray jet, low iron fence with entry gaps, perimeter paving ring.
public struct FrogPond: RealAsset {
    public static let id = "frog-pond"
    public static let summary = "Frog Pond, 60 x 40 m oval wading pool: granite coping, blue concrete floor, shallow water, central spray jet and a low fence with gaps."
    public static let tags = ["structure", "park", "outdoor", "water", "stone", "concrete", "city"]
    public static let budget = 30000
    public static let author = "hunterh37"
    public static let preview = PreviewHint(azimuth: 20, elevation: 22, distance: 1.0)

    /// Pool length along X (m).
    public var length: Float = 60
    /// Pool width along Z (m).
    public var width: Float = 40
    /// Superellipse exponent of the oval plan (2 = ellipse).
    public var squareness: Float = 2.3
    /// Coping width (m).
    public var copingWidth: Float = 0.45
    /// Water depth above the floor (m).
    public var waterDepth: Float = 0.15
    /// Spray jet height (m).
    public var jetHeight: Float = 3.0
    /// Painted pool floor.
    public var floor: MaterialKey = "concrete.smooth:5B9CC9"
    /// Granite coping.
    public var coping: MaterialKey = "stone.granite-curb"
    /// Walkway ring.
    public var paving: MaterialKey = "paving.slab"
    public var water: MaterialKey = "glass.water-clear:3E8FB0"
    /// Aerated spray of the jet.
    public var spray: MaterialKey = "glass.frosted"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    func outline(_ a: Float, _ b: Float, _ n: Int) -> [V2] {
        let e = 2 / squareness
        return (0..<n).map { i in
            let t = Float(i) / Float(n) * 2 * .pi
            let c = cos(t), s = sin(t)
            return V2(a * copysign(pow(abs(c), e), c), b * copysign(pow(abs(s), e), s))
        }
    }

    /// Flat ring between two outlines at height y, facing up. UVs in meters.
    func ring(_ inner: [V2], _ outer: [V2], y: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let n = inner.count
        for i in 0..<n {
            _ = s.add(V3(inner[i].x, y, -inner[i].y), V3(0, 1, 0), V2(inner[i].x, inner[i].y))
            _ = s.add(V3(outer[i].x, y, -outer[i].y), V3(0, 1, 0), V2(outer[i].x, outer[i].y))
        }
        for i in 0..<n {
            let j = (i + 1) % n
            let a = UInt32(2 * i), b = UInt32(2 * j)
            s.quad(a, a + 1, b + 1, b)
        }
        s.computeTangents()
        return s
    }

    /// Filled oval at height y facing up.
    func disc(_ o: [V2], y: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let c = s.add(V3(0, y, 0), V3(0, 1, 0), .zero)
        for p in o { _ = s.add(V3(p.x, y, -p.y), V3(0, 1, 0), p) }
        let n = UInt32(o.count)
        for i in 0..<n { s.tri(c, 1 + i, 1 + (i + 1) % n) }
        s.computeTangents()
        return s
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let a = length / 2, b = width / 2, n = 160
        let cw = copingWidth, copeY: Float = 0.32, floorY: Float = 0.06
        // Floor: blue painted concrete, a shallow dish at the edges.
        let inner = outline(a - cw, b - cw, n)
        m.add(disc(inner, y: floorY, material: floor))
        // Inside face of the coping wall.
        var wall = Surface(material: coping)
        for (i, p) in inner.enumerated() {
            let nn = simd_normalize(V2(-p.x / (a * a), -p.y / (b * b)))
            _ = wall.add(V3(p.x, floorY - 0.01, -p.y), V3(nn.x, 0, -nn.y), V2(Float(i) * 0.6, 0))
            _ = wall.add(V3(p.x, copeY - 0.02, -p.y), V3(nn.x, 0, -nn.y), V2(Float(i) * 0.6, 0.3))
        }
        for i in 0..<n { let j = (i + 1) % n; wall.quad(UInt32(2 * i), UInt32(2 * i + 1), UInt32(2 * j + 1), UInt32(2 * j)) }
        wall.computeTangents()
        m.add(wall)
        // Coping: rounded granite section swept round the oval.
        let path = outline(a - cw / 2, b - cw / 2, n).map { V3($0.x, 0, -$0.y) }
        let prof = Shape2D.rounded([V2(0, -cw / 2), V2(copeY, -cw / 2), V2(copeY, cw / 2), V2(0, cw / 2)], radius: 0.04)
        m.add(Prim.sweep(prof, along: path, up: V3(0, 1, 0), closedPath: true, material: coping))
        // Coping joints every ~1.2 m.
        for i in stride(from: 0, to: n, by: 3) {
            let p = path[i], q = path[(i + 1) % n]
            let t = simd_normalize(q - p)
            m.add(cuboid(V3(0.012, 0.01, cw - 0.02), material: "concrete.rough:4E4C48"),
                  Xform(translation: p + V3(0, copeY + 0.002, 0), rotation: simd_quatf(angle: atan2(t.x, t.z) + .pi / 2, axis: V3(0, 1, 0))))
        }
        // Paint worn through to grey concrete in scattered patches where feet scuff most.
        for k in 0..<8 {
            let ang = rng.float(0...(2 * .pi)), rr = sqrt(rng.float(0.05...0.85))
            let c = V3(cos(ang) * (a - cw) * rr, floorY + 0.003, sin(ang) * (b - cw) * rr)
            let pr = rng.float(1.5...4.0)
            let sd = UInt32(k * 31 + 7)
            let patch: [V2] = (0..<20).map { i in
                let t = Float(i) / 20 * 2 * .pi
                let wob = 0.6 + 0.5 * Noise.perlin(V3(cos(t) * 1.5, sin(t) * 1.5, Float(k)), seed: sd)
                return V2(cos(t), sin(t) * 0.7) * pr * wob
            }
            m.add(disc(patch, y: 0, material: "concrete.smooth:76A0B6"), Xform(translation: c, rotation: simd_quatf(angle: rng.float(0...3), axis: V3(0, 1, 0))))
        }
        // Algae and scuff band along the foot of the wall, where the paint wears first.
        m.add(ring(outline(a - cw - 0.9, b - cw - 0.9, n), inner, y: floorY + 0.004, material: "concrete.smooth:3E6E86"))
        // Water surface.
        m.add(disc(outline(a - cw - 0.01, b - cw - 0.01, n), y: floorY + waterDepth, material: water))
        // Paving ring outside the coping, then lawn edge.
        let pave: Float = 2.5
        m.add(ring(outline(a, b, n), outline(a + pave, b + pave, n), y: 0.04, material: paving))
        // Central spray jet: bronze nozzle, rising column, falling crown and splash ring.
        m.add(turned([(0, 0), (0.45, 0), (0.45, 0.08), (0.2, 0.14), (0.12, 0.3), (0.08, 0.36), (0, 0.36)], segments: 24, material: "metal.bronze-cast"),
              Xform(translation: V3(0, floorY, 0)))
        let jy = floorY + 0.36
        // Aerated core column and a clear sheet falling back around it.
        m.add(Prim.tube([V3(0, jy, 0), V3(0, jetHeight * 0.5, 0), V3(0, jetHeight - 0.02, 0)], radii: [0.09, 0.07, 0.04], sides: 10, seamTile: 0.3, material: spray))
        var crown = Prim.lathe([V2(0.95, floorY + waterDepth), V2(0.8, jetHeight * 0.45), V2(0.5, jetHeight * 0.85), V2(0.06, jetHeight)],
                               segments: 28, seamTile: 0.5, material: water)
        crown.displace { p, _ in 0.03 * sin(atan2(p.z, p.x) * 14 + p.y * 3) }
        m.add(crown)
        m.add(Prim.torus(major: 0.95, minor: 0.07, segments: 32, sides: 6, material: spray), Xform(translation: V3(0, floorY + waterDepth, 0)))
        // Low iron fence along the outer paving edge with four entry gaps on the axes.
        let fence = outline(a + pave + 0.1, b + pave + 0.1, n * 2)
        var run: [V3] = []
        func flush() {
            guard run.count > 1 else { run = []; return }
            for h in [Float(0.85), 0.25] {
                m.add(Prim.tube(run.map { $0 + V3(0, h, 0) }, radii: Array(repeating: 0.035, count: run.count), sides: 5, seamTile: 0.2, material: iron))
            }
            run = []
        }
        for (i, p) in fence.enumerated() {
            let ang = atan2(p.y / b, p.x / a)
            let q: Float = .pi / 2
            let off: Float = abs(remainder(ang, q))
            let gap = off < 0.05
            if gap { flush(); continue }
            let v = V3(p.x, 0, -p.y)
            run.append(v)
            if i % 2 == 0 {
                m.add(Prim.tube([v, v + V3(0, 0.92, 0)], radii: [0.05, 0.045], sides: 5, seamTile: 0.2, material: iron))
            }
        }
        flush()
        _ = rng.float()
        groundAO(&m, height: 0.3, floor: 0.6)
        return LODModel(m)
    }
}
