import simd
import Foundation

/// Moorish horseshoe arch window: stucco wall plate with a raised alfiz frame, a horseshoe arch of
/// alternating brick and limestone voussoirs on impost blocks and engaged colonnettes, a diagonal wood
/// lattice over glass, and a stone sill with a drip groove. Wall plane at z = 0.
public struct MoorishHorseshoeArchWindow: RealAsset {
    public static let id = "moorish-horseshoe-arch-window"
    public static let summary = "Moorish horseshoe arch window, 0.9 x 1.8 m: alternating brick and limestone voussoirs, alfiz frame, colonnettes, lattice and glass."
    public static let tags = ["prop", "architecture", "facade", "stone", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 3.0)

    public var width: Float = 0.9
    public var height: Float = 1.8
    /// Intrados radius (m), height of the arch circle centre, and how far the circle runs below the springing line (degrees).
    public var radius: Float = 0.24
    public var centerY: Float = 1.32
    public var overhang: Float = 20
    /// Voussoir ring depth (m).
    public var ringDepth: Float = 0.1
    public var plaster: MaterialKey = "paint.stucco:E3D3B2"
    public var stone: MaterialKey = "stone.limestone-sooted"
    public var brick: MaterialKey = "brick.red"
    public var timber: MaterialKey = "wood.deadwood"
    public var glass: MaterialKey = "glass.tinted"
    public init() {}

