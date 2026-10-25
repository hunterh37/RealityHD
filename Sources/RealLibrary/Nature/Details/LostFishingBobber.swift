import simd
import Foundation

/// Lost fishing bobber, 4 cm round float: red upper hemisphere, white lower, black through-pin, a short
/// run of snagged line, lying on its side in a mud smear.
public struct LostFishingBobber: RealAsset {
    public static let id = "lost-fishing-bobber"
    public static let summary = "Lost fishing bobber, 4 cm: red and white plastic float with pin and snagged line, lying in mud."
    public static let tags = ["nature", "plastic", "water", "ground"]
    public static let budget = 2150
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.3)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r = rng.float(0.019...0.023)
        func half(_ from: Float, _ to: Float, _ mat: MaterialKey) -> Surface {
            let prof = (0...12).map { i -> V2 in
                let a = from + (to - from) * Float(i) / 12
                return V2(max(0, r * sin(a)) * (a == 0 || a == .pi ? 0 : 1), r * 0.95 * cos(a))
            }
            return Prim.lathe(prof.sorted { $0.y < $1.y }, segments: 24, seamTile: 0.05, material: mat)
        }
        let red = half(0, .pi * 0.52, "plastic.hardhat:C2281C"), white = half(.pi * 0.5, .pi, "plastic.pom:ECE8DC")
        var ball = Surface(material: red.material)
        var wb = Surface(material: white.material)
        // lying on its side with random yaw; rest height fixed by the sphere radius
        let q = simd_quatf(angle: rng.float(0...6.28), axis: V3(0, 1, 0)) * simd_quatf(angle: .pi / 2 + rng.float(-0.25...0.25), axis: V3(0, 0, 1))
        let xf = Xform(translation: V3(0, r * 0.88, 0), rotation: q)
        ball.append(red, xf); wb.append(white, xf)
        ball.computeTangents(); wb.computeTangents(); m.add(ball); m.add(wb)
        // pin through the axis, sticking out both ends
        let ax = q.act(V3(0, 1, 0))
        let c = V3(0, r * 0.88, 0)
        var pin = Prim.tube([c - ax * (r + 0.007), c + ax * (r + 0.009)], radii: [0.0028, 0.0028], sides: 8, seamTile: 0.02, material: "plastic.grime", capEnd: true)
        pin.computeTangents(); m.add(pin)
        // snagged line from the pin end, wandering through the mud
        let a0 = c - ax * (r + 0.007)
        var lp: [V3] = [a0], d = simd_normalize(V3(-ax.x, 0.1, -ax.z))
        for _ in 0..<10 {
            d = simd_normalize(d + V3(rng.float(-0.35...0.35), rng.float(-0.12...0.12), rng.float(-0.35...0.35)))
            var p = lp.last! + d * 0.008; p.y = max(0.0012, p.y * 0.9 + 0.0006); lp.append(p)
        }
        var line = Prim.tube(lp, radii: [Float](repeating: 0.0007, count: lp.count), sides: 4, seamTile: 0.01, material: "plastic.pom:D9DED2", capEnd: true)
        line.computeTangents(); m.add(line)
        var mud = DetailKit19.mound(radius: 0.055, height: 0.01, at: V3(0.002, -0.002, 0.004), material: "ground.mud", rng: &rng)
        mud.computeTangents(); m.add(mud)
        groundAO(&m, height: 0.03)
        return LODModel(levels: [m], switchDistances: [])
    }
}
