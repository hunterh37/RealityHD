import simd
import Foundation

/// Tangled monofilament, ~18 cm across: seven looping strands snarled into a nest with a rusty hook and
/// a lead split-shot, lying on the forest floor. 2 LODs.
public struct TangledFishingLine: RealAsset {
    public static let id = "tangled-fishing-line"
    public static let summary = "Tangled monofilament, ~18 cm: seven snarled loops of line with a rusty hook and split-shot on the forest floor."
    public static let tags = ["nature", "plastic", "water", "ground"]
    public static let budget = 3900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 55, distance: 0.45)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        func make(segs: Int, sides: Int) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            var line = Surface(material: "plastic.pom:CFD8C8")
            for k in 0..<7 {
                let c = V3(rng.float(-0.035...0.035), 0, rng.float(-0.035...0.035))
                let rad = V3(rng.float(0.035...0.07), rng.float(0.008...0.03), rng.float(0.03...0.065))
                let pts = DetailKit19.loopPath(center: c, radius: rad, turns: rng.float(1.2...2.4), segs: segs, phase: rng.float(0...6.28), rng: &rng)
                let r = Float(0.0006) * rng.float(0.9...1.2)
                line.append(Prim.tube(pts, radii: [Float](repeating: r, count: pts.count), sides: sides, seamTile: 0.01, material: line.material, capEnd: true))
                _ = k
            }
            line.computeTangents(); m.add(line)
            // hook: bent wire with shank, bend and point
            var hp: [V3] = []
            let hc = V3(0.07, 0.003, -0.02)
            for i in 0...10 {
                let f = Float(i) / 10
                let a = Float.pi * 1.1 * f
                hp.append(hc + V3(0.012 * sin(a), 0.001 + 0.001 * f, -0.014 * f * 0 + 0.012 * (1 - cos(a))) + V3(0, 0, 0.02 * (1 - f) * 0))
            }
            hp = hp.map { V3($0.x, max($0.y, 0.0015), $0.z) }
            var hook = Prim.tube(hp, radii: [Float](repeating: 0.0009, count: hp.count), sides: 5, seamTile: 0.01, material: "metal.wrought-iron:7A4326", capEnd: true)
            hook.computeTangents(); m.add(hook)
            var shot = Surface(material: "metal.cast-iron-worn:7A7B80")
            let sh = Prim.cubeSphere(subdivisions: sides > 3 ? 4 : 2, material: shot.material) { d in V3(d.x * 0.0034, d.y * 0.0028, d.z * 0.0032) * (1 + 0.1 * sin(d.x * 8)) }
            shot.append(sh, Xform(translation: V3(-0.05, 0.0027, 0.04), rotation: simd_quatf(angle: rng.float(0...3), axis: V3(0, 1, 0))))
            shot.computeTangents(); m.add(shot)
            groundAO(&m, height: 0.03, floor: 0.7)
            return m
        }
        return LODModel(levels: [make(segs: 52, sides: 4), make(segs: 20, sides: 3)], switchDistances: [4])
    }
}
