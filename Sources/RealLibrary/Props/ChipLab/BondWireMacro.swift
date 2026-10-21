import simd
import Foundation

/// Bond wire macro display, about 160x scale, 0.4 x 0.1 x 0.2 m: black plinth, silicon die with aluminium pad rows on the
/// right edge, ABF substrate with gold finger rows, and parametric gold wire loops with squashed ball bonds (neck) on the
/// die pads and wedge bonds (foot and tail) on the fingers. Alternating wires use the far pad and finger row.
public struct BondWireMacro: RealAsset {
    public static let id = "bond-wire-macro"
    public static let summary = "Parametric gold bond wire loops between die pads and substrate fingers with ball and wedge bonds at macro scale."
    public static let tags = ["prop", "chiplab"]
    public static let budget = 10500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 25, distance: 0.8, studio: true)

    /// Overall size in meters.
    public var size = V3(0.4, 0.1, 0.2)
    /// Wire count.
    public var wires = 8
    /// Wire radius (m).
    public var wireRadius: Float = 0.0020
    /// Loop height above the pads (m).
    public var loopHeight: Float = 0.050
    public var wire: MaterialKey = "metal.gold"
    public var pad: MaterialKey = "metal.aluminum-brushed"
    public var die: MaterialKey = "silicon.die"
    public var dieEdge: MaterialKey = "silicon.die-edge"
    public var substrate: MaterialKey = "laminate.abf"
    public var plinth: MaterialKey = "metal.anodized-black"
    public init() {}

    func flat(_ w: Float, _ d: Float, _ t: Float, _ mat: MaterialKey) -> Surface {
        Prim.extrude(Shape2D.rect(w, d), depth: t, bevel: 0.0003, bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let pl: Float = 0.012
        m.add(Prim.roundedBox(V3(W, pl, D), radius: 0.003, bevelSegments: 2, material: plinth), Xform(translation: V3(0, pl / 2, 0)))
        let dieT: Float = 0.016, subT: Float = 0.008
        let dieX0: Float = -W / 2 + 0.012, dieX1: Float = -0.045
        m.add(Prim.roundedBox(V3(dieX1 - dieX0, dieT, D - 0.03), radius: 0.0012, bevelSegments: 2, material: dieEdge),
              Xform(translation: V3((dieX0 + dieX1) / 2, pl + dieT / 2, 0)))
        let dTop = pl + dieT
        m.add(flat(dieX1 - dieX0 - 0.002, D - 0.032, 0.0005, die), Xform(translation: V3((dieX0 + dieX1) / 2, dTop + 0.00025, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        let subX0: Float = -0.02, subX1: Float = W / 2 - 0.012
        m.add(Prim.roundedBox(V3(subX1 - subX0, subT, D - 0.03), radius: 0.0012, bevelSegments: 2, material: substrate),
              Xform(translation: V3((subX0 + subX1) / 2, pl + subT / 2, 0)))
        let sTop = pl + subT
        let pitch = (D - 0.07) / Float(wires - 1)
        let xr = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        for i in 0..<wires {
            let far = i % 2 == 1
            let z = -(D - 0.07) / 2 + Float(i) * pitch
            let px: Float = dieX1 - (far ? 0.024 : 0.009)
            let fx: Float = subX0 + (far ? 0.095 : 0.060)
            m.add(flat(0.011, 0.0135, 0.0008, pad), Xform(translation: V3(px, dTop + 0.0009, z), rotation: xr))
            m.add(flat(0.020, 0.0105, 0.0008, wire), Xform(translation: V3(fx, sTop + 0.0004, z), rotation: xr))
            // Ball bond (squashed sphere) and wedge bond foot.
            let y0 = dTop + 0.0014 + 0.0022, y1 = sTop + 0.0008 + wireRadius * 0.7
            m.add(Prim.superellipsoid(V3(0.0100, 0.0042, 0.0100), exponent: 2.6, subdivisions: 6, material: wire), Xform(translation: V3(px, dTop + 0.0009 + 0.0021, z)))
            m.add(Prim.superellipsoid(V3(0.0140, 0.0030, 0.0070), exponent: 3, subdivisions: 5, material: wire), Xform(translation: V3(fx, y1 - 0.0005, z)))
            // Loop: steep neck then arc; slight per-wire height and sway variation.
            let h = loopHeight * rng.float(0.85...1.2) * (far ? 1.25 : 1)
            let sway = rng.float(-0.002...0.002)
            var pts: [V3] = []
            let n = 22
            for k in 0...n {
                let t = Float(k) / Float(n)
                let x = px + (fx - px) * t
                let arc = h * pow(sin(.pi * pow(t, 0.72)), 0.9)
                let y = y0 + (y1 - y0) * t + arc
                pts.append(V3(x, y, z + sway * sin(.pi * t)))
            }
            let radii = [Float](repeating: wireRadius, count: pts.count)
            m.add(Prim.tube(pts, radii: radii, sides: 8, seamTile: 0.02, material: wire))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
