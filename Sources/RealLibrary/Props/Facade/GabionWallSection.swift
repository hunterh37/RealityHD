import simd
import Foundation

/// Gabion wall section: architectural facade customizer, Contemporary. Parts: welded wire cages, stacked stone fill, corner posts, spiral binders, top lid mesh, stone variation, stepped cells.
public struct GabionWallSection: RealAsset {
    public static let id = "gabion-wall-section"
    public static let summary = "Contemporary gabion wall, galvanized welded wire baskets filled with angular stone"
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 1.0, 0.4)
    public init() {}

    /// Fill stone mix (angular quarry stone, 100-160 mm).
    public var stones: [MaterialKey] = ["stone.wall-block", "stone.granite-paver", "stone.limestone", "stone.slate", "stone.wall-block", "stone.granite-paver", "stone.limestone", "stone.wall-block"]
    /// Moss on some north-face stones.
    public var moss: MaterialKey = "stone.granite-moss"
    /// Welded wire mesh (galvanised, aged).
    public var wire: MaterialKey = "metal.galvanized-aged"
    /// Bright spiral binders and edge rods.
    public var binder: MaterialKey = "metal.galvanized"
    /// Rust at the cut ends and base.
    public var rust: MaterialKey = "metal.rust-grime"
    /// Wire grid pitch in meters.
    public var pitch: Float = 0.1

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Cage dimensions: the stone tips and mesh add about 12 mm on every outer face.
        let W = size.x - 0.095, H = size.y - 0.09, D = size.z - 0.083
        let hw = W / 2, hd = D / 2
        // Dark core so the voids between stones read as shadow.
        FA.box(&m, V3(W - 0.02, H - 0.02, D - 0.02), V3(0, H / 2, 0), "stone.granite-paver", r: 0.003)
        // Angular stone shell: a jittered grid of non-uniform stones on every visible face, rotated at random.
        // axis 0/1/2 is the outward normal; `out` is the signed face position.
        func stone(_ u: Float, _ v: Float, axis: Int, out: Float, _ r: inout SeededRNG, fine: Bool = false) {
            let t = r.float(0.09...0.12)                          // depth along the normal
            let a = r.float(0.15...0.22), b = r.float(0.13...0.2)   // tangential sizes
            let sz: V3 = axis == 0 ? V3(t, a, b) : (axis == 1 ? V3(a, t, b) : V3(a, b, t))
            let sign: Float = out < 0 ? -1 : 1
            let off = out - sign * (t / 2 - 0.016 - r.float(0...0.008))
            let c: V3 = axis == 0 ? V3(off, u, v) : (axis == 1 ? V3(u, off, v) : V3(u, v, off))
            let mat = r.chance(0.05) ? moss : stones[r.int(0...(stones.count - 1))]
            let ph = r.float(0...6.28)
            var st = Prim.superellipsoid(sz, exponent: fine ? 3.0 : 3.4, subdivisions: fine ? 2 : 1, material: mat,
                                         bulge: { d in 0.92 + 0.08 * sin(7 * d.x + ph) * cos(5 * d.y - ph) - 0.05 * abs(sin(9 * d.z + ph)) })
            let uvk: Float = fine ? 1.6 : 5
            st.uvs = st.uvs.map { V2($0.x * uvk, $0.y * uvk) }
            st.computeTangents()
            let nrm: V3 = axis == 0 ? FA.X : (axis == 1 ? FA.Y : FA.Z)
            let spin = simd_quatf(angle: r.float(0...6.28), axis: nrm)
            let tilt = FA.q(r.float(-10...10), FA.X) * FA.q(r.float(-10...10), FA.Z)
            m.add(st, Xform(translation: c, rotation: spin * tilt))
        }
        let step: Float = 0.1
        let nx = Int(W / step), ny = Int(H / step), nz = Int(D / step)
        for face in [-1, 1] as [Float] {
            var r = rng.fork(face > 0 ? 1 : 2)
            let fx = face > 0 ? Int(W / 0.118) : nx, fy = face > 0 ? Int(H / 0.118) : ny
            for i in 0..<fx { for j in 0..<fy {
                stone(-hw + (Float(i) + 0.5) * (W / Float(fx)) + r.float(-0.012...0.012), (Float(j) + 0.5) * (H / Float(fy)) + r.float(-0.012...0.012), axis: 2, out: face * hd, &r, fine: face > 0)
            } }
        }
        do {
            var r = rng.fork(3)
            for i in 0..<nx { for k in 0..<nz {
                stone(-hw + (Float(i) + 0.5) * (W / Float(nx)) + r.float(-0.012...0.012), -hd + (Float(k) + 0.5) * (D / Float(nz)) + r.float(-0.012...0.012), axis: 1, out: H, &r)
            } }
            for sx in [-1, 1] as [Float] {
                for j in 0..<ny { for k in 0..<nz {
                    stone((Float(j) + 0.5) * (H / Float(ny)), -hd + (Float(k) + 0.5) * (D / Float(nz)), axis: 0, out: sx * hw, &r)
                } }
            }
        }
        // Welded mesh outside the stones: 4.5 mm wire on a 100 mm grid, wires crossing in two layers.
        func line(_ len: Float, _ c: V3, axis: Int, _ t: Float = 0.0045, _ mat: MaterialKey? = nil) {
            let size: V3 = axis == 0 ? V3(len, t, t) : (axis == 1 ? V3(t, len, t) : V3(t, t, len))
            FG.slab(&m, size, c, mat ?? wire)
        }
        for face in [-1, 1] as [Float] {
            let z = face * (hd + 0.0145)
            for k in 0...Int(W / pitch) { line(H, V3(-hw + Float(k) * pitch + (W - Float(Int(W / pitch)) * pitch) / 2, H / 2, z), axis: 1) }
            for j in 0...Int(H / pitch) { line(W, V3(0, Float(j) * pitch, z + face * 0.0045), axis: 0) }
        }
        for k in 0...Int(W / pitch) { line(D, V3(-hw + Float(k) * pitch + (W - Float(Int(W / pitch)) * pitch) / 2, H + 0.0145, 0), axis: 2) }
        for k in 0...Int(D / 0.1) { line(W, V3(0, H + 0.019, -hd + Float(k) * 0.1 + (D - Float(Int(D / 0.1)) * 0.1) / 2), axis: 0) }
        for sx in [-1, 1] as [Float] {
            let x = sx * (hw + 0.0145)
            for k in 0...Int(D / 0.1) { line(H, V3(x, H / 2, -hd + Float(k) * 0.1 + (D - Float(Int(D / 0.1)) * 0.1) / 2), axis: 1) }
            for j in 0...Int(H / pitch) { line(D, V3(x + sx * 0.0045, Float(j) * pitch, 0), axis: 2) }
        }
        // Edge rods (7 mm) at the cell boundaries, and spiral binders along the vertical corners and the mid joint.
        for y in [0.0, 0.5, H] as [Float] {
            for face in [-1, 1] as [Float] { line(W + 0.02, V3(0, y == 0 ? 0.004 : y, face * (hd + 0.0215)), axis: 0, 0.007, binder) }
        }
        for x in [-hw, 0, hw] as [Float] {
            for face in [-1, 1] as [Float] {
                line(H, V3(x, H / 2, face * (hd + 0.0215)), axis: 1, 0.007, binder)
                var y: Float = 0.04
                while y < H - 0.02 {
                    FG.slab(&m, V3(0.006, 0.024, 0.0095), V3(x, y, face * (hd + 0.0215)), binder, rot: FA.q(35 * face, FA.X))
                    y += 0.075
                }
            }
        }
        // Wear: rust at the lowest wires, soil splash, a bent wire end.
        for k in 0..<10 {
            var r = rng.fork(60 + k)
            FG.slab(&m, V3(r.float(0.04...0.12), r.float(0.03...0.06), 0.0015), V3(r.float(-hw + 0.1...hw - 0.1), r.float(0.02...0.16), (r.chance(0.5) ? 1 : -1) * (hd + 0.0215)), rust)
        }
        groundAO(&m, height: 0.25, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
