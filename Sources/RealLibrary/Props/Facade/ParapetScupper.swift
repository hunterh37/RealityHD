import simd
import Foundation

/// Parapet scupper: architectural facade customizer, Commercial, through-wall parapet scupper with sheet metal liner, flange, spout and membrane flashing. Parts: stucco parapet wall, sheet metal scupper liner, back flange, projecting spout, drip edge, solder seams, fasteners, membrane base.
public struct ParapetScupper: RealAsset {
    public static let id = "parapet-scupper"
    public static let summary = "Parapet scupper, 0.5 x 0.25 x 0.3 m: through-wall metal liner with flange and spout."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Opening width in meters.
    public var opening: Float = 0.24
    /// Liner paint material key.
    public var paint: MaterialKey = "metal.painted:8A8D8E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let inner: MaterialKey = "metal.galvanized-aged", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime", sol: MaterialKey = "metal.solder"
        let liner: MaterialKey = "metal.galvanized", wall: MaterialKey = "stone.limestone-sooted", mem: MaterialKey = "asphalt.worn"
        let ow = opening / 2, y0: Float = 0.03, y1: Float = 0.13, wb: Float = -0.06, wf: Float = 0.04, t: Float = 0.002
        // Roof membrane, cant strip and upturned flashing on the roof side of the wall.
        FA.box(&m, V3(0.5, 0.012, 0.09), V3(0, 0.006, -0.105), mem, r: 0.003)
        FA.box(&m, V3(0.5, 0.012, 0.012), V3(0, 0.018, -0.066), mem, r: 0.004, rot: FA.q(45, FA.X))
        FA.box(&m, V3(0.46, 0.1, 0.004), V3(0, 0.06, -0.0635), mem, r: 0.0015)
        FA.box(&m, V3(0.46, 0.006, 0.01), V3(0, 0.112, -0.0645), inner, r: 0.0015)
        // Membrane details: termination bar screws, vertical lap seams with heat-welded edges, a patch, pooled grime at the cant.
        for k in 0..<9 { FA.cylZ(&m, r: 0.0034, h: 0.002, at: V3(-0.22 + Float(k) * 0.055, 0.112, wb - 0.0066), (k * 5) % 11 == 0 ? rust : zinc, bevel: 0.0007, segments: 6) }
        for x in [-0.15, 0.17] as [Float] {
            FA.box(&m, V3(0.006, 0.098, 0.0016), V3(x, 0.06, wb - 0.0058), mem, r: 0.0006)
            FA.box(&m, V3(0.0015, 0.098, 0.0018), V3(x + 0.0045, 0.06, wb - 0.0058), "metal.solder", r: 0.0005)
        }
        FA.box(&m, V3(0.07, 0.05, 0.0014), V3(-0.19, 0.045, wb - 0.0055), mem, r: 0.0005)
        FA.box(&m, V3(0.5, 0.0016, 0.03), V3(0, 0.0128, -0.12), rust, r: 0.0004)
        for _ in 0..<4 { FA.box(&m, V3(rng.float(0.006...0.012), rng.float(0.03...0.07), 0.0006), V3(rng.float(-0.23...0.23), 0.085, wf + 0.0004), "stone.limestone", r: 0.0002) }
        // Stucco/limestone parapet wall with the opening cut as four blocks, mortar reveals and coping.
        let wd = wf - wb, wz = (wf + wb) / 2
        FA.box(&m, V3(0.25 - ow, 0.25 - 0.012, wd), V3(-(0.25 + ow) / 2, 0.012 + (0.238 - 0.012) / 2 - 0.0, wz), wall, r: 0.002)
        FA.box(&m, V3(0.25 - ow, 0.238, wd), V3((0.25 + ow) / 2, 0.119, wz), wall, r: 0.002)
        FA.box(&m, V3(2 * ow, y0 - 0.0, wd), V3(0, y0 / 2, wz), wall, r: 0.002)
        FA.box(&m, V3(2 * ow, 0.238 - y1, wd), V3(0, (0.238 + y1) / 2, wz), wall, r: 0.002)
        FA.box(&m, V3(0.51, 0.012, wd + 0.02), V3(0, 0.244, wz), paint, r: 0.002)
        FA.box(&m, V3(0.51, 0.006, 0.004), V3(0, 0.236, wf + 0.01), paint, r: 0.001)
        for y in [0.085, 0.165, 0.22] as [Float] { FA.box(&m, V3(0.5, 0.0035, 0.0015), V3(0, y, wf + 0.0002), mem, r: 0.0005) }
        for (i, y) in ([0.0425, 0.125, 0.1925] as [Float]).enumerated() {
            let off: Float = i % 2 == 0 ? 0 : 0.07
            for k in -3...3 { let x = Float(k) * 0.14 + off; if abs(x) < 0.245, abs(x) > ow + 0.01 || y < 0.03 { FA.box(&m, V3(0.0035, 0.07, 0.0015), V3(x, y, wf + 0.0002), mem, r: 0.0005) } }
        }
        // Liner: floor, sides, top; spout projects to z = 0.15 with a drip hem.
        let zb: Float = -0.1, zf: Float = 0.15, zl = (zb + zf) / 2, ln = zf - zb
        FA.box(&m, V3(2 * ow + 0.01, t, ln), V3(0, y0 + t / 2, zl), liner, r: 0.0006)
        FA.box(&m, V3(2 * ow - 0.02, 0.0012, ln - 0.004), V3(0, y0 + t + 0.0006, zl), inner, r: 0.0004)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(t, y1 - y0, zf - wb + 0.04), V3(s * (ow + 0.001), (y0 + y1) / 2, (zf + wb - 0.04) / 2 ), liner, r: 0.0006)
            FA.box(&m, V3(0.0008, y1 - y0 - 0.014, zf - wb + 0.03), V3(s * (ow - 0.0006), (y0 + y1) / 2, (zf + wb - 0.03) / 2), inner, r: 0.0003)
            FA.box(&m, V3(0.004, 0.012, 0.006), V3(s * (ow + 0.003), y1 - 0.004, zf - 0.003), liner, r: 0.001) // hemmed return
        }
        FA.box(&m, V3(2 * ow + 0.01, t, zf - wb + 0.04), V3(0, y1 + t / 2, (zf + wb - 0.04) / 2), liner, r: 0.0006)
        FA.box(&m, V3(2 * ow + 0.01, 0.014, 0.003), V3(0, y0 - 0.006, zf - 0.001), liner, r: 0.0008) // drip hem under the spout
        FA.box(&m, V3(2 * ow + 0.012, 0.004, 0.005), V3(0, y1 + 0.004, zf - 0.0025), liner, r: 0.001)
        // Solder along the corner seams and a lap joint on the apron.
        for s: Float in [-1, 1] {
            FA.rod(&m, V3(s * (ow - 0.001), y0 + 0.004, wb - 0.03), V3(s * (ow - 0.001), y0 + 0.004, zf - 0.006), r: 0.0017, sol, sides: 6)
            FA.rod(&m, V3(s * (ow - 0.001), y1 - 0.004, wb - 0.0), V3(s * (ow - 0.001), y1 - 0.004, zf - 0.006), r: 0.0017, sol, sides: 6)
        }
        FA.box(&m, V3(2 * ow, 0.0012, 0.03), V3(0, y0 + t + 0.0012, -0.075), inner, r: 0.0004)
        FA.rod(&m, V3(-ow, y0 + t + 0.002, -0.06), V3(ow, y0 + t + 0.002, -0.06), r: 0.0014, sol, sides: 6)
        // Back and front flanges (frames around the opening) with screw rows.
        for (z, th, w) in [(wb - 0.0030 - 0.0, 0.003, 0.02), (wf + 0.0015, 0.003, 0.018)] as [(Float, Float, Float)] {
            let hx = ow + 0.012 + w / 2, ym = (y0 + y1) / 2
            for s: Float in [-1, 1] { FA.box(&m, V3(w, y1 - y0 + 0.024 + 2 * w, th), V3(s * hx, ym, z), z < 0 ? inner : paint, r: 0.0008) }
            for s: Float in [-1, 1] { FA.box(&m, V3(2 * (ow + 0.012), w, th), V3(0, ym + s * ((y1 - y0) / 2 + 0.012 + w / 2), z), z < 0 ? inner : paint, r: 0.0008) }
            for s: Float in [-1, 1] {
                for k in 0..<5 {
                    let y = y0 - 0.012 + Float(k) * (y1 - y0 + 0.024) / 4
                    FA.cylZ(&m, r: 0.0036, h: 0.0022, at: V3(s * hx, y, z + (z < 0 ? -0.0022 : th)), (k + Int(s) + 7) % 6 == 0 ? rust : zinc, bevel: 0.0007, segments: 6)
                }
                for k in 0..<4 {
                    let x = -ow + Float(k) * 2 * ow / 3
                    FA.cylZ(&m, r: 0.0036, h: 0.0022, at: V3(x, ym + s * ((y1 - y0) / 2 + 0.012 + w / 2), z + (z < 0 ? -0.0022 : th)), zinc, bevel: 0.0007, segments: 6)
                }
            }
        }
        // Sealant bead around the front flange, stain runs below the spout, debris in the channel.
        for s: Float in [-1, 1] { FA.rod(&m, V3(s * (ow + 0.034), y0 - 0.022, wf + 0.0045), V3(s * (ow + 0.034), y1 + 0.022, wf + 0.0045), r: 0.0012, "metal.solder", sides: 6) }
        for _ in 0..<5 {
            let x = rng.float(-ow...ow), l = rng.float(0.01...0.024)
            FA.box(&m, V3(rng.float(0.006...0.016), l, 0.0006), V3(x, y0 - 0.002 - l / 2, wf + 0.0004), rust, r: 0.0002)
        }
        FA.box(&m, V3(0.1, 0.0006, 0.1), V3(0.03, y0 + t + 0.0016, 0.095), rust, r: 0.0002)
        for i in 0..<4 {
            m.add(Prim.superellipsoid(V3(rng.float(0.008...0.02), 0.004, rng.float(0.006...0.014)), exponent: 2, subdivisions: 4, material: i % 3 == 0 ? "metal.rust" : "wood.weathered"),
                  Xform(translation: V3(rng.float(-ow + 0.02...ow - 0.02), y0 + t + 0.0025, rng.float(-0.095...0.0)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        m = FA.centerZ(m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
