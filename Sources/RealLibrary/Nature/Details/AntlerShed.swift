import simd
import Foundation

/// Whitetail shed antler, 40 cm along the beam, rough burr, three gnawed tines, half buried in dry leaves.
public struct AntlerShed: RealAsset {
    public static let id = "antler-shed"
    public static let summary = "Whitetail shed antler 40 cm long with gnawed tines and weathered bone, half buried in dry leaves."
    public static let tags = ["nature", "ground"]
    public static let budget = 1_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 0.8, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let bone: MaterialKey = "rock.limestone:DCCFB4"
        let sides = 8
        func beamPt(_ t: Float) -> V3 { V3(0.37 * t, 0.10 * sin(t * 1.6), 0.045 * sin(t * 3.1 + 0.4)) }
        func beamR(_ t: Float) -> Float { 0.0165 * (1 - 0.72 * pow(t, 0.8)) }
        let N = 12
        let path = (0..<N).map { beamPt(Float($0) / Float(N - 1)) }
        let radii = (0..<N).map { beamR(Float($0) / Float(N - 1)) }
        let ph = rng.float(0...6.28)
        var parts: [Surface] = [Prim.tube(path, radii: radii, sides: sides, seamTile: 0.04, material: bone,
                                          rippling: { a, c in 1 + 0.025 * sin(c * 5 + a * 9 + ph) })]
        let tines: [(t: Float, len: Float, gnaw: Bool, side: Float)] = [(0.18, 0.11, true, 1), (0.42, 0.14, false, -1), (0.66, 0.095, true, 1)]
        for tn in tines {
            let p = beamPt(tn.t) + V3(0, -0.002, 0)
            let L = tn.len * rng.float(0.9...1.1) * (tn.gnaw ? 0.8 : 1)
            let dir = V3(0.35, 1, tn.side * rng.float(0.1...0.3)).normalized
            let r0 = beamR(tn.t) * 0.75
            let M = 6
            var tp: [V3] = [], tr: [Float] = []
            for i in 0..<M {
                let s = Float(i) / Float(M - 1)
                tp.append(p + dir * L * s + V3(0.25 * L * s * s, 0, 0))
                tr.append(tn.gnaw ? max(0.0035, r0 * (1 - 0.75 * s)) : max(0.0012, r0 * (1 - 0.92 * pow(s, 0.9))))
            }
            let amp: Float = tn.gnaw ? 0.08 : 0.03
            let p2 = rng.float(0...6.28)
            parts.append(Prim.tube(tp, radii: tr, sides: sides, seamTile: 0.03, material: bone,
                                   rippling: { a, c in 1 + amp * sin(c * 3 + a * 14 + p2) }))
        }
        // Tip tine ends the beam; add a pale gnawed end on the longest tine.
        parts = DetailKit07.rotated(parts, simd_quatf(angle: 1.15, axis: V3(1, 0, 0)))
        DetailKit07.settle(&parts, sink: 0.004, center: true)
        parts = DetailKit07.rotated(parts, DetailKit07.yaw(0))
        var leaves = Surface(material: DetailKit07.leafMat)
        for i in 0..<26 {
            let c = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
            var b = PlantKit.Blade()
            b.length = rng.float(0.05...0.1); b.width = b.length
            b.yaw = rng.float(0...6.28)
            let x = rng.float(-0.2...0.12), z = rng.float(-0.06...0.06)
            b.root = V3(x, 0.002 + rng.float(0...0.02) + Float(i) * 0.0003, z) - V3(cos(b.yaw), 0, sin(b.yaw)) * b.length / 2
            b.constantWidth = true; b.tipWidth = 1; b.lean = rng.float(1.1...1.55); b.curl = rng.float(-0.05...0.1); b.segments = 1
            b.u = V2(c.origin.x, c.origin.x + c.size.x); b.v = V2(c.origin.y, c.origin.y + c.size.y)
            b.weight = V2(0, 0); b.ao = V2(0.75, 0.9); b.upNormal = 0.2; b.fold = rng.float(-0.18...0.04)
            leaves.append(PlantKit.blade(b, material: DetailKit07.leafMat))
        }
        return LODModel(levels: [DetailKit07.finish(Self.id, parts + [leaves])], switchDistances: [])
    }
}
