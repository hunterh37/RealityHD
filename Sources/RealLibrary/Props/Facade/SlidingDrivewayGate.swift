import simd
import Foundation

/// Sliding driveway gate: architectural facade customizer, Contemporary. Parts: steel frame, infill slats, top track rail, guide rollers, bottom rail, drive rack, tail wheels, gate post, receiver post.
public struct SlidingDrivewayGate: RealAsset {
    public static let id = "sliding-driveway-gate"
    public static let summary = "Contemporary cantilever sliding gate, aluminium slat infill in steel frame with rack and rollers."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(4.0, 1.8, 0.1)
    public init() {}

    /// Powder-coated steel frame (hex tint after the colon).
    public var coat: MaterialKey = "metal.powdercoat:4B5156"
    /// Woodgrain-effect aluminium slat infill.
    public var slat: MaterialKey = "metal.powdercoat:7A5B3C"
    /// Second slat tone (woodgrain-effect aluminium alternates two tones).
    public var slatDark: MaterialKey = "metal.powdercoat:68492E"
    /// Galvanised steel (rack, track, brackets).
    public var zinc: MaterialKey = "metal.galvanized-aged"
    /// Nylon roller wheels.
    public var nylon: MaterialKey = "plastic.white"
    /// Rust at the weld toes near the ground.
    public var rust: MaterialKey = "metal.rust-grime"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let x0: Float = -W / 2 + 0.02, x1: Float = W / 2 - 0.16      // leaf extent (receiver post to the right)
        let lw = x1 - x0, cx = (x0 + x1) / 2
        let lz: Float = 0.025                                         // leaf centre z (leaf z 0 ... 0.05)
        let by0: Float = 0.1, bh: Float = 0.12                        // bottom rail
        // Frame: bottom track rail (deeper), top rail, two stiles, intermediate cross rails.
        FA.box(&m, V3(lw, bh, 0.05), V3(cx, by0 + bh / 2, lz), coat, r: 0.004)
        FA.box(&m, V3(lw, 0.06, 0.05), V3(cx, H - 0.03, lz), coat, r: 0.004)
        for x in [x0 + 0.03, x1 - 0.03] as [Float] { FA.box(&m, V3(0.06, H - by0, 0.05), V3(x, (H + by0) / 2, lz), coat, r: 0.004) }
        for y in [0.62, 1.2] as [Float] { FA.box(&m, V3(lw - 0.1, 0.04, 0.04), V3(cx, y, lz - 0.003), coat, r: 0.003) }
        // Vertical support bars every 0.9 m behind the slats.
        let bars = 5
        for k in 0..<bars {
            let x = x0 + 0.06 + (lw - 0.12) * Float(k) / Float(bars - 1)
            FA.box(&m, V3(0.04, H - by0 - bh - 0.06, 0.04), V3(x, (H + by0 + bh - 0.06 + 0.0) / 2 - 0.0, lz - 0.004), coat, r: 0.003)
        }
        // Horizontal aluminium slats: 95 mm face, 14 mm deep, tongue-and-groove gaps; end caps.
        let sy0: Float = by0 + bh + 0.015, sy1: Float = H - 0.075
        let ns = Int((sy1 - sy0) / 0.105)
        for k in 0..<ns {
            var r = rng.fork(k)
            let y = sy0 + 0.0475 + Float(k) * 0.105
            FA.box(&m, V3(lw - 0.12, 0.095, 0.016), V3(cx, y, lz + 0.014), k % 2 == 0 ? slat : slatDark, r: 0.0025)
            // Stainless pan-head fixings at each vertical support, black plastic end caps.
            for b in 0..<bars {
                let bx = x0 + 0.06 + (lw - 0.12) * Float(b) / Float(bars - 1)
                if abs(bx) < lw / 2 - 0.08 || true { FGate.slab(&m, V3(0.007, 0.007, 0.003), V3(bx, y, lz + 0.0235), "metal.nickel-worn") }
            }
            for ex in [-1, 1] as [Float] { FA.box(&m, V3(0.008, 0.095, 0.017), V3(cx + ex * (lw - 0.12) / 2, y, lz + 0.014), "plastic.black", r: 0.0015) }
            FA.box(&m, V3(lw - 0.12 - 0.01, 0.012, 0.01), V3(cx, y - 0.0535, lz + 0.01), slat, r: 0.001)
            // Grime and scuffs on the lowest slats.
            if k < 3 && r.chance(0.8) { FGate.slab(&m, V3(r.float(0.2...0.6), 0.03, 0.002), V3(cx + r.float(-1...1), y - 0.02, lz + 0.0225), zinc) }
        }
        // Road-splash grime band on the lower slats and rust runs from the rack.
        FGate.slab(&m, V3(lw - 0.14, 0.11, 0.002), V3(cx, sy0 + 0.055, lz + 0.0225), "metal.rust-grime")
        for k in 0..<7 {
            var r = rng.fork(150 + k)
            FGate.slab(&m, V3(r.float(0.015...0.03), r.float(0.1...0.3), 0.002), V3(r.float(x0 + 0.2...x1 - 0.2), sy0 + 0.25, lz + 0.0228), "metal.rust-grime")
        }
        // Drive rack on the face of the bottom rail: plate and ~31 mm pitch teeth.
        FA.box(&m, V3(lw - 0.2, 0.03, 0.006), V3(cx, by0 + 0.06, lz + 0.028), zinc, r: 0.001)
        var tx = x0 + 0.1
        while tx < x1 - 0.1 {
            FGate.slab(&m, V3(0.017, 0.018, 0.009), V3(tx, by0 + 0.06, lz + 0.031), zinc)
            tx += 0.0314
        }
        // Carriage posts: two cassette posts behind the leaf, each with two nylon rollers on the track flange.
        for px in [-0.35, 0.8] as [Float] {
            FA.box(&m, V3(0.1, 0.62, 0.04), V3(px, 0.31, -0.017), coat, r: 0.004)
            FA.box(&m, V3(0.16, 0.012, 0.04), V3(px, 0.018, -0.017), zinc, r: 0.002)
            FA.box(&m, V3(0.42, 0.012, 0.082), V3(px, 0.006, 0.0), "concrete.rough", r: 0.003)
            for bx in [-0.06, 0.06] as [Float] { FA.box(&m, V3(0.014, 0.008, 0.014), V3(px + bx, 0.028, -0.017), "metal.nickel-worn", r: 0.002) }
            for dx in [-0.05, 0.05] as [Float] {
                m.add(Prim.cylinder(radius: 0.032, height: 0.03, bevel: 0.004, segments: 18, bevelSegments: 1, material: nylon),
                      Xform(translation: V3(px + dx, by0 - 0.02, 0.0), rotation: FA.q(90, FA.X)))
                FA.cylZ(&m, r: 0.008, h: 0.05, at: V3(px + dx, by0 - 0.02, -0.01), zinc, bevel: 0.001, segments: 10)
            }
            // Top plate with a nylon guide roller.
            FA.box(&m, V3(0.1, 0.02, 0.04), V3(px, 0.62, -0.017), zinc, r: 0.002)
        }
        // Tail wheels at the free end carrying the counterbalance.
        for dx in [0.1, 0.5] as [Float] {
            FA.box(&m, V3(0.05, 0.1, 0.02), V3(x0 + dx, by0 - 0.04, lz + 0.0), zinc, r: 0.002)
            m.add(Prim.cylinder(radius: 0.04, height: 0.022, bevel: 0.004, segments: 18, bevelSegments: 1, material: nylon),
                  Xform(translation: V3(x0 + dx, 0.04, lz - 0.011), rotation: FA.q(90, FA.X)))
        }
        // Receiver post (right) with catch bracket and a protective cap.
        let rx = W / 2 - 0.05
        FA.box(&m, V3(0.1, H - 0.012, 0.05), V3(rx, (H + 0.012) / 2, lz), coat, r: 0.004)
        FA.box(&m, V3(0.3, 0.012, 0.082), V3(rx - 0.1, 0.006, 0.0), "concrete.rough", r: 0.003)
        FA.box(&m, V3(0.11, 0.02, 0.06), V3(rx, H - 0.01, lz), coat, r: 0.003)
        FA.box(&m, V3(0.05, 0.12, 0.035), V3(rx - 0.075, 1.15, lz), zinc, r: 0.003)
        FA.box(&m, V3(0.035, 0.07, 0.06), V3(rx - 0.04, 1.15, lz), zinc, r: 0.003)
        // Photocell pair and a rubber edge strip on the leading stile.
        FA.box(&m, V3(0.05, 0.08, 0.03), V3(rx - 0.07, 0.35, lz + 0.0), "plastic.black", r: 0.004)
        FA.box(&m, V3(0.012, H - by0 - 0.1, 0.04), V3(x1 + 0.006, (H + by0) / 2 - 0.02, lz), "plastic.black", r: 0.003)
        // Weld toes and rust at the foot of the receiver post and carriage posts.
        for k in 0..<9 {
            var r = rng.fork(90 + k)
            FA.box(&m, V3(r.float(0.02...0.05), r.float(0.02...0.06), 0.0505), V3(r.float(x0 + 0.1...x1 - 0.1), by0 + r.float(0.02...0.1), lz), rust, r: 0.001)
        }
        FA.box(&m, V3(0.102, 0.08, 0.0505), V3(rx, 0.05, lz), rust, r: 0.001)
        groundAO(&m, height: 0.2, floor: 0.5)
        return LODModel(FC.place(m))
    }
}
