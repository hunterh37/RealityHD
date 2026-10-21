import simd
import Foundation

/// Plastic laundry basket: Pale blue household basket, light scuffing near the feet.. Parts: tapered rectangular HDPE tub with rolled rim, ventilation slots between vertical ribs on all four walls, molded hand grips at each end, bottom pan with four feet, corner posts, folded towels and a shirt inside.
public struct LaundryBasket: RealAsset {
    public static let id = "laundry-basket"
    public static let summary = "Ventilated rectangular laundry basket: tapered ribbed walls, rolled rim, end hand grips and feet, with folded towels inside."
    public static let tags = ["prop", "floorplan", "laundry", "plastic", "container", "interior"]
    public static let budget = 11000
    public static let author = "realityhd"

    /// Overall size in meters (x length including grips, y height, z width).
    public var size = V3(0.6, 0.27, 0.42)
    /// Plastic color.
    public var plasticColor: UInt32 = 0x86B4D2
    /// Vertical ribs along each long wall.
    public var ribs = 12
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    private func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pl = String(format: "plastic.bucket:%06X", plasticColor)
        let H = size.y
        let gripOut: Float = 0.03
        let Lt = size.x - 2 * gripOut + 0.010, Wt = size.z + 0.006          // outer rim size at the top
        let Lb: Float = 0.46, Wb: Float = 0.30              // outer size at the bottom pan
        func plan(_ y: Float) -> (Float, Float) {
            let t = y / H
            return (Lb + (Lt - Lb) * t, Wb + (Wt - Wb) * t)
        }
        func rrPath(_ L: Float, _ W: Float, _ y: Float, r: Float, n: Int) -> [V3] {
            var pts: [V3] = []
            let cs: [(Float, Float, Float)] = [(L / 2 - r, W / 2 - r, 0), (-(L / 2 - r), W / 2 - r, .pi / 2), (-(L / 2 - r), -(W / 2 - r), .pi), (L / 2 - r, -(W / 2 - r), 3 * .pi / 2)]
            for (cx, cz, a0) in cs { for k in 0...n { let t = a0 + Float(k) / Float(n) * (.pi / 2); pts.append(V3(cx + r * cos(t), y, cz + r * sin(t))) } }
            pts.append(pts[0])
            return pts
        }
        func rib(from a: V3, to b: V3, width: Float, thick: Float, endWall: Bool = false) {
            let mid = (a + b) / 2
            let dir = b - a
            let len = simd_length(dir)
            let u = dir / len
            let w: V3 = endWall ? V3(0, 0, 1) : V3(1, 0, 0)
            if lite {
                let sz = endWall ? V3(thick, len, width) : V3(width, len, thick)
                m.add(cuboid(sz, material: pl), Xform(translation: mid, rotation: simd_quatf(from: V3(0, 1, 0), to: u)))
                return
            }
            let n = simd_normalize(simd_cross(u, w))
            let q = simd_quatf(simd_float3x3(columns: (w, n, u)))
            m.add(Prim.extrude(Shape2D.roundedRect(width, thick, radius: 0.0016, segments: 1), depth: len, bevel: 0.0012, bevelSegments: 1, material: pl),
                  Xform(translation: mid, rotation: q))
        }
        // Bottom pan and feet.
        do {
            let outline = Shape2D.rounded([V2(-Lb / 2, -Wb / 2), V2(Lb / 2, -Wb / 2), V2(Lb / 2, Wb / 2), V2(-Lb / 2, Wb / 2)], radius: 0.04, segments: lite ? 2 : 4)
            m.add(Prim.extrude(outline, depth: 0.006, bevel: 0.0015, bevelSegments: 1, material: pl), Xform(translation: V3(0, 0.012, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            for sx in [Float(-1), 1] { for sz in [Float(-1), 1] {
                m.add(Prim.roundedBox(V3(0.07, 0.012, 0.05), radius: 0.004, bevelSegments: 1, material: "rubber.tire"), Xform(translation: V3(sx * (Lb / 2 - 0.05), 0.006, sz * (Wb / 2 - 0.045))))
            } }
        }
        // Rim and bottom band: swept rounded-rectangle bands.
        let rimY: Float = H - 0.019
        let (Lr, Wr) = plan(rimY)
        let rimPath = rrPath(Lr - 0.01, Wr - 0.01, rimY, r: 0.04, n: lite ? 2 : 4)
        m.add(Prim.sweep(Shape2D.roundedRect(0.034, 0.012, radius: 0.004, segments: 2), along: rimPath, up: V3(0, 1, 0), closedPath: true, caps: false, material: pl))
        let botY: Float = 0.035
        let (Lq, Wq) = plan(botY)
        m.add(Prim.sweep(Shape2D.roundedRect(0.044, 0.008, radius: 0.0025, segments: 1), along: rrPath(Lq - 0.004, Wq - 0.004, botY, r: 0.035, n: lite ? 2 : 4), up: V3(0, 1, 0), closedPath: true, caps: false, material: pl))
        // Mid stiffener band.
        let midY: Float = 0.14
        let (Lm, Wm) = plan(midY)
        m.add(Prim.sweep(Shape2D.roundedRect(0.01, 0.006, radius: 0.002, segments: 1), along: rrPath(Lm - 0.004, Wm - 0.004, midY, r: 0.035, n: lite ? 2 : 4), up: V3(0, 1, 0), closedPath: true, caps: false, material: pl))
        // Corner posts.
        for sx in [Float(-1), 1] { for sz in [Float(-1), 1] {
            let (L0, W0) = plan(0.03), (L1, W1) = plan(H - 0.03)
            let a = V3(sx * (L0 / 2 - 0.016), 0.03, sz * (W0 / 2 - 0.016))
            let b = V3(sx * (L1 / 2 - 0.016), H - 0.03, sz * (W1 / 2 - 0.016))
            m.add(Prim.tube([a, b], radii: [0.0085, 0.0085], sides: lite ? 6 : 8, seamTile: 0.05, material: pl, capEnd: true))
        } }
        // Ribs: two slot rows on each long wall, one row on each short wall.
        let rows: [(Float, Float)] = [(0.057, 0.133), (0.147, 0.222)]
        let nr = lite ? 6 : ribs
        for (y0, y1) in rows {
            for sz in [Float(-1), 1] {
                for k in 0..<nr {
                    let t = (Float(k) + 0.5) / Float(nr)
                    func pos(_ y: Float) -> V3 { let (L, W) = plan(y); return V3((t - 0.5) * (L - 0.07), y, sz * (W / 2 - 0.002)) }
                    rib(from: pos(y0), to: pos(y1), width: 0.012, thick: 0.004)
                }
            }
        }
        // Short walls: ribs with a hand-grip opening in the center of the upper row.
        for sx in [Float(-1), 1] {
            let nsr = lite ? 3 : 6
            for (rowIdx, (y0, y1)) in rows.enumerated() {
                for k in 0..<nsr {
                    let t = (Float(k) + 0.5) / Float(nsr)
                    func pos(_ y: Float) -> V3 { let (L, W) = plan(y); return V3(sx * (L / 2 - 0.002), y, (t - 0.5) * (W - 0.07)) }
                    if rowIdx == 1 && abs(t - 0.5) < 0.2 { continue }
                    rib(from: pos(y0), to: pos(y1), width: 0.014, thick: 0.004, endWall: true)
                }
            }
            // Grip: bar across the opening and the molded grip loop outside.
            let (Lg, Wg) = plan(0.2)
            m.add(Prim.roundedBox(V3(0.012, 0.016, 0.15), radius: 0.005, bevelSegments: 2, material: pl),
                  Xform(translation: V3(sx * (size.x / 2 - 0.006), 0.205, 0)))
            for sz in [Float(-1), 1] {
                m.add(Prim.tube([V3(sx * (Lg / 2 - 0.004), 0.205, sz * 0.075), V3(sx * (size.x / 2 - 0.006), 0.205, sz * 0.075)], radii: [0.008, 0.008], sides: lite ? 6 : 8, seamTile: 0.05, material: pl, capEnd: true))
            }
            _ = Wg
        }
        // Folded towels and a shirt inside.
        if true {
            let tints: [MaterialKey] = ["fabric.linen:E4DCCB", "fabric.linen:8CA9BF", "fabric.linen:E4DCCB", "fabric.canvas:C98F86"]
            for (k, mat) in tints.enumerated() {
                let jx = rng.float(-0.008...0.008), jz = rng.float(-0.006...0.006)
                m.add(Prim.roundedBox(V3(0.34 - Float(k) * 0.004, 0.044, 0.22), radius: 0.012, bevelSegments: lite ? 1 : 2, material: mat),
                      Xform(translation: V3(-0.06 + jx, 0.038 + Float(k) * 0.045, jz), rotation: simd_quatf(degrees: rng.float(-4...4), axis: V3(0, 1, 0))))
            }
            m.add(Prim.superellipsoid(V3(0.22, 0.05, 0.16), exponent: 3, subdivisions: lite ? 5 : 8, material: "fabric.linen:8CA9BF"),
                  Xform(translation: V3(0.12, 0.2, 0.01), rotation: simd_quatf(degrees: 15, axis: V3(0, 1, 0))))
        }
        // Stains and a dark rim smudge: story wear on the towels.
        if !lite {
            m.add(Prim.superellipsoid(V3(0.07, 0.003, 0.04), exponent: 2.5, subdivisions: 6, material: "fabric.canvas:9C5E58"),
                  Xform(translation: V3(-0.1, 0.2175, -0.04), rotation: simd_quatf(degrees: 20, axis: V3(0, 1, 0))))
            m.add(Prim.superellipsoid(V3(0.04, 0.003, 0.03), exponent: 2.5, subdivisions: 6, material: "fabric.canvas:7A4B46"),
                  Xform(translation: V3(-0.02, 0.2175, 0.05), rotation: simd_quatf(degrees: -35, axis: V3(0, 1, 0))))
        }
        groundAO(&m, height: 0.1, floor: 0.7)
        return m
    }
}
