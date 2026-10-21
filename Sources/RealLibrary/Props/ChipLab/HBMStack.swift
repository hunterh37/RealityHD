import simd
import Foundation

/// HBM5 memory stack, 11 x 10 mm footprint: base logic die with exposed margin and pin-1 mark, sixteen
/// thinned DRAM dies with chamfered silicon edges and slight lateral stepping, underfill fillets in every
/// bond line, rows of copper microbumps at the front and back edges, and molded epoxy sidewalls on the
/// left and right. Parts: base-die, dram-01 ... dram-16, mold-left, mold-right; state "exploded" lifts layers.
public struct HBMStack: RealArticulated {
    public static let id = "hbm-stack"
    public static let summary = "HBM5 stack: base logic die, 16 thinned DRAM dies with edge sheen, underfill fillets, copper microbump rows and molded sidewalls; explodes."
    public static let tags = ["prop", "chiplab", "electronics", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 24, distance: 0.9, studio: true)

    /// Base die footprint (m).
    public var footprint = V2(0.011, 0.010)
    /// DRAM die count.
    public var layers = 16
    /// Microbumps per row.
    public var bumpsPerRow = 12
    public var dieEdge: MaterialKey = "silicon.die-edge"
    public var dieFace: MaterialKey = "silicon.die"
    public var bump: MaterialKey = "metal.copper"
    public var fill: MaterialKey = "plastic.underfill:6B5230"
    public var mold: MaterialKey = "plastic.underfill:16120E"
    public init() {}

    func box(_ s: V3, _ r: Float, _ seg: Int = 1, _ mat: MaterialKey) -> Surface {
        Prim.roundedBox(s, radius: r, bevelSegments: seg, material: mat)
    }

    public func rig(seed: UInt64) -> Rig {
        let rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let W = footprint.x, D = footprint.y
        let baseT: Float = 0.00014, dieT: Float = 0.00008, gap: Float = 0.00005, topT: Float = 0.00012
        let dW = W - 0.0014, dD = D - 0.0016
        let pitch = dieT + gap
        let n = layers

        rig.base[0] = Model(name: Self.id)
        let stackTop = baseT + Float(n - 1) * pitch + gap + topT
        let spread = Float(n) * 0.0011 + 0.001

        // Base logic die: edge body, polished face inset, pin-1 triangle, SoC-side copper pad rows at the margin.
        _ = rig.part("base-die", pivot: V3(0, 0, 0), joint: .slide(axis: V3(0, -1, 0), 0...0.002, duration: 0.8))
        rig.add(box(V3(W, baseT, D), 0.000012, 2, dieEdge), Xform(translation: V3(0, baseT / 2, 0)), to: "base-die")
        rig.add(box(V3(W - 0.00014, 0.000012, D - 0.00014), 0.000004, 1, dieFace), Xform(translation: V3(0, baseT + 0.000002, 0)), to: "base-die")
        for sz: Float in [-1, 1] {
            for k in 0..<14 {
                let x = (Float(k) - 6.5) * 0.00070
                rig.add(Prim.lathe([V2(0.000085, 0), V2(0.000085, 0.00002)], segments: 6, seamTile: 1, material: bump),
                        Xform(translation: V3(x, baseT + 0.000008, sz * (D / 2 - 0.0003))), to: "base-die")
            }
        }
        rig.add(Prim.extrude([V2(0, 0), V2(0.0004, 0), V2(0, 0.0004)], depth: 0.000012, bevel: 0.000002, bevelSegments: 1, material: bump),
                Xform(translation: V3(-W / 2 + 0.0003, baseT + 0.000012, D / 2 - 0.0007), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))), to: "base-die")

        // DRAM dies: each part carries its die, the fillet and microbumps in the bond line under it.
        for i in 0..<n {
            let name = String(format: "dram-%02d", i + 1)
            let y0 = baseT + Float(i) * pitch + gap
            let last = i == n - 1
            let t = last ? topT : dieT
            _ = rig.part(name, pivot: V3(0, y0 - gap, 0), joint: .slide(axis: V3(0, 1, 0), 0...spread, duration: 0.9))
            var r = rng.fork(i)
            let dx = r.float(-0.00016...0.00016), dz = r.float(-0.00012...0.00012)
            let cx = dx, cz = dz
            // Bond line: underfill with side fillets, and bump rows right at the front and back edges.
            rig.add(box(V3(dW + 0.00011, gap + 0.00001, dD - 0.0002), 0.000018, 1, fill),
                    Xform(translation: V3(cx, y0 - gap / 2, cz)), to: name)
            for sz: Float in [-1, 1] {
                for k in 0..<bumpsPerRow {
                    let x = (Float(k) - Float(bumpsPerRow - 1) / 2) * ((dW - 0.0008) / Float(bumpsPerRow - 1))
                    rig.add(Prim.lathe([V2(0.000011, 0), V2(0.000024, gap + 0.000006)], segments: 6, seamTile: 1, material: bump),
                            Xform(translation: V3(cx + x, y0 - gap - 0.000003, cz + sz * (dD / 2 - 0.00004))), to: name)
                }
            }
            // Thinned die: chamfered diced edge, polished face on the topmost die.
            rig.add(box(V3(dW, t, dD), 0.000014, 1, dieEdge), Xform(translation: V3(cx, y0 + t / 2, cz)), to: name)
            if last {
                rig.add(box(V3(dW - 0.00012, 0.000008, dD - 0.00012), 0.000003, 1, dieFace), Xform(translation: V3(cx, y0 + t + 0.000001, cz)), to: name)
            }
        }

        // Molded epoxy sidewalls, left and right, with a rounded outer top edge. One bubble void as the story detail.
        let mw: Float = 0.00060, mh = stackTop - baseT * 0.2
        for (s, nm) in [(Float(-1), "mold-left"), (1, "mold-right")] {
            _ = rig.part(nm, pivot: V3(s * (dW / 2 + 0.0002), 0, 0), joint: .slide(axis: V3(s, 0, 0), 0...0.006, duration: 0.8))
            rig.add(box(V3(mw, mh, D - 0.0006), 0.00005, 2, mold),
                    Xform(translation: V3(s * (dW / 2 + 0.00012 + mw / 2 + 0.00003), baseT * 0.2 + mh / 2, 0)), to: nm)
            rig.add(Prim.lathe([V2(0.00004, 0), V2(0.00004, 0.000012)], segments: 6, seamTile: 1, material: "plastic.underfill"),
                    Xform(translation: V3(s * (dW / 2 + 0.00012 + mw), baseT + 0.0003, 0.0011), rotation: simd_quatf(degrees: s * 90, axis: V3(0, 0, 1))), to: nm)
        }

        let ex: [String: Float] = Dictionary(uniqueKeysWithValues: (1...n).map { (String(format: "dram-%02d", $0), Float($0) * 0.0011) })
        rig.states = [
            RigState("assembled"),
            RigState("exploded", ex.merging(["base-die": 0.001, "mold-left": 0.004, "mold-right": 0.004]) { a, _ in a }),
        ]
        return rig
    }
}
