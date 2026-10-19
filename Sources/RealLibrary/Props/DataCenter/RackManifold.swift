import simd
import Foundation

/// Rack manifold: brushed stainless 2.2 m vertical coolant manifold with blue supply and red return hoses and quick-disconnect couplings.
public struct RackManifold: RealArticulated {
    public static let id = "rack-manifold"
    public static let summary = "2.2 m vertical stainless rack manifold with blue supply and red return hoses and named quick-disconnect couplings."
    public static let tags = ["prop", "articulated"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 15, distance: 3.2, studio: true)

    /// Overall size in meters (x width, y height, z depth). Hoses extend toward +Z.
    public var size = V3(0.08, 2.2, 0.12)
    /// Manifold body material key.
    public var body: MaterialKey = "metal.stainless"
    /// Supply hose material key.
    public var supply: MaterialKey = "rubber.tubing:1F4E8C"
    /// Return hose material key.
    public var returnHose: MaterialKey = "rubber.tubing:B51D17"
    /// Number of couplings per manifold.
    public var taps = 4
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        let zc: Float = -0.022
        let top = size.y
        // Mounting rail on the rack post with two manifold clamps per bracket.
        rig.base[0].add(Prim.roundedBox(V3(0.07, top - 0.08, 0.004), radius: 0.0015, bevelSegments: 1, material: "metal.powdercoat:1B1C1F"), Xform(translation: V3(0, top / 2, zc - 0.036)))
        for sx: Float in [-1, 1] {
            let x = sx * 0.02
            // Manifold tube with welded end caps and flanged ends.
            rig.base[0].add(Prim.tube([V3(x, 0.05, zc), V3(x, top - 0.05, zc)], radii: [0.0165, 0.0165], sides: 14, seamTile: 0.2, material: body), .identity)
            for y in [Float(0.012), top - 0.012] {
                rig.base[0].add(Prim.cylinder(radius: 0.0205, height: 0.012, bevel: 0.0015, segments: 14, bevelSegments: 1, material: body), Xform(translation: V3(x, y < 1 ? 0 : y, zc)))
                rig.base[0].add(Prim.cylinder(radius: 0.0125, height: 0.01, bevel: 0.002, segments: 10, bevelSegments: 1, material: "metal.nickel"), Xform(translation: V3(x, y < 1 ? 0.02 - 0.0 : top - 0.02, zc)))
            }
            for y in [Float(0.3), 1.1, 1.9] {
                rig.base[0].add(Prim.cylinder(radius: 0.0215, height: 0.008, bevel: 0.0015, segments: 14, bevelSegments: 1, material: "metal.aluminum"), Xform(translation: V3(x, y, zc)))
                rig.base[0].add(Prim.roundedBox(V3(0.012, 0.008, 0.026), radius: 0.001, bevelSegments: 1, material: "metal.powdercoat:1B1C1F"), Xform(translation: V3(x, y + 0.004, zc - 0.018)))
            }
        }
        // Branch taps: stub, named quick-disconnect coupling, hose looping forward then down.
        let n = taps
        let y0: Float = 0.28, pitch: Float = (top - 0.5) / Float(max(n - 1, 1))
        for i in 0..<n {
            let y = y0 + Float(i) * pitch
            for (label, sx, mat) in [("supply", Float(-1), supply), ("return", Float(1), returnHose)] {
                let x = sx * 0.02
                let name = "qd-\(label)-\(i + 1)"
                rig.part(name, pivot: V3(x, y, zc + 0.02), joint: .fixed)
                let zr = zc + 0.0165
                rig.add(Prim.cylinder(radius: 0.0075, height: 0.014, bevel: 0.001, segments: 8, bevelSegments: 1, material: body), Xform(translation: V3(x, y, zr), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: name)
                rig.add(Prim.lathe([V2(0.0095, 0), V2(0.0105, 0.002), V2(0.0105, 0.012), V2(0.0085, 0.0145), V2(0.0075, 0.02)], segments: 8, material: "metal.nickel"),
                        Xform(translation: V3(x, y, zr + 0.014), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: name)
                rig.add(Prim.cylinder(radius: 0.0125, height: 0.008, bevel: 0.002, segments: 8, bevelSegments: 1, material: mat == supply ? "plastic.matte:2A5CB8" : "plastic.matte:B51D17"), Xform(translation: V3(x, y, zr + 0.0185), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: name)
                let zs = zr + 0.035
                let pts = catmull([V3(x, y, zs), V3(x, y, zs + 0.012), V3(x + sx * 0.004, y - 0.014, zs + 0.02), V3(x + sx * 0.008, y - 0.07, zs + 0.02)], per: 2)
                rig.add(Prim.tube(pts, radii: Array(repeating: 0.0075, count: pts.count), sides: 6, seamTile: 0.1, material: mat), .identity, to: name)
            }
        }
        // Story detail: serial and flow-direction label on the supply manifold.
        rig.base[0].add(Prim.roundedBox(V3(0.0006, 0.1, 0.014), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:E8E8E4"), Xform(translation: V3(-0.0375, 1.0, zc)))
        groundAO(&rig, height: 0.1, floor: 0.6)
        rig.states = [RigState("static", [:])]
        rig.defaultState = "static"
        return rig
    }
}
