import simd
import Foundation

/// Two-seat loveseat, 155 x 84 x 90 cm: rolled arms with a piped front disc and button, a stitched back
/// rail, two welted loose seat cushions with a sitting sag, two leaning back cushions and four turned
/// walnut feet with brass ferrules.
public struct Loveseat: RealAsset {
    public static let id = "loveseat"
    public static let summary = "Two-seat loveseat, 1.55 m: rolled arms, welted loose cushions, turned walnut feet."
    public static let tags = ["prop", "floorplan", "living", "furniture", "fabric", "wood", "interior"]
    public static let budget = 8500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 15, distance: 1.1, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.55, 0.84, 0.9)
    /// Cushion fabric.
    public var cushionFabric: MaterialKey = "fabric.linen:7D7466"
    /// Frame and arm fabric.
    public var frameFabric: MaterialKey = "fabric.linen:6C6458"
    /// Foot wood.
    public var legWood: MaterialKey = "wood.walnut"
    /// Ferrule metal.
    public var ferrule: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func cushion(w: Float, t: Float, d: Float, sag: Float, exponent: Float, detail: Bool) -> Surface {
        var s = Prim.superellipsoid(V3(w, t, d), exponent: exponent, subdivisions: detail ? 8 : 4, material: cushionFabric)
        s.deform { p in
            let fx = p.x / (w / 2), fz = p.z / (d / 2)
            let dip = max(0, 1 - fx * fx) * max(0, 1 - pow(fz - 0.1, 2)) * (p.y > 0 ? 1 : 0.2)
            let corner = pow(abs(fx), 3) * pow(abs(fz), 3) * (p.y > 0 ? 0.012 : 0)
            let crease = (p.y > 0 ? 1 : 0) * exp(-pow((fz - 0.62) * 9, 2)) * 0.006 * (1 - fx * fx)
            return p - V3(0, dip * sag + corner + crease, 0)
        }
        if detail {
            for sign: Float in [1, -1] {
                let yy = sign * (t / 2 - 0.016)
                let k = pow(max(0, 1 - pow(abs(yy) / (t / 2), exponent)), 1 / exponent)
                let ring = Shape2D.roundedRect(w * k - 0.002, d * k - 0.002, radius: 0.04, segments: 2)
                    .map { V3($0.x, yy - (sign > 0 ? sag * 0.1 : 0), -$0.y) }
                s.append(Prim.sweep(Shape2D.circle(0.0045, segments: 5), along: ring, closedPath: true, caps: false, material: cushionFabric))
            }
        }
        return s
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let armW: Float = 0.19, legH: Float = 0.12, deckTop: Float = 0.25, armTop: Float = 0.62, backFrameD: Float = 0.14
        let inner = W - 2 * armW
        // Deck and back rail.
        m.add(Prim.roundedBox(V3(inner + 0.02, deckTop - legH, D), radius: 0.015, bevelSegments: 2, material: frameFabric),
              Xform(translation: V3(0, (legH + deckTop) / 2, 0)))
        m.add(Prim.roundedBox(V3(inner + 0.02, 0.36, backFrameD), radius: 0.045, bevelSegments: 3, material: frameFabric),
              Xform(translation: V3(0, deckTop + 0.18, -D / 2 + backFrameD / 2)))
        // Rolled arms: extruded roll profile, front cap carries a piped disc and a button.
        let rr: Float = armW / 2, cy = armTop - rr
        var prof: [V2] = [V2(-0.08, legH), V2(0.08, legH), V2(0.08, cy - 0.02)]
        for k in 0...16 { let a = Float(-20 + k * 14) * .pi / 180; prof.append(V2(cos(a) * rr, cy + sin(a) * rr)) }
        prof.append(V2(-0.08, cy - 0.02))
        let outline = Shape2D.rounded(Shape2D.deduped(prof), radius: 0.008, segments: 1)
        for s: Float in [-1, 1] {
            let ax = s * (W / 2 - armW / 2)
            m.add(Prim.extrude(outline, depth: D - 0.012, bevel: 0.02, bevelSegments: 3, material: frameFabric),
                  Xform(translation: V3(ax, 0, 0)))
            if detail {
                let disc = (0..<20).map { k -> V3 in let a = Float(k) / 20 * 2 * .pi; return V3(ax + cos(a) * 0.058, cy + sin(a) * 0.058, D / 2 + 0.001) }
                m.add(Prim.sweep(Shape2D.circle(0.0035, segments: 5), along: disc, closedPath: true, caps: false, material: frameFabric))
                m.add(Prim.superellipsoid(V3(0.02, 0.02, 0.012), exponent: 2.2, subdivisions: 2, material: frameFabric),
                      Xform(translation: V3(ax, cy, D / 2 + 0.002)))
                // Pleats radiating from the button.
                for k in 0..<10 {
                    let a = Float(k) / 10 * 2 * .pi
                    m.add(Prim.tube([V3(ax + cos(a) * 0.014, cy + sin(a) * 0.014, D / 2 + 0.0015), V3(ax + cos(a) * 0.055, cy + sin(a) * 0.055, D / 2 + 0.0015)],
                                    radii: [0.0018, 0.0018], sides: 3, seamTile: 0.01, material: frameFabric, capEnd: false))
                }
            }
        }
        if detail {
            let top = (0...16).map { V3(-inner / 2 + 0.03 + Float($0) / 16 * (inner - 0.06), deckTop + 0.36 + 0.0005, -D / 2 + backFrameD / 2) }
            m.add(stitches(along: top, normal: { _ in .up }, pitch: 0.02, thread: 0.0008, material: frameFabric))
        }
        // Cushions.
        let gap: Float = 0.006
        let cw = (inner - gap) / 2
        let seatD = D - backFrameD - 0.02
        for i in 0..<2 {
            let cx = (Float(i) - 0.5) * (cw + gap)
            m.add(cushion(w: cw, t: 0.17, d: seatD, sag: rng.float(0.014...0.022), exponent: 5.5, detail: detail),
                  Xform(translation: V3(cx, deckTop + 0.083, -D / 2 + backFrameD + 0.005 + seatD / 2 + (i == 0 ? 0.003 : 0)),
                        rotation: simd_quatf(degrees: i == 0 ? 1.0 : -0.4, axis: .up)))
            m.add(cushion(w: cw, t: 0.2, d: 0.44, sag: -0.012, exponent: 4.2, detail: detail),
                  Xform(translation: V3(cx, 0.616, -D / 2 + backFrameD + 0.06),
                        rotation: simd_quatf(degrees: i == 0 ? 81.5 : 79, axis: V3(1, 0, 0))))
        }
        // Turned feet with ferrules.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let p = V3(sx * (W / 2 - 0.07), 0, sz * (D / 2 - 0.07))
            m.add(turned([(0, 0), (0.019, 0), (0.021, 0.014), (0.025, 0.045), (0.03, 0.085), (0.038, legH), (0, legH)],
                         segments: 14, material: legWood, grainVertical: true), Xform(translation: p))
            m.add(Prim.cylinder(radius: 0.0215, height: 0.012, bevel: 0.002, segments: 12, bevelSegments: 1, material: ferrule), Xform(translation: p))
        }}
        groundAO(&m, height: 0.2, floor: 0.5)
        return m
    }
}
