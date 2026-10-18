import simd
import Foundation

/// EFEM wafer-handling robot, 1 x 1.5 x 1 m: SCARA arm on a lift column. Arm folded in a Z so the footprint stays in the
/// envelope. Named parts: column-lift (slides Y), shoulder, elbow, wrist (hinges about Y; fork carries the wafer).
public struct EfemRobot: RealArticulated {
    public static let id = "efem-robot"
    public static let summary = "SCARA wafer-handling robot with column, two-link arm, fork end-effector and cable carrier."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.0, studio: true)

    /// Cover color (sRGB hex).
    public var color: UInt32 = 0xEDEEEC
    public init() {}

    private func cc(_ k: ClusterKit, _ r: Float, _ h: Float, _ c: V3, _ mat: MaterialKey, seg: Int = 16, name: String? = nil) {
        k.cyl(r, h, c - V3(0, h / 2, 0), mat, seg: seg, name: name)
    }

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let white: MaterialKey = "plastic.matte:" + String(format: "%06X", color)
        let anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let steel: MaterialKey = "metal.stainless"
        let sy: Float = 1.3, sz: Float = -0.3      // shoulder pivot
        let ez: Float = sz + 0.42, wz: Float = ez - 0.38   // elbow, wrist
        rig.part("column-lift", pivot: V3(0, 0.8, 0), joint: .slide(axis: V3(0, 1, 0), 0...0.2, duration: 3))
        rig.part("shoulder", parent: "column-lift", pivot: V3(0, sy, sz), joint: .hinge(axis: .up, -150...150, duration: 2))
        rig.part("elbow", parent: "shoulder", pivot: V3(0, sy + 0.08, ez), joint: .hinge(axis: .up, -150...150, duration: 2))
        rig.part("wrist", parent: "elbow", pivot: V3(0, sy + 0.16, wz), joint: .hinge(axis: .up, -170...170, duration: 2))
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            // Pedestal, base cover, footplate.
            k.bb(V3(0.96, 0.03, 0.96), V3(0, 0.015, 0), anod, r: 0.003)
            k.bb(V3(0.84, 0.27, 0.84), V3(0, 0.165, 0), white, r: 0.006)
            k.bb(V3(0.78, 0.02, 0.78), V3(0, 0.31, 0), anod, r: 0.003)
            k.bb(V3(0.2, 0.1, 0.01), V3(0.2, 0.2, 0.425), black, r: 0.002)
            k.bb(V3(0.06, 0.012, 0.004), V3(0.14, 0.2, 0.432), "glass.lamp:30C050", r: 0.001)
            k.bb(V3(0.84, 0.006, 0.004), V3(0, 0.1, 0.422), "metal.powdercoat:9FA3A7", r: 0)
            if hi { for q in 0..<4 { cc(k, 0.012, 0.012, V3(((q % 2 == 0) ? -1 : 1) * 0.43, 0.036, ((q / 2 == 0) ? -1 : 1) * 0.43), steel, seg: 6) } }
            cc(k, 0.14, 0.03, V3(0, 0.335, 0), anod, seg: 24)
            // Fixed outer column sleeve behind the moving column.
            cc(k, 0.115, 0.5, V3(0, 0.57, 0), white, seg: 28)
            k.bb(V3(0.1, 0.5, 0.03), V3(0, 0.6, sz - 0.2), anod, r: 0.003)
            // Lift column (moving).
            let cl = "column-lift", sh = "shoulder", el = "elbow", wr = "wrist"
            cc(k, 0.1, 0.66, V3(0, 0.93, 0), white, seg: 28, name: cl)
            cc(k, 0.103, 0.02, V3(0, 0.62, 0), black, seg: 28, name: cl)
            k.bb(V3(0.1, 0.07, 0.1), V3(0, sy - 0.12, sz), "metal.aluminum-brushed", r: 0.003, name: cl)
            cc(k, 0.115, 0.04, V3(0, sy - 0.04, sz), anod, seg: 24, name: cl)
            // Shoulder: housing and link 1.
            cc(k, 0.105, 0.085, V3(0, sy - 0.0, sz), white, seg: 24, name: sh)
            k.bb(V3(0.17, 0.08, 0.5), V3(0, sy + 0.0, (sz + ez) / 2), white, r: 0.006, name: sh)
            cc(k, 0.075, 0.008, V3(0, sy + 0.04, sz), black, seg: 20, name: sh)
            cc(k, 0.06, 0.008, V3(0, sy + 0.04, ez), black, seg: 20, name: sh)
            if hi { for q in 0..<6 { let t = Float(q) / 6 * 2 * .pi; cc(k, 0.006, 0.006, V3(0.075 * cos(t), sy + 0.045, sz + 0.075 * sin(t)), steel, seg: 6, name: sh) } }
            // Elbow housing and link 2.
            cc(k, 0.09, 0.08, V3(0, sy + 0.08, ez), white, seg: 24, name: el)
            k.bb(V3(0.14, 0.07, 0.46), V3(0, sy + 0.08, (ez + wz) / 2), white, r: 0.006, name: el)
            cc(k, 0.05, 0.008, V3(0, sy + 0.12, ez), black, seg: 18, name: el)
            k.bb(V3(0.05, 0.012, 0.004), V3(0.0, sy + 0.1, ez + 0.082), "glass.lamp:F0A020", r: 0.001, name: el)
            // Wrist: hub and end-effector fork with wafer.
            cc(k, 0.06, 0.06, V3(0, sy + 0.16, wz), anod, seg: 20, name: wr)
            cc(k, 0.04, 0.01, V3(0, sy + 0.195, wz), black, seg: 16, name: wr)
            k.bb(V3(0.1, 0.012, 0.14), V3(0, sy + 0.19, wz + 0.1), "metal.aluminum-brushed", r: 0.002, name: wr)
            for q: Float in [-1, 1] {
                k.bb(V3(0.024, 0.008, 0.32), V3(q * 0.045, sy + 0.19, wz + 0.26), steel, r: 0.001, name: wr)
                for pz: Float in [0.2, 0.38] { cc(k, 0.007, 0.004, V3(q * 0.045, sy + 0.198, wz + pz), "rubber.tubing", seg: 8, name: wr) }
            }
            k.put(Prim.cylinder(radius: 0.15, height: 0.00078, bevel: 0, segments: hi ? 40 : 16, material: "silicon.thinfilm"),
                  Xform(translation: V3(0, sy + 0.206, wz + 0.2)), wr)
            // Cable carrier: chain links along a curve from the base to the column back.
            let pts = catmull([V3(0, 0.34, -0.2), V3(0, 0.32, -0.4), V3(0, 0.65, -0.46), V3(0, 1.0, -0.38), V3(0, 1.2, -0.26)], per: hi ? 5 : 2)
            for i in 0..<(pts.count - 1) {
                let a = pts[i], b = pts[i + 1], d = b - a, len = simd_length(d)
                if len < 0.002 { continue }
                let q = simd_quatf(from: V3(0, 0, 1), to: d / len)
                k.put(cuboid(V3(0.08, 0.035, len * 0.92), material: i % 2 == 0 ? "plastic.matte:2A2C2F" : "plastic.matte:3A3C40"),
                      Xform(translation: (a + b) / 2, rotation: q))
            }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.1, floor: 0.5)
        rig.states = [RigState("idle"), RigState("reach", ["shoulder": 40, "elbow": -80, "wrist": 40])]
        return rig
    }
}
