import simd
import Foundation

/// American giant millipede (Narceus americanus), 10 cm: cylindrical dark brown-black body of 45 rings, each with a pale reddish-brown rear margin, two short leg pairs per ring, short antennae and a tapered tail.
public struct Millipede: RealArticulated {
    public static let id = "insect-millipede"
    public static let summary = "Giant millipede, 10 cm: cylindrical brown-black body, 45 rings with pale rear margins, two leg pairs per ring, short antennae; segment chain for walking wave."
    public static let tags = ["nature", "insect", "crawling", "articulated"]
    public static let budget = 28_000
    public static let preview = PreviewHint(azimuth: 40, elevation: 35, distance: 1.0, ground: false, studio: true)
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        let n = 45
        let seg: Float = 0.0022
        let z0 = Float(n) * seg * 0.5
        func rad(_ t: Float) -> Float {
            let tail = t > 0.88 ? max(0.25, 1 - (t - 0.88) / 0.12 * 0.75) : 1
            let head = t < 0.06 ? 0.8 + t / 0.06 * 0.2 : 1
            return 0.0038 * tail * head
        }
        var s = InsectKit.Segmented(name: Self.id, count: n, segLength: seg,
                                    radius: { t in V2(rad(t), rad(t) * 0.97) },
                                    centerY: { t in rad(t) + 0.0004 }, material: { i in ["insect.chitin:2A1E18", "insect.chitin:33241B", "insect.chitin:2D2019", "insect.chitin:382819"][(i * 7 + i / 5) % 4] })
        s.height = 0.0085
        s.subDrop = 3
        s.neck = V3(0, 0.0042, z0)
        s.head = [.init(V3(0, 0.0038, z0 + 0.0014), V3(0.0030, 0.0026, 0.0024), "insect.chitin:3A281E"),
                  .init(V3(0.0017, 0.0042, z0 + 0.0022), V3(0.0004, 0.0004, 0.0004), "insect.eye", mirror: true)]
        s.antenna = .init(base: V3(0.0012, 0.0044, z0 + 0.0034), dir: V3(0.3, -0.05, 0.95), length: 0.006, radius: 0.00032, curve: 0.15, beads: 7)
        s.antennaMat = "insect.chitin:4A3224"
        s.legMat = "insect.chitin-soft:8A5A3C"
        func leg(_ i: Int, _ zOff: Float) -> InsectKit.Leg {
            let t = n > 1 ? Float(i) / Float(n - 1) : 0
            let r = rad(t)
            return InsectKit.Leg(attach: V3(r * 0.55, 0.0012, z0 - Float(i) * seg - zOff), side: 1, yaw: -80, coxa: 0.0002,
                                 femur: 0.0015, tibia: 0.0013, tarsus: 0.0008, lift: -25, radius: 0.00011, bulge: 1)
        }
        s.leg = { i in leg(i, seg * 0.3) }
        s.axis = V3(0, 1, 0)
        s.range = -14...14
        s.extra = { rig, d, L, zf in
            for i in 0..<n {
                let t = Float(i) / Float(n - 1)
                let r = rad(t)
                let zc = zf(i) - seg * 0.5
                let r2 = rad(min(1, t + 1 / Float(n - 1)))
                rig.add(InsectKit.limb([V3(0, r + 0.0004, zf(i) - seg * 0.02), V3(0, r2 + 0.0004, zf(i) - seg * 0.98)], radii: [r * 0.97, r2 * 0.97],
                                       material: "insect.chitin:2A1E18", sides: 12, per: 1), to: "segment-\(i)", lods: L)
                rig.add(InsectKit.blob(V3(0, r + 0.0004, zc - seg * 0.40), V3(r * 1.035, r * 1.02, seg * 0.17),
                                       material: ["insect.chitin:6A3624", "insect.chitin:753D28", "insect.chitin:5E301F"][i % 3], sub: 0), to: "segment-\(i)", lods: L)
                for side: Float in [1, -1] {
                    for zo: Float in [0.3, 0.78] {
                        let x = side * r * 0.6, z = zf(i) - seg * zo
                        rig.add(InsectKit.limb([V3(x, 0.0014, z), V3(x * 1.3, 0.0, z + 0.0004)],
                                               radii: [0.00018, 0.00009], material: "insect.chitin-soft:8A5A3C", sides: 4, per: 1), to: "segment-\(i)", lods: L)
                    }
                }
            }
            for side: Float in [1, -1] {
                rig.add(InsectKit.blob(V3(side * 0.0014, 0.0030, z0 + 0.0010), V3(0.0009, 0.0008, 0.0012),
                                       material: "insect.chitin:4A3224", sub: 2), to: "head", lods: L)
            }
        }
        s.states = [RigState("rest"),
                    RigState("walk-a", InsectKit.wave(n, amplitude: 4, wavelength: 14, phase: 0).merging(InsectKit.gait(14, swapped: false)) { a, _ in a }),
                    RigState("walk-b", InsectKit.wave(n, amplitude: 4, wavelength: 14, phase: 0.5).merging(InsectKit.gait(14, swapped: true)) { a, _ in a })]
        return InsectKit.assemble(s)
    }
}
