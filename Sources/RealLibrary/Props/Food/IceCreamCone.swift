import simd
import Foundation

/// Waffle cone with three glossy scoops (vanilla, strawberry, pistachio), held tip down: the tip sits at
/// y = 0 as with other handheld props. Cone is a lathe with an embossed diamond waffle grid, a paper sleeve
/// collar at the rim, two thick drips with bulbs running down the cone, scalloped melting skirts under
/// each scoop, rainbow sprinkles and a twisted chocolate flake stick.
public struct IceCreamCone: RealAsset {
    public static let id = "ice-cream-cone"
    public static let summary = "Ice cream cone, 22 cm: diamond waffle cone with paper collar, three wet scoops with scalloped skirts, two drips, sprinkles and a flake stick."
    public static let tags = ["prop", "food", "handheld"]
    public static let budget = 14800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 0.95, studio: true)

    /// Cone height tip to rim (m) and rim radius (m).
    public var coneHeight: Float = 0.108
    public var rimRadius: Float = 0.0295
    /// Diamond cells around the cone.
    public var waffleCells = 18
    /// Kept for API symmetry with stand-up props; adds nothing (tip stays at y = 0).
    public var standing = false
    /// Material keys.
    public var waffle: MaterialKey = "food.batter-cooked"
    public var paper: MaterialKey = "food.onion-skin:EDE6D6"
    public var vanilla: MaterialKey = "food.mozzarella-melted:F7EDD0"
    public var strawberry: MaterialKey = "food.mozzarella-melted:F4A3BA"
    public var pistachio: MaterialKey = "food.stem-green:A9C56C"
    public var chocolate: MaterialKey = "food.chocolate"
    public var sprinkleColors: [MaterialKey] = ["food.cheddar-melted:E8325F", "food.cheddar-melted:2F7FE0", "food.cheddar-melted:F6D234",
                                                "food.cheddar-melted:3DB86A", "food.cheddar-melted:FFFFFF", "food.cheddar-melted:F58A2A"]
    public init() {}

    func coneR(_ y: Float) -> Float { rimRadius * max(y, 0) / coneHeight }

    /// Scoop of base radius `R`, dome height `H`, sitting with its skirt at `base`.
    func scoop(base: Float, R: Float, H: Float, phase: Float, mat: MaterialKey) -> Surface {
        let y0: Float = 0.011, Rd = R * 1.03
        var prof: [V2] = [V2(0, 0.003), V2(0.45 * R, 0.0012), V2(0.85 * R, 0.0018), V2(1.04 * R, 0.0045), V2(1.075 * R, 0.0085)]
        for deg in [0, 9, 20, 32, 45, 57, 68, 78, 85, 90] as [Float] {
            let t = deg * .pi / 180
            prof.append(V2(deg == 90 ? 0 : Rd * pow(cos(t), 0.92), y0 + H * sin(t)))
        }
        var s = Prim.lathe(prof.map { V2($0.x, $0.y + base) }, segments: 64, seamTile: 0.06, material: mat)
        let n: Float = 9
        s.deform { p in
            let a = atan2(-p.z, p.x), ly = p.y - base
            let w = 1 - smoothstep(0.004, 0.0125, ly)
            let sc = sin(n * a + phase)
            var r = simd_length(V2(p.x, p.z))
            r *= 1 + 0.085 * w * sc + 0.028 * sin(3 * a + phase * 1.7) * smoothstep(0.004, 0.02, ly)
            let drop = w * 0.0034 * (0.5 + 0.5 * sin(n * a + phase + 1.2))
            return V3(r * cos(a), p.y - drop + 0.0018 * sin(2 * a + phase) * smoothstep(0.01, 0.03, ly), -r * sin(a))
        }
        return s
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let H = coneHeight, N = Float(waffleCells)
        var m = Model(name: Self.id)

        // Cone with embossed diamond grid.
        var prof: [V2] = []
        let rows = 36
        for i in 0...rows {
            let y = H * Float(i) / Float(rows)
            prof.append(V2(max(coneR(y), 0.0006) * (i == 0 ? 0 : 1), y))
        }
        prof.append(V2(rimRadius + 0.0007, H)); prof.append(V2(rimRadius - 0.003, H + 0.0004)); prof.append(V2(0, H - 0.003))
        var cone = Prim.lathe(prof, segments: 72, seamTile: 0.05, material: waffle)
        let w: Float = 280
        cone.deform { p in
            guard p.y > 0.004, p.y < H - 0.0005 else { return p }
            let a = atan2(-p.z, p.x)
            let d = min(abs(sin(N * a + w * p.y)), abs(sin(N * a - w * p.y)))
            let groove = 1 - smoothstep(0.0, 0.5, d)
            let r = simd_length(V2(p.x, p.z)) - 0.0019 * groove
            return V3(r * cos(a), p.y, -r * sin(a))
        }
        m.add(cone)

        // Paper sleeve collar with pleats.
        let c0: Float = 0.078, c1: Float = 0.0985
        var col: [V2] = []
        for i in 0...5 { let y = c0 + (c1 - c0) * Float(i) / 5; col.append(V2(coneR(y) + 0.0014, y)) }
        col.append(V2(coneR(c1) + 0.0042, c1 + 0.0012)); col.append(V2(coneR(c1) + 0.0034, c1 + 0.0016))
        col.append(V2(coneR(c1) + 0.0002, c1 + 0.0004))
        for i in (0...5).reversed() { let y = c0 + (c1 - c0) * Float(i) / 5; col.append(V2(coneR(y) + 0.0003, y)) }
        col.append(V2(coneR(c0) + 0.0003, c0))
        var collar = Prim.lathe(col, segments: 64, seamTile: 0.05, material: paper)
        collar.deform { p in
            let a = atan2(-p.z, p.x), t = (p.y - c0) / (c1 - c0)
            let r = simd_length(V2(p.x, p.z)) * (1 + (0.012 * sin(30 * a) + 0.004 * sin(7 * a)) * (0.4 + 0.6 * t))
            return V3(r * cos(a), p.y, -r * sin(a))
        }
        m.add(collar)

        // Scoops.
        let b: [Float] = [0.0965, 0.1235, 0.1505]
        m.add(scoop(base: b[0], R: 0.0318, H: 0.027, phase: 0.4, mat: vanilla))
        m.add(scoop(base: b[1], R: 0.0306, H: 0.026, phase: 2.1, mat: strawberry))
        m.add(scoop(base: b[2], R: 0.0286, H: 0.026, phase: 4.0, mat: pistachio))

        // Drips with bulbs down the cone.
        for (ang, yEnd, wob) in [(Float(0.5), Float(0.060), Float(0.06)), (Float(3.1), Float(0.071), Float(-0.05))] as [(Float, Float, Float)] {
            let yTop: Float = 0.102
            let steps = 18
            var path: [V3] = [], radii: [Float] = []
            for i in 0...steps {
                let f = Float(i) / Float(steps)
                let y = yTop + (yEnd - yTop) * f
                let a = ang + wob * sin(f * 5)
                let r = coneR(y) + 0.0019 + 0.0026 * smoothstep(0.074, 0.082, y)
                path.append(V3(r * cos(a), y, -r * sin(a)))
                let body = 0.0031 - 0.0006 * smoothstep(0, 0.6, f)
                let bulb = 0.0023 * smoothstep(0.72, 0.95, f) * (1 - 0.35 * smoothstep(0.95, 1.0, f))
                radii.append(body + bulb)
            }
            m.add(FoodMesh.tube(path, radii: radii, sides: 10, endBulge: 0.9, seamTile: 0.03, material: vanilla))
        }

        // Sprinkles on the top scoop.
        let R3: Float = 0.0286 * 1.03, H3: Float = 0.026
        for i in 0..<14 {
            var r = rng.fork(i)
            let a = r.float(0...(2 * .pi)), th = r.float(0.35...1.2)
            let p = V3(R3 * cos(th) * cos(a), b[2] + 0.011 + H3 * sin(th), -R3 * cos(th) * sin(a))
            let nrm = simd_normalize(V3(cos(th) * cos(a) / R3, sin(th) / H3, -cos(th) * sin(a) / R3))
            let d = simd_normalize(simd_cross(nrm, V3(r.float(-1...1), r.float(-1...1), r.float(-1...1))))
            let c = p + nrm * 0.0004
            let path = [c - d * 0.0030, c - d * 0.0015 + nrm * 0.0002, c + d * 0.0015 + nrm * 0.0002, c + d * 0.0030]
            m.add(FoodMesh.tube(path, radii: [0.0007, 0.0008, 0.0008, 0.0007], sides: 6, endBulge: 0.9, seamTile: 0.005,
                                material: sprinkleColors[i % sprinkleColors.count]))
        }

        // Twisted chocolate flake pushed into the top scoop.
        var flake = FoodMesh.box(V3(0.013, 0.062, 0.0035), radius: 0.0012, edge: 0.006, bevelSegments: 1, material: chocolate)
        let tilt: Float = 0.32
        flake.deform { p in
            let t = (p.y + 0.031) / 0.062
            let tw = t * 1.5
            let x = p.x * cos(tw) - p.z * sin(tw), z = p.x * sin(tw) + p.z * cos(tw)
            let wob = 0.0007 * sin(t * 18) * (x > 0 ? 1 : -1)
            let q = V3(x, p.y + wob, z)
            return V3(q.x + sin(tilt) * (q.y + 0.031) * 0.9 + 0.008, cos(tilt) * (q.y + 0.031) + 0.165, q.z - 0.004)
        }
        m.add(flake)

        groundAO(&m, height: 0.02, floor: 0.7)
        return LODModel(m)
    }
}
