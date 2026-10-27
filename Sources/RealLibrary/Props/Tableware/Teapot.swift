import simd
import Foundation

/// Teapot: everyday tableware, glazed ceramic. Parts: round glazed body, unglazed foot ring, lid with knob and seat, curved spout, pulled loop handle, strainer holes inside, chipped lid rim and tea-stained spout tip.
public struct Teapot: RealAsset {
    public static let id = "teapot"
    public static let summary = "Glazed ceramic teapot: round body, seated lid with knob, curved spout, loop handle, chipped lid and stained spout tip."
    public static let tags = ["prop", "interior", "ceramic", "kitchen", "container"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 22, studio: true)

    /// Overall size in meters (x width spout to handle, y height, z depth).
    public var size = V3(0.22, 0.15, 0.15)
    /// Glaze material.
    public var glaze: MaterialKey = "ceramic.celadon"
    /// Unglazed foot ring.
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    /// Chip material.
    public var chipMaterial: MaterialKey = "ceramic.porcelain-fracture"
    /// Tea stain tint at the spout tip.
    public var stain: MaterialKey = "ceramic.stoneware:8A6540"
    public init() {}

    static let outer: [V2] = [V2(0, 0.0035), V2(0.030, 0.0032), V2(0.0338, 0.0008), V2(0.0348, 0.0), V2(0.0415, 0.0022), V2(0.0525, 0.0105), V2(0.0645, 0.0265),
                              V2(0.0725, 0.0480), V2(0.0752, 0.0640), V2(0.0725, 0.0820), V2(0.0620, 0.0960), V2(0.0500, 0.1030), V2(0.0460, 0.1052)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let wall: Float = 0.0038, floorY: Float = 0.0060
        m.add(Prim.lathe(DD1FTableware.shell(outer: Self.outer, wall: wall, floorY: floorY), segments: seg, seamTile: 0.3, material: glaze))
        m.add(Prim.lathe([V2(0.0340, 0.0010), V2(0.0349, -0.00006), V2(0.0418, 0.0026)], segments: seg, seamTile: 0.3, material: foot))
        // Lid: plug seated in the mouth, flange resting on the rim, dome and knob.
        let lid: [V2] = [V2(0, 0.1075), V2(0.0376, 0.1075), V2(0.0382, 0.1022), V2(0.0394, 0.1020), V2(0.0397, 0.1062), V2(0.0452, 0.1064), V2(0.0463, 0.1070),
                         V2(0.0459, 0.1082), V2(0.0430, 0.1112), V2(0.0370, 0.1170), V2(0.0290, 0.1215), V2(0.0200, 0.1245), V2(0.0120, 0.1262),
                         V2(0.0085, 0.1268), V2(0.0072, 0.1280), V2(0.0072, 0.1370), V2(0.0098, 0.1410), V2(0.0108, 0.1440), V2(0.0092, 0.1478), V2(0.0050, 0.1496), V2(0, 0.1500)]
        m.add(Prim.lathe(lid, segments: seg, seamTile: 0.3, material: glaze))
        // Steam hole in the dome.
        m.add(Prim.cylinder(radius: 0.0016, height: 0.0008, bevel: 0.0003, segments: 10, bevelSegments: 1, material: "ceramic.porcelain-black"),
              Xform(translation: V3(-0.019, 0.1237, 0), rotation: simd_quatf(angle: 0.38, axis: V3(0, 0, 1))))
        // Spout: tapered tube from the shoulder to a tip at +X, dark bore disc at the end.
        let sp = catmull([V3(0.058, 0.034, 0), V3(0.078, 0.040, 0), V3(0.092, 0.057, 0), V3(0.1005, 0.079, 0), V3(0.1070, 0.093, 0), V3(0.1100, 0.099, 0)], per: detail ? 5 : 3)
        let rad: [Float] = sp.indices.map { i in 0.0165 - 0.0100 * Float(i) / Float(sp.count - 1) }
        m.add(Prim.tube(sp, radii: rad, sides: detail ? 18 : 10, seamTile: 0.1, material: glaze))
        let n = sp.count
        let tipDir = (sp[n - 1] - sp[n - 2]).normalized
        let tq = simd_quatf(from: V3(0, 1, 0), to: tipDir)
        m.add(Prim.cylinder(radius: rad[n - 1] * 0.7, height: 0.0008, bevel: 0.0002, segments: 14, bevelSegments: 1, material: "ceramic.porcelain-black:2A1E16"),
              Xform(translation: sp[n - 1] - tipDir * 0.0003, rotation: tq))
        // Tea stain: the last centimetre of the spout tinted brown.
        let k0 = max(0, n - 4)
        let stainPath = Array(sp[k0...])
        m.add(Prim.tube(stainPath, radii: rad[k0...].map { $0 + 0.0003 }, sides: detail ? 18 : 10, seamTile: 0.1, material: stain, capEnd: false))
        // Strainer holes inside the body around the spout root (cluster of dark dots).
        if detail {
            for (i, d) in [(0.0, 0.0), (0.012, 0.0), (-0.012, 0.0), (0.006, 0.0105), (-0.006, 0.0105), (0.006, -0.0105), (-0.006, -0.0105)].enumerated() {
                let y: Float = 0.040 + Float(d.1)
                let ang = Float(d.0) / 0.0495
                let rin = DD1FTableware.radius(Self.outer, at: y) - wall - 0.0003
                let c = V3(cos(ang) * rin, y, sin(ang) * rin)
                _ = i
                m.add(Prim.cylinder(radius: 0.0016, height: 0.0006, bevel: 0.0002, segments: 8, bevelSegments: 1, material: "ceramic.porcelain-black:1E1712"),
                      Xform(translation: c, rotation: simd_quatf(from: V3(0, 1, 0), to: V3(-cos(ang), 0, -sin(ang)))))
            }
        }
        // Loop handle at -X, thumb rest on top.
        let ctrl = [V2(0.0560, 0.0990), V2(0.0820, 0.1030), V2(0.1020, 0.0900), V2(0.1060, 0.0650), V2(0.0980, 0.0420), V2(0.0760, 0.0300), V2(0.0640, 0.0330)]
        m.add(DD1FTableware.loop(ctrl, dir: V3(-1, 0, 0), section: V2(0.0150, 0.0100), detail: detail, flare: 0.5, material: glaze))
        // Story: chip on the lid flange.
        DD1FTableware.chip(&m, radius: 0.0460, y: 0.1078, angle: 0.8, size: 0.0085, material: chipMaterial, off: .zero)
        groundAO(&m, height: 0.03, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(64, true), make(32, false)], switchDistances: [3.5])
    }
}
