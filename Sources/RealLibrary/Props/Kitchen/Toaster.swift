import simd
import Foundation

/// Two-slot toaster, 29 x 19 x 17 cm: smudged stainless shell on a black base, black top plate with two long slots
/// and wire guards, a carriage lever (up) in a track on the right end, a browning dial with three buttons on the
/// front, a pull-out crumb tray, rubber feet and two toasted slices standing in the slots.
public struct Toaster: RealAsset {
    public static let id = "toaster"
    public static let summary = "Two-slot stainless toaster: rounded body, carriage lever, browning dial, crumb tray, two toasted slices in the slots."
    public static let tags = ["prop", "floorplan", "kitchen", "appliance", "metal", "interior"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 28, distance: 0.75, studio: true)

    /// Overall size in meters (x width including the lever, y height including slice tops, z depth).
    public var size = V3(0.29, 0.19, 0.17)
    /// Shell metal.
    public var shell: MaterialKey = "metal.stainless-smudged"
    /// Black plastic.
    public var plastic: MaterialKey = "plastic.black"
    /// Toast crust.
    public var crust: MaterialKey = "food.bread-crust-toasted"
    /// Toast face.
    public var crumb: MaterialKey = "food.bread-toast"
    public init() {}

    private func box(_ m: inout Model, _ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.002) {
        m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: 2, material: key), Xform(translation: c))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let D = size.z - 0.022                         // shell depth; dial and tray handle add the rest
        let sw: Float = 0.276                           // shell width (lever protrudes past it)
        let hz = D / 2
        // Feet and base plinth.
        for fx: Float in [-1, 1] { for fz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.010, height: 0.006, bevel: 0.0015, segments: 12, material: "rubber.silicone:222222"),
                  Xform(translation: V3(fx * (sw / 2 - 0.022), 0, fz * (hz - 0.024))))
        } }
        box(&m, V3(sw - 0.004, 0.022, D - 0.004), V3(0, 0.017, 0), plastic, r: 0.008)
        // Stainless shell: a pillowed superellipsoid, and a bright trim band where it meets the base.
        let shellH: Float = 0.128
        m.add(Prim.roundedBox(V3(sw, shellH, D), radius: 0.030, bevelSegments: 5, material: shell), Xform(translation: V3(0, 0.028 + shellH / 2, 0)))
        box(&m, V3(sw - 0.002, 0.003, D - 0.002), V3(0, 0.0295, 0), "metal.chrome", r: 0.0015)
        // Top plate: black frame around two slots running along X.
        let py0: Float = 0.150, ph: Float = 0.016, pw: Float = sw - 0.012
        let pd: Float = D - 0.012
        let sxh: Float = 0.062, szc: Float = 0.030, szh: Float = 0.0135
        let endW = pw / 2 - sxh
        for s: Float in [-1, 1] {
            let outline = Shape2D.rounded([V2(-endW / 2, -pd / 2), V2(endW / 2, -pd / 2), V2(endW / 2, pd / 2), V2(-endW / 2, pd / 2)], radius: 0.020)
            m.add(Prim.extrude(outline, depth: ph, bevel: 0.003, bevelSegments: 2, material: plastic),
                  Xform(translation: V3(s * (sxh + endW / 2), py0 + ph / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        box(&m, V3(2 * sxh + 0.002, ph, szc - szh), V3(0, py0 + ph / 2, 0), plastic, r: 0.0025)
        let outerZ = pd / 2 - (szc + szh)
        for s: Float in [-1, 1] { box(&m, V3(2 * sxh + 0.002, ph, outerZ), V3(0, py0 + ph / 2, s * (szc + szh + outerZ / 2)), plastic, r: 0.0025) }
        // Slot floors (dark) and wire guards across each slot.
        for s: Float in [-1, 1] {
            box(&m, V3(2 * sxh - 0.002, 0.004, 2 * szh - 0.002), V3(0, py0 + 0.008, s * szc), "plastic.matte:060607", r: 0.0006)
            for gx: Float in [-0.040, 0, 0.040] {
                m.add(Prim.cylinder(radius: 0.0008, height: 2 * szh - 0.002, bevel: 0.0002, segments: 6, material: "metal.chrome"),
                      Xform(translation: V3(gx, py0 + ph - 0.0016, s * szc - szh + 0.001), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
        }
        // Toasted slices standing in the slots: crust slab plus slightly thicker toast faces.
        let hw: Float = 0.052
        let slice = Shape2D.rounded([V2(-hw, 0), V2(hw, 0), V2(hw + 0.002, 0.062), V2(hw + 0.009, 0.086), V2(hw - 0.006, 0.104),
                                     V2(-hw + 0.006, 0.104), V2(-hw - 0.009, 0.086), V2(-hw - 0.002, 0.062)], radius: 0.008)
        for s in [-1, 1] as [Float] {
            let lift = py0 + ph - 0.073 + rng.float(-0.002...0.002)       // top sticks out about 3 cm
            let jit = Xform(translation: V3(rng.float(-0.003...0.003), 0, s * szc + rng.float(-0.0025...0.0025)), rotation: simd_quatf(degrees: rng.float(-1.2...1.2), axis: V3(0, 1, 0)))
            var sl = Prim.extrude(slice, depth: 0.0125, bevel: 0.0025, bevelSegments: 1, material: crust)
            sl.recomputeNormals()
            m.add(sl, Xform(translation: V3(jit.translation.x, lift, jit.translation.z), rotation: jit.rotation))
            var face = Prim.extrude(Shape2D.offset(slice, -0.0045), depth: 0.0136, bevel: 0.0008, bevelSegments: 1, material: crumb)
            face.recomputeNormals()
            m.add(face, Xform(translation: V3(jit.translation.x, lift - 0.0, jit.translation.z), rotation: jit.rotation))
        }
        // Lever track and carriage on the right end.
        let ex = sw / 2
        box(&m, V3(0.003, 0.088, 0.016), V3(ex + 0.0003, 0.094, 0), plastic, r: 0.0012)
        box(&m, V3(0.004, 0.074, 0.007), V3(ex + 0.0008, 0.094, 0), "plastic.matte:040405", r: 0.0012)
        let ly: Float = 0.130
        box(&m, V3(0.010, 0.006, 0.006), V3(ex + 0.005, ly, 0), "metal.chrome", r: 0.0015)
        box(&m, V3(0.013, 0.013, 0.034), V3(ex + 0.0125, ly, 0), plastic, r: 0.005)
        // Dial bezel, dial, ticks, buttons on the front face.
        let fz = hz - 0.0035
        let dy: Float = 0.090, dx: Float = 0.082
        box(&m, V3(0.044, 0.044, 0.005), V3(dx, dy, fz), plastic, r: 0.008)
        m.add(Prim.cylinder(radius: 0.0165, height: 0.012, bevel: 0.002, segments: 28, material: plastic),
              Xform(translation: V3(dx, dy, fz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0125, height: 0.0016, bevel: 0.0005, segments: 28, material: "metal.aluminum-brushed"),
              Xform(translation: V3(dx, dy, fz + 0.0118), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        box(&m, V3(0.0016, 0.012, 0.0014), V3(dx - 0.0030, dy + 0.0045, fz + 0.0128), "plastic.white", r: 0.0005)
        for k in 0..<7 {
            let a = (-120 + Float(k) * 40) * Float.pi / 180
            m.add(Prim.cylinder(radius: 0.0011, height: 0.0007, bevel: 0.0002, segments: 8, material: "plastic.white"),
                  Xform(translation: V3(dx + sin(a) * 0.0235, dy + cos(a) * 0.0235, fz + 0.0030), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        for (i, bx) in ([-0.082, -0.058, -0.034] as [Float]).enumerated() {
            box(&m, V3(0.019, 0.010, 0.006), V3(bx, dy + 0.002, fz + 0.001), i == 2 ? "plastic.matte:8A2A22" : "plastic.matte:1B1B1D", r: 0.002)
            m.add(cuboid(V3(0.010, 0.0012, 0.0006), material: "plastic.white"), Xform(translation: V3(bx, dy - 0.0125, fz + 0.001)))
        }
        // Crumb tray pull-out under the front.
        box(&m, V3(0.200, 0.009, 0.004), V3(0, 0.019, hz - 0.0015), "metal.stainless", r: 0.0015)
        box(&m, V3(0.050, 0.006, 0.006), V3(0, 0.019, hz + 0.0020), plastic, r: 0.002)
        // Story detail: scattered crumbs on the top plate and a few on the stainless shell ledge.
        for _ in 0..<9 {
            let cr = rng.float(0.0012...0.0028)
            let onX = rng.float(-0.125...0.125), onZ = rng.float(-hz + 0.02...hz - 0.02)
            if abs(onX) < sxh + 0.004 && abs(abs(onZ) - szc) < szh + 0.003 { continue }
            m.add(Prim.cylinder(radius: cr, height: cr * 1.1, bevel: cr * 0.3, segments: 6, material: crust),
                  Xform(translation: V3(onX, py0 + ph + cr * 0.5, onZ), rotation: simd_quatf(degrees: rng.float(0...180), axis: V3(0, 1, 0))))
        }
        // Cord stub at the back left.
        let cord = catmull([V3(-0.080, 0.018, -hz + 0.004), V3(-0.081, 0.015, -hz - 0.006), V3(-0.070, 0.008, -hz - 0.011)], per: 6)
        m.add(Prim.tube(cord, radii: cord.map { _ in 0.0032 }, sides: 8, seamTile: 0.05, material: "plastic.black", capEnd: true))
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
