import simd
import Foundation

/// Kombucha swing-top bottle: 28 cm tall, 8 cm wide amber glass with a thick punted base, shoulder, neck bead and lip, cloudy golden-brown
/// tea inside with a pale SCOBY disc floating near the top and hanging yeast strands, porcelain stopper on a rubber gasket held by a steel
/// wire bail, paper label and a few condensation beads.
public struct KombuchaBottle: RealAsset {
    public static let id = "kombucha-bottle"
    public static let summary = "Amber swing-top kombucha bottle, 0.5 l: porcelain stopper with wire bail, paper label, cloudy tea with SCOBY and yeast strands."
    public static let tags = ["prop", "kitchen", "glass", "handheld"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, distance: 0.8, studio: true)

    /// Body radius (m).
    public var bodyRadius: Float = 0.0405
    /// Glass wall thickness (m).
    public var wall: Float = 0.0028
    /// Tea surface height (m).
    public var teaLevel: Float = 0.1905
    /// Amber glass key.
    public var glass: MaterialKey = "glass.tinted:B06A18"
    /// Tea key.
    public var tea: MaterialKey = "fluid.tap-water:A5651F"
    /// Label paper key.
    public var label: MaterialKey = "label.canister:EBDFC2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ seg: Int, _ detail: Bool) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let r = bodyRadius, w = wall
            let steel: MaterialKey = "metal.stainless", rubber: MaterialKey = "rubber.seal", porcelain: MaterialKey = "ceramic.vitreous"
            // Outer silhouette: punt, foot, straight wall, shoulder, neck.
            let shoulder: [V2] = [V2(r, 0.115), V2(r, 0.132), V2(r * 0.968, 0.150), V2(r * 0.869, 0.170), V2(r * 0.679, 0.189),
                                  V2(0.0195, 0.2005), V2(0.0152, 0.209), V2(0.0145, 0.218)]
            let lower: [V2] = [V2(0, 0.0125), V2(0.012, 0.0105), V2(0.023, 0.0045), V2(0.031, 0.0012), V2(0.036, 0.0005), V2(0.039, 0.003),
                               V2(r - 0.0003, 0.008), V2(r, 0.02), V2(r, 0.06)]
            var outer = Profile.smooth(lower + shoulder, per: 1)
            outer += Profile.smooth([V2(0.0145, 0.218), V2(0.0145, 0.2265), V2(0.0156, 0.231), V2(0.0184, 0.2335), V2(0.0190, 0.239), V2(0.0186, 0.2455),
                                     V2(0.0170, 0.2492), V2(0.0140, 0.2503)], per: 2).dropFirst()
            // Inner wall: mouth, neck, shoulder offset by the wall thickness, thick floor.
            let innerShoulder = shoulder.map { V2(max(0.0116, $0.x - w), $0.y) }
            var inner: [V2] = [V2(0.0128, 0.2503), V2(0.0120, 0.2465), V2(0.0116, 0.236), V2(0.0116, 0.224)]
            inner += Profile.smooth(Array(innerShoulder.reversed()), per: 1).dropFirst()
            inner += [V2(r - w, 0.06), V2(r - w, 0.03), V2(r - w - 0.0012, 0.0215), V2(r - w - 0.006, 0.0175), V2(0.02, 0.0168), V2(0, 0.0166)]
            m.add(Prim.lathe(outer + inner, segments: seg, seamTile: 0.09, material: glass))

            // Tea body, inset from the glass, with a meniscus at the surface.
            let ts: [V2] = [V2(0, 0.0182), V2(0.028, 0.0182), V2(r - w - 0.0017, 0.0222), V2(r - w - 0.0007, 0.032), V2(r - w - 0.0007, 0.115),
                            V2(r - w - 0.0007 - 0.0008, 0.132), V2(r * 0.968 - w - 0.0007, 0.150), V2(r * 0.869 - w - 0.0007, 0.170),
                            V2(r * 0.679 - w - 0.0007, 0.189)]
            let rTop = ts.last!.x
            var teaProfile = Profile.smooth(ts, per: 1)
            teaProfile += [V2(rTop - 0.0006, teaLevel - 0.0008), V2(rTop - 0.0018, teaLevel), V2(rTop - 0.006, teaLevel - 0.0004), V2(0, teaLevel - 0.0004)]
            m.add(Prim.lathe(teaProfile, segments: seg, seamTile: 0.1, material: tea))

