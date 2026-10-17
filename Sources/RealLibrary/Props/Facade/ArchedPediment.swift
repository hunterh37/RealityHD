import simd
import Foundation

/// Arched pediment: architectural facade customizer, Palladian. Parts: segmental arch, archivolt, entablature, keystone, impost blocks, tympanum.
public struct ArchedPediment: RealAsset {
    public static let id = "arched-pediment"
    public static let summary = "Arched pediment, 1.8 m: Palladian segmental arch pediment with archivolt, keystone and impost blocks on an entablature."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.8, 0.7, 0.3)
    public init() {}

    /// Rise of the segmental arch centreline above the springing.
    public var rise: Float = 0.23
    /// Limestone for the arch, archivolt and keystone.
    public var stone: MaterialKey = "stone.limestone"
    /// Cast stone for the entablature and impost blocks.
    public var cast: MaterialKey = "stone.cast-stone"
    /// Sooted limestone for the tympanum and joints.
    public var sooted: MaterialKey = "stone.limestone-sooted"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let eH: Float = 0.20, impH: Float = 0.12, band: Float = 0.14
        let yE = FP.entablature(&m, width: W, y0: 0, depth: D, height: eH, dentil: true, cast, shadow: sooted, skipDentil: 9)
        let c: Float = 0.78, ySpring = yE + impH
        let R = (c * c + rise * rise) / (2 * rise)
        let cy = ySpring + rise - R
        let th = asin(c / R)
        func arcPt(_ a: Float, _ r: Float) -> V2 { V2(sin(a) * r, cy + cos(a) * r) }
        // Impost blocks: base plate, die, moulded cap, one per springing.
        for e: Float in [-1, 1] {
            let x = e * 0.805
            FA.box(&m, V3(0.19, 0.02, 0.24), V3(x, yE + 0.01, 0.15), cast, r: 0.002)
            FA.box(&m, V3(0.17, impH - 0.045, 0.22), V3(x, yE + 0.02 + (impH - 0.045) / 2, 0.14), cast, r: 0.003)
            FA.run(&m, [V2(0.03, 0), V2(0.255, 0), V2(0.255, 0.012), V2(0.27, 0.02), V2(0.27, 0.025), V2(0.03, 0.025)],
                   length: 0.19, at: V3(x, ySpring - 0.025, 0), cast, bevel: 0.0015)
        }
        // Tympanum: sooted panel under the intrados between the impost blocks.
        var tym: [V2] = [V2(-0.735, yE), V2(0.735, yE)]
        let n = 24
        for k in 0...n {
            let a = th - Float(k) / Float(n) * 2 * th
            let p = arcPt(a, R - band / 2)
            if abs(p.x) <= 0.735 { tym.append(p) }
        }
        m.add(Prim.extrude(Shape2D.deduped(tym), depth: 0.05, bevel: 0.002, bevelSegments: 1, material: sooted), Xform(translation: V3(0, 0, 0.055)))
        // Archivolt: stepped swept moulding along the segmental arch, plus an inner bead.
        let path: [V2] = (0...n).map { k in arcPt(-th + Float(k) / Float(n) * 2 * th, R) }
        m.add(Prim.sweep(FP.archivolt(d: 0.20, h: band), along: path.map { V3($0.x, $0.y, 0.13) }, up: FA.Z, material: stone))
        let inner: [V2] = (0...n).map { k in arcPt(-th + Float(k) / Float(n) * 2 * th, R - band / 2 - 0.012) }
        m.add(Prim.sweep([V2(-0.014, -0.012), V2(0.014, -0.012), V2(0.014, 0.012), V2(-0.014, 0.012)], along: inner.map { V3($0.x, $0.y, 0.115) },
                         up: FA.Z, material: stone))
        // Voussoir joints across the face; one is open and stained.
        let vs = 11
        for k in 1..<vs {
            let a = -th + Float(k) / Float(vs) * 2 * th
            let p = arcPt(a, R + 0.05 * band)
            let w: Float = k == 4 ? 0.006 : 0.003
            FA.box(&m, V3(w, 0.19 * band, 0.004), V3(p.x, p.y, 0.2305), sooted, r: 0.0006, rot: FA.q(-a * 180 / .pi, FA.Z))
        }
        // Keystone: tapering block with a fillet, projecting past the archivolt.
        let apex = arcPt(0, R)
        let ky = apex.y - band / 2 - 0.02
        let key = [V2(-0.04, ky), V2(0.04, ky), V2(0.062, 0.70), V2(-0.062, 0.70)]
        m.add(Prim.extrude(key, depth: 0.23, bevel: 0.003, bevelSegments: 1, material: stone), Xform(translation: V3(0, 0, 0.145)))
        FA.box(&m, V3(0.16, 0.022, 0.25), V3(0, 0.70 - 0.011, 0.145), stone, r: 0.003)
        FA.box(&m, V3(0.05, 0.1, 0.004), V3(0, ky + 0.15, 0.2615), sooted, r: 0.002)
        // Soot bloom and a rain-washed streak on the tympanum.
        FA.box(&m, V3(0.04, 0.12, 0.003), V3(0.1 + rng.float(0...0.05), yE + 0.09, 0.082), sooted, r: 0.001)
        FA.box(&m, V3(0.03, 0.08, 0.003), V3(-0.3, yE + 0.06, 0.082), sooted, r: 0.001)
        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
