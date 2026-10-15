import simd
import Foundation

/// Cast iron radiator: Old white enamel radiator, chipped paint at the legs and header edges.. Parts: 13 cast-iron column sections, three tubes each, top and bottom header collars with joint rings, two cast end legs, brass angle valve with handwheel and floor pipe, chrome floor escutcheon, bleed valve plug at the top right, blind plug at the lower right.
public struct Radiator: RealAsset {
    public static let id = "radiator"
    public static let summary = "Cast-iron column radiator: 13 three-column sections with header collars, end legs, brass supply valve with floor pipe and a bleed plug."
    public static let tags = ["prop", "floorplan", "home", "hvac", "metal", "interior"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.8, 0.65, 0.2)
    /// Number of cast sections.
    public var sections = 13
    /// Enamel color.
    public var enamelColor: UInt32 = 0xE9E7DF
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    private func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let enamel = String(format: "metal.enamel:%06X", enamelColor)
        let pitch: Float = 0.057
        let D = size.z
        func along(_ dir: V3) -> simd_quatf { simd_quatf(from: V3(0, 1, 0), to: dir.normalized) }
        func cyl(_ r: Float, _ h: Float, _ mat: MaterialKey, at: V3, dir: V3 = V3(0, 1, 0), seg: Int = 14, bevel: Float = 0.001) {
            m.add(Prim.cylinder(radius: r, height: h, bevel: bevel, segments: lite ? max(6, seg / 2) : seg, bevelSegments: 1, material: mat), Xform(translation: at, rotation: along(dir)))
        }
        func hexNut(_ at: V3, r: Float, h: Float, mat: MaterialKey, dir: V3) {
            let hex = Shape2D.rounded(Shape2D.polygon(sides: 6, radius: r), radius: r * 0.08, segments: 1)
            m.add(Prim.extrude(hex, depth: h, bevel: 0.0007, bevelSegments: 1, material: mat), Xform(translation: at, rotation: simd_quatf(from: V3(0, 0, 1), to: dir)))
        }
        func ellipse(_ rx: Float, _ rz: Float, n: Int) -> [V2] {
            (0..<n).map { k in let t = Float(k) / Float(n) * 2 * .pi; return V2(rx * cos(t), rz * sin(t)) }
        }
        func rrect(_ w: Float, _ d: Float, r: Float, n: Int) -> [V2] {
            // Rounded rectangle, CCW, n points per corner pair.
            var pts: [V2] = []
            let per = max(2, n / 4)
            let cs: [(Float, Float, Float)] = [(w / 2 - r, d / 2 - r, 0), (-(w / 2 - r), d / 2 - r, .pi / 2), (-(w / 2 - r), -(d / 2 - r), .pi), (w / 2 - r, -(d / 2 - r), 3 * .pi / 2)]
            for (cx, cy, a0) in cs { for k in 0..<per { let t = a0 + Float(k) / Float(per - 1) * (.pi / 2); pts.append(V2(cx + r * cos(t), cy + r * sin(t))) } }
            return pts
        }
        let yBot0: Float = 0.06, yBot1: Float = 0.135, yTop0: Float = 0.565, yTop1: Float = 0.65
        let n = sections
        let x0 = -Float(n - 1) / 2 * pitch
        for i in 0..<n {
            let cx = x0 + Float(i) * pitch
            let off = V3(cx, 0, 0)
            // Header collars (bottom and top) as lofted rounded blocks with a joint ring.
            let hw: Float = 0.049, hd: Float = D - 0.002
            let hp = lite ? 8 : 12
            var rBot: [(Float, Float)] = [(yBot0, 0.9), (yBot0 + 0.006, 1.0), (yBot1 - 0.012, 1.0), (yBot1 - 0.004, 0.93), (yBot1, 0.8)]
            if lite { rBot = [(yBot0, 0.9), (yBot0 + 0.006, 1.0), (yBot1 - 0.008, 0.9), (yBot1, 0.8)] }
            m.add(Prim.loft(rBot.map { Prim.ring(rrect(hw * $0.1, hd * $0.1, r: 0.02, n: hp), y: $0.0, offset: off) }, capStart: true, capEnd: true, material: enamel))
            var rTop: [(Float, Float)] = [(yTop0, 0.8), (yTop0 + 0.004, 0.93), (yTop0 + 0.012, 1.0), (yTop1 - 0.006, 1.0), (yTop1, 0.9)]
            if lite { rTop = [(yTop0, 0.8), (yTop0 + 0.01, 1.0), (yTop1 - 0.006, 1.0), (yTop1, 0.9)] }
            m.add(Prim.loft(rTop.map { Prim.ring(rrect(hw * $0.1, hd * $0.1, r: 0.02, n: hp), y: $0.0, offset: off) }, capStart: true, capEnd: true, material: enamel))
            // Three tubes with a slight belly.
            for tz in [Float(-0.062), 0, 0.062] {
                let tp = lite ? 6 : 10
                var rings: [(Float, Float)] = [(yBot1 - 0.003, 0.92), (0.25, 1.0), (0.35, 1.04), (0.45, 1.0), (yTop0 + 0.003, 0.92)]
                if lite { rings = [(yBot1 - 0.003, 0.92), (0.35, 1.04), (yTop0 + 0.003, 0.92)] }
                m.add(Prim.loft(rings.map { Prim.ring(ellipse(0.0205 * $0.1, 0.0235 * $0.1, n: tp), y: $0.0, offset: off + V3(0, 0, tz)) }, material: enamel))
            }
        }
        // Legs: two cast feet under the end headers.
        for sx in [Float(-1), 1] {
            let lx = sx * (-x0)
            m.add(Prim.roundedBox(V3(0.05, 0.062, 0.12), radius: 0.008, bevelSegments: 1, material: enamel), Xform(translation: V3(lx, 0.031, 0)))
            m.add(Prim.roundedBox(V3(0.062, 0.012, 0.14), radius: 0.004, bevelSegments: 1, material: "metal.cast-iron-worn"), Xform(translation: V3(lx, 0.006, 0)))
        }
        // Brass angle valve at the left end, bottom, with floor pipe and escutcheon.
        let vx = x0 - 0.0205
        let vy: Float = 0.098
        cyl(0.011, 0.012, "metal.brass-aged", at: V3(vx, vy, 0), dir: V3(-1, 0, 0), seg: 12)
        hexNut(V3(vx - 0.01, vy, 0), r: 0.0145, h: 0.01, mat: "metal.brass-aged", dir: V3(-1, 0, 0))
        m.add(Prim.roundedBox(V3(0.022, 0.03, 0.03), radius: 0.007, bevelSegments: 1, material: "metal.brass-aged"), Xform(translation: V3(vx - 0.025, vy, 0)))
        cyl(0.012, 0.03, "metal.brass-aged", at: V3(vx - 0.025, vy + 0.01, 0), seg: 12)
        cyl(0.004, 0.026, "metal.brass-aged", at: V3(vx - 0.025, vy + 0.038, 0), seg: 8)
        m.add(Prim.torus(major: 0.0135, minor: 0.0035, segments: lite ? 10 : 16, sides: 6, material: "plastic.black"), Xform(translation: V3(vx - 0.025, vy + 0.058, 0)))
        // Floor pipe (chrome-plated) with escutcheon cups.
        cyl(0.0095, vy - 0.016, "metal.chrome", at: V3(vx - 0.025, 0, 0), seg: 12)
        cyl(0.0195, 0.014, "metal.chrome", at: V3(vx - 0.025, 0, 0), seg: 16)
        // Right end: bleed valve at the top, blind plug at the bottom.
        let rx = -x0 + 0.0205
        cyl(0.009, 0.014, "metal.brass-aged", at: V3(rx, 0.605, 0), dir: V3(1, 0, 0), seg: 12)
        cyl(0.0045, 0.012, "metal.brass-aged", at: V3(rx + 0.014, 0.605, 0), dir: V3(1, 0, 0), seg: 8)
        hexNut(V3(rx, 0.098, 0), r: 0.0155, h: 0.012, mat: "metal.cast-iron-worn", dir: V3(1, 0, 0))
        // Top grille bar (short stamped lid), rivet-like nuts on the headers.
        _ = rng.float()
        groundAO(&m, height: 0.14, floor: 0.6)
        return m
    }
}
