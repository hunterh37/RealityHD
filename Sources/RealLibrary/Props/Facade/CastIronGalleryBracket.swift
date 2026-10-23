import simd
import Foundation

/// New Orleans cast-iron gallery bracket, 0.5 x 0.6 m: a moulded vertical wall plate with end blocks, a horizontal
/// arm with a half-round top bead and a bolted seat plate for the gallery floor beam, a tapered S-curved diagonal
/// strut, two ringed C-scroll volutes in the angle under the arm, an acanthus leaf cluster at the strut foot and an
/// acorn pendant at the arm tip. Black paint chipped to rust along the top edges and bolt heads, rust runs from
/// the seat plate bolts and the wall plate, one bright replacement bolt.
public struct CastIronGalleryBracket: RealAsset {
    public static let id = "cast-iron-gallery-bracket"
    public static let summary = "New Orleans cast-iron gallery bracket, 0.5 x 0.6 m: wall plate, curved strut, scroll volutes, acanthus leaves, seat plate and acorn pendant."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 55, elevation: 12, distance: 1.5)

    /// Black painted cast iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Bare cast iron of the seat plate and pendant.
    public var cast: MaterialKey = "metal.cast-iron"
    /// Rust showing through chipped paint.
    public var rust: MaterialKey = "metal.rust"
    /// Replacement bolt.
    public var bolt: MaterialKey = "metal.bolt-bright"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sides = lite ? 5 : 10
        let W: Float = 0.5, H: Float = 0.6
        func bar(_ size: V3, _ c: V3, _ mat: MaterialKey, bevel: Float = 0.002) {
            let hx = size.x / 2, hy = size.y / 2
            m.add(Prim.extrude([V2(-hx, -hy), V2(hx, -hy), V2(hx, hy), V2(-hx, hy)], depth: size.z, bevel: min(bevel, min(size.x, size.y) * 0.3), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Wall plate: back plate with a raised centre rib and bevelled end blocks.
        FA.box(&m, V3(0.034, H, 0.036), V3(0.017, H / 2, 0), iron, r: 0.004)
        FA.box(&m, V3(0.012, H - 0.12, 0.036), V3(0.04, H / 2, 0), iron, r: 0.004)
        for y: Float in [0.018, H - 0.018] { FA.box(&m, V3(0.046, 0.036, 0.04), V3(0.023, y, 0), iron, r: 0.006) }
        // Arm: extruded profile with a half-round top bead and a drop at the tip.
        let ay0: Float = 0.552, ay1: Float = 0.588
        m.add(Prim.extrude([V2(0.04, ay0), V2(0.46, ay0), V2(0.472, ay0 + 0.008), V2(0.478, ay0 + 0.02), V2(0.472, ay1 - 0.008), V2(0.46, ay1), V2(0.04, ay1)], depth: 0.032, bevel: 0.003, bevelSegments: 1, material: iron),
              Xform(translation: .zero))
        // Half-round bead on the top edge of the arm.
        FA.rod(&m, V3(0.046, ay1 + 0.0018, 0), V3(0.474, ay1 + 0.0018, 0), r: 0.0055, iron, sides: sides)
        // Seat plate for the floor beam.
        bar(V3(0.44, 0.007, 0.04), V3(0.26, H - 0.001 + 0.0035 - 0.0, 0), cast)
        // Seat plate bolts: hex heads along the plate, one new.
        if !lite {
            for (i, x) in [Float(0.1), 0.2, 0.3, 0.4].enumerated() {
                m.add(Prim.cylinder(radius: 0.0075, height: 0.006, bevel: 0.0012, segments: 6, bevelSegments: 1, material: i == 2 ? bolt : cast), Xform(translation: V3(x, H + 0.0025, 0.0)))
            }
            // Wall bolts through the rib.
            for y: Float in [0.09, 0.3, 0.45] {
                m.add(Prim.cylinder(radius: 0.0085, height: 0.006, bevel: 0.0012, segments: 6, bevelSegments: 1, material: cast), Xform(translation: V3(0.04, y, 0.0), rotation: FA.q(-90, FA.Z)))
            }
        }
        // Strut: tapered S-curve from the plate foot to under the arm tip, rectangular section with a raised centre.
        var path: [V3] = []
        let ctrl: [V3] = [V3(0.04, 0.05, 0), V3(0.11, 0.075, 0), V3(0.21, 0.15, 0), V3(0.31, 0.3, 0), V3(0.40, 0.46, 0), V3(0.455, 0.552, 0)]
        path = catmull(ctrl, per: lite ? 4 : 8)
        let tp = (0..<path.count).map { 1 - 0.25 * Float($0) / Float(path.count - 1) }
        m.add(Prim.sweep([V2(-0.0155, -0.0185), V2(0.0155, -0.0185), V2(0.0155, 0.0185), V2(-0.0155, 0.0185)], along: path, up: FA.Z, scales: tp, caps: true, material: iron))
        let mid = Array(path.dropFirst(1).dropLast(1))
        m.add(Prim.sweep([V2(-0.0188, -0.0065), V2(0.0188, -0.0065), V2(0.0188, 0.0065), V2(-0.0188, 0.0065)], along: mid, up: FA.Z, scales: Array(tp.dropFirst(1).dropLast(1)), caps: true, material: iron))
        // Scroll volutes in the angle under the arm.
        func scroll(_ c: V3, radius R: Float, dir: Float, start: Float, turns: Float, r0: Float) {
            var pts: [V3] = [], rad: [Float] = []
            let steps = lite ? 12 : 22
            for k in 0...steps {
                let t = Float(k) / Float(steps)
                let a = start + dir * t * turns * 2 * .pi
                let r = R * (1 - 0.78 * t)
                pts.append(c + V3(cos(a) * r, sin(a) * r, 0)); rad.append(r0 - 0.0035 * t)
            }
            m.add(Prim.tube(pts, radii: rad, sides: sides, seamTile: 0.1, material: iron, capEnd: true))
            m.add(Prim.superellipsoid(V3(repeating: r0 * 2.3), exponent: 2, subdivisions: lite ? 1 : 3, material: iron), Xform(translation: pts.last!))
        }
        scroll(V3(0.105, 0.455, 0), radius: 0.075, dir: -1, start: .pi / 2 + 0.0, turns: 1.1, r0: 0.0095)
        scroll(V3(0.285, 0.492, 0), radius: 0.05, dir: 1, start: .pi / 2, turns: 0.95, r0: 0.0085)
        // Stem joining the scrolls to the arm and plate.
        FA.rod(&m, V3(0.04, 0.53, 0), V3(0.11, 0.532, 0), r: 0.008, iron, sides: sides)
        // Acanthus leaves at the strut foot: lathe lozenges flattened in Z.
        func leaf(_ at: V3, deg: Float, len: Float, wid: Float, _ mat: MaterialKey) {
            m.add(turned([(0, 0), (0.45 * wid, 0.1 * len), (wid, 0.4 * len), (0.7 * wid, 0.75 * len), (0, len)], segments: lite ? 4 : 6, material: mat, seamTile: 0.1),
                  Xform(translation: at, rotation: FA.q(deg, FA.Z), scale: V3(1, 1, 0.5)))
        }
        for (i, d) in ([5, 30, 55, 80, 105] as [Float]).enumerated() {
            // Fan of acanthus leaves at the strut foot; d is the direction from +X, counter-clockwise.
            leaf(V3(0.075 + 0.01 * Float(i % 2), 0.075, 0.0), deg: d - 90, len: 0.1 - Float(i % 2) * 0.02, wid: 0.02, iron)
        }
        // Matching leaf pair where the arm meets the wall plate.
        for d: Float in [-15, -50] { leaf(V3(0.06, 0.53, 0.0), deg: d - 90 + 180 + 0, len: 0.09, wid: 0.028, iron) }
        // Dentil row under the arm.
        var dx: Float = 0.06
        while dx < 0.45 { bar(V3(0.01, 0.011, 0.026), V3(dx, ay0 - 0.0045, 0), iron, bevel: 0.0015); dx += 0.022 }
        // Ringed medallion on the plate rib and one on the strut mid-point.
        m.add(Prim.torus(major: 0.016, minor: 0.0035, segments: lite ? 10 : 16, sides: 5, material: iron), Xform(translation: V3(0.25, 0.246, 0.0125), rotation: FA.q(90, FA.X)))
        FC.bead(&m, r: 0.0072, at: V3(0.25, 0.246, 0.0128), iron, sub: lite ? 1 : 2)
        // Acorn pendant under the arm tip.
        m.add(turned([(0, 0.462), (0.006, 0.464), (0.012, 0.474), (0.0165, 0.49), (0.015, 0.51), (0.0105, 0.528), (0.014, 0.534), (0.018, 0.54), (0.016, 0.555), (0, 0.555)], segments: lite ? 8 : 12, material: iron, seamTile: 0.1, grainVertical: true),
              Xform(translation: V3(0.462, 0, 0)))
        // Weathering.
        if !lite {
            // Paint worn off the lower strut, where rain runs, as a slightly proud rust skin.
            let low = Array(path.prefix(path.count / 2 + 1))
            m.add(Prim.sweep([V2(-0.0159, -0.0188), V2(0.0159, -0.0188), V2(0.0159, 0.0188), V2(-0.0159, 0.0188)], along: low.map { $0 + V3(0, 0, 0) }, up: FA.Z, scales: Array(tp.prefix(low.count)).map { $0 * 1.0 }, caps: false, material: rust))
            // Irregular chips on both faces of the wall plate, heavier toward the foot.
            for side: Float in [-1, 1] {
                for k in 0..<5 {
                    let cy = 0.05 + Float(k) * 0.1 + rng.float(-0.03...0.03), rx = rng.float(0.006...0.014), ry = rng.float(0.01...0.03)
                    var poly: [V2] = []
                    for j in 0..<9 { let a = Float(j) / 9 * 2 * .pi; poly.append(V2(0.017 + cos(a) * rx * rng.float(0.5...1.1), cy + sin(a) * ry * rng.float(0.5...1.1))) }
                    m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: rust), Xform(translation: V3(0, 0, side * 0.0182)))
                }
            }
            m.add(Prim.superellipsoid(V3(0.016, 0.014, 0.012), exponent: 2, subdivisions: 2, material: rust), Xform(translation: V3(0.105, 0.455 + 0.075, 0.003)))
            func flat(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<9 { let a = Float(j) / 9 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.55...1.1), cz + sin(a) * rz * rng.float(0.55...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: mat), Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for _ in 0..<5 { flat(rng.float(0.06...0.44), rng.float(-0.012...0.012), rng.float(0.01...0.04), rng.float(0.004...0.008), y: H + 0.0062, rust) }
            for _ in 0..<4 { flat(rng.float(0.06...0.44), rng.float(-0.012...0.012), rng.float(0.01...0.03), rng.float(0.003...0.007), y: ay1 + 0.0046, rust) }
            // Rust runs down the arm face under the seat plate bolts.
            for x in [Float(0.1), 0.2, 0.4] { bar(V3(0.005, rng.float(0.014...0.03), 0.0324), V3(x, ay1 - 0.01, 0), rust, bevel: 0.0008) }
            // Rust at the strut foot where water runs off, and a chip on the wall plate end block.
            bar(V3(0.05, 0.02, 0.0322), V3(0.075, 0.04, 0), rust, bevel: 0.0008)
            bar(V3(0.047, 0.014, 0.0402), V3(0.0235, 0.004, 0), rust, bevel: 0.001)
            bar(V3(0.0476, 0.012, 0.0402), V3(0.0235, H - 0.008, 0), rust, bevel: 0.001)
            bar(V3(0.0012, 0.1, 0.0362), V3(0.0275, 0.2, 0), rust, bevel: 0.0003)
        }
        groundAO(&m, height: 0.1, floor: 0.85)
        return FC.place(m)
    }
}