            // SCOBY: two irregular pale discs riding in the surface, a darker wrinkled rim.
            let rs = rTop - 0.0035
            m.add(Prim.superellipsoid(V3(rs * 2, 0.0075, rs * 1.93), exponent: 2.7, subdivisions: detail ? 4 : 2, material: "food.batter:D6C79A"),
                  Xform(translation: V3(0.0006, teaLevel - 0.0014, 0), rotation: simd_quatf(degrees: 5, axis: V3(1, 0, 0.3))))
            m.add(Prim.superellipsoid(V3(rs * 1.35, 0.005, rs * 1.2), exponent: 2.4, subdivisions: detail ? 3 : 2, material: "food.batter:C2AE7C"),
                  Xform(translation: V3(-0.004, teaLevel - 0.0043, 0.003), rotation: simd_quatf(degrees: -14, axis: .up)))
            // Yeast strands hanging from the underside, plus sediment flecks on the floor.
            var r2 = rng.fork(7)
            for i in 0..<(detail ? 10 : 5) {
                let a = Float(i) * 2.399 + r2.float(-0.3...0.3), rad = r2.float(0.002...(rs * 0.85))
                let len = r2.float(0.035...0.085), ph = r2.float(0...6.28), sway = r2.float(0.002...0.006)
                let p0 = V3(rad * cos(a), teaLevel - 0.005, rad * sin(a))
                let pts = (0..<7).map { k -> V3 in
                    let t = Float(k) / 6
                    return V3(p0.x + sway * sin(t * 4 + ph) * t, p0.y - len * t, p0.z + sway * cos(t * 3.2 + ph) * t)
                }
                let path = catmull(pts, per: 2)
                let n = path.count
                let rad2 = (0..<n).map { k -> Float in let t = Float(k) / Float(n - 1); return 0.0019 * (1 - t) + 0.0004 * t }
                m.add(Prim.tube(path, radii: rad2, sides: 6, seamTile: 0.02, material: "food.batter:BDA066", capEnd: true))
            }
            if detail {
                for _ in 0..<6 {
                    let a = r2.float(0...6.28), d = r2.float(0.003...0.014), s = r2.float(0.002...0.004)
                    m.add(Prim.superellipsoid(V3(s * 1.6, s, s * 1.3), exponent: 2, subdivisions: 2, material: "food.batter:6A4420"),
                          Xform(translation: V3(d * cos(a), 0.0192 + s * 0.4, d * sin(a)), rotation: simd_quatf(degrees: r2.float(0...90), axis: .up)))
                }
            }

            // Paper label wrapped on the wall with a rolled-edge profile.
            let lr = r + 0.0005
            m.add(Prim.lathe([V2(lr - 0.0004, 0.0445), V2(lr, 0.0450), V2(lr, 0.1145), V2(lr - 0.0004, 0.1150)], segments: seg, seamTile: 0.35, material: label))

            // Stopper: rubber gasket, porcelain cap with a wire groove.
            m.add(Prim.torus(major: 0.0146, minor: 0.0019, segments: 32, sides: 8, material: rubber), Xform(translation: V3(0, 0.2512, 0)))
            m.add(turned([(0, 0.2515), (0.0140, 0.2515), (0.0162, 0.2535), (0.0172, 0.2585), (0.0170, 0.266), (0.0150, 0.2725), (0.0105, 0.2755),
                          (0.005, 0.2765), (0, 0.2767)], segments: 40, material: porcelain, seamTile: 0.15))
            // Steel wire bail: neck collar, two side wires over the cap, cross bar and hinge pin.
            m.add(Prim.torus(major: 0.0168, minor: 0.0009, segments: 32, sides: 6, material: steel), Xform(translation: V3(0, 0.2255, 0)))
            let loop: [V3] = [V3(-0.0165, 0.2255, 0), V3(-0.0212, 0.238, 0), V3(-0.0212, 0.248, 0), V3(-0.0197, 0.262, 0), V3(-0.0168, 0.2715, 0),
                              V3(-0.009, 0.2772, 0), V3(0, 0.2782, 0), V3(0.009, 0.2772, 0), V3(0.0168, 0.2715, 0), V3(0.0197, 0.262, 0),
                              V3(0.0212, 0.248, 0), V3(0.0212, 0.238, 0), V3(0.0165, 0.2255, 0)]
            for z: Float in [-0.0042, 0.0042] {
                let p = catmull(loop.map { V3($0.x, $0.y, z) }, per: 4)
                m.add(Prim.tube(p, radii: p.map { _ in 0.0008 }, sides: 6, seamTile: 0.02, material: steel, capEnd: true))
            }
            m.add(Prim.tube([V3(0, 0.2782, -0.0042), V3(0, 0.2782, 0.0042)], radii: [0.0008, 0.0008], sides: 6, seamTile: 0.02, material: steel, capEnd: true))
            m.add(Prim.tube([V3(-0.0212, 0.243, -0.0058), V3(-0.0212, 0.243, 0.0058)], radii: [0.0009, 0.0009], sides: 6, seamTile: 0.02, material: steel, capEnd: true))
            m.add(Prim.tube([V3(0.0212, 0.243, -0.0058), V3(0.0212, 0.243, 0.0058)], radii: [0.0009, 0.0009], sides: 6, seamTile: 0.02, material: steel, capEnd: true))

            // Condensation beads on the glass above the label and a few on the shoulder.
            if detail {
                var r3 = rng.fork(11)
                for _ in 0..<10 {
                    let a = r3.float(0...(2 * .pi)), y = r3.float(0.12...0.18)
                    let rr: Float = y < 0.132 ? r + 0.0004 : (y < 0.15 ? r * 0.968 + 0.0004 : (y < 0.17 ? r * 0.869 + 0.0006 : r * 0.7 + 0.0008))
                    let d = r3.float(0.0013...0.0032)
                    let n = V3(cos(a), 0.0, sin(a))
                    m.add(Prim.superellipsoid(V3(d, d * 0.5, d * 1.15), exponent: 2, subdivisions: 2, material: "glass.water-clear"),
                          Xform(translation: V3(n.x * rr, y, n.z * rr), rotation: simd_quatf(from: .up, to: n)))
                }
            }
            return m
        }
        var lod0 = make(64, true)
        let bb = lod0.bounds
        lod0 = lod0.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        var lod1 = make(32, false)
        lod1 = lod1.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&lod0, height: 0.05, floor: 0.5)
        groundAO(&lod1, height: 0.05, floor: 0.5)
        return LODModel(levels: [lod0, lod1], switchDistances: [3])
    }
}
