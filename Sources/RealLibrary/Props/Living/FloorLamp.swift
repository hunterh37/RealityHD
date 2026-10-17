import simd
import Foundation

/// Floor lamp: mid-century brass floor lamp, 1.65 m tall with a 45 cm linen drum shade. Parts: weighted round base with a brass boss and
/// felt pads, slim brushed brass pole with turned collars, switch and cord (inline rocker switch, flat plug), fabric drum shade with
/// wire rim rings, inner diffuser liner and bulb on a spider fitter, brass finial.
public struct FloorLamp: RealAsset {
    public static let id = "floor-lamp"
    public static let summary = "Floor lamp, 1.65 m: round weighted base, brass pole with inline switch and cord, linen drum shade with warm bulb."
    public static let tags = ["prop", "floorplan", "living", "light", "metal", "fabric", "interior"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 10, distance: 2.5, studio: true)

    /// Overall size in meters (x width, y height, z depth). Width and depth are the shade diameter.
    public var size = V3(0.45, 1.65, 0.45)
    /// Height of the shade bottom edge (m).
    public var shadeBottom: Float = 1.372
    /// Shade height (m).
    public var shadeHeight: Float = 0.235
    /// Brass for pole, spider, collars and finial.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Polished brass where hands touch it: collars, knob and finial.
    public var polished: MaterialKey = "metal.brass"
    /// Painted iron base.
    public var baseMetal: MaterialKey = "metal.powdercoat:2B2B2D"
    /// Shade fabric.
    public var fabric: MaterialKey = "fabric.linen:E3D8BC"
    /// Shade lining.
    public var lining: MaterialKey = "plastic.matte:EFE6D2"
    /// Bulb glow.
    public var glow: MaterialKey = "emissive.warm"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ seg: Int, _ detail: Bool) -> Model {
            var m = Model(name: Self.id)
            let R = size.x / 2
            let shadeSeg = seg * 5 / 4
            let sb = shadeBottom, sh = shadeHeight, st = sb + sh
            // Weighted base: domed iron disc, 30 cm across, with a stepped brass boss.
            let base: [V2] = [V2(0, 0.0045), V2(0.12, 0.0045), V2(0.1425, 0.0045), V2(0.1505, 0.0075), V2(0.152, 0.012), V2(0.1495, 0.0195), V2(0.138, 0.0262),
                              V2(0.105, 0.0305), V2(0.06, 0.0335), V2(0.03, 0.036), V2(0.0, 0.0365)]
            m.add(Prim.lathe(base, segments: seg, seamTile: 0.3, material: baseMetal))
            let boss: [V2] = [V2(0.0, 0.03), V2(0.044, 0.03), V2(0.046, 0.033), V2(0.046, 0.039), V2(0.0415, 0.043), V2(0.032, 0.0455), V2(0.022, 0.056), V2(0.0135, 0.066),
                              V2(0.0105, 0.08), V2(0.0, 0.08)]
            m.add(Prim.lathe(boss, segments: seg * 2 / 3, seamTile: 0.1, material: brass))
            // Felt pads under the rim (dark, thin).
            for k in 0..<3 {
                let a = Float(k) / 3 * 2 * .pi + 0.4
                m.add(Prim.cylinder(radius: 0.012, height: 0.0045, bevel: 0.0006, segments: 12, material: "fabric.wool:2A2A2A"),
                      Xform(translation: V3(0.125 * cos(a), 0, 0.125 * sin(a))))
            }
            // Pole: brushed brass tube with turned collars.
            let poleTop = sb + 0.02
            m.add(Prim.cylinder(radius: 0.0092, height: poleTop - 0.07, bevel: 0.0004, segments: max(12, seg / 3), material: brass), Xform(translation: V3(0, 0.07, 0)))
            for y: Float in [0.34, 0.93] {
                let collar: [V2] = [V2(0.0089, y - 0.014), V2(0.0145, y - 0.012), V2(0.0165, y - 0.006), V2(0.0165, y + 0.006), V2(0.0145, y + 0.012), V2(0.0089, y + 0.014)]
                m.add(Prim.lathe(collar, segments: seg / 2, seamTile: 0.05, material: polished))
            }
            // Pole joint seams (hairline grooves).
            for y: Float in [0.62, 1.18] {
                m.add(Prim.torus(major: 0.0094, minor: 0.0006, segments: 16, sides: 5, material: "metal.brass-aged"), Xform(translation: V3(0, y, 0)))
            }
            // Socket neck with a turn knob, spider fitter and the bulb.
            let neck: [V2] = [V2(0.0, sb + 0.005), V2(0.016, sb + 0.005), V2(0.019, sb + 0.012), V2(0.0185, sb + 0.04), V2(0.016, sb + 0.052), V2(0.0, sb + 0.052)]
            m.add(Prim.lathe(neck, segments: seg / 2, seamTile: 0.06, material: brass))
            let knob: [V2] = [V2(0, 0), V2(0.0058, 0), V2(0.0066, 0.002), V2(0.0066, 0.010), V2(0.0045, 0.0135), V2(0, 0.0135)]
            m.add(Prim.lathe(knob, segments: 14, seamTile: 0.03, material: polished),
                  Xform(translation: V3(0.0185, sb + 0.03, 0), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            let bulbCenter = V3(0, sb + 0.052 + 0.045, 0)
            let bulb: [V2] = [V2(0.0, 0.0), V2(0.007, 0.001), V2(0.009, 0.014), V2(0.0225, 0.04), V2(0.0285, 0.062), V2(0.0285, 0.078), V2(0.0215, 0.098), V2(0.008, 0.1105), V2(0.0, 0.1115)]
            m.add(Prim.lathe(bulb.map { V2($0.x, $0.y - 0.0556) }, segments: seg / 2, seamTile: 0.1, material: glow), Xform(translation: bulbCenter))
            // Spider arms to the bottom rim ring and the top ring.
            let ringR = R - 0.0075
            for k in 0..<3 {
                let a = Float(k) / 3 * 2 * .pi + 0.5
                let d = V3(cos(a), 0, sin(a))
                let p0 = V3(0, sb + 0.026, 0) + d * 0.015, p1 = d * (ringR - 0.001) + V3(0, sb + 0.0035, 0)
                m.add(Prim.tube([p0, (p0 + p1) / 2 + V3(0, 0.001, 0), p1], radii: [0.0025, 0.0022, 0.002], sides: 6, seamTile: 0.02, material: brass, capEnd: true))
            }
            for k in 0..<3 {
                let a = Float(k) / 3 * 2 * .pi + 0.5 + .pi / 3
                let d = V3(cos(a), 0, sin(a))
                let p0 = V3(0, st - 0.004, 0), p1 = d * (ringR - 0.001) + V3(0, st - 0.004, 0)
                m.add(Prim.tube([p0, p1], radii: [0.002, 0.002], sides: 6, seamTile: 0.02, material: brass, capEnd: true))
            }
            // Wire rim rings inside the shade.
            for y: Float in [sb + 0.0035, st - 0.004] {
                m.add(Prim.torus(major: ringR, minor: 0.0014, segments: shadeSeg, sides: 4, material: brass), Xform(translation: V3(0, y, 0)))
            }
            // Finial: turned brass cap on the top spider.
            let fin: [V2] = [V2(0, st - 0.006), V2(0.007, st - 0.006), V2(0.007, st - 0.002), V2(0.0048, st + 0.002), V2(0.0045, st + 0.01), V2(0.0105, st + 0.017),
                             V2(0.0125, st + 0.026), V2(0.0095, st + 0.036), V2(0.003, st + 0.0415), V2(0, st + 0.0425)]
            // Shade: linen drum with turned-over top and bottom edges and a pressed seam; liner inside.
            let wallT: Float = 0.0012
            let outerPts: [V2] = [V2(R - 0.003, sb), V2(R, sb + 0.003), V2(R, sb + 0.012), V2(R - 0.0002, sb + sh * 0.5), V2(R, st - 0.012), V2(R, st - 0.003), V2(R - 0.003, st),
                                  V2(R - 0.006, st - 0.001), V2(R - 0.008, st - 0.004), V2(R - 0.008 - wallT, st - 0.0045), V2(R - 0.008 - wallT, st - 0.012),
                                  V2(R - 0.0085 - wallT, sb + sh * 0.5), V2(R - 0.008 - wallT, sb + 0.012), V2(R - 0.008 - wallT, sb + 0.004), V2(R - 0.006, sb + 0.0005)]
            var shade = Prim.lathe(outerPts, segments: shadeSeg, seamTile: 0.5, material: fabric)
            if detail { shade.deform { p in
                let a = atan2(p.z, p.x)
                let r = simd_length(V2(p.x, p.z))
                let k = 1 + 0.0009 * sin(a * 7 + 0.3) * ((r > R - 0.004) ? 1 : 0)
                return V3(p.x * k, p.y, p.z * k)
            } }
            m.add(shade)
            // Liner: the lit inside face, slightly inside the fabric.
            let rl = R - 0.0105 - wallT
            let lin: [V2] = [V2(rl, sb + 0.012), V2(rl, sb + sh * 0.5), V2(rl, st - 0.012)]
            m.add(Prim.lathe(lin, segments: shadeSeg, seamTile: 0.5, material: lining).flipped())
            // Binding tape on both edges.
            for y in [sb + 0.004, st - 0.004] {
                let tape: [V2] = [V2(R + 0.0004, y - 0.0065), V2(R + 0.0012, y - 0.0055), V2(R + 0.0012, y + 0.0055), V2(R + 0.0004, y + 0.0065)]
                m.add(Prim.lathe(tape, segments: shadeSeg, seamTile: 0.5, material: "fabric.canvas:BDB095"))
            }
            // Vertical overlap seam of the fabric.
            m.add(Prim.roundedBox(V3(0.0022, sh - 0.03, 0.0012), radius: 0.0004, bevelSegments: 1, material: "fabric.canvas:C8BDA3"),
                  Xform(translation: V3(R + 0.0006, sb + sh / 2, 0)))
            // Finial on top of the spider hub.
            m.add(Prim.lathe(fin, segments: seg / 2, seamTile: 0.05, material: polished))
            // Cord: out of the base at the back, curling on the floor to an inline rocker switch and a flat plug.
            let cord = catmull([V3(0.01, 0.022, -0.148), V3(0.012, 0.0072, -0.19), V3(0.04, 0.0072, -0.208), V3(0.09, 0.0072, -0.2), V3(0.13, 0.0072, -0.17),
                                V3(0.15, 0.0072, -0.115)], per: 5)
            m.add(Prim.tube(cord, radii: cord.map { _ in 0.0033 }, sides: 6, seamTile: 0.02, material: "plastic.black:1E1E1E", capEnd: true))
            let sw = V3(0.09, 0.0072, -0.2)
            m.add(Prim.roundedBox(V3(0.034, 0.014, 0.017), radius: 0.0035, bevelSegments: 2, material: "plastic.black:222222"), Xform(translation: V3(sw.x, 0.007, sw.z), rotation: simd_quatf(degrees: -10, axis: .up)))
            m.add(Prim.roundedBox(V3(0.012, 0.004, 0.011), radius: 0.001, bevelSegments: 1, material: "plastic.matte:E7DFD0"), Xform(translation: V3(sw.x, 0.0152, sw.z)))
            let plug = V3(0.15, 0, -0.108)
            m.add(Prim.roundedBox(V3(0.026, 0.011, 0.02), radius: 0.003, bevelSegments: 2, material: "plastic.black:1E1E1E"), Xform(translation: V3(plug.x, 0.0057, plug.z + 0.0)))
            for s: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.0016, 0.0016, 0.014), radius: 0.0004, bevelSegments: 1, material: "metal.brass"), Xform(translation: V3(plug.x + s * 0.006, 0.0057, plug.z + 0.016)))
            }
            groundAO(&m, height: 0.03, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(40, true), make(20, false)], switchDistances: [5])
    }
}
