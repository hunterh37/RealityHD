import simd
import Foundation

/// School Scissors: everyday school, steel and plastic. Parts: two steel blades, blunt rounded tips, two plastic finger loops, pivot screw, shanks.
public struct ScissorsSchool: RealAsset {
    public static let id = "scissors-school"
    public static let summary = "Blunt-tip school scissors with stainless blades, plastic loop handles and a pivot screw."
    public static let tags = ["prop", "interior", "school", "metal", "plastic"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.07, 0.01, 0.14)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let L: Float = 0.069
        let layerA: Float = 0.0036, layerB: Float = 0.0066, th: Float = 0.0026
        // Blade outlines in (x, z); extruded then laid flat (outline y becomes world z).
        let outline: [V2] = [V2(-0.0045, -0.006), V2(0.0050, -0.006), V2(0.0042, 0.030), V2(0.0030, L - 0.003), V2(0.0018, L), V2(-0.0010, L), V2(-0.0020, L - 0.003), V2(-0.0045, 0.030)]
        let mirror = outline.map { V2(-$0.x, $0.y) }.reversed() as [V2]
        let rot = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        func blade(_ pts: [V2], y: Float, yaw: Float) {
            let open = Xform(rotation: simd_quatf(degrees: yaw, axis: .up))
            m.add(Prim.extrude(pts, depth: th, bevel: 0.0005, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: V3(0, y, 0), rotation: rot).then(open))
        }
        blade(outline, y: layerA, yaw: 2.5)
        blade(mirror, y: layerB, yaw: -2.5)
        // Plastic shanks and finger loops: A (blue) loop on +X, B (orange) loop on -X.
        for (s, col, y) in [(Float(1), "2E6FB5", layerA), (Float(-1), "F08A1C", layerB)] {
            let mat = "plastic.gloss:" + col
            m.add(Prim.tube([V3(s * 0.0, y, -0.004), V3(s * 0.006, 0.005, -0.020), V3(s * 0.014, 0.005, -0.036)], radii: [0.0030, 0.0036, 0.0040], sides: 10, seamTile: 0.03, material: mat), Xform())
            var ring: [V3] = []
            for k in 0...24 { let a = Float.pi * 2 * Float(k) / 24; ring.append(V3(s * 0.0185 + 0.0125 * cos(a) , 0.005, -0.0525 + 0.0165 * sin(a))) }
            m.add(Prim.tube(ring, radii: Array(repeating: 0.0042, count: ring.count), sides: 10, seamTile: 0.03, material: mat), Xform())
        }
        // Pivot screw: slotted head on top, nut below.
        m.add(Prim.cylinder(radius: 0.0036, height: 0.0016, bevel: 0.0004, segments: 14, material: "metal.steel"), Xform(translation: V3(0, 0.0080, 0)))
        m.add(Prim.cylinder(radius: 0.0017, height: 0.0084, bevel: 0, segments: 10, material: "metal.steel"), Xform(translation: V3(0, 0.0004, 0)))
        m.add(Prim.roundedBox(V3(0.0052, 0.0003, 0.0007), radius: 0, bevelSegments: 1, material: "plastic.matte:1A1A1A"), Xform(translation: V3(0, 0.0097, 0)))
        m.add(Prim.cylinder(radius: 0.0030, height: 0.0012, bevel: 0.0003, segments: 6, material: "metal.steel"), Xform(translation: V3(0, 0.0, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
