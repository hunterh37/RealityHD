import simd
import Foundation

/// Double swing driveway gate: architectural facade customizer, Contemporary. Parts: two leaves, steel frame, slat infill, hinges, gate posts, drop bolt, centre stop, actuator arm, leaf stile.
public struct SwingDrivewayGateDouble: RealAsset {
    public static let id = "swing-driveway-gate-double"
    public static let summary = "Contemporary double swing driveway gate with slatted leaves, heavy hinges and linear actuators"
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(4.0, 1.8, 0.1)
    public init() {}

    /// Powder-coated steel frame and posts (hex tint after the colon).
    public var coat: MaterialKey = "metal.powdercoat:3B4146"
    /// Cedar infill boards.
    public var board: MaterialKey = "wood.cedar"
    /// Silvered cedar for replaced or sun-bleached boards.
    public var aged: MaterialKey = "wood.cedar-weathered"
    /// Galvanised hardware (hinges, bolts, brackets).
    public var zinc: MaterialKey = "metal.galvanized-aged"
    /// Rust at weld toes and the foot of the posts.
    public var rust: MaterialKey = "metal.rust-grime"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let pxw: Float = 0.14, pxc = W / 2 - pxw / 2          // post width and centre
        let inner = pxc - pxw / 2                              // inner face of each post
        let lz: Float = 0.012                                  // leaf z centre (-0.013 ... 0.037)
        let y0: Float = 0.1, y1: Float = H - 0.05
        // Gate posts: 140 x 100 box section with a capped head, base plate and a foot of rust.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(pxw, H - 0.02, 0.08), V3(sx * pxc, (H - 0.02) / 2 + 0.012, 0), coat, r: 0.005)
            FA.box(&m, V3(pxw + 0.016, 0.022, 0.08), V3(sx * pxc, H - 0.011, 0), coat, r: 0.004)
            FA.box(&m, V3(pxw, 0.012, 0.08), V3(sx * pxc, 0.006, 0), "concrete.rough", r: 0.003)
            FA.box(&m, V3(pxw + 0.004, 0.09, 0.0805), V3(sx * pxc, 0.06, 0), rust, r: 0.002)
            for bx in [-0.05, 0.05] as [Float] { FA.box(&m, V3(0.016, 0.01, 0.016), V3(sx * pxc + bx, 0.017, 0.02), zinc, r: 0.002) }
        }
        // Two leaves: 60 x 40 frame, three rails, boards on the front, hinge side outermost.
        for side in [-1, 1] as [Float] {
            var lr = rng.fork(side > 0 ? 1 : 0)
            let xa = side * 0.02, xb = side * (inner - 0.025)
            let xmin = min(xa, xb), xmax = max(xa, xb)
            let lw = xmax - xmin, cx = (xmin + xmax) / 2
            // Stiles and rails.
            for x in [xmin + 0.03, xmax - 0.03] as [Float] { FA.box(&m, V3(0.06, y1 - y0, 0.05), V3(x, (y0 + y1) / 2, lz), coat, r: 0.004) }
            for y in [y0 + 0.03, 0.9, y1 - 0.03] as [Float] { FA.box(&m, V3(lw - 0.1, 0.06, 0.05), V3(cx, y, lz), coat, r: 0.004) }
            // Diagonal brace in the frame (hinge foot to latch head).
            let dx = lw - 0.12, dy = 0.9 - (y0 + 0.03) - 0.06
            let ang = atan2(dy, dx) * 180 / .pi
            FA.box(&m, V3((dx * dx + dy * dy).squareRoot(), 0.04, 0.04), V3(cx, (0.9 + y0 + 0.03) / 2, lz - 0.004), coat, r: 0.003, rot: FA.q(side > 0 ? ang : -ang, FA.Z))
            // Vertical cedar boards 90 mm wide on a 95 mm pitch, front-fixed with a shadow gap.
            let pitch: Float = 0.095
            let n = Int((lw - 0.12) / pitch)
            let bx0 = cx - Float(n - 1) * pitch / 2
            for k in 0..<n {
                var r = lr.fork(k)
                let mat = r.chance(0.12) ? aged : board
                let top = y1 - 0.04 + r.float(-0.002...0.002)
                FA.box(&m, V3(0.088, top - y0 - 0.04, 0.016), V3(bx0 + Float(k) * pitch, (top + y0 + 0.04) / 2, lz + 0.027), mat, r: 0.0025)
            }
            // Sun-bleach at the board ends and road splash along the foot.
            FG.slab(&m, V3(lw - 0.16, 0.12, 0.002), V3(cx, y1 - 0.11, lz + 0.0355), aged, rot: .identity)
            FG.slab(&m, V3(lw - 0.16, 0.09, 0.002), V3(cx, y0 + 0.095, lz + 0.0355), rust)
            for k in 0..<5 {
                var r = lr.fork(70 + k)
                FG.slab(&m, V3(r.float(0.02...0.05), r.float(0.12...0.4), 0.002), V3(r.float(xmin + 0.12...xmax - 0.12), y0 + 0.28, lz + 0.0355), rust)
            }
            // Top cap rail over the board ends.
            FA.box(&m, V3(lw - 0.06, 0.03, 0.058), V3(cx, y1 + 0.015, lz), coat, r: 0.003)
            // Hinges: post leaf, barrel and gudgeon at three heights on the outer stile.
            let hx = side * (inner + 0.0)
            for y in [0.28, 0.9, 1.52] as [Float] {
                FA.box(&m, V3(0.055, 0.07, 0.014), V3(hx - side * 0.0275, y, lz - 0.0), zinc, r: 0.0025)
                m.add(Prim.cylinder(radius: 0.02, height: 0.11, bevel: 0.003, segments: 12, bevelSegments: 1, material: zinc), Xform(translation: V3(hx - side * 0.004, y - 0.055, lz - 0.0)))
                FA.box(&m, V3(0.06, 0.05, 0.026), V3(hx + side * 0.0, y, lz), zinc, r: 0.002)
            }
            // Actuator: tube, rod and clevis brackets from the post to the leaf, behind the boards.
            let sgn: Float = side
            let tubeLen: Float = 0.6
            let tx0 = sgn < 0 ? -(inner - 0.04) : (inner - 0.04) - tubeLen
            FA.cylX(&m, r: 0.025, h: tubeLen, at: V3(tx0, 1.1, -0.015), zinc, bevel: 0.004, segments: 14)
            // Rod runs from the tube toward the leaf and ends in a clevis on a bracket welded to the stile.
            let rodStart = sgn < 0 ? tx0 + tubeLen : tx0
            let rodEnd = sgn < 0 ? rodStart + 0.38 : rodStart - 0.38
            FA.rod(&m, V3(rodStart, 1.1, -0.015), V3(rodEnd, 1.1, -0.015), r: 0.011, "metal.chrome", sides: 10)
            FA.box(&m, V3(0.05, 0.06, 0.05), V3(rodEnd + sgn * 0.0, 1.1, -0.015), zinc, r: 0.004)
            FA.box(&m, V3(0.1, 0.05, 0.012), V3(rodEnd - sgn * 0.0, 1.1, 0.0), zinc, r: 0.003)
            FA.box(&m, V3(0.05, 0.06, 0.05), V3(sgn < 0 ? tx0 - 0.0 : tx0 + tubeLen, 1.1, -0.015), zinc, r: 0.004)
            // Weld toes and rust at the base of the stiles.
            for k in 0..<5 {
                var r = lr.fork(50 + k)
                FA.box(&m, V3(r.float(0.02...0.05), r.float(0.03...0.07), 0.0505), V3(r.float(xmin + 0.05...xmax - 0.05), y0 + r.float(0.0...0.06), lz), rust, r: 0.001)
            }
            FA.box(&m, V3(lw - 0.1, 0.02, 0.0505), V3(cx, y0 + 0.01, lz), rust, r: 0.001)
        }
        // Centre: cane bolt in guides on the left leaf, ground sleeve, keeper plate and lock case.
        FA.box(&m, V3(0.05, 0.4, 0.014), V3(-0.045, 0.45, lz + 0.026), zinc, r: 0.003)
        FA.rod(&m, V3(-0.045, -0.0 + 0.02, lz + 0.04), V3(-0.045, 0.6, lz + 0.04), r: 0.0075, "metal.chrome", sides: 8)
        for y in [0.2, 0.55] as [Float] { FA.box(&m, V3(0.03, 0.04, 0.02), V3(-0.045, y, lz + 0.036), zinc, r: 0.003) }
        FA.box(&m, V3(0.07, 0.01, 0.07), V3(-0.045, 0.005, lz + 0.01), zinc, r: 0.002)
        FA.box(&m, V3(0.13, 0.17, 0.02), V3(0.065, 0.9, lz + 0.03), coat, r: 0.004)
        FA.box(&m, V3(0.04, 0.012, 0.02), V3(0.085, 0.9, lz + 0.042), "metal.chrome", r: 0.002)
        // Photocell housings on both posts and a black cable run.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(0.05, 0.06, 0.03), V3(sx * (inner - 0.03), 0.4, -0.02), "plastic.black", r: 0.005)
        }
        groundAO(&m, height: 0.2, floor: 0.5)
        return LODModel(FC.place(m))
    }
}
