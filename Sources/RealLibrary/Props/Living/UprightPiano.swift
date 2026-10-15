import simd
import Foundation

/// Upright piano, 150 x 120 x 65 cm: polished black case with a lid and flush top door, two end panels with key cheeks, an
/// open 88-key keyboard (52 white keys at 23.5 mm pitch, 36 black), key slip and name board with a brass maker's plate,
/// a raised music desk with two pages of score and a pencil on the ledge, a lower panel over three brass pedals, toe blocks
/// and four brass casters. Front toward +Z, back flat for standing against a wall.
public struct UprightPiano: RealAsset {
    public static let id = "upright-piano"
    public static let summary = "Upright piano, 88 keys: polished black case, open keyboard, music desk with score, brass pedals and casters."
    public static let tags = ["prop", "floorplan", "living", "wood", "metal", "plastic", "interior"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 16, distance: 3.2, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.5, 1.2, 0.65)
    /// Polished case finish.
    public var case_: MaterialKey = "plastic.gloss:0B0B0D"
    /// Satin interior black.
    public var satin: MaterialKey = "plastic.matte:0E0E10"
    /// Brass hardware.
    public var brass: MaterialKey = "metal.brass"
    public init() {}

    private func box(_ m: inout Model, _ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.004, seg: Int = 1) {
        m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: seg, material: key), Xform(translation: c))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = size.x / 2, hd = size.z / 2
        let zf = hd                                         // key slip front, z = +0.325
        let panelT: Float = 0.035
        let kbHalf: Float = 0.611                           // half keyboard width (52 x 23.5 mm)
        // Plinth: toe blocks under each end, a rear rail, and four casters.
        for s: Float in [-1, 1] {
            box(&m, V3(0.200, 0.072, 0.560), V3(s * (hw - 0.100 - 0.012), 0.045 + 0.036, -0.020), case_, r: 0.006)
        }
        box(&m, V3(size.x - 0.060, 0.072, 0.040), V3(0, 0.081, -hd + 0.060), satin, r: 0.004)
        for s: Float in [-1, 1] { for fz: Float in [-1, 1] {
            let cx = s * (hw - 0.100 - 0.012); let cz: Float = fz == 1 ? 0.185 : -0.225
            m.add(Prim.cylinder(radius: 0.030, height: 0.012, bevel: 0.003, segments: 14, bevelSegments: 1, material: brass), Xform(translation: V3(cx, 0.030, cz), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            box(&m, V3(0.040, 0.020, 0.040), V3(cx, 0.050, cz), brass, r: 0.005, seg: 1)
            m.add(Prim.cylinder(radius: 0.004, height: 0.014, bevel: 0.001, segments: 8, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(cx, 0.036, cz), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        } }
        // Satin core fills the case between the end panels (hidden action area, seen from the gap above the keys).
        box(&m, V3(size.x - 2 * panelT - 0.004, 1.057, 0.440), V3(0, 0.1175 + 0.5285, -0.105), satin, r: 0.002, seg: 1)
        // End panels, three parts each: lower (to the toe line), cheek block at keybed height, upper.
        for s: Float in [-1, 1] {
            let cx = s * (hw - panelT / 2)
            box(&m, V3(panelT, 0.505, 0.615), V3(cx, 0.115 + 0.2525, -0.0175), case_, r: 0.008, seg: 2)                  // lower: y .115 - .62
            let cheekW: Float = hw - kbHalf
            box(&m, V3(cheekW, 0.160, 0.170), V3(s * (hw - cheekW / 2), 0.620 + 0.080, zf - 0.085), case_, r: 0.012, seg: 2)    // cheek: y .62 - .78
            box(&m, V3(panelT, 0.405, 0.490), V3(cx, 0.780 + 0.2025 + 0.0, -0.080), case_, r: 0.008, seg: 2)               // upper: y .78 - 1.185
        }
        // Top door (flush front above the keys), name board, keybed, key slip, lower panel.
        box(&m, V3(size.x - 2 * panelT, 0.405, 0.026), V3(0, 0.765 + 0.2025 + 0.0, 0.153), case_, r: 0.004)
        box(&m, V3(2 * kbHalf + 0.004, 0.045, 0.030), V3(0, 0.757, 0.176), case_, r: 0.004)                       // name board
        box(&m, V3(2 * kbHalf + 0.002, 0.030, 0.170), V3(0, 0.640, 0.240), satin, r: 0.003, seg: 1)                // keybed
        box(&m, V3(2 * kbHalf + 0.020, 0.095, 0.022), V3(0, 0.6725, zf - 0.011), case_, r: 0.006, seg: 2)                   // key slip
        box(&m, V3(size.x - 2 * panelT, 0.520, 0.026), V3(0, 0.115 + 0.260, 0.178), case_, r: 0.004)                // lower panel
        // Lid: slab with a rounded front edge, slight overhang; brass piano hinges along the back.
        box(&m, V3(size.x + 0.010, 0.034, size.z + 0.008), V3(0, 1.1925 - 0.0100 + 0.0, 0.0), case_, r: 0.012, seg: 2)
        box(&m, V3(size.x - 0.008, 0.020, size.z - 0.050), V3(0, 1.168, -0.015), case_, r: 0.004, seg: 1)
        for hx: Float in [-0.45, 0, 0.45] { box(&m, V3(0.110, 0.0012, 0.022), V3(hx, 1.2092 - 0.0100, -hd + 0.020), brass, r: 0.0005, seg: 1) }
        // Brass maker's plate on the name board and a small brand-line below it.
        box(&m, V3(0.150, 0.016, 0.0016), V3(0, 0.758, 0.1925), brass, r: 0.0005, seg: 1)
        box(&m, V3(0.110, 0.0025, 0.0006), V3(0, 0.758, 0.1938), "metal.brass-aged", r: 0.0003, seg: 1)
        // Red baize strip along the back of the keys, and the maker's name in raised letters on the name board.
        box(&m, V3(2 * kbHalf, 0.006, 0.010), V3(0, 0.7395, 0.1620 + 0.0), "fabric.canvas:8A1D22", r: 0.0012, seg: 1)
        for k in 0..<7 {
            let lx = -0.036 + Float(k) * 0.012
            m.add(cuboid(V3(0.0065, 0.0075, 0.0006), material: "metal.brass-aged"), Xform(translation: V3(lx - 0.20, 0.760, 0.1912)))
        }
        // Keys: 52 whites with slow yellowing variation, 36 blacks.
        let pitch: Float = 2 * kbHalf / 52
        let kz = zf - 0.022 - 0.075                          // white key centre z, front 2.2 cm behind the key slip front
        let whiteTints: [MaterialKey] = ["plastic.gloss:EDE7D3", "plastic.gloss:E9E1C9", "plastic.gloss:F1ECDB"]
        for i in 0..<52 {
            let x = -kbHalf + (Float(i) + 0.5) * pitch
            let tint = whiteTints[Int(rng.float(0...2.999))]
            let depress: Float = rng.float(0...0.0004)
            m.add(cuboid(V3(pitch - 0.0010, 0.022, 0.150), material: tint),
                  Xform(translation: V3(x, 0.724 - depress, kz + rng.float(-0.0006...0.0006))))
        }
        let letters = [0, 1, 2, 3, 4, 5, 6]                  // A B C D E F G
        for i in 0..<51 {
            let l = letters[i % 7]
            guard l == 0 || l == 2 || l == 3 || l == 5 || l == 6 else { continue }      // black after A, C, D, F, G
            let x = -kbHalf + (Float(i) + 1.0) * pitch
            m.add(Prim.roundedBox(V3(0.0118, 0.014, 0.096), radius: 0.0022, bevelSegments: 1, material: "plastic.gloss:0A0A0B"),
                  Xform(translation: V3(x, 0.742, kz - 0.028)))
        }
        // Music desk: slanted panel leaning on the top door, ledge, side brackets.
        let tilt: Float = 8
        let dc = V3(0, 0.872, 0.196)
        m.add(Prim.roundedBox(V3(1.100, 0.190, 0.016), radius: 0.004, bevelSegments: 2, material: case_),
              Xform(translation: dc, rotation: simd_quatf(degrees: -tilt, axis: V3(1, 0, 0))))
        box(&m, V3(1.100, 0.014, 0.030), V3(0, 0.783, 0.214), case_, r: 0.004)
        for s: Float in [-1, 1] { box(&m, V3(0.016, 0.040, 0.054), V3(s * 0.546, 0.790, 0.210), case_, r: 0.004, seg: 1) }
        // Sheet music: two pages with staff lines and a few note heads.
        for (pi, px) in ([-0.118, 0.118] as [Float]).enumerated() {
            let off = V3(px, 0.0, 0.0)
            let page = Xform(translation: dc + V3(0, 0.002, 0.0095) + off, rotation: simd_quatf(degrees: -tilt + (pi == 0 ? -0.6 : 0.4), axis: V3(1, 0, 0)))
            m.add(Prim.roundedBox(V3(0.226, 0.285, 0.0010), radius: 0.0003, bevelSegments: 1, material: "paper.sheet:F1ECDD"), page)
            for sys in 0..<4 {
                let y0 = 0.090 - Float(sys) * 0.060
                for ln in 0..<5 {
                    let ly = y0 + Float(ln) * 0.0030
                    m.add(cuboid(V3(0.196, 0.00028, 0.0003), material: "plastic.matte:2A2A2C"),
                          Xform(translation: dc + V3(0, 0.002, 0.0095) + off + simd_act(page.rotation, V3(0, ly, 0.0007)), rotation: page.rotation))
                }
                for nn in 0..<3 {
                    let nx = -0.070 + Float(nn) * 0.065 + rng.float(-0.006...0.006)
                    let ny = y0 + Float(Int(rng.float(0...4.99))) * 0.0015
                    m.add(Prim.cylinder(radius: 0.0023, height: 0.0004, bevel: 0.0001, segments: 8, bevelSegments: 1, material: "plastic.matte:151517"),
                          Xform(translation: dc + V3(0, 0.002, 0.0095) + off + simd_act(page.rotation, V3(nx, ny, 0.0010)), rotation: page.rotation * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
            }
        }
        // Pencil on the ledge: yellow barrel, pink eraser, bare wood tip.
        let pa: Float = rng.float(-8...8)
        let pq = simd_quatf(degrees: 90, axis: V3(0, 0, 1))
        m.add(Prim.cylinder(radius: 0.0036, height: 0.170, bevel: 0.0006, segments: 6, bevelSegments: 1, material: "plastic.pencil-lacquer:E2B422"),
              Xform(translation: V3(0.265, 0.7985 + 0.0036, 0.220), rotation: simd_quatf(degrees: pa, axis: V3(0, 1, 0)) * pq))
        m.add(Prim.cylinder(radius: 0.0037, height: 0.009, bevel: 0.0012, segments: 8, bevelSegments: 1, material: "rubber.silicone:D58C8C"),
              Xform(translation: V3(0.274, 0.7985 + 0.0036, 0.220), rotation: simd_quatf(degrees: pa, axis: V3(0, 1, 0)) * pq))
        // Pedals: three brass treadles on short rods, below the lower panel.
        for px: Float in [-0.075, 0, 0.075] {
            box(&m, V3(0.048, 0.007, 0.090), V3(px, 0.076, 0.250), brass, r: 0.0025, seg: 1)
            box(&m, V3(0.030, 0.012, 0.016), V3(px, 0.084, 0.298), brass, r: 0.003, seg: 1)
            m.add(Prim.cylinder(radius: 0.0035, height: 0.040, bevel: 0.0006, segments: 8, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(px, 0.078, 0.200)))
        }
        // Pedal lyre brace: a small black block behind the pedals.
        box(&m, V3(0.260, 0.030, 0.030), V3(0, 0.105, 0.205), satin, r: 0.003, seg: 1)
        // Authoring frame: centred X/Z, lowest point y = 0.
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.10, floor: 0.5)
        return LODModel(m)
    }
}
