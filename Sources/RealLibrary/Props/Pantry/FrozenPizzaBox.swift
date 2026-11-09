import simd
import Foundation

/// Frozen pizza carton, 32 cm square and 3.2 cm deep: printed coated board with a pizza photo on the top
/// panel, printed side bands, raised tuck flaps on the ends, a perforated tear strip with a pull tab on the
/// front, a crushed front corner, frost flecks and the invented brand FORNO.
public struct FrozenPizzaBox: RealAsset {
    public static let id = "frozen-pizza-box"
    public static let summary = "Printed frozen pizza carton, 32 cm: pizza photo, printed sides, tear strip, tuck flaps, crushed corner, frost."
    public static let tags = ["prop", "interior", "pantry", "paper", "container", "food"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: -32, elevation: 40, distance: 1.3, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.32, 0.032, 0.32)
    /// Brand field color.
    public var color: UInt32 = 0xB71C1C
    public var brand = "FORNO"
    public var frost: MaterialKey = "plastic.white:E4ECF0"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true, seed: seed), level(hi: false, seed: seed)], switchDistances: [3])
    }

    /// Crushed front right corner: pushes geometry down and in.
    func crush(_ p: V3) -> V3 {
        let c = V3(size.x / 2, size.y, size.z / 2)
        let d = simd_length(V2(p.x - c.x, p.z - c.z))
        guard d < 0.05 else { return p }
        let k = pow(1 - d / 0.05, 2)
        return V3(p.x - 0.002 * k, p.y - 0.007 * k * (p.y / size.y), p.z - 0.002 * k)
    }

    func level(hi: Bool, seed: UInt64) -> Model {
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, h = size.y
        let print = GroceryKit.tint("pkg.carton-gloss", color)
        func add(_ s: Surface) { var s = s; s.deform { self.crush($0) }; s.recomputeNormals(); s.computeTangents(); m.add(s) }
        var body = Prim.roundedBox(size, radius: 0.0022, bevelSegments: 2, material: GroceryKit.tint("paper.sheet", color))
        body = body.transformed(Xform(translation: V3(0, h / 2, 0)))
        add(body)
        let gs = hi ? 8 : 4
        // Top panel: design crop with the logo pill at the back right.
        let tw = size.x - 0.005
        add(GroceryKit.sheet(cols: gs, rows: gs, print, crop: (0, 1, 0.3, 0.98)) { u, v in V3((u - 0.5) * tw, h + 0.0004, (0.5 - v) * tw) })
        // Side bands: the swoosh strip of the design.
        for k in 0..<4 {
            let rot = simd_quatf(angle: Float(k) * .pi / 2, axis: .up)
            let s = GroceryKit.sheet(cols: gs, rows: 1, print, crop: (0, 1, 0.34, 0.405)) { u, v in
                V3((u - 0.5) * tw, 0.002 + v * (h - 0.004), hz + 0.0004) }
            add(s.transformed(Xform(rotation: rot)))
        }
        // Tuck flaps on the ends.
        for sx: Float in [1, -1] {
            let flap = Prim.roundedBox(V3(0.0008, h - 0.008, size.z - 0.03), radius: 0.0003, bevelSegments: 1, material: GroceryKit.tint("paper.sheet", GroceryKit.shade(color, 0.85)))
            add(flap.transformed(Xform(translation: V3(sx * (hx + 0.0008), h / 2, 0))))
        }
        // Pizza photo printed on the top: crust, cheese, pepperoni, basil.
        let pc = V3(-0.057, h + 0.0006, 0.005)
        func disc(_ r: Float, _ y: Float, _ key: MaterialKey, _ c: V3, segs: Int) {
            var d = Prim.lathe([V2(r, y), V2(0.0001, y)], segments: segs, seamTile: 0.05, material: key).transformed(Xform(translation: c))
            d.uvs = d.positions.map { V2($0.x, $0.z) }
            add(d)
        }
        disc(0.112, 0.0003, "food.bun-crust", pc, segs: hi ? 40 : 16)
        disc(0.096, 0.0005, "food.mozzarella-melted", pc, segs: hi ? 40 : 16)
        var rng = SeededRNG(seed: seed &+ 12)
        for i in 0..<(hi ? 11 : 6) {
            let a = Float(i) * 2.4 + rng.float(-0.2...0.2), rr = 0.025 + 0.06 * sqrt(Float(i) / 11)
            disc(0.0125, 0.0007, "food.beef-seared:8A1E14", pc + V3(rr * cos(a), 0, rr * sin(a)), segs: hi ? 10 : 6)
        }
        if hi {
            for i in 0..<6 {
                let a = Float(i) * 1.1 + 0.4, rr: Float = 0.05
                add(Prim.superellipsoid(V3(0.012, 0.0004, 0.006), exponent: 2, subdivisions: 2, material: "food.lettuce-leaf:2F6E2A")
                    .transformed(Xform(translation: pc + V3(rr * cos(a), 0.0005, rr * sin(a)), rotation: simd_quatf(angle: a, axis: .up))))
            }
        }
        // Wordmarks: brand in the pill, product line under the photo.
        let up = simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))
        GroceryKit.printSmooth(&m, brand, height: 0.03, at: V3(0.063, h + 0.0009, -0.088), "plastic.gloss:FFFFFF", rot: up, maxWidth: 0.12, weight: 1.35)
        GroceryKit.printSmooth(&m, "PEPPERONI", height: 0.014, at: V3(-0.057, h + 0.0009, 0.142), "plastic.gloss:F2C230", rot: up, maxWidth: 0.15, weight: 1.3)
        GroceryKit.printSmooth(&m, "STONE BAKED", height: 0.008, at: V3(0.075, h + 0.0009, -0.06), "plastic.gloss:FFFFFF", rot: up, maxWidth: 0.08, weight: 1)
        // Tear strip: two perforation rows and a pull tab on the front.
        if hi {
            var perf = Surface(material: "plastic.matte:3A1010")
            var x = -hx + 0.02
            let nz = V3(0, 0, 1)
            while x < hx - 0.06 {
                for y: Float in [0.011, 0.022] {
                    let a = perf.add(V3(x, y - 0.0003, hz + 0.0007), nz, V2(x, y)), b = perf.add(V3(x + 0.0028, y - 0.0003, hz + 0.0007), nz, V2(x + 0.0028, y))
                    let c = perf.add(V3(x + 0.0028, y + 0.0003, hz + 0.0007), nz, V2(x + 0.0028, y + 0.0006)), d = perf.add(V3(x, y + 0.0003, hz + 0.0007), nz, V2(x, y + 0.0006))
                    perf.quad(a, b, c, d)
                }
                x += 0.0055
            }
            add(perf)
            GroceryKit.printSmooth(&m, "PULL", height: 0.006, at: V3(-hx + 0.012, 0.0135, hz + 0.0009), "plastic.gloss:FFFFFF", maxWidth: 0.02, weight: 1)
        }
        // Frost flecks in two drifts on the top.
        if hi {
            let fleck = Prim.superellipsoid(V3(1, 0.25, 1), exponent: 2, subdivisions: 1, material: frost)
            var fr = Surface(material: frost)
            for (cx, cz, n) in [(Float(0.11), Float(0.12), 70), (-0.13, -0.11, 45)] {
                for _ in 0..<n {
                    let a = rng.float(0...6.28), rr = 0.035 * sqrt(rng.float(0...1)), s = rng.float(0.0012...0.003)
                    fr.append(fleck, Xform(translation: V3(cx + rr * cos(a), h + 0.0012, cz + rr * sin(a)), scale: V3(s, s, s)))
                }
            }
            fr.uvs = fr.positions.map { V2($0.x, $0.z) }
            add(fr)
        }
        return m
    }
}
