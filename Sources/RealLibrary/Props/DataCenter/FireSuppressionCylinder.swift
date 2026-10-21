import simd
import Foundation

/// Fire suppression cylinder: red painted clean-agent cylinder with a brass valve, pressure gauge, discharge outlet and floor bracket.
public struct FireSuppressionCylinder: RealAsset {
    public static let id = "fire-suppression-cylinder"
    public static let summary = "Clean-agent suppression cylinder: red domed steel body, brass valve with gauge and discharge outlet, label band, wall strap and floor base."
    public static let tags = ["prop"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 10, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.3, 1.6, 0.3)
    /// Cylinder paint material key.
    public var paint: MaterialKey = "metal.painted:B51D17"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let r = size.x * 0.5 * 0.72, h = size.y
        let brass: MaterialKey = "metal.brass"
        let alongX = simd_quatf(degrees: 90, axis: V3(0, 0, 1))
        let alongZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        func cyl(_ rad: Float, _ ht: Float, _ p: V3, _ mat: MaterialKey, rot: simd_quatf = .identity, segs: Int = 18) {
            m.add(Prim.cylinder(radius: rad, height: ht, bevel: min(0.002, rad * 0.25), segments: segs, bevelSegments: 1, material: mat), Xform(translation: p, rotation: rot))
        }
        let bodyBottom: Float = 0.04, bodyTop = h - 0.2
        // Body with domed shoulder and rounded base, as one lathe profile.
        var prof: [V2] = [V2(0.001, bodyBottom), V2(r * 0.7, bodyBottom + 0.004), V2(r, bodyBottom + 0.03), V2(r, bodyTop - 0.06)]
        for k in 1...6 {
            let a = Float(k) / 6 * (.pi / 2)
            prof.append(V2(r * cos(a) * 0.98 + 0.02 * (1 - sin(a)) * 0, bodyTop - 0.06 + 0.075 * sin(a)))
        }
        prof.append(V2(0.04, bodyTop + 0.017))
        m.add(Prim.lathe(prof, segments: 28, material: paint), .identity)
        // Neck, valve body, brass fittings.
        cyl(0.04, 0.04, V3(0, bodyTop + 0.03, 0), brass)
        cyl(0.05, 0.09, V3(0, bodyTop + 0.095, 0), brass)
        cyl(0.03, 0.03, V3(0, bodyTop + 0.15, 0), brass, segs: 16)
        cyl(0.022, 0.03, V3(0, bodyTop + 0.18, 0), "metal.stainless", segs: 16)
        // Discharge outlet to +X with a collar and cap, and a safety pin lever.
        cyl(0.022, 0.1, V3(0.075, bodyTop + 0.1, 0), brass, rot: alongX, segs: 16)
        cyl(0.03, 0.02, V3(0.13, bodyTop + 0.1, 0), brass, rot: alongX, segs: 16)
        cyl(0.01, 0.07, V3(-0.065, bodyTop + 0.11, 0), "metal.stainless", rot: alongX, segs: 10)
        // Pressure gauge on +Z side of the valve.
        cyl(0.012, 0.03, V3(0, bodyTop + 0.105, 0.065), brass, rot: alongZ, segs: 10)
        cyl(0.034, 0.016, V3(0, bodyTop + 0.105, 0.095), "metal.stainless", rot: alongZ, segs: 18)
        cyl(0.03, 0.002, V3(0, bodyTop + 0.105, 0.1035), "plastic.matte:F2F2EE", rot: alongZ, segs: 18)
        cyl(0.031, 0.0016, V3(0, bodyTop + 0.105, 0.1055), "glass.gauge-lens", rot: alongZ, segs: 18)
        m.add(cuboid(V3(0.0015, 0.022, 0.0008), material: "plastic.matte:B51D17"), Xform(translation: V3(0.004, bodyTop + 0.112, 0.1045)))
        m.add(cuboid(V3(0.02, 0.003, 0.0008), material: "plastic.matte:2AB85C"), Xform(translation: V3(0, bodyTop + 0.088, 0.1045)))
        // Agent label band and warning stripe.
        cyl(r + 0.0012, 0.22, V3(0, h * 0.55, 0), "plastic.matte:E8E8E4", segs: 28)
        cyl(r + 0.0018, 0.02, V3(0, h * 0.55 + 0.09, 0), "plastic.matte:121316", segs: 28)
        // Straps and floor base ring.
        for y in [h * 0.3, h * 0.8] {
            cyl(r + 0.004, 0.03, V3(0, y, 0), "metal.galvanized", segs: 28)
            m.add(cuboid(V3(0.03, 0.03, 0.04), material: "metal.galvanized"), Xform(translation: V3(0, y, -r - 0.02)))
        }
        cyl(r + 0.02, 0.04, V3(0, 0.02, 0), "metal.powdercoat:3A3C40", segs: 28)
        groundAO(&m)
        return LODModel(m)
    }
}
