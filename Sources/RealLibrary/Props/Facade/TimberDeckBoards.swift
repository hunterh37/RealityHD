import simd
import Foundation

/// Timber deck boards: architectural facade customizer, Contemporary. Grooved weathered cedar boards
/// with 5 mm gaps on pine joists, paired stainless screws over every joist, staggered butt joints,
/// fascia boards on the two board ends.
public struct TimberDeckBoards: RealAsset {
    public static let id = "timber-deck-boards"
    public static let summary = "Timber deck tile, 2 x 2 m: weathered cedar deck boards with 5 mm gaps on pine joists, paired stainless screws, staggered butt joints, fascia ends."
    public static let tags = ["prop", "architecture", "facade", "ground", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.2, 2.0)
    /// Deck board width (m).
    public var boardWidth: Float = 0.14
    /// Deck board thickness (m).
    public var boardThick: Float = 0.028
    /// Gap between boards (m).
    public var gap: Float = 0.005
    /// Joist spacing along X (m).
    public var joistSpacing: Float = 0.4
    /// Board material.
    public var boardMaterial: MaterialKey = "wood.cedar-weathered"
    /// Joist and fascia material.
    public var joistMaterial: MaterialKey = "wood.lumber-pine:8E7A62"
    /// Screw head material.
    public var screwMaterial: MaterialKey = "metal.stainless"
    /// Board tones (sRGB hex) mixed across the deck.
    public var tones: [UInt32] = [0x9C8A74, 0x8A7964, 0xA89580, 0x7E6F5D]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, top = size.y
        let fasciaT: Float = 0.022
        let deckX0 = -hx + fasciaT + 0.002, deckX1 = hx - fasciaT - 0.002
        let jy0: Float = 0.0, jy1 = top - boardThick - 0.001
        // Joists along Z.
        var joistX: [Float] = []
        var x = deckX0 + 0.03
        while x < deckX1 - 0.02 { joistX.append(x); x += joistSpacing }
        joistX.append(deckX1 - 0.03)
        for (i, jx) in joistX.enumerated() {
            var r = rng.fork(10 + i)
            m.add(plank(size.z - 0.01, jy1 - jy0, 0.045, bevel: 0.003, material: joistMaterial),
                  Xform(translation: V3(jx, (jy0 + jy1) / 2, r.float(-0.002...0.002)),
                        rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Boards along X, staggered butt joints over a joist.
        let pitch = boardWidth + gap
        let n = Int((size.z - gap) / pitch)
        let z0 = -Float(n) * pitch / 2 + pitch / 2
        let keys = tones.map { "\(boardMaterial):\(String(format: "%06X", $0))" }
        for b in 0..<n {
            var r = rng.fork(100 + b)
            let z = z0 + Float(b) * pitch
            var cuts: [Float] = [deckX0, deckX1]
            if b % 3 != 1 {
                let j = joistX[(b * 2 + 1) % (joistX.count - 2) + 1]
                cuts.insert(j, at: 1)
            }
            for s in 0..<(cuts.count - 1) {
                let a = cuts[s] + (s > 0 ? 0.0015 : 0), e = cuts[s + 1] - (s < cuts.count - 2 ? 0.0015 : 0)
                let len = e - a
                let th = boardThick + r.float(-0.0015...0.0012)
                var surf = Prim.roundedBox(V3(len, th, boardWidth - r.float(0...0.002)), radius: 0.004, bevelSegments: 1, material: r.chance(0.15) ? keys[0] : keys[r.int(0...(keys.count - 1))])
                // Slight cup across the width.
                let w2 = boardWidth / 2
                surf.deform { p in V3(p.x, p.y + (p.z * p.z) / (w2 * w2) * 0.0018 * (p.y > 0 ? 1 : 0), p.z) }
                let off = r.float(0...7)
                surf.uvs = surf.uvs.map { $0 + V2(off, off * 0.3) }
                surf.computeTangents()
                var xf = Xform(translation: V3((a + e) / 2, top - th / 2, z + r.float(-0.0008...0.0008)))
                xf.rotation = simd_quatf(degrees: r.float(-0.15...0.15), axis: V3(1, 0, 0))
                m.add(surf, xf)
                // Screws: pair over each joist covered by this board.
                for jx in joistX where jx > a + 0.015 && jx < e - 0.015 {
                    for side: Float in [-1, 1] {
                        let sx = jx + r.float(-0.003...0.003)
                        let sz = z + side * boardWidth * 0.3 + r.float(-0.002...0.002)
                        let head = Prim.cylinder(radius: 0.0055, height: 0.0016, bevel: 0.0007, segments: 6, bevelSegments: 1, material: screwMaterial)
                        m.add(head, Xform(translation: V3(sx, top + 0.0006, sz)))
                    }
                }
            }
        }
        // Fascia boards on the board ends.
        for side: Float in [-1, 1] {
            let f = plank(size.z, top - 0.004, fasciaT, bevel: 0.003, material: "wood.cedar-weathered:8C7A66")
            m.add(f, Xform(translation: V3(side * (hx - fasciaT / 2), (top - 0.004) / 2, 0),
                           rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        groundAO(&m, height: 0.08, floor: 0.6)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, size.y, size.z), radius: 0.004, bevelSegments: 1, material: boardMaterial), Xform(translation: V3(0, size.y / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }

}