    private func opening(_ r: Float, _ cy: Float, _ th: Float, floor y0: Float, steps: Int = 28) -> [V2] {
        let j = r * cos(th), ys = cy - r * sin(th)
        var pts: [V2] = [V2(j, y0), V2(j, ys)]
        let a0 = -th, a1 = Float.pi + th
        for i in 1..<steps {
            let a = a0 + (a1 - a0) * Float(i) / Float(steps)
            pts.append(V2(r * cos(a), cy + r * sin(a)))
        }
        pts += [V2(-j, ys), V2(-j, y0)]
        return pts
    }
    /// Extrudes an XY outline between z0 and z1.
    private func slab(_ m: inout Model, _ o: [V2], _ z0: Float, _ z1: Float, _ mat: MaterialKey, bevel: Float = 0.002) {
        m.add(Prim.extrude(o, depth: z1 - z0, bevel: bevel, bevelSegments: 1, material: mat),
              Xform(translation: V3(0, 0, (z0 + z1) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, r = radius, cy = centerY, th = overhang * .pi / 180
        let R = r + ringDepth, j = r * cos(th), ys = cy - r * sin(th)
        let hw = W / 2, sill: Float = 0.07

        // Stucco wall plate with the horseshoe opening cut from the bottom edge.
        let op = opening(r, cy, th, floor: sill)
        var plateOutline: [V2] = [V2(-hw, 0), V2(-j, 0)]
        plateOutline += Array(op.dropFirst().dropLast().reversed())
        plateOutline += [V2(j, 0), V2(hw, 0), V2(hw, H), V2(-hw, H)]
        slab(&m, plateOutline, 0, 0.05, plaster, bevel: 0.003)

        // Alfiz: raised rectangular frame (ogee-faced stone bands).
        let f: Float = 0.05
        FA.box(&m, V3(f, H - 0.02, 0.04), V3(-hw + f / 2 + 0.01, H / 2 + 0.01, 0.07), stone, r: 0.004)
        FA.box(&m, V3(f, H - 0.02, 0.04), V3(hw - f / 2 - 0.01, H / 2 + 0.01, 0.07), stone, r: 0.004)
        FA.box(&m, V3(W - 0.02, f, 0.04), V3(0, H - f / 2 - 0.01, 0.07), stone, r: 0.004)
        // Inner fillet bead running inside the alfiz.
        FA.box(&m, V3(0.012, H - 0.12, 0.012), V3(-hw + f + 0.03, (H - 0.02) / 2 + 0.01, 0.096), stone, r: 0.003)
        FA.box(&m, V3(0.012, H - 0.12, 0.012), V3(hw - f - 0.03, (H - 0.02) / 2 + 0.01, 0.096), stone, r: 0.003)
        FA.box(&m, V3(W - 2 * f - 0.05, 0.012, 0.012), V3(0, H - f - 0.03, 0.096), stone, r: 0.003)

        // Voussoirs, ten degrees each, alternating brick and limestone with 2 mm joints.
        let a0 = -th, a1 = Float.pi + th
        let n = 22
        let step = (a1 - a0) / Float(n)
        for i in 0..<n {
            let ia = a0 + Float(i) * step + 0.004, ib = a0 + Float(i + 1) * step - 0.004
            let isStone = i % 2 == 0
            let ro = R + (isStone ? 0.012 : 0) + rng.float(-0.002...0.002)
            let ri = r - 0.004
            let q: [V2] = [V2(ri * cos(ia), cy + ri * sin(ia)), V2(ro * cos(ia), cy + ro * sin(ia)),
                           V2(ro * cos(ib), cy + ro * sin(ib)), V2(ri * cos(ib), cy + ri * sin(ib))]
            // one replaced brick voussoir in a duller common brick, the story detail of the arch
            let mat: MaterialKey = isStone ? stone : (i == 7 ? "brick.common" : brick)
            slab(&m, q, 0.04, 0.04 + 0.075 + (isStone ? 0.006 : 0), mat, bevel: 0.003)
        }
        // Extrados rope moulding around the ring.
        var arc: [V3] = []
        for i in 0...36 {
            let a = a0 + (a1 - a0) * Float(i) / 36
            arc.append(V3((R + 0.026) * cos(a), cy + (R + 0.026) * sin(a), 0.052))
        }
        FA.path(&m, arc, r: 0.007, stone, sides: 6)

        // Impost blocks where the arch springs, and engaged colonnettes below.
        for s: Float in [-1, 1] {
            let xc = s * (r + R) / 2 * cos(th)
            FA.box(&m, V3(0.15, 0.04, 0.1), V3(xc, ys - 0.02, 0.09), stone, r: 0.004)
            FA.box(&m, V3(0.16, 0.012, 0.105), V3(xc, ys - 0.046, 0.0925), stone, r: 0.002)
            let cx = xc, base: Float = sill
            // Colonnette: attic base, smooth shaft with entasis, flared Caliphal capital.
            let prof: [V2] = [V2(0.001, base), V2(0.034, base), V2(0.034, base + 0.012), V2(0.029, base + 0.02), V2(0.022, base + 0.026),
                              V2(0.02, base + 0.05), V2(0.0215, base + 0.4), V2(0.02, ys - 0.15),
                              V2(0.02, ys - 0.1), V2(0.03, ys - 0.085), V2(0.036, ys - 0.07), V2(0.046, ys - 0.058), V2(0.052, ys - 0.052), V2(0.001, ys - 0.052)]
            m.add(Prim.lathe(prof, segments: 20, seamTile: 0.3, material: "stone.cast-stone"), Xform(translation: V3(cx, 0, 0.075)))
            for k in 0..<8 {   // carved leaf notches on the capital
                let a = Float(k) / 8 * 2 * .pi
                FC.bead(&m, r: 0.006, at: V3(cx + 0.034 * cos(a), ys - 0.072, 0.075 + 0.034 * sin(a)), "stone.cast-stone", sub: 2)
            }
        }

        // Spalled stucco low on the left exposes the brick beneath; a pale lime-render patch sits above it.
        let spall: [V2] = [V2(-0.43, 0.2), V2(-0.36, 0.19), V2(-0.33, 0.26), V2(-0.35, 0.33), V2(-0.3, 0.38), V2(-0.37, 0.43), V2(-0.43, 0.4)]
        slab(&m, spall, 0.05, 0.057, "brick.common", bevel: 0.002)
        for k in 0..<4 {
            FA.box(&m, V3(0.1, 0.004, 0.003), V3(-0.38, 0.22 + Float(k) * 0.06, 0.0585), "paint.stucco:9C9486", r: 0.001)
        }
        slab(&m, [V2(0.31, 1.05), V2(0.43, 1.05), V2(0.43, 1.2), V2(0.31, 1.2)], 0.05, 0.053, "paint.stucco:F0E6CF", bevel: 0.002)
        // Window: glass behind, timber frame around the opening and a diagonal lattice.
        let inner = opening(r - 0.002, cy, th, floor: sill)
        slab(&m, inner, 0.035, 0.041, glass, bevel: 0.001)
        let framePath: [V3] = Array(opening(r - 0.014, cy, th, floor: sill, steps: 36).dropLast().dropFirst()).map { V3($0.x, $0.y, 0.05) }
        m.add(Prim.tube(framePath, radii: Array(repeating: 0.011, count: framePath.count), sides: 4, seamTile: 0.2, material: timber, capEnd: true))
        func inside(_ x: Float, _ y: Float) -> Bool {
            if y < sill + 0.012 { return false }
            if y < ys { return abs(x) < j - 0.016 }
            return hypot(x, y - cy) < r - 0.016
        }
        let pitch: Float = 0.085
        for fam in 0..<2 {
            let sgn: Float = fam == 0 ? 1 : -1
            let z: Float = fam == 0 ? 0.052 : 0.062
            var c: Float = -0.4
            while c < 2.1 {
                c += pitch * 1.4142
                // line: y = sgn * x + c
                var run: (V2, V2)? = nil
                var x: Float = -0.3
                while x <= 0.3 + 0.0001 {
                    let y = sgn * x + c, ins = inside(x, y)
                    if ins { run = (run?.0 ?? V2(x, y), V2(x, y)) }
                    if (!ins || x + 0.004 > 0.3) , let rn = run {
                        if simd_length(rn.1 - rn.0) > 0.03 {
                            FA.rod(&m, V3(rn.0.x, rn.0.y, z), V3(rn.1.x, rn.1.y, z), r: 0.0065, timber, sides: 4)
                        }
                        run = nil
                    }
                    x += 0.004
                }
            }
        }
        // Wrought iron pins at the lattice meeting the frame.
        for k in 0..<5 {
            let a = a0 + (a1 - a0) * (Float(k) + 0.5) / 5
            let p = V3((r - 0.014) * cos(a), cy + (r - 0.014) * sin(a), 0.062)
            FC.bead(&m, r: 0.006, at: p, "metal.wrought-iron", sub: 2)
        }

        // Stone sill, 0.2 m deep with drip groove and weathered slope.
        let sp: [V2] = [V2(0, 0.0), V2(0.2, 0.0), V2(0.2, 0.03), V2(0.18, 0.045), V2(0.08, 0.06), V2(0, 0.06)]
        FA.run(&m, sp, length: W - 0.02, at: V3(0, 0.0, 0), stone, bevel: 0.003)
        FA.box(&m, V3(W - 0.1, 0.004, 0.006), V3(0, 0.006, 0.186), "stone.limestone-sooted", r: 0.001)

        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
