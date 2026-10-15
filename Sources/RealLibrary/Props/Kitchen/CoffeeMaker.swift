import simd
import Foundation

/// 12-cup drip coffee maker, 24 x 36 x 26 cm: black tower at the back with a water tank window, a head that
/// overhangs a swing-out filter basket, a glass carafe with handle and lid on a stainless warming plate, and
/// a control strip (display, three buttons, power LED) on the head front.
public struct CoffeeMaker: RealAsset {
    public static let id = "coffee-maker"
    public static let summary = "12-cup drip coffee maker: black tower, hinged lid, swing-out filter basket, glass carafe on a warming plate."
    public static let tags = ["prop", "floorplan", "kitchen", "appliance", "plastic", "glass", "metal", "interior"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.24, 0.36, 0.26)
    /// Housing plastic.
    public var housing: MaterialKey = "plastic.black"
    /// Glossy top and panel plastic.
    public var gloss: MaterialKey = "plastic.gloss:1B1B1D"
    /// Warming plate and trim.
    public var steel: MaterialKey = "metal.stainless"
    /// Carafe glass.
    public var glassKey: MaterialKey = "glass.clear"
    /// Liquid in the carafe.
    public var liquid: MaterialKey = "food.chocolate-melted"
    /// Fill level of the carafe, 0...1.
    public var fill: Float = 0.38
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let zb = -D / 2, zf = D / 2
        // Carafe sits at the front half.
        let cz: Float = 0.040
        // Base plate with a stainless warming ring.
        m.add(Prim.roundedBox(V3(W, 0.032, D), radius: 0.008, bevelSegments: 2, material: housing), Xform(translation: V3(0, 0.016, 0)))
        m.add(Prim.cylinder(radius: 0.088, height: 0.006, bevel: 0.0015, segments: 40, material: steel), Xform(translation: V3(0, 0.0315, cz)))
        m.add(Prim.cylinder(radius: 0.072, height: 0.0016, bevel: 0.0005, segments: 40, material: "plastic.black"), Xform(translation: V3(0, 0.0372, cz)))
        // Drip stain on the base in front of the plate, and a stainless trim strip on the base front edge.
        m.add(Prim.cylinder(radius: 0.011, height: 0.0006, bevel: 0.0002, segments: 14, material: liquid),
              Xform(translation: V3(0.030, 0.0320, zf - 0.020), rotation: simd_quatf(degrees: 0, axis: V3(0, 1, 0))))
        m.add(Prim.roundedBox(V3(W - 0.030, 0.003, 0.0012), radius: 0.0005, bevelSegments: 1, material: steel), Xform(translation: V3(0, 0.020, zf - 0.0004)))
        // Tower (back column): taller and narrower at the top corners, with the tank window.
        let tz0 = zb, tz1 = zb + 0.085
        m.add(Prim.roundedBox(V3(W, H - 0.032 - 0.090, tz1 - tz0), radius: 0.008, bevelSegments: 2, material: housing),
              Xform(translation: V3(0, 0.032 + (H - 0.032 - 0.090) / 2 - 0.001, (tz0 + tz1) / 2)))
        // Water tank window: recessed bezel, glass pane, water and level marks.
        let twy: Float = 0.165, twh: Float = 0.150, tww: Float = 0.062
        m.add(Prim.roundedBox(V3(tww + 0.008, twh + 0.008, 0.003), radius: 0.003, bevelSegments: 1, material: gloss),
              Xform(translation: V3(0, twy, tz1 + 0.0004)))
        m.add(Prim.roundedBox(V3(tww, twh, 0.003), radius: 0.002, bevelSegments: 1, material: "glass.frosted"),
              Xform(translation: V3(0, twy, tz1 + 0.0021)))
        let wl: Float = 0.62
        m.add(cuboid(V3(tww - 0.004, twh * wl, 0.0008), material: "fluid.tap-water"),
              Xform(translation: V3(0, twy - twh / 2 + twh * wl / 2 + 0.002, tz1 + 0.0036)))
        for k in 0..<6 {
            m.add(cuboid(V3(k % 2 == 0 ? 0.012 : 0.007, 0.0012, 0.0008), material: "plastic.white"),
                  Xform(translation: V3(-tww / 2 + 0.010, twy - twh / 2 + 0.014 + Float(k) * 0.022, tz1 + 0.0040)))
        }
        // Head: overhangs the basket and carafe.
        let hy0 = H - 0.090, hz0 = zb, hz1 = zf - 0.018
        m.add(Prim.roundedBox(V3(W, 0.090, hz1 - hz0), radius: 0.012, bevelSegments: 3, material: housing),
              Xform(translation: V3(0, hy0 + 0.045, (hz0 + hz1) / 2)))
        // Glossy lid panel on top with a seam to the back and a front-edge thumb dent.
        m.add(Prim.roundedBox(V3(W - 0.030, 0.003, hz1 - hz0 - 0.080), radius: 0.0015, bevelSegments: 1, material: gloss),
              Xform(translation: V3(0, H - 0.0025, hz0 + 0.020 + (hz1 - hz0 - 0.080) / 2)))
        // Stainless trim line under the head front and a seam groove across the lid.
        m.add(Prim.roundedBox(V3(W - 0.020, 0.0035, 0.0016), radius: 0.0008, bevelSegments: 1, material: steel), Xform(translation: V3(0, hy0 + 0.014, hz1 + 0.0002)))
        m.add(cuboid(V3(W - 0.040, 0.0008, 0.0014), material: "plastic.matte:0B0B0C"), Xform(translation: V3(0, H - 0.0005, hz0 + 0.019)))
        // Control strip on the head front: display, three buttons, power LED.
        let fy = hy0 + 0.050
        m.add(Prim.roundedBox(V3(W - 0.050, 0.030, 0.003), radius: 0.003, bevelSegments: 1, material: gloss),
              Xform(translation: V3(0, fy, hz1 + 0.0004)))
        m.add(Prim.roundedBox(V3(0.050, 0.016, 0.002), radius: 0.0015, bevelSegments: 1, material: "screen.off"),
              Xform(translation: V3(-0.050, fy, hz1 + 0.0024)))
        for (i, dx) in ([-0.0475, -0.034, -0.021, -0.008] as [Float]).enumerated() where i != 3 {
            let seg: [Bool] = i == 0 ? [true, true, true, false, false, true, true] : [true, true, false, true, true, true, true]
            _ = seg; _ = dx
        }
        // Lit "12:00" style segments: four small bars.
        for k in 0..<4 {
            m.add(cuboid(V3(0.007, 0.0028, 0.0008), material: "emissive.led-green"),
                  Xform(translation: V3(-0.050 - 0.015 + Float(k) * 0.010, fy, hz1 + 0.0034)))
        }
        for k in 0..<3 {
            m.add(Prim.roundedBox(V3(0.018, 0.011, 0.004), radius: 0.003, bevelSegments: 1, material: "plastic.matte:2E2E31"),
                  Xform(translation: V3(0.008 + Float(k) * 0.024, fy, hz1 + 0.0030)))
        }
        m.add(Prim.cylinder(radius: 0.0032, height: 0.0014, bevel: 0.0004, segments: 12, material: "emissive.indicator"),
              Xform(translation: V3(0.0825, fy, hz1 + 0.0021), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Brew head underside: filter basket (swing-out cup) with a drip spout under the head.
        let basketY: Float = hy0 - 0.002
        m.add(Prim.cylinder(radius: 0.058, height: 0.040, bevel: 0.004, segments: 36, material: "plastic.black"),
              Xform(translation: V3(0, basketY - 0.034, cz)))
        m.add(Prim.cylinder(radius: 0.054, height: 0.0018, bevel: 0.0005, segments: 36, material: steel),
              Xform(translation: V3(0, basketY - 0.0345 + 0.040 - 0.0004, cz)))
        m.add(Prim.cylinder(radius: 0.012, height: 0.010, bevel: 0.002, segments: 18, material: "plastic.black"),
              Xform(translation: V3(0, basketY - 0.044, cz)))
        // Basket handle tab at the front.
        m.add(Prim.roundedBox(V3(0.032, 0.012, 0.022), radius: 0.003, bevelSegments: 1, material: gloss),
              Xform(translation: V3(0, basketY - 0.020, cz + 0.066)))
        // Carafe: glass body (lathe, double wall), liquid, lid ring and handle.
        let cy0: Float = 0.0385
        let outer: [V2] = Profile.smooth([V2(0, 0), V2(0.060, 0), V2(0.072, 0.010), V2(0.0775, 0.050), V2(0.076, 0.105), V2(0.066, 0.158), V2(0.060, 0.178)], per: 4)
        let shell = Profile.shell(outer, wall: 0.0035, floor: 0.007)
        var gl = Prim.lathe(shell, segments: 40, seamTile: 0.3, material: glassKey)
        gl.recomputeNormals()
        m.add(gl, Xform(translation: V3(0, cy0, cz)))
        let lh = 0.178 * fill + 0.007
        let liq: [V2] = [V2(0, 0.007), V2(0.0575, 0.007), V2(0.0715, 0.012), V2(0.0735, lh), V2(0, lh)]
        m.add(Prim.lathe(liq, segments: 40, seamTile: 0.3, material: liquid), Xform(translation: V3(0, cy0 + 0.0002, cz)))
        // Lid ring and knob.
        m.add(Prim.cylinder(radius: 0.063, height: 0.016, bevel: 0.003, segments: 40, material: "plastic.black"), Xform(translation: V3(0, cy0 + 0.176, cz)))
        m.add(Prim.cylinder(radius: 0.012, height: 0.010, bevel: 0.003, segments: 20, material: "plastic.black"), Xform(translation: V3(0, cy0 + 0.190, cz)))
        // Pour spout lip at the front-left of the carafe rim.
        m.add(Prim.roundedBox(V3(0.020, 0.004, 0.012), radius: 0.0015, bevelSegments: 1, material: glassKey),
              Xform(translation: V3(-0.050, cy0 + 0.168, cz + 0.055), rotation: simd_quatf(degrees: -25, axis: V3(0, 1, 0))))
        // Handle on the right: black loop with a finger rest.
        let hp: [V3] = [V3(0.074, 0.165, 0), V3(0.098, 0.172, 0), V3(0.108, 0.140, 0), V3(0.104, 0.100, 0), V3(0.092, 0.075, 0), V3(0.078, 0.070, 0)]
            .map { V3($0.x, cy0 + $0.y - 0.020, cz) }
        let hpath = catmull(hp, per: 5)
        m.add(Prim.tube(hpath, radii: [Float](repeating: 0.0065, count: hpath.count), sides: 10, seamTile: 0.1, material: "plastic.black", capEnd: true))
        // Feet.
        for fx: Float in [-1, 1] { for fz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.009, height: 0.003, bevel: 0.001, segments: 10, material: "rubber.silicone:2A2A2A"),
                  Xform(translation: V3(fx * (W / 2 - 0.016), -0.0, fz * (D / 2 - 0.016))).jittered(&rng))
        } }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
