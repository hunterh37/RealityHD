import simd
import Foundation

/// Chain link fence section: architectural facade customizer, Commercial. Parts: terminal posts, line post, top rail, chain link mesh, tension bar, tension band, tie wires, post caps, bottom tension wire.
public struct ChainLinkFenceSection: RealAsset {
    public static let id = "chain-link-fence-section"
    public static let summary = "Commercial galvanized chain link fence, 2 inch mesh, tubular posts and top rail."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 1.8, 0.05)
    public init() {}

    /// Woven galvanised mesh, 50 mm diamond.
    public var mesh: MaterialKey = "fence.chainlink"
    /// Aged galvanised tube (posts, rail).
    public var tube: MaterialKey = "metal.galvanized-aged"
    /// Fresh galvanised fittings (bands, bars, caps).
    public var fitting: MaterialKey = "metal.galvanized"
    /// White-rust and red-rust staining.
    public var rust: MaterialKey = "metal.rust-grime"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let pr: Float = 0.0245                       // terminal post radius (48 mm tube)
        let tx = W / 2 - pr
        let railY = H - 0.03, rr: Float = 0.0105
        let mz: Float = 0.0185                  // mesh plane sits proud of the posts
        // Terminal posts (2) and one line post, with domed loop caps on the terminals.
        for sx in [-1, 1] as [Float] {
            m.add(Prim.cylinder(radius: pr, height: H - 0.02, bevel: 0.002, segments: 18, bevelSegments: 1, material: tube), Xform(translation: V3(sx * tx, 0, 0)))
            // Loop cap: dome plus a ring for the top rail.
            m.add(Prim.superellipsoid(V3(0.048, 0.036, 0.048), exponent: 2, subdivisions: 5, material: fitting), Xform(translation: V3(sx * tx, H - 0.019, 0)))
            m.add(Prim.torus(major: 0.0165, minor: 0.0035, segments: 14, sides: 6, material: fitting), Xform(translation: V3(sx * tx, railY - 0.0, 0), rotation: FA.q(90, FA.Z)))
            // Ground sleeve ring and rust splash at the foot.
            m.add(Prim.cylinder(radius: pr + 0.0002, height: 0.03, bevel: 0.002, segments: 16, bevelSegments: 1, material: fitting), Xform(translation: V3(sx * tx, 0.0, 0)))
            FA.box(&m, V3(0.04, 0.12, 0.003), V3(sx * tx + 0.0, 0.1, pr - 0.0005), rust, r: 0.0005)
        }
        m.add(Prim.cylinder(radius: 0.0215, height: H - 0.05, bevel: 0.002, segments: 16, bevelSegments: 1, material: tube), Xform(translation: V3(0, 0, 0)))
        m.add(Prim.cylinder(radius: 0.0235, height: 0.014, bevel: 0.002, segments: 16, bevelSegments: 1, material: fitting), Xform(translation: V3(0, H - 0.062, 0)))
        // Top rail: 42 mm tube through the loop caps, with a boulevard clamp at the line post.
        FA.cylX(&m, r: rr, h: W - 0.02, at: V3(-W / 2 + 0.01, railY, 0), tube, bevel: 0.002, segments: 12)
        FA.box(&m, V3(0.03, 0.05, 0.05), V3(0, railY - 0.01, 0), fitting, r: 0.004)
        // Mesh: two bays split by the line post, framed top and bottom with a knuckled selvage.
        let mh = H - 0.07 - 0.05
        let mcy = 0.04 + mh / 2 + 0.02
        for (x0, x1) in [(-tx + pr + 0.016, -0.026), (0.026, tx - pr - 0.016)] {
            FGate.slab(&m, V3(x1 - x0, mh, 0.0022), V3((x0 + x1) / 2, mcy, mz), mesh)
            // Knuckled selvage: small twisted-wire loops every 50 mm along top and bottom.
            var x = x0 + 0.01
            while x < x1 - 0.01 {
                FGate.slab(&m, V3(0.011, 0.011, 0.0035), V3(x, mcy + mh / 2 - 0.004, mz), fitting, rot: FA.q(45, FA.Z))
                FGate.slab(&m, V3(0.011, 0.011, 0.0035), V3(x, mcy - mh / 2 + 0.004, mz), fitting, rot: FA.q(45, FA.Z))
                x += 0.05
            }
        }
        // Tension bars (flat 6 x 19 mm) at the mesh ends, banded to the terminal posts; carriage bolt heads.
        for sx in [-1, 1] as [Float] {
            let bx = sx * (tx - pr - 0.012)
            FA.box(&m, V3(0.006, mh + 0.02, 0.01), V3(bx, mcy, mz), fitting, r: 0.001)
            for k in 0..<6 {
                let y = 0.2 + Float(k) * (mh - 0.2) / 5
                FA.box(&m, V3(0.034, 0.012, 0.012), V3(sx * (tx - 0.0), y, 0.0), fitting, r: 0.002)
                FGate.slab(&m, V3(0.016, 0.016, 0.004), V3(bx - sx * 0.012, y, mz + 0.0), fitting)
            }
        }
        // Bottom tension wire and aluminium tie wires on the top rail and line post.
        FA.rod(&m, V3(-W / 2 + 0.03, 0.045, mz + 0.003), V3(W / 2 - 0.03, 0.045, mz + 0.003), r: 0.0025, fitting, sides: 5)
        for k in 0..<10 {
            let x = -W / 2 + 0.2 + Float(k) * (W - 0.4) / 9
            if abs(x) < 0.04 { continue }
            FGate.slab(&m, V3(0.003, 0.034, 0.0045), V3(x, railY - 0.002, mz + 0.0012), "metal.screw-zinc")
        }
        for k in 0..<5 {
            FGate.slab(&m, V3(0.034, 0.003, 0.0045), V3(0, 0.3 + Float(k) * 0.34, mz + 0.0012), "metal.screw-zinc")
        }
        // Wear: white-rust bloom at the bottom edge, rust at the bands, and a dent in the mesh.
        for k in 0..<7 {
            var r = rng.fork(k)
            FGate.slab(&m, V3(r.float(0.03...0.12), r.float(0.02...0.05), 0.0012), V3(r.float(-1.3...1.3), r.float(0.06...0.2), mz + 0.0015), rust)
        }
        groundAO(&m, height: 0.2, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
