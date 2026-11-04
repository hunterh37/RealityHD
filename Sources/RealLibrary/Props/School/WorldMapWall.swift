import simd
import Foundation

/// World Map Wall: everyday school, printed. Parts: printed paper sheet, ocean field, continent polygons, lat lon grid, title band, legend, wood hanging rods.
public struct WorldMapWall: RealAsset {
    public static let id = "world-map-wall"
    public static let summary = "Printed wall world map with continents, graticule, title band, legend and wood rods."
    public static let tags = ["prop", "interior", "school", "paper", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.2, 0.8, 0.01)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, rod: Float = 0.005
        // Paper sheet between two wood hanging rods.
        m.add(Prim.roundedBox(V3(W - 0.02, H - 2 * rod, 0.002), radius: 0.0004, bevelSegments: 1, material: "paper.sheet:F2EEE0"), Xform(translation: V3(0, H / 2, -0.003)))
        for y in [rod, H - rod] {
            m.add(Prim.cylinder(radius: rod, height: W, bevel: 0.0005, segments: 14, material: "wood.walnut"),
                  Xform(translation: V3(-W / 2, y, -0.002), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        }
        // Map face: 360 x 180 degrees at 1.08 x 0.54 m, ocean field first.
        let mw: Float = 1.08, mh: Float = 0.54, cy = H * 0.46
        let sx = mw / 360, sy = mh / 180
        m.add(Prim.roundedBox(V3(mw, mh, 0.0006), radius: 0.0002, bevelSegments: 1, material: "paper.sheet:9CC9E8"), Xform(translation: V3(0, cy, -0.0016)))
        let land: [(String, [V2])] = [
            ("D8CFA0", [V2(-168, 66), V2(-162, 70), V2(-150, 71), V2(-140, 69), V2(-125, 70), V2(-110, 72), V2(-95, 72), V2(-82, 68), V2(-80, 62), V2(-92, 58), V2(-95, 52), V2(-82, 52), V2(-78, 60), V2(-65, 60), V2(-62, 50), V2(-70, 44), V2(-76, 37), V2(-81, 31), V2(-80, 25), V2(-84, 30), V2(-90, 29), V2(-97, 27), V2(-97, 21), V2(-90, 19), V2(-87, 21), V2(-88, 15), V2(-83, 15), V2(-83, 10), V2(-79, 9), V2(-80, 7), V2(-84, 8), V2(-86, 12), V2(-92, 14), V2(-97, 16), V2(-105, 20), V2(-110, 24), V2(-113, 31), V2(-117, 32), V2(-121, 35), V2(-124, 40), V2(-124, 48), V2(-130, 54), V2(-137, 58), V2(-148, 60), V2(-155, 57), V2(-165, 54), V2(-158, 58), V2(-165, 62)]),
            ("B9D49A", [V2(-79, 9), V2(-72, 12), V2(-62, 10), V2(-52, 5), V2(-50, 0), V2(-44, -2), V2(-35, -6), V2(-39, -14), V2(-41, -22), V2(-48, -26), V2(-53, -34), V2(-58, -38), V2(-65, -41), V2(-66, -47), V2(-69, -52), V2(-73, -52), V2(-75, -46), V2(-73, -38), V2(-71, -30), V2(-70, -18), V2(-76, -14), V2(-81, -5), V2(-80, 0), V2(-77, 5)]),
            ("EDEDE6", [V2(-55, 60), V2(-45, 60), V2(-20, 70), V2(-20, 80), V2(-40, 83), V2(-65, 80), V2(-70, 76), V2(-56, 68)]),
            ("E3C37A", [V2(-17, 21), V2(-10, 30), V2(-6, 36), V2(10, 37), V2(11, 33), V2(20, 32), V2(32, 31), V2(34, 28), V2(43, 12), V2(51, 12), V2(45, 2), V2(40, -5), V2(40, -15), V2(35, -24), V2(33, -29), V2(27, -34), V2(18, -34), V2(14, -22), V2(12, -6), V2(9, 3), V2(5, 5), V2(-8, 4), V2(-13, 8), V2(-17, 14)]),
            ("E8B7A0", [V2(-9, 37), V2(-9, 43), V2(-1, 46), V2(-4, 48), V2(2, 51), V2(8, 54), V2(10, 58), V2(12, 55), V2(21, 55), V2(24, 60), V2(30, 60), V2(22, 66), V2(28, 71), V2(42, 67), V2(60, 69), V2(72, 73), V2(100, 78), V2(140, 72), V2(170, 70), V2(180, 66), V2(165, 60), V2(156, 57), V2(160, 52), V2(140, 52), V2(141, 46), V2(135, 43), V2(129, 35), V2(126, 38), V2(122, 40), V2(122, 30), V2(114, 22), V2(108, 19), V2(106, 10), V2(100, 13), V2(103, 2), V2(98, 8), V2(98, 16), V2(92, 21), V2(88, 22), V2(80, 15), V2(77, 8), V2(72, 20), V2(67, 24), V2(57, 25), V2(52, 27), V2(48, 30), V2(51, 26), V2(56, 25), V2(58, 22), V2(52, 16), V2(43, 13), V2(35, 28), V2(36, 36), V2(27, 37), V2(26, 40), V2(23, 37), V2(21, 40), V2(19, 42), V2(14, 45), V2(18, 40), V2(15, 38), V2(12, 44), V2(8, 44), V2(3, 43), V2(0, 39), V2(-5, 36)]),
            ("E7A46C", [V2(114, -22), V2(122, -18), V2(130, -12), V2(137, -12), V2(142, -11), V2(146, -19), V2(153, -26), V2(150, -37), V2(141, -38), V2(131, -31), V2(115, -34)]),
            ("F1F1EC", [V2(-180, -70), V2(-120, -74), V2(-60, -65), V2(0, -70), V2(60, -67), V2(120, -66), V2(180, -70), V2(180, -90), V2(-180, -90)]),
            ("E8B7A0", [V2(-5, 50), V2(1, 51), V2(0, 55), V2(-3, 58), V2(-6, 57)]),
            ("E8B7A0", [V2(130, 31), V2(135, 34), V2(141, 38), V2(142, 43), V2(140, 41), V2(135, 36)]),
            ("E3C37A", [V2(44, -25), V2(47, -25), V2(50, -15), V2(49, -12), V2(44, -17)]),
            ("B9D49A", [V2(167, -46), V2(172, -41), V2(175, -37), V2(178, -38), V2(172, -46)]),
            ("B9D49A", [V2(95, 5), V2(105, -6), V2(115, -8), V2(120, -9), V2(110, -2), V2(103, 2)])
        ]
        for (hex, pts) in land {
            var o = pts.map { V2($0.x * sx, $0.y * sy) }
            var area: Float = 0
            for i in 0..<o.count { let a = o[i], b = o[(i + 1) % o.count]; area += a.x * b.y - b.x * a.y }
            if area < 0 { o.reverse() }
            m.add(Prim.extrude(o, depth: 0.0006, bevel: 0.0001, bevelSegments: 1, material: "paper.sheet:" + hex), Xform(translation: V3(0, cy, -0.0010)))
        }
        // Graticule every 30 degrees plus equator, as flat quads on top of the face.
        let gz: Float = -0.0005, gn = V3(0, 0, 1)
        var grid = Surface(material: "plastic.matte:5A7E9A")
        func bar(_ x: Float, _ y: Float, _ w: Float, _ h: Float) {
            for order in 0..<2 {
                let p = [V2(x, y), V2(x + w, y), V2(x + w, y + h), V2(x, y + h)]
                let q = order == 0 ? p : p.reversed()
                let i = q.map { grid.add(V3($0.x, $0.y, gz), gn, V2($0.x, $0.y)) }
                grid.quad(i[0], i[1], i[2], i[3])
            }
        }
        for lon in stride(from: -180, through: 180, by: 30) { bar(Float(lon) * sx - 0.0003, cy - mh / 2, 0.0006, mh) }
        for lat in stride(from: -90, through: 90, by: 30) { bar(-mw / 2, cy + Float(lat) * sy - 0.0003, mw, lat == 0 ? 0.0009 : 0.0006) }
        // Title band and legend (bars stand in for printed text).
        bar(-mw / 2, cy + mh / 2 + 0.01, mw, 0.0005)
        grid.computeTangents()
        m.add(grid, Xform())
        m.add(Prim.roundedBox(V3(mw, 0.05, 0.0006), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:1E3A66"), Xform(translation: V3(0, cy + mh / 2 + 0.045, -0.0016)))
        var txt = Surface(material: "plastic.matte:F2EEE0")
        for k in 0..<6 {
            let x0 = -0.2 + Float(k) * 0.07, w: Float = 0.055
            let p = [V2(x0, cy + mh / 2 + 0.040), V2(x0 + w, cy + mh / 2 + 0.040), V2(x0 + w, cy + mh / 2 + 0.054), V2(x0, cy + mh / 2 + 0.054)]
            for order in 0..<2 {
                let q = order == 0 ? p : p.reversed()
                let i = q.map { txt.add(V3($0.x, $0.y, -0.0011), V3(0, 0, 1), V2($0.x, $0.y)) }
                txt.quad(i[0], i[1], i[2], i[3])
            }
        }
        txt.computeTangents()
        m.add(txt, Xform())
        // Legend box with colored key squares.
        m.add(Prim.roundedBox(V3(0.2, 0.06, 0.0006), radius: 0.0002, bevelSegments: 1, material: "paper.sheet:FAF7EC"), Xform(translation: V3(0.4, cy - mh / 2 - 0.045, -0.0016)))
        for (k, hex) in ["D8CFA0", "B9D49A", "E3C37A", "E8B7A0", "E7A46C"].enumerated() {
            m.add(Prim.roundedBox(V3(0.016, 0.01, 0.0005), radius: 0.0001, bevelSegments: 1, material: "paper.sheet:" + hex),
                  Xform(translation: V3(0.335 + Float(k) * 0.03, cy - mh / 2 - 0.035, -0.0010)))
            m.add(Prim.roundedBox(V3(0.02, 0.003, 0.0004), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:3A3A3A"),
                  Xform(translation: V3(0.335 + Float(k) * 0.03, cy - mh / 2 - 0.055, -0.0010)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
