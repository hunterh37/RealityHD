import simd
import Foundation

/// Folding ironing board: Standard steel ironing board, blue-grey cover, light scorch near the rest.. Parts: tapered steel board with padded canvas cover and drawstring, stainless iron rest at the nose with grooves and rubber stops, two U-frame scissor legs with pivot bolts, rubber-sleeved foot bars, side slide rails with hinge and slider brackets, height lever, safety hook, cover edge welt.
public struct IroningBoard: RealAsset {
    public static let id = "ironing-board"
    public static let summary = "Open ironing board: tapered padded top, stainless iron rest, white tube scissor legs with rubber foot bars, slide rails and height lever."
    public static let tags = ["prop", "floorplan", "laundry", "metal", "fabric", "interior"]
    public static let budget = 7500
    public static let author = "realityhd"

    /// Overall size in meters (x length, y height, z width).
    public var size = V3(1.37, 0.91, 0.38)
    /// Cover color.
    public var coverColor: UInt32 = 0xB9C7D6
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    private func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let leg: MaterialKey = "metal.powdercoat:D8D8D4"
        let cover = String(format: "fabric.canvas:%06X", coverColor)
        let sides = lite ? 6 : 10
        func tube(_ pts: [V3], _ rad: Float, _ mat: MaterialKey) {
            m.add(Prim.tube(pts, radii: pts.map { _ in rad }, sides: sides, seamTile: 0.05, material: mat, capEnd: true))
        }
        func box(_ s: V3, _ rr: Float, _ mat: MaterialKey, at: V3, rot: simd_quatf = .identity) {
            m.add(Prim.roundedBox(s, radius: rr, bevelSegments: 1, material: mat), Xform(translation: at, rotation: rot))
        }
        let halfL = size.x / 2, halfW = size.z / 2
        func outline(_ inset: Float) -> [V2] {
            let pts: [V2] = [V2(-halfL, -halfW), V2(0.1, -halfW), V2(0.45, -0.12), V2(0.65, -0.055), V2(halfL + 0.007, 0), V2(0.65, 0.055), V2(0.45, 0.12), V2(0.1, halfW), V2(-halfL, halfW)]
            return Shape2D.offset(Shape2D.rounded(pts, radius: 0.035, segments: lite ? 2 : 4), -inset)
        }
        let flat = simd_quatf(degrees: 90, axis: V3(1, 0, 0))   // outline XY -> world XZ
        let yPlate: Float = 0.862
        // Steel mesh deck and padded cover.
        m.add(Prim.extrude(outline(0.012), depth: 0.004, bevel: 0.001, bevelSegments: 1, material: "metal.basket-mesh"), Xform(translation: V3(0, yPlate, 0), rotation: flat))
        m.add(Prim.extrude(outline(0.0), depth: 0.034, bevel: 0.012, bevelSegments: lite ? 2 : 3, material: cover), Xform(translation: V3(0, yPlate + 0.019, 0), rotation: flat))
        // Cover welt (piping) under the pad edge.
        if !lite {
            var loop = outline(0.004).map { V3($0.x, yPlate + 0.002, $0.y) }
            loop.append(loop[0])
            m.add(Prim.tube(loop, radii: loop.map { _ in 0.0025 }, sides: 6, seamTile: 0.05, material: "fabric.canvas:8FA0B2", capEnd: false))
        }
        // Stitched seam line around the top of the cover.
        if !lite {
            var seam = outline(0.03).map { V3($0.x, 0.8975, $0.y) }
            seam.append(seam[0])
            m.add(stitches(along: seam, normal: { _ in V3(0, 1, 0) }, pitch: 0.016, thread: 0.0009, material: "thread.white"))
        }
        // Iron rest at the nose: stainless plate with grooves and rubber stops.
        do {
            let rest = Shape2D.rounded([V2(0.44, -0.11), V2(0.56, -0.083), V2(0.665, -0.04), V2(0.68, 0), V2(0.665, 0.04), V2(0.56, 0.083), V2(0.44, 0.11)], radius: 0.015, segments: lite ? 2 : 3)
            m.add(Prim.extrude(rest, depth: 0.012, bevel: 0.003, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(0, 0.904, 0), rotation: flat))
            if !lite {
                for k in 0..<6 {
                    box(V3(0.006, 0.0015, 0.17 - Float(k) * 0.012), 0.0004, "metal.painted:2A2A2C", at: V3(0.47 + Float(k) * 0.035, 0.9105, 0))
                }
            }
            for sz in [Float(-1), 1] { box(V3(0.02, 0.008, 0.012), 0.002, "rubber.tire", at: V3(0.455, 0.914, sz * 0.095)) }
        }
        // Slide rails under the deck.
        for sz in [Float(-1), 1] {
            box(V3(1.08, 0.016, 0.014), 0.002, "metal.powdercoat:A8AAAD", at: V3(0.03, 0.852, sz * 0.125))
        }
        // Frame A (hinged at the wide end), frame B (slider toward the nose).
        let yH: Float = 0.846
        let aTop = V3(-0.47, yH, 0), aFoot = V3(0.27, 0.02, 0)
        let bTop = V3(0.49, yH, 0), bFoot = V3(-0.21, 0.02, 0)
        let zA: Float = 0.16, zB: Float = 0.124
        func lerp(_ a: V3, _ b: V3, _ t: Float) -> V3 { a + (b - a) * t }
        for (top, foot, z) in [(aTop, aFoot, zA), (bTop, bFoot, zB)] {
            for sz in [Float(-1), 1] {
                let a = V3(top.x, top.y, sz * z), b = V3(foot.x, foot.y, sz * z)
                tube([a, lerp(a, b, 0.5), b], 0.0085, leg)
            }
            tube([V3(top.x, top.y, -z), V3(top.x, top.y, z)], 0.0085, leg)
            // Foot bar sleeved in rubber.
            tube([V3(foot.x, foot.y, -z - 0.012), V3(foot.x, foot.y, z + 0.012)], 0.0115, "rubber.tire")
        }
        // Brackets: hinge and slider blocks on the rails.
        for sz in [Float(-1), 1] {
            box(V3(0.05, 0.024, 0.02), 0.003, "metal.powdercoat:A8AAAD", at: V3(-0.47, 0.848, sz * zA))
            box(V3(0.06, 0.024, 0.02), 0.003, "metal.powdercoat:A8AAAD", at: V3(0.49, 0.848, sz * zB))
        }
        // Pivot bolt through the crossing.
        let cross = lerp(aTop, aFoot, (bTop.x - aTop.x) / ((bTop.x - aTop.x) + (aFoot.x - bFoot.x)) * 1.0)
        _ = cross
        let t = (bTop.x - aTop.x) / ((aFoot.x - aTop.x) + (bTop.x - bFoot.x))
        let pivot = lerp(aTop, aFoot, t)
        for sz in [Float(-1), 1] {
            m.add(Prim.cylinder(radius: 0.011, height: 0.006, bevel: 0.0015, segments: lite ? 8 : 14, bevelSegments: 1, material: "metal.screw-zinc"),
                  Xform(translation: V3(pivot.x, pivot.y, sz * (zA + 0.009)), rotation: simd_quatf(from: V3(0, 1, 0), to: V3(0, 0, sz))))
            m.add(Prim.cylinder(radius: 0.006, height: 0.02, bevel: 0.001, segments: 8, bevelSegments: 1, material: "metal.screw-zinc"),
                  Xform(translation: V3(pivot.x, pivot.y, sz * (zB - 0.01)), rotation: simd_quatf(from: V3(0, 1, 0), to: V3(0, 0, sz))))
        }
        // Height lever (rod and rubber grip) under the nose end, and safety hook near the hinge.
        tube([V3(0.3, 0.846, zB), V3(0.34, 0.80, zB + 0.02), V3(0.38, 0.78, zB + 0.04)], 0.0055, "metal.chrome")
        box(V3(0.05, 0.016, 0.016), 0.006, "rubber.tire", at: V3(0.405, 0.775, zB + 0.05), rot: simd_quatf(degrees: -20, axis: V3(0, 0, 1)))
        tube([V3(-0.30, 0.846, -zA), V3(-0.30, 0.8, -zA - 0.015), V3(-0.27, 0.77, -zA - 0.015)], 0.0045, "metal.chrome")
        // Light scorch near the rest.
        m.add(Prim.extrude(Shape2D.rounded([V2(0.36, -0.03), V2(0.43, -0.02), V2(0.44, 0.03), V2(0.37, 0.04)], radius: 0.015, segments: 2), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "fabric.canvas:8B7B5A"),
              Xform(translation: V3(0, 0.8987 + rng.float(0...0.0003), 0.01), rotation: flat))
        // Drawstring tail with cord lock hanging from the tail end, and a second scorch ring.
        tube([V3(-0.66, 0.864, 0.07), V3(-0.668, 0.83, 0.075), V3(-0.664, 0.80, 0.07)], 0.0028, "fabric.canvas:8FA0B2")
        tube([V3(-0.66, 0.864, 0.07), V3(-0.652, 0.835, 0.083), V3(-0.655, 0.81, 0.09)], 0.0028, "fabric.canvas:8FA0B2")
        box(V3(0.012, 0.02, 0.01), 0.003, "plastic.matte:2A2A2C", at: V3(-0.667, 0.84, 0.078))
        m.add(Prim.extrude(Shape2D.rounded([V2(0.28, -0.05), V2(0.33, -0.045), V2(0.34, -0.01), V2(0.29, 0.0)], radius: 0.012, segments: 2), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "fabric.canvas:A8987A"),
              Xform(translation: V3(0, 0.8986, 0), rotation: flat))
        groundAO(&m, height: 0.12, floor: 0.7)
        return m
    }
}
