import simd
import Foundation

/// 4 empty banded garden snail shells (2 to 3 cm) and one live snail with antennae.
public struct SnailShell: RealAsset {
    public static let id = "snail-shell"
    public static let summary = "Four empty banded garden snail shells of 2 to 3 cm and one live snail with antennae."
    public static let tags = ["nature", "ground"]
    public static let budget = 2_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.35, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit07.lods(seed: seed) { lod, rng in
            let hi = lod == 0
            let sides = hi ? 9 : 5, pts = hi ? 26 : 12
            var out: [Surface] = []
            let tints = ["B88A4A", "C9A465", "A9763A", "D2B77A"]
            for i in 0..<4 {
                let size = rng.float(0.02...0.03)
                var part = [DetailKit07.snailShell(size: size, material: "insect.chitin:" + tints[i], sides: sides, points: pts)]
                // Pale band along a second thinner tube.
                let q = DetailKit07.yaw(rng.float(0...6.28)) * simd_quatf(angle: rng.float(0.9...1.7), axis: V3(1, 0, 0))
                part = DetailKit07.rotated(part, q)
                DetailKit07.settle(&part, sink: -0.0005, center: false)
                let a = Float(i) / 4 * 6.28 + 0.4 + rng.float(-0.3...0.3)
                let d = rng.float(0.03...0.05)
                DetailKit07.shift(&part, V3(cos(a) * d - 0.02, 0, sin(a) * d))
                out += part
            }
            // Live snail.
            let bodyPath: [V3] = [V3(-0.032, 0.0012, 0), V3(-0.014, 0.0035, 0.001), V3(0.006, 0.0042, 0), V3(0.022, 0.0065, -0.001), V3(0.031, 0.012, 0)]
            let bodyR: [Float] = [0.0008, 0.0034, 0.0042, 0.0034, 0.0030]
            var snail = [Prim.tube(bodyPath, radii: bodyR, sides: hi ? 8 : 5, seamTile: 0.03, material: "ground.mud:A89C80")]
            for s: Float in [-1, 1] {
                let base = V3(0.031, 0.0145, s * 0.0015)
                let tip = base + V3(0.005, 0.017, s * 0.008)
                snail.append(Prim.tube([base, (base + tip) / 2 + V3(0.001, 0, 0), tip], radii: [0.0007, 0.0006, 0.0005], sides: 3, seamTile: 0.01, material: "ground.mud:8E8268"))
                snail.append(DetailKit07.xf(Prim.cubeSphere(subdivisions: 1, material: "insect.chitin:1A1612") { $0 * 0.0008 }, Xform(translation: tip, rotation: .init(angle: 0, axis: V3(0, 1, 0)))))
            }
            let shell = DetailKit07.snailShell(size: 0.03, material: "insect.chitin:9A6B38", sides: hi ? 9 : 5, points: pts)
            snail.append(DetailKit07.xf(shell, Xform(translation: V3(-0.006, 0.0175, 0), rotation: simd_quatf(angle: 0.55, axis: V3(0, 0, 1)))))
            DetailKit07.shift(&snail, V3(0.03, 0, -0.04))
            out += snail
            return DetailKit07.finish(Self.id, out)
        }
    }
}
