import simd
import Foundation

/// Salad spinner: clear bowl on a rubber foot ring, orange perforated basket, white pump-lid with orange knob, brake button and two rim latches. Story: dried water residue ring on the bowl wall.
public struct SaladSpinner: RealAsset {
    public static let id = "salad-spinner"
    public static let summary = "Salad spinner, 27 cm: clear plastic bowl, perforated basket, pump-knob lid with rim latches and a non-slip foot."
    public static let tags = ["prop", "interior", "kitchen", "plastic"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, distance: 1.15, studio: true)

    /// Bowl.
    public var bowl: MaterialKey = "plastic.clear"
    /// Lid.
    public var lid: MaterialKey = "plastic.white"
    /// Basket and pump knob.
    public var accent: MaterialKey = "plastic.orange:E8742A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Rubber foot ring.
        m.add(Prim.lathe([V2(0.0880, 0), V2(0.1040, 0), V2(0.1040, 0.0070), V2(0.0880, 0.0070), V2(0.0880, 0)], segments: 64, seamTile: 0.2, material: "rubber.insulating-black"))
        // Clear bowl shell.
        let outer: [V2] = [V2(0.0965, 0.0060), V2(0.0990, 0.0075), V2(0.1130, 0.0200), V2(0.1230, 0.0600), V2(0.1285, 0.1100), V2(0.1325, 0.1520)]
        var shell = DD1EKitchen.shell(outer, wall: 0.0030)
        shell.insert(V2(0, 0.0060), at: 0); shell.append(V2(0, 0.0090))
        m.add(Prim.lathe(shell, segments: 72, seamTile: 0.3, material: bowl))
        // Rim bead and bottom ridge moulding.
        m.add(Prim.lathe([V2(0.1292, 0.1500), V2(0.1345, 0.1500), V2(0.1350, 0.1530), V2(0.1345, 0.1565), V2(0.1292, 0.1565), V2(0.1292, 0.1500)], segments: 72, seamTile: 0.3, material: bowl))
        // Residue ring: dried water line on the inner wall.
        func wallR(_ yy: Float) -> Float { 0.113 + (yy - 0.02) * 0.25 - 0.0030 }
        let y1: Float = 0.034, y2: Float = 0.048
        m.add(Prim.lathe([V2(wallR(y1) + 0.0003, y1), V2(wallR(y2) + 0.0003, y2), V2(wallR(y2) - 0.0005, y2), V2(wallR(y1) - 0.0005, y1), V2(wallR(y1) + 0.0003, y1)],
                         segments: 64, seamTile: 0.3, material: "decal.soap-residue"))
        // Basket: slotted cage of curved ribs and three hoops, solid floor, rim flange.
        let prof: [V2] = [V2(0.0850, 0.0140), V2(0.1000, 0.0260), V2(0.1130, 0.0700), V2(0.1210, 0.1300), V2(0.1226, 0.1420)]
        func basketR(_ yy: Float) -> Float {
            for i in 1..<prof.count where yy <= prof[i].y {
                let t = (yy - prof[i - 1].y) / (prof[i].y - prof[i - 1].y)
                return prof[i - 1].x + (prof[i].x - prof[i - 1].x) * t
            }
            return prof[prof.count - 1].x
        }
        for i in 0..<20 {
            let a = Float(i) / 20 * 2 * .pi
            let pts = catmull(prof.map { V3($0.x * cos(a), $0.y, -$0.x * sin(a)) }, per: 1)
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0017 }, sides: 5, seamTile: 0.02, material: accent))
        }
        for hy: Float in [0.045, 0.085, 0.122] {
            m.add(Prim.torus(major: basketR(hy), minor: 0.0024, segments: 32, sides: 6, material: accent), Xform(translation: V3(0, hy, 0)))
        }
        m.add(Prim.cylinder(radius: 0.0850, height: 0.0030, bevel: 0.0010, segments: 48, material: accent), Xform(translation: V3(0, 0.0110, 0)))
        m.add(Prim.lathe([V2(0.1195, 0.1405), V2(0.1260, 0.1410), V2(0.1262, 0.1455), V2(0.1225, 0.1462), V2(0.1195, 0.1450), V2(0.1195, 0.1405)], segments: 64, seamTile: 0.1, material: accent))
        // Centre spindle.
        m.add(Prim.cylinder(radius: 0.0090, height: 0.1300, bevel: 0.0020, segments: 24, material: lid), Xform(translation: V3(0, 0.0130, 0)))
        let lidPts: [V2] = [V2(0.0, 0.1485), V2(0.1290, 0.1485), V2(0.1350, 0.1520), V2(0.1355, 0.1560), V2(0.1330, 0.1640), V2(0.1180, 0.1730), V2(0.0800, 0.1810), V2(0.0480, 0.1855)]
        func lidSurfaceY(_ r: Float) -> Float {
            var i = lidPts.count - 1
            while i > 0 && lidPts[i - 1].x > r { i -= 1 }
            if i == 0 { return lidPts[0].y }
            // outermost segment where x decreases with y; walk from the rim inward
            for k in stride(from: lidPts.count - 1, to: 3, by: -1) where r <= lidPts[k - 1].x && r >= lidPts[k].x {
                let t = (lidPts[k - 1].x - r) / (lidPts[k - 1].x - lidPts[k].x)
                return lidPts[k - 1].y + (lidPts[k].y - lidPts[k - 1].y) * t
            }
            return 0.1855
        }
        // Lid: domed disc with raised pump housing.
        let lidP: [V2] = [V2(0, 0.1485), V2(0.1290, 0.1485), V2(0.1350, 0.1520), V2(0.1355, 0.1560), V2(0.1330, 0.1640), V2(0.1180, 0.1730), V2(0.0800, 0.1810),
                          V2(0.0480, 0.1855), V2(0.0430, 0.1880), V2(0.0400, 0.1930), V2(0.0300, 0.1950), V2(0.0, 0.1952)]
        m.add(Prim.lathe(lidP, segments: 72, seamTile: 0.25, material: lid))
        // Pump knob and ring.
        m.add(Prim.cylinder(radius: 0.0285, height: 0.0050, bevel: 0.0016, segments: 32, material: accent), Xform(translation: V3(0, 0.1940, 0)))
        m.add(Prim.cylinder(radius: 0.0150, height: 0.0060, bevel: 0.0022, segments: 24, material: accent), Xform(translation: V3(0, 0.1985, 0)))
        // Brake button and two rim latches.
        m.add(Prim.cylinder(radius: 0.0090, height: 0.0055, bevel: 0.0018, segments: 20, material: accent), Xform(translation: V3(0.0770, 0.1795, 0), rotation: simd_quatf(degrees: -10, axis: V3(0, 0, 1))))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.0120, 0.0110, 0.0300), radius: 0.0030, bevelSegments: 2, material: lid), Xform(translation: V3(s * 0.1270, 0.1640, 0), rotation: simd_quatf(degrees: -s * 18, axis: V3(0, 0, 1))))
            m.add(Prim.roundedBox(V3(0.0060, 0.0090, 0.0220), radius: 0.0020, bevelSegments: 1, material: accent), Xform(translation: V3(s * 0.1315, 0.1585, 0), rotation: simd_quatf(degrees: -s * 6, axis: V3(0, 0, 1))))
        }
        // Torn lettuce scraps left on the basket floor.
        for _ in 0..<7 {
            let a = rng.float(0...(2 * .pi)), rr = rng.float(0.012...0.075)
            m.add(Prim.superellipsoid(V3(rng.float(0.018...0.030), 0.0012, rng.float(0.010...0.016)), exponent: 2.4, subdivisions: 5, material: "plastic.matte:5E9B3C"),
                  Xform(translation: V3(rr * cos(a), 0.0152, -rr * sin(a)), rotation: DD1EKitchen.rotY(rng.float(0...180))))
        }
        // Water droplets left on the lid from rinsing.
        for _ in 0..<4 {
            let a = rng.float(0...(2 * .pi)), rr = rng.float(0.05...0.115)
            let yy = 0.1485 + (0.1290 - rr) * 0.0
            _ = yy
            let ly = lidSurfaceY(rr)
            let s = rng.float(0.004...0.008)
            m.add(Prim.superellipsoid(V3(s, s * 0.45, s * 0.8), exponent: 2.2, subdivisions: 4, material: "glass.water-clear"),
                  Xform(translation: V3(rr * cos(a), ly, -rr * sin(a)), rotation: DD1EKitchen.rotY(rng.float(0...180))))
        }
        _ = rng.float()
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
