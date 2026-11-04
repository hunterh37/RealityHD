import simd
import Foundation

/// Desktop Globe: everyday school, printed. Parts: ocean sphere, continents, graticule, half meridian arm, tilted axis pins, wood base.
public struct GlobeDesktop: RealAsset {
    public static let id = "globe-desktop"
    public static let summary = "Desktop world globe tilted 23.5 degrees in a half meridian arm on a wood base."
    public static let tags = ["prop", "interior", "school", "plastic", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.3, 0.4, 0.3)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let R: Float = 0.147, cy: Float = 0.238
        let tilt = simd_quatf(degrees: 23.5, axis: V3(0, 0, 1))
        let center = V3(0, cy, 0)
        // Ocean sphere.
        m.add(Prim.cubeSphere(subdivisions: 11, material: "plastic.gloss:4C8FC4") { d in d * R }, Xform(translation: center))
        // Continents as thin flattened lozenges seated on the sphere: (lon, lat, width m, height m, hex).
        let land: [(Float, Float, Float, Float, String)] = [
            (-100, 48, 0.10, 0.085, "D8CFA0"), (-105, 30, 0.05, 0.04, "D8CFA0"), (-60, -12, 0.05, 0.095, "B9D49A"), (-66, -38, 0.025, 0.05, "B9D49A"),
            (18, 8, 0.07, 0.09, "E3C37A"), (22, -20, 0.04, 0.05, "E3C37A"), (15, 50, 0.05, 0.035, "E8B7A0"), (80, 52, 0.15, 0.08, "E8B7A0"),
            (110, 30, 0.07, 0.06, "E8B7A0"), (78, 20, 0.03, 0.035, "E8B7A0"), (134, -25, 0.055, 0.04, "E7A46C"), (-40, 72, 0.03, 0.045, "EDEDE6"),
            (170, -42, 0.015, 0.03, "B9D49A")]
        for (lon, lat, w, h, hex) in land {
            let lo = lon * .pi / 180, la = lat * .pi / 180
            let d = V3(cos(la) * cos(lo), sin(la), cos(la) * sin(lo))
            let e = V3(-sin(lo), 0, cos(lo)), n = V3(-sin(la) * cos(lo), cos(la), -sin(la) * sin(lo))
            let q = simd_quatf(simd_float3x3([e, d, n]))
            var patch = Prim.superellipsoid(V3(w, 0.0045, h), exponent: 3, subdivisions: 6, material: "plastic.matte:" + hex)
            // Bend the flat lozenge onto the sphere: local +Y is outward, x/z become arc lengths.
            patch.deform { p in
                let u = p.x / R, v = p.z / R, rr = R - 0.0008 + p.y
                return V3(rr * sin(u) * cos(v), rr * cos(u) * cos(v) - (R - 0.0008), rr * sin(v))
            }
            m.add(patch, Xform(translation: tilt.act(d * (R - 0.0008)) + center, rotation: tilt * q))
        }
        // Polar ice cap at the south pole.
        m.add(Prim.superellipsoid(V3(0.075, 0.006, 0.075), exponent: 2, subdivisions: 8, material: "plastic.matte:F1F1EC"),
              Xform(translation: tilt.act(V3(0, -R + 0.001, 0)) + center, rotation: tilt))
        // Graticule: latitude rings every 30 degrees.
        for lat in stride(from: -60, through: 60, by: 30) {
            let la = Float(lat) * .pi / 180
            m.add(Prim.torus(major: R * cos(la) + 0.0005, minor: 0.0005, segments: 32, sides: 5, material: "plastic.matte:2A4F7A"),
                  Xform(translation: tilt.act(V3(0, R * sin(la), 0)) + center, rotation: tilt))
        }
        // Half meridian arm on the -X side with a graduated edge, axis pins at both poles.
        var arm: [V3] = []
        let ar: Float = R + 0.014
        for k in 0...24 { let a = -Float.pi / 2 + Float.pi * Float(k) / 24; arm.append(V3(-ar * cos(a), cy + ar * sin(a), 0)) }
        m.add(Prim.tube(arm, radii: Array(repeating: 0.0032, count: arm.count), sides: 10, seamTile: 0.05, material: "metal.brass-aged"), Xform())
        for s: Float in [-1, 1] {
            let pole = tilt.act(V3(0, s * (R + 0.002), 0)) + center
            m.add(Prim.cylinder(radius: 0.0035, height: 0.012, bevel: 0.0008, segments: 10, material: "metal.brass-aged"),
                  Xform(translation: pole - tilt.act(V3(0, 0.006, 0)) * (s > 0 ? -1 : 1) * 0 , rotation: tilt))
        }
        // Stem and wood base disc with a rim bevel and felt pad.
        m.add(Prim.tube([V3(0, cy - ar, 0), V3(0, 0.03, 0)], radii: [0.005, 0.0065], sides: 12, seamTile: 0.05, material: "metal.brass-aged"), Xform())
        m.add(Prim.cylinder(radius: 0.085, height: 0.018, bevel: 0.004, segments: 40, material: "wood.walnut"), Xform())
        m.add(Prim.cylinder(radius: 0.060, height: 0.0010, bevel: 0, segments: 28, material: "fabric.wool:2A2A2A"), Xform(translation: V3(0, -0.0002, 0)))
        m.add(Prim.cylinder(radius: 0.012, height: 0.013, bevel: 0.002, segments: 16, material: "metal.brass-aged"), Xform(translation: V3(0, 0.018, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
