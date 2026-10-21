import simd
import Foundation

/// Surface-mount medicine cabinet, door closed: white powder-coated steel box, aluminum-framed beveled
/// mirror door, three barrel hinges on the left, a finger pull on the right and light water spotting on the
/// mirror. Wall mount: lowest point at y = 0, back face at z = -depth / 2.
public struct MedicineCabinet: RealAsset {
    public static let id = "medicine-cabinet"
    public static let summary = "Surface-mount medicine cabinet: white steel box, aluminum-framed beveled mirror door, barrel hinges and a finger pull."
    public static let tags = ["prop", "floorplan", "bathroom", "furniture", "glass", "wall", "interior"]
    public static let budget = 3600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 1.7, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.6, 0.76, 0.14)
    public var box: MaterialKey = "metal.powder-white"
    public var frame: MaterialKey = "metal.aluminum-brushed"
    public var mirror: MaterialKey = "metal.chrome"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let W = size.x, H = size.y, D = size.z
            let back = -D / 2
            let doorT: Float = 0.014
            let boxD = D - doorT
            // Steel box.
            m.add(Prim.roundedBox(V3(W, H, boxD), radius: 0.004, bevelSegments: hi ? 2 : 1, material: box), Xform(translation: V3(0, H / 2, back + boxD / 2)))
            // Door frame: four aluminum extrusions around the mirror.
            let fz = back + boxD + doorT / 2 + 0.0005
            let fw: Float = 0.024, rv: Float = 0.004   // door reveal to the box edge
            for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(fw, H - 2 * rv, doorT), radius: 0.0025, bevelSegments: 1, material: frame), Xform(translation: V3(sx * (W / 2 - fw / 2 - rv), H / 2, fz)))
            }
            for sy: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(W - 2 * fw - 2 * rv, fw, doorT), radius: 0.0025, bevelSegments: 1, material: frame), Xform(translation: V3(0, H / 2 + sy * (H / 2 - fw / 2 - rv), fz)))
            }
            // Beveled mirror pane, set 2 mm behind the frame face.
            let bandW: Float = 0.05
            let mw = W - 2 * fw - 2 * rv + 0.004 - 2 * bandW, mh = H - 2 * fw - 2 * rv + 0.004
            let pane = Prim.extrude(Shape2D.roundedRect(mw, mh, radius: 0.002, segments: 2), depth: 0.006, bevel: 0.0055, bevelSegments: hi ? 2 : 1, material: mirror)
            let mz = back + boxD + doorT - 0.002 - 0.003
            m.add(pane, Xform(translation: V3(0, H / 2, mz)))
            // Frosted LED light bands down both sides of the mirror.
            let inner = W - 2 * fw - 2 * rv
            for sx: Float in [-1, 1] {
                let bx = sx * (inner / 2 - bandW / 2 + 0.002)
                m.add(Prim.roundedBox(V3(bandW - 0.002, mh - 0.004, 0.003), radius: 0.001, bevelSegments: 1, material: "emissive.panel"), Xform(translation: V3(bx, H / 2, mz - 0.0005)))
                m.add(Prim.roundedBox(V3(bandW, mh, 0.004), radius: 0.0012, bevelSegments: 1, material: "glass.frosted"), Xform(translation: V3(bx, H / 2, mz + 0.0023)))
            }
            // Barrel hinges on the left edge.
            for y in [0.12, H / 2, H - 0.12] as [Float] {
                m.add(Prim.cylinder(radius: 0.0052, height: 0.05, bevel: 0.0012, segments: hi ? 12 : 6, material: "metal.chrome"), Xform(translation: V3(-W / 2 + rv + 0.0058, y - 0.025, back + boxD + 0.002)))
                m.add(Prim.roundedBox(V3(0.012, 0.05, 0.0035), radius: 0.001, bevelSegments: 1, material: "metal.chrome"), Xform(translation: V3(-W / 2 + 0.005, y, back + boxD + 0.0003)))
            }
            // Finger pull tab on the right edge and a magnetic catch strip.
            m.add(Prim.roundedBox(V3(0.006, 0.09, 0.012), radius: 0.002, bevelSegments: 1, material: "metal.brushed-nickel"), Xform(translation: V3(W / 2 - rv - 0.0005, H * 0.55, fz - 0.0015)))
            m.add(Prim.roundedBox(V3(0.008, 0.04, 0.003), radius: 0.001, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(W / 2 - 0.012, H * 0.3, back + boxD - 0.0002)))
            // Mounting cleat shadow and top vent slot.
            if hi {
                m.add(Prim.roundedBox(V3(0.18, 0.004, 0.004), radius: 0.001, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0, H - 0.0022, back + boxD * 0.6)))
            }
            // Water spotting on the mirror.
            if hi {
                var rng = SeededRNG(seed: seed)
                let zf = mz + 0.003 + 0.0006
                for _ in 0..<18 {
                    let r = rng.float(0.0015...0.006)
                    let x = rng.float((-mw / 2 + 0.01)...(mw / 2 - 0.01)), y = rng.float(0.06...(H - 0.06))
                    m.add(Prim.lathe([V2(0.0001, 0), V2(r, 0), V2(r, 0.0003), V2(0.0001, 0.0003)], segments: 8, seamTile: 0.05, material: "decal.soap-residue"),
                          Xform(translation: V3(x, y, zf), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
            }
            groundAO(&m, height: 0.1, floor: 0.9)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [4])
    }
}
