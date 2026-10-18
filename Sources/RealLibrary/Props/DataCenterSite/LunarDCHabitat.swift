import simd
import Foundation

/// Lunar data-center habitat, 15 x 6 x 15 m: three rigid white pressure modules and one inflatable module half buried in a
/// regolith berm with sandbag retaining courses, a radiator fin bank on stands, an airlock with hatch and access ramp,
/// a comms mast, and a cratered grey regolith ground skirt. Base y = 0, centred on X/Z.
public struct LunarDCHabitat: RealAsset {
    public static let id = "lunar-dc-habitat"
    public static let summary = "Lunar data center habitat: modules under a sandbag regolith berm, radiator fins, airlock and grey regolith skirt."
    public static let tags = ["prop", "space", "datacenter", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 28, distance: 1.0, studio: true)

    /// Ground and berm slope material.
    public var ground: MaterialKey = "regolith.lunar"
    public var slope: MaterialKey = "regolith.lunar-fine"
    /// Sandbag fabric, tinted by dust.
    public var bag: MaterialKey = "fabric.canvas:8D887C"
    public var hull: MaterialKey = "thermal.radiator-white:DDDDD7"
    public var inflatable: MaterialKey = "mli.silver"
    public var metal: MaterialKey = "metal.aluminum-brushed"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Craters: x, z, radius.
        var craters: [(V2, Float)] = []
        for _ in 0..<7 { craters.append((V2(rng.float(-7...7), rng.float(-7...7)), rng.float(0.4...1.1))) }
        craters.append((V2(5.4, -5.2), 1.3))
        let bx: Float = 4.6, bz: Float = 3.4, top: Float = 2.1
        func berm(_ x: Float, _ z: Float) -> Float {
            let qx = abs(x) - (bx - 1.6), qz = abs(z - 0.5) - (bz - 1.6)
            let d = simd_length(V2(max(qx, 0), max(qz, 0))) + min(max(qx, qz), 0) - 1.6
            let t = max(0, min(1, 1 - d / 3.2))
            return top * t * t * (3 - 2 * t)
        }
        func height(_ p: V2) -> Float {
            var h = berm(p.x, p.y) + 0.12
            h += 0.05 * sin(p.x * 0.9 + 1.3) * cos(p.y * 0.8) + 0.03 * sin(p.x * 2.7 + p.y * 2.1)
            for (c, r) in craters {
                let d = simd_length(p - c) / r
                if d < 1.5 { h -= 0.1 * r * (d < 1 ? (1 - d * d) : 0) - 0.05 * r * exp(-pow((d - 1.05) * 5, 2)) * -1 }
            }
            let edge = max(abs(p.x), abs(p.y)); if edge > 6.2 { h *= max(0, 1 - (edge - 6.2) / 1.3) }
            return h
        }
        m.add(Prim.terrain(size: V2(15, 15), segments: 34, material: slope) { height($0) })
        // Rigid modules: lathe cylinders along X and Z buried to ~ y 1.3.
        let cy: Float = 1.75, R: Float = 1.45
        func cyl(len: Float, at c: V3, alongZ: Bool) {
            let hp: [V2] = [V2(0, 0), V2(R - 0.12, 0), V2(R, 0.12), V2(R, len - 0.12), V2(R - 0.12, len), V2(0, len)]
            let q = alongZ ? OK.qz : OK.qx
            let off = alongZ ? V3(c.x, c.y, c.z - len / 2) : V3(c.x - len / 2, c.y, c.z)
            m.add(Prim.lathe(hp, segments: 20, seamTile: 1.0, material: hull), Xform(translation: off, rotation: q))
            for k in 1..<4 {
                let t = Float(k) * len / 4
                let ring: [V2] = [V2(R - 0.002, 0), V2(R + 0.03, 0.01), V2(R + 0.03, 0.09), V2(R - 0.002, 0.1)]
                let o = alongZ ? V3(c.x, c.y, c.z - len / 2 + t) : V3(c.x - len / 2 + t, c.y, c.z)
                m.add(Prim.lathe(ring, segments: 20, seamTile: 1.0, material: metal), Xform(translation: o, rotation: q))
            }
        }
        cyl(len: 7.6, at: V3(-0.2, cy, -0.9), alongZ: false)
        cyl(len: 5.2, at: V3(-2.9, cy, 1.9), alongZ: true)
        cyl(len: 4.4, at: V3(2.8, cy, 1.3), alongZ: true)
        // Inflatable module: fat superellipsoid with MLI skin and restraint straps.
        m.add(Prim.superellipsoid(V3(4.6, 3.0, 3.2), exponent: 2.6, subdivisions: 7, material: inflatable), Xform(translation: V3(-0.2, 1.5, -4.6)))
        for k in -2...2 {
            let p: [V2] = [V2(1.5, 0), V2(1.55, 0.02), V2(1.55, 0.1), V2(1.5, 0.12)]
            _ = p
            m.add(Prim.torus(major: 1.45 * (1 - 0.07 * Float(k * k)), minor: 0.018, segments: 20, sides: 4, material: metal), Xform(translation: V3(-0.2 + Float(k) * 0.8, 1.5, -4.6), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        // Tunnel linking inflatable to the main module.
        m.add(Prim.cylinder(radius: 0.55, height: 1.6, bevel: 0.02, segments: 12, bevelSegments: 1, material: hull), Xform(translation: V3(-0.2, cy - 0.2, -3.9), rotation: OK.qz))
        // Airlock at the +X end of the main module: cylinder, hatch, ramp, handrail.
        let ax: Float = 3.4
        m.add(Prim.cylinder(radius: 1.0, height: 2.2, bevel: 0.05, segments: 20, bevelSegments: 1, material: hull), Xform(translation: V3(ax, cy - 0.1, -0.9), rotation: OK.qx))
        m.add(Prim.cylinder(radius: 0.62, height: 0.06, bevel: 0.01, segments: 20, bevelSegments: 1, material: "plastic.matte:2A2D33"), Xform(translation: V3(ax + 2.2, cy - 0.1, -0.9), rotation: OK.qx))
        m.add(Prim.torus(major: 0.68, minor: 0.04, segments: 20, sides: 6, material: "metal.titanium"), Xform(translation: V3(ax + 2.22, cy - 0.1, -0.9), rotation: OK.qx))
        m.add(Prim.sweep(Shape2D.rect(1.2, 0.05), along: [V3(ax + 2.3, 0.95, -0.9), V3(ax + 3.5, 0.12, -0.9)], up: V3(0, 0, 1), material: metal))
        for z: Float in [-1.5, -0.3] { m.add(OK.rod(V3(ax + 2.35, 1.5, z), V3(ax + 3.5, 0.7, z), r: 0.02, "metal.stainless", sides: 6)) }
        // Sandbag courses: retaining walls flanking the airlock path and capping module ends.
        func bags(from a: V3, to b: V3, courses: Int, bagLen: Float = 0.5) {
            let dir = b - a, len = simd_length(dir), n = Int(len / bagLen)
            let ang = atan2(dir.x, dir.z) * 180 / .pi
            for c in 0..<courses {
                for i in 0..<n {
                    let t = (Float(i) + 0.5 + (c % 2 == 0 ? 0 : 0.5)) / Float(n)
                    let pos = a + dir * t + V3(rng.float(-0.015...0.015), 0.0 + Float(c) * 0.15, rng.float(-0.015...0.015))
                    let s = Prim.superellipsoid(V3(0.27, 0.16, bagLen * 0.96), exponent: 3.2, subdivisions: 2, material: bag)
                    m.add(s, Xform(translation: V3(pos.x, pos.y + height(V2(pos.x, pos.z)), pos.z), rotation: simd_quatf(degrees: ang + rng.float(-3...3), axis: V3(0, 1, 0))))
                }
            }
        }
        bags(from: V3(ax + 1.0, 0.0, -2.3), to: V3(ax + 3.9, 0.0, -2.3), courses: 4)
        bags(from: V3(ax + 1.0, 0.0, 0.5), to: V3(ax + 3.9, 0.0, 0.5), courses: 4)
        bags(from: V3(-4.6, 0.0, -3.0), to: V3(-4.6, 0.0, 4.0), courses: 4)
        bags(from: V3(4.1, 0.0, -2.2), to: V3(4.1, 0.0, 3.4), courses: 3)
        bags(from: V3(-4.2, 0.0, -2.6), to: V3(-4.2, 0.0, -0.6), courses: 3)
        bags(from: V3(-3.9, 0.0, 4.9), to: V3(1.0, 0.0, 4.9), courses: 3)
        // Radiator fin bank at -Z/+X corner: stands and white-coated fins with glowing coolant header.
        for i in 0..<9 {
            let x = 1.6 + Float(i) * 0.55
            let fin = Prim.extrude(Shape2D.rect(0.05, 2.0), depth: 3.0, bevel: 0.004, bevelSegments: 1, material: "thermal.radiator-white:E3E3DD")
            m.add(fin, Xform(translation: V3(x, 1.5, -5.7)))
        }
        for z: Float in [-7.0, -4.4] { m.add(OK.rod(V3(1.4, 0.0, z), V3(1.4, 0.55, z), r: 0.05, metal, sides: 6)); m.add(OK.rod(V3(6.2, 0.0, z), V3(6.2, 0.55, z), r: 0.05, metal, sides: 6)) }
        let (hdr, hx) = OK.box(V3(5.2, 0.12, 0.14), V3(3.9, 0.45, -5.7), "thermal.radiator-glow", r: 0.01); m.add(hdr, hx)
        let (frame, fx) = OK.box(V3(5.2, 0.06, 0.1), V3(3.9, 0.55, -5.7), metal, r: 0.004); m.add(frame, fx)
        // Comms mast with dish on the berm top.
        m.add(OK.rod(V3(-3.8, top - 0.1, 0.8), V3(-3.8, 5.6, 0.8), r: 0.05, metal, sides: 8))
        m.add(Prim.lathe([V2(0, 0), V2(0.5, 0.07), V2(0.7, 0.22)], segments: 16, seamTile: 1.0, material: "thermal.radiator-white"), Xform(translation: V3(-3.8, 5.3, 0.8), rotation: simd_quatf(degrees: 70, axis: V3(0, 0, 1))))
        // Solar-grey rocks and a dust-covered cable run.
        for _ in 0..<16 {
            let p = V2(rng.float(-6.8...6.8), rng.float(-6.8...6.8)); if berm(p.x, p.y) > 0.3 { continue }
            let s = rng.float(0.1...0.45)
            m.add(Prim.superellipsoid(V3(s, s * 0.6, s * 0.8), exponent: 3, subdivisions: 4, material: ground), Xform(translation: V3(p.x, height(p) + s * 0.1, p.y), rotation: simd_quatf(degrees: rng.float(0...360), axis: V3(0, 1, 0))))
        }
        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(m)
    }
}
