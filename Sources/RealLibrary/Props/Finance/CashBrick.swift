import simd
import Foundation

/// Banded brick of green banknotes, 16 x 7 x 4 cm: about 400 sheets (stacked edges visible), a kraft paper
/// strap around the middle and a printed note on top.
public struct CashBrick: RealAsset {
    public static let id = "cash-brick"
    public static let summary = "Brick of green banknotes, 16x7x4 cm, banded with a paper strap, printed top note."
    public static let tags = ["prop", "finance", "paper", "handheld"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 32)

    /// Length, width, height in meters.
    public var size = V3(0.16, 0.07, 0.04)
    /// Strap width along the length in meters.
    public var strapWidth: Float = 0.032
    /// Strap paper material key.
    public var strap = "paper.sheet:D9B66B"
    public init() {}

    static func planarUV(_ s: inout Surface, origin: V3) {
        s.uvs = s.positions.map { V2($0.x - origin.x, $0.z - origin.z) }
        s.computeTangents()
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Stack in 4 slabs of loose-packed sheets with sub-millimetre shifts so edges are not CAD flat.
        let slabs = 4
        let slabH = size.z / Float(slabs)
        var top: Float = 0
        for i in 0..<slabs {
            let dx = rng.float(-0.0012...0.0012), dz = rng.float(-0.0012...0.0012)
            let w = size.x - rng.float(0...0.0012), d = size.y - rng.float(0...0.0012)
            var s = Prim.roundedBox(V3(w, slabH + 0.0004, d), radius: 0.0005, bevelSegments: 2, material: "paper.bill-edge")
            let base = Float(i) * slabH
            s.uvs = s.positions.map { V2($0.x + $0.z, $0.y + base + slabH / 2) }
            s.computeTangents()
            m.add(s, Xform(translation: V3(dx, base + slabH / 2, dz)))
            top = Float(i + 1) * slabH
        }
        // Printed top note.
        var note = Prim.roundedBox(V3(size.x - 0.0006, 0.0004, size.y - 0.0006), radius: 0.0001, bevelSegments: 1, material: "paper.banknote")
        Self.planarUV(&note, origin: V3(-size.x / 2, 0, -size.y / 2))
        m.add(note, Xform(translation: V3(rng.float(-0.0006...0.0006), top + 0.0001, rng.float(-0.0004...0.0004))))
        // Paper strap around the middle, slightly oversized.
        m.add(Prim.roundedBox(V3(strapWidth, size.z + 0.0008, size.y + 0.0008), radius: 0.0004, bevelSegments: 2, material: strap),
              Xform(translation: V3(rng.float(-0.004...0.004), size.z / 2, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
