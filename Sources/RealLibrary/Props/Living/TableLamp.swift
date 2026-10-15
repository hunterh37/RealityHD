import simd
import Foundation

/// Table lamp, 36 x 60 x 36 cm: cobalt-glazed ceramic baluster base on a felted foot ring, brass cap, neck, socket with
/// a rotary knob and a frosted bulb, wire harp with a turned finial, a tapered linen drum shade with piped rims and a
/// three-arm spider under the crown, and a white cord with an inline rocker switch running off the back.
public struct TableLamp: RealAsset {
    public static let id = "table-lamp"
    public static let summary = "Table lamp: glazed ceramic baluster base, brass fittings, linen drum shade, cord with inline switch."
    public static let tags = ["prop", "floorplan", "living", "light", "ceramic", "fabric", "metal", "interior"]
    public static let budget = 14400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 1.7, studio: true)

    /// Overall size in meters (x width at the shade rim, y height to the finial tip, z depth).
    public var size = V3(0.36, 0.6, 0.36)
    /// Glazed ceramic base.
    public var glaze: MaterialKey = "ceramic.cobalt"
    /// Brass fittings.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Shade fabric.
    public var shadeFabric: MaterialKey = "fabric.linen:E9DDC4"
    /// Shade piping.
    public var piping: MaterialKey = "fabric.canvas"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rimR = size.x / 2 - 0.005              // shade bottom radius (piping adds the last 2 mm)
        // Ceramic base: felted foot ring, a swelling belly, shoulder, neck.
        let baseProfile = Profile.smooth([V2(0, 0.002), V2(0.052, 0.002), V2(0.056, 0.012), V2(0.066, 0.028), V2(0.088, 0.070), V2(0.096, 0.112),
                                          V2(0.088, 0.152), V2(0.062, 0.200), V2(0.040, 0.232), V2(0.034, 0.248), V2(0.0, 0.250)], per: 3)
        m.add(Prim.lathe(baseProfile, segments: 40, seamTile: 0.25, material: glaze))
        // Foot ring glaze-free bisque band and felt pad.
        m.add(Prim.cylinder(radius: 0.050, height: 0.004, bevel: 0.001, segments: 32, material: "ceramic.bisque"), Xform(translation: V3(0, 0.0, 0)))
        m.add(Prim.cylinder(radius: 0.046, height: 0.0015, bevel: 0.0004, segments: 24, material: "fabric.wool:2B3A2C"), Xform(translation: V3(0, -0.0003, 0)))
        // Story detail: a chipped patch on the foot rim where glaze has flaked to the bisque, 7 mm across.
        let chipA = rng.float(0.5...2.5)
        m.add(Prim.cylinder(radius: 0.0036, height: 0.0030, bevel: 0.0008, segments: 8, material: "ceramic.bisque"),
              Xform(translation: V3(0.0575 * cos(chipA), 0.012, -0.0575 * sin(chipA)), rotation: simd_quatf(degrees: 70, axis: V3(sin(chipA), 0, cos(chipA)))))
        // Brass cap, collar and neck tube up to the socket.
        let cap: [V2] = [V2(0, 0.246), V2(0.040, 0.246), V2(0.042, 0.250), V2(0.040, 0.258), V2(0.026, 0.262), V2(0.022, 0.268), V2(0.014, 0.272), V2(0.012, 0.280), V2(0, 0.280)]
        m.add(Prim.lathe(cap, segments: 32, seamTile: 0.1, material: brass))
        m.add(Prim.cylinder(radius: 0.0075, height: 0.060, bevel: 0.0006, segments: 14, material: brass), Xform(translation: V3(0, 0.278, 0)))
        // Socket: shell with a knurled collar, rotary knob on the side, bulb inside.
        let sy: Float = 0.336
        let shell: [V2] = [V2(0, sy), V2(0.015, sy), V2(0.017, sy + 0.004), V2(0.017, sy + 0.012), V2(0.0155, sy + 0.016), V2(0.0155, sy + 0.036), V2(0.0185, sy + 0.038), V2(0.0185, sy + 0.044), V2(0, sy + 0.044)]
        m.add(Prim.lathe(shell, segments: 28, seamTile: 0.1, material: brass))
        m.add(Prim.cylinder(radius: 0.0085, height: 0.007, bevel: 0.0012, segments: 16, material: brass),
              Xform(translation: V3(0.0155, sy + 0.025, 0), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        m.add(cuboid(V3(0.0012, 0.0008, 0.011), material: "metal.brass"), Xform(translation: V3(0.0245, sy + 0.025, 0)))
        // Frosted bulb: tapered glass with a neck, 8 cm tall.
        let bulb = Profile.smooth([V2(0, sy + 0.040), V2(0.013, sy + 0.042), V2(0.015, sy + 0.054), V2(0.026, sy + 0.074), V2(0.031, sy + 0.094),
                                   V2(0.028, sy + 0.114), V2(0.016, sy + 0.126), V2(0, sy + 0.128)], per: 4)
        m.add(Prim.lathe(bulb, segments: 28, seamTile: 0.1, material: "glass.frosted"))
        // Harp: two wire legs rise from a cup on the cap, arch over the bulb and meet at the finial.
        let top: Float = 0.570
        let harpR: Float = 0.052
        for s: Float in [-1, 1] {
            let pts = catmull([V3(s * 0.020, 0.286, 0), V3(s * harpR, 0.320, 0), V3(s * harpR * 1.02, 0.400, 0), V3(s * harpR * 0.82, 0.470, 0), V3(s * 0.030, 0.520, 0), V3(s * 0.010, top - 0.006, 0)], per: 6)
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0020 }, sides: 8, seamTile: 0.04, material: "metal.brass", capEnd: true))
        }
        m.add(Prim.cylinder(radius: 0.017, height: 0.004, bevel: 0.0008, segments: 20, material: brass), Xform(translation: V3(0, 0.282, 0)))
        // Shade: tapered linen drum, thin wall, 26 cm tall; bottom radius from size, top 14 cm.
        let sh0: Float = 0.316, sh1: Float = 0.578
        let tr: Float = 0.140
        let wall: Float = 0.0018
        var prof: [V2] = []
        prof.append(V2(rimR, sh0)); prof.append(V2(tr, sh1))
        prof.append(V2(tr - wall, sh1))
        prof.append(V2(rimR - wall, sh0))
        prof.append(V2(rimR, sh0))
        // Subdivide the slant so the weave texture and deformation have vertices.
        var slant: [V2] = []
        for i in 0..<prof.count - 1 {
            for k in 0..<3 { slant.append(prof[i] + (prof[i + 1] - prof[i]) * (Float(k) / 3)) }
        }
        slant.append(prof[prof.count - 1])
        var shade = Prim.lathe(slant, segments: 44, seamTile: 0.2, material: shadeFabric)
        // Hand-sewn feel: faint horizontal bow in the linen and a slight waviness on the rim.
        let ph = rng.float(0...6)
        let lean0 = rng.float(0.006...0.014)
        shade.deform { p in
            let rimWave = 1 + 0.0035 * sin(atan2(p.z, p.x) * 5 + ph) * max(0, 1 - (p.y - sh0) / 0.05)
            let bow = 1 + 0.004 * sin((p.y - sh0) / (sh1 - sh0) * .pi)
            let lean = (p.y - sh0) * lean0                 // shade sits a little off true on the spider
            return V3(p.x * rimWave * bow + lean, p.y, p.z * rimWave * bow)
        }
        m.add(shade)
        // Piped rims top and bottom, plus the vertical seam strip.
        m.add(Prim.torus(major: rimR, minor: 0.0030, segments: 44, sides: 6, material: piping), Xform(translation: V3(0, sh0, 0)))
        m.add(Prim.torus(major: tr, minor: 0.0026, segments: 36, sides: 6, material: piping), Xform(translation: V3(0, sh1, 0)))
        let seamA: Float = rng.float(2.4...3.0)
        let seam = Prim.sweep([V2(-0.003, 0), V2(0.003, 0), V2(0.003, 0.0008), V2(-0.003, 0.0008)],
                              along: [V3(rimR * cos(seamA) * 1.0, sh0, -rimR * sin(seamA)), V3(tr * cos(seamA), sh1, -tr * sin(seamA))],
                              up: V3(0, 0.0, 1), caps: true, material: piping)
        m.add(seam)
        // Spider: three arms from a collar on the neck out to the shade crown ring, and a brass crown cap with finial.
        let sp = sh1 - 0.010
        for k in 0..<3 {
            let a = Float(k) * 2 * .pi / 3 + 0.4
            let pts = [V3(0.010 * cos(a), sp - 0.0, -0.010 * sin(a)), V3((tr - 0.004) * cos(a), sh1 - 0.0025, -(tr - 0.004) * sin(a))]
            m.add(Prim.tube(pts, radii: [0.0016, 0.0016], sides: 6, seamTile: 0.05, material: "metal.brass", capEnd: true))
        }
        m.add(Prim.cylinder(radius: 0.013, height: 0.006, bevel: 0.0015, segments: 20, material: brass), Xform(translation: V3(0, sp - 0.002, 0)))
        // Finial: turned brass teardrop screwed into the harp top.
        let fin: [V2] = Profile.smooth([V2(0, top - 0.002), V2(0.006, top - 0.001), V2(0.0045, top + 0.004), V2(0.012, top + 0.010), V2(0.011, top + 0.018), V2(0.004, top + 0.026), V2(0, top + 0.028)], per: 4)
        m.add(Prim.lathe(fin, segments: 20, seamTile: 0.1, material: brass))
        // Cord: exits the base rear, droops to the floor plane, inline rocker switch on the run.
        let cordPts = catmull([V3(0, 0.014, -0.050), V3(-0.002, 0.012, -0.100), V3(0.012, 0.006, -0.135), V3(0.050, 0.0032, -0.160), V3(0.100, 0.0032, -0.120)], per: 7)
        m.add(Prim.tube(cordPts, radii: cordPts.map { _ in 0.0030 }, sides: 8, seamTile: 0.04, material: "plastic.white", capEnd: true))
        m.add(Prim.roundedBox(V3(0.020, 0.013, 0.034), radius: 0.004, bevelSegments: 2, material: "plastic.white"),
              Xform(translation: V3(0.050, 0.0075, -0.160), rotation: simd_quatf(degrees: -20, axis: V3(0, 1, 0))))
        m.add(Prim.roundedBox(V3(0.009, 0.0035, 0.016), radius: 0.0015, bevelSegments: 1, material: "plastic.matte:2A2A2C"),
              Xform(translation: V3(0.050, 0.0147, -0.160), rotation: simd_quatf(degrees: -20, axis: V3(0, 1, 0))))
        // Cord tie: a small white twist-tie loop around the run near the base.
        m.add(Prim.torus(major: 0.0034, minor: 0.0007, segments: 10, sides: 5, material: "plastic.white"),
              Xform(translation: cordPts[6], rotation: simd_quatf(degrees: 70, axis: V3(0, 0, 1))))
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.04, floor: 0.6)
        return LODModel(m)
    }
}
