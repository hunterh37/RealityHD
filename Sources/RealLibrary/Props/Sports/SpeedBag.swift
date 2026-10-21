import simd
import Foundation

/// Medium leather speed bag. Origin is the bag bottom (y = 0); the bulb runs to `length`, a laced tan neck
/// sleeve and a chrome swivel with an open hook carry it to `hangHeight`. Six panels with welted seams,
/// worn red leather, one scuffed patch where the fists land.
public struct SpeedBag: RealAsset {
    public static let id = "speed-bag"
    public static let summary = "Red leather teardrop speed bag: stitched panels, tied neck and chrome swivel hook."
    public static let tags = ["prop", "sports", "leather", "metal"]
    public static let budget = 8500
    public static let author = "hunter"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 0.9, studio: true)

    /// Bulb length without the neck (m).
    public var length: Float = 0.200
    /// Maximum bulb radius (m).
    public var radius: Float = 0.085
    /// Leather.
    public var leather: MaterialKey = "leather.oxblood-worn:A3170F"
    public init() {}

    /// Hook apex height above the bag bottom (m).
    public var hangHeight: Float { length + 0.069 }
    /// Where the hook's inner top bears on the swivel eye: the bag's pivot (m above the bag bottom).
    public var pivotHeight: Float { hangHeight - 0.0052 }

    func bulb(_ t: Float) -> Float {
        // t = y / length. Teardrop: full round low, tapering to the neck.
        let pts: [(Float, Float)] = [(0, 0), (0.02, 0.42), (0.07, 0.75), (0.16, 0.94), (0.30, 1.0), (0.46, 0.95), (0.62, 0.78), (0.78, 0.50), (0.90, 0.30), (0.97, 0.22), (1.0, 0.20)]
        for i in 1..<pts.count where t <= pts[i].0 {
            let (t0, r0) = pts[i - 1], (t1, r1) = pts[i]
            let u = (t - t0) / (t1 - t0)
            return (r0 + (r1 - r0) * u * u * (3 - 2 * u)) * radius
        }
        return 0.20 * radius
    }

    public func build(seed: UInt64) -> LODModel {
        var levels: [Model] = []
        for l in 0..<2 {
            let detail = l == 0
            var m = Model(name: Self.id)
            let L = length
            let steps = detail ? 36 : 14
            let prof = (0...steps).map { k -> V2 in let y = L * Float(k) / Float(steps); return V2(bulb(y / L), y) }
            m.add(Prim.lathe(prof, segments: detail ? 48 : 20, seamTile: 0.12, material: leather))

            // Six welted meridian seams with stitching alongside.
            for k in 0..<6 {
                let a = Float(k) / 6 * 2 * .pi
                let path = (0...(detail ? 22 : 9)).map { i -> V3 in
                    let y = 0.006 + (L - 0.012) * Float(i) / Float(detail ? 22 : 9)
                    let rr = bulb(y / L) + 0.0007
                    return V3(cos(a) * rr, y, sin(a) * rr)
                }
                m.add(Prim.tube(path, radii: path.map { _ in 0.0017 }, sides: detail ? 5 : 3, seamTile: 0.02, material: leather))
                if detail {
                    for da: Float in [-0.05, 0.05] {
                        let sp = path.map { p -> V3 in let rr = simd_length(V2(p.x, p.z)) + 0.0004; return V3(cos(a + da) * rr, p.y, sin(a + da) * rr) }
                        m.add(stitches(along: sp, normal: { V3($0.x, 0, $0.z) }, pitch: 0.009, thread: 0.0005, material: "thread.white"))
                    }
                }
            }

            // Neck sleeve in tan leather with a crossed lace.
            let nr = bulb(1)
            m.add(Prim.lathe([V2(nr * 0.9, L - 0.045), V2(nr + 0.0035, L - 0.042), V2(nr + 0.0045, L - 0.03), V2(nr + 0.0045, L + 0.014),
                              V2(nr + 0.0026, L + 0.022), V2(nr * 0.55, L + 0.024)],
                             segments: detail ? 24 : 10, seamTile: 0.05, material: "leather.tan"))
            if detail {
                let lace = (0...40).map { i -> V3 in
                    let t = Float(i) / 40, a = t * 4 * .pi
                    return V3(cos(a) * (nr + 0.0058), L - 0.030 + 0.040 * t, sin(a) * (nr + 0.0058))
                }
                m.add(Prim.tube(lace, radii: lace.map { _ in 0.0012 }, sides: 4, seamTile: 0.02, material: "leather.black"))
            }

            // Chrome swivel and open hook.
            let top = V3(0, L + 0.024, 0)
            m.add(Prim.cylinder(radius: 0.0105, height: 0.012, bevel: 0.0025, segments: detail ? 16 : 8, material: "metal.chrome"), Xform(translation: top))
            m.add(Prim.cylinder(radius: 0.0075, height: 0.016, bevel: 0.002, segments: detail ? 14 : 8, material: "metal.chrome"), Xform(translation: top + V3(0, 0.010, 0)))
            m.add(Prim.torus(major: 0.0105, minor: 0.0026, segments: detail ? 20 : 10, sides: detail ? 8 : 4, arc: 1.75 * .pi, material: "metal.chrome"),
                  Xform(translation: top + V3(0, 0.032, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: 20, axis: .up)))

            groundAO(&m, height: 0.08, floor: 0.75)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [3])
    }
}
