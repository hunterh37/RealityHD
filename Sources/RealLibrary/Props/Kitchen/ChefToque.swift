import simd
import Foundation

/// Chef toque: starched white cotton chef hat, 28 cm tall on a stiff 5.5 cm band with a 0.19 m inside diameter. The crown is a loft of
/// 144-point rings carrying 20 pleats (sinusoidal ripples with a slight lean and per-pleat variation) that flare from the band, puff out
/// near the top and converge into a soft rounded crown. Inner sweatband liner with a seam, stitch grooves on the band, smooth inner crown skin.
public struct ChefToque: RealAsset {
    public static let id = "chef-toque"
    public static let summary = "Tall pleated white chef toque, 28 cm tall on a 0.19 m head band, pleated lofted crown with a puffed top."
    public static let tags = ["prop", "kitchen", "fabric", "interior", "handheld"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.235, 0.28, 0.235)
    /// Number of pleats around the crown.
    public var pleats = 22
    /// Crown cloth.
    public var cloth: MaterialKey = "fabric.nylon:F6F4EE"
    /// Band and inner sweatband cloth (starched).
    public var band: MaterialKey = "fabric.canvas:ECE8DF"
    public init() {}

    /// Crown stations: (height, radius).
    private static let crownR: [V2] = [
        V2(0.0990, 0.0535), V2(0.0990, 0.0620), V2(0.0995, 0.0800), V2(0.1010, 0.1000), V2(0.1035, 0.1250), V2(0.1055, 0.1500),
        V2(0.1070, 0.1750), V2(0.1080, 0.2000), V2(0.1080, 0.2200), V2(0.1060, 0.2400), V2(0.1010, 0.2550), V2(0.0920, 0.2660),
        V2(0.0780, 0.2740), V2(0.0600, 0.2790), V2(0.0300, 0.2810), V2(0.0100, 0.2815),
    ]
    private static let amp: [(Float, Float)] = [
        (0.0535, 0.0010), (0.0620, 0.0035), (0.0800, 0.0065), (0.1000, 0.0080), (0.1250, 0.0092), (0.1500, 0.0098),
        (0.2000, 0.0092), (0.2400, 0.0075), (0.2550, 0.0055), (0.2660, 0.0035), (0.2740, 0.0020), (0.2810, 0.0004),
    ]

    private func ampAt(_ y: Float) -> Float {
        let a = Self.amp
        if y <= a[0].0 { return a[0].1 }
        for i in 1..<a.count where y <= a[i].0 {
            let t = (y - a[i - 1].0) / (a[i].0 - a[i - 1].0)
            return a[i - 1].1 + (a[i].1 - a[i - 1].1) * t
        }
        return a.last!.1
    }

    /// The soft crown leans a little to one side, as a starched hat does after a shift.
    private func slump(_ y: Float) -> (Float, Float) {
        let t = max(0, (y - 0.0535) / 0.2275)
        return (0.011 * pow(t, 2.4), 0.004 * t * t)
    }

    func level(segs: Int, detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = max(segs, pleats * 4)
        let pleatK = (0..<pleats).map { _ in rng.float(0.7...1.3) }
        let phase = rng.float(0...(2 * .pi))
        let cr = Profile.smooth(Self.crownR.map { V2($0.x, $0.y) }, per: detail ? 2 : 1)
        // Crown: pleated rings, each leaning a little with height.
        func pleatedRing(_ r: V2) -> [V3] {
            let R = r.x, y = r.y
            let a = ampAt(y) * 0.85
            let lean = 0.10 * (y - 0.0535) / 0.2275
            let (sx, sz) = slump(y)
            let outline: [V2] = (0..<n).map { k in
                let th = 2 * Float.pi * Float(k) / Float(n)
                let pi = min(pleats - 1, Int(th / (2 * .pi) * Float(pleats)))
                let ph = Float(pleats) * (th + lean) + phase
                let w = sin(ph) + 0.22 * sin(2 * ph + 0.8) * min(1, a * 160)
                let rr = R + a * pleatK[pi] * w
                return V2(cos(th) * rr + sx, sin(th) * rr + sz)
            }
            return Prim.ring(outline, y: y)
        }
        let rings = cr.map(pleatedRing)
        var crown = Prim.loft(rings, capEnd: true, material: cloth)
        crown.recomputeNormals(weldSeams: true)
        crown.computeTangents()
        m.add(crown)
        // Inner crown skin, smooth and a few mm inside, visible from below.
        let innerStations = stride(from: 0, to: cr.count, by: detail ? 3 : 4).map { cr[$0] } + [cr[cr.count - 1]]
        let innerRings = innerStations.map { r -> [V3] in
            let rr = max(0.002, r.x - 0.0032)
            let sl = slump(r.y)
            return Prim.ring((0..<(detail ? 72 : 36)).map { k in
                let th = 2 * Float.pi * Float(k) / Float(detail ? 72 : 36)
                return V2(cos(th) * rr + sl.0, sin(th) * rr + sl.1)
            }, y: r.y - 0.0025)
        }
        m.add(Prim.loft(innerRings, capEnd: true, material: band).flipped())
        // Head band: rolled lips, two stitch grooves near the top.
        let bandP: [V2] = [
            V2(0.0950, 0.0012), V2(0.0958, 0.0), V2(0.0972, 0.0), V2(0.0985, 0.0015), V2(0.0990, 0.0035), V2(0.0990, 0.0450),
            V2(0.0988, 0.0455), V2(0.0990, 0.0460), V2(0.0990, 0.0490), V2(0.0988, 0.0495), V2(0.0990, 0.0500), V2(0.0990, 0.0505),
            V2(0.0987, 0.0530), V2(0.0980, 0.0545), V2(0.0968, 0.0550), V2(0.0958, 0.0545), V2(0.0952, 0.0535), V2(0.0950, 0.0515),
            V2(0.0950, 0.0012),
        ]
        var bandS = Prim.lathe(bandP, segments: min(segs, 96), seamTile: 0.12, material: band)
        bandS.recomputeNormals(weldSeams: true)
        m.add(bandS)
        // Sweatband liner inside the head opening with a lap seam.
        m.add(Prim.lathe([V2(0.0947, 0.0016), V2(0.0947, 0.0505)], segments: min(segs, 96), seamTile: 0.12, material: "fabric.linen:E6E1D4").flipped())
        m.add(Prim.roundedBox(V3(0.0016, 0.0470, 0.0120), radius: 0.0004, bevelSegments: 1, material: "fabric.linen:DCD6C6"),
              Xform(translation: V3(0.0942, 0.0262, 0), rotation: simd_quatf(degrees: 0, axis: .up)))
        m = m.transformed(Xform.identity)
        groundAO(&m, height: 0.01, floor: 0.9)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        let lod0 = level(segs: 120, detail: true, seed: seed)
        let lod1 = level(segs: 80, detail: false, seed: seed)
        return LODModel(levels: [lod0, lod1], switchDistances: [2.5])
    }
}
