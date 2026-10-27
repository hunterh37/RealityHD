import simd
import Foundation

/// Cutlery tray, 35 x 5 x 28 cm: molded off-white plastic with a floor, rounded-corner wall rail with a rolled top lip,
/// a floor fillet, one long divider and three cross dividers (two with finger notches, one with a chipped corner),
/// four corner feet and ejector-pin marks under the compartments. Scuff streaks mark the floor.
public struct CutleryTray: RealAsset {
    public static let id = "cutlery-tray"
    public static let summary = "Cutlery tray, plastic: rounded tray with raised rim, four dividers with fillets, finger notch, corner feet, scuffed floor and one chipped divider edge."
    public static let tags = ["prop", "interior", "tableware", "plastic"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 42, distance: 0.9, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.35, 0.05, 0.28)
    /// Tray plastic.
    public var plastic: MaterialKey = "plastic.matte:E9E6DD"
    /// Slightly lighter, polished rim lip.
    public var lip: MaterialKey = "plastic.matte:F2EFE7"
    /// Yellowed food stains.
    public var yellowed: MaterialKey = "plastic.matte:DDD3AE"
    /// Feet and wear streaks.
    public var worn: MaterialKey = "plastic.medical-grey-worn:DAD6CC"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    /// Divider outline in XY (x along its length), optional finger notch on top and optional chipped right-top corner.
    static func divider(length L: Float, height h: Float, notchX: Float?, chip: Bool) -> [V2] {
        var p: [V2] = [V2(-L / 2, 0), V2(L / 2, 0)]
        if chip { p += [V2(L / 2, h - 0.016), V2(L / 2 - 0.004, h - 0.009), V2(L / 2 - 0.0095, h - 0.0045), V2(L / 2 - 0.017, h)] }
        else { p.append(V2(L / 2, h)) }
        if let nx = notchX {
            for k in 0...8 { let a = Float(k) / 8 * .pi; p.append(V2(nx + 0.025 * cos(a), h - 0.022 * sin(a))) }
        }
        p.append(V2(-L / 2, h))
        return Shape2D.rounded(p, radius: 0.0016, segments: 2)
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, footH: Float = 0.004, floorT: Float = 0.003, H = size.y
        let floorTop = footH + floorT, wallT: Float = 0.0028
        m.add(Prim.extrude(Shape2D.roundedRect(W - 0.008, D - 0.008, radius: 0.02, segments: 5), depth: floorT, bevel: 0.0012, bevelSegments: 2, material: plastic),
              Xform(translation: V3(0, footH + floorT / 2, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        // Wall rail and rolled lip.
        let wallPath = DD1HTable.railPath(w: W - wallT, d: D - wallT, radius: 0.022, y: footH, segments: detail ? 6 : 3)
        m.add(DD1HTable.wall(path: wallPath, h: H - footH - 0.0014, t: wallT, material: plastic))
        m.add(DD1HTable.bead(path: DD1HTable.railPath(w: W - wallT, d: D - wallT, radius: 0.022, y: H - 0.0021, segments: detail ? 6 : 3),
                             r: 0.0022, sides: 6, material: lip))
        // Floor fillet where wall meets floor.
        m.add(DD1HTable.bead(path: DD1HTable.railPath(w: W - 2 * wallT - 0.002, d: D - 2 * wallT - 0.002, radius: 0.02, y: floorTop + 0.0012, segments: 4),
                             r: 0.0032, sides: 5, material: plastic))
        // Dividers.
        let dh: Float = H - footH - floorT - 0.0034, y0 = floorTop - 0.0004
        let ext = { (o: [V2]) in Prim.extrude(o, depth: 0.0026, bevel: 0.0008, bevelSegments: 2, material: self.plastic) }
        m.add(ext(Self.divider(length: W - 0.008, height: dh, notchX: -0.045, chip: false)), Xform(translation: V3(0, y0, 0)))
        let across = simd_quatf(degrees: 90, axis: .up)
        m.add(ext(Self.divider(length: D / 2 - 0.007, height: dh, notchX: nil, chip: false)), Xform(translation: V3(-0.058, y0, -D / 4), rotation: across))
        m.add(ext(Self.divider(length: D / 2 - 0.007, height: dh, notchX: nil, chip: true)), Xform(translation: V3(0.058, y0, -D / 4), rotation: across))
        m.add(ext(Self.divider(length: D / 2 - 0.007, height: dh, notchX: 0.0, chip: false)), Xform(translation: V3(0.04, y0, D / 4), rotation: across))
        // Fillets where the dividers meet the floor and the walls.
        let fy = floorTop + 0.0018
        func fillet(_ a: V3, _ b: V3) { m.add(Prim.tube([a, b], radii: [0.0021, 0.0021], sides: 5, seamTile: 0.02, material: plastic)) }
        for s in [Float(-1), 1] {
            fillet(V3(-W / 2 + 0.004, fy, s * 0.0019 * 2.2), V3(W / 2 - 0.004, fy, s * 0.0019 * 2.2))
            for (x, z0, z1) in [(Float(-0.058), -D / 2 + 0.006, Float(-0.002)), (0.058, -D / 2 + 0.006, -0.002), (0.04, 0.002, D / 2 - 0.006)] {
                fillet(V3(x + s * 0.0042, fy, z0), V3(x + s * 0.0042, fy, z1))
            }
        }
        // Molded liner ribs across every compartment floor.
        let ribY = floorTop + 0.0006
        let cells: [(Float, Float, Float)] = [(-0.1155, 0.115, -D / 4), (0, 0.113, -D / 4), (0.1155, 0.115, -D / 4), (-0.066, 0.208, D / 4), (0.1065, 0.128, D / 4)]
        for (cx, w, cz) in cells { for r in -2...2 {
            m.add(cuboid(V3(w - 0.03, 0.0012, 0.0035), material: lip), Xform(translation: V3(cx, ribY, cz + Float(r) * 0.022)))
        }}
        // Corner feet.
        for sx in [Float(-1), 1] { for sz in [Float(-1), 1] {
            m.add(Prim.cylinder(radius: 0.014, height: footH + 0.0006, bevel: 0.0012, segments: detail ? 16 : 10, bevelSegments: 2, material: worn),
                  Xform(translation: V3(sx * (W / 2 - 0.038), 0, sz * (D / 2 - 0.036))))
        }}
        if detail {
            // Ejector-pin marks and floor scuffs.
            for p in [V2(-0.11, -0.08), V2(0.11, -0.08), V2(-0.11, 0.08), V2(0.11, 0.08), V2(0.0, -0.09)] {
                m.add(Prim.cylinder(radius: 0.0045, height: 0.0006, bevel: 0.0002, segments: 12, bevelSegments: 1, material: lip),
                      Xform(translation: V3(p.x, floorTop - 0.0001, p.y)))
            }
            let fl: (Float, Float) -> Float = { _, _ in floorTop }
            // Faint food stains yellowing two compartments.
            m.add(DD1HTable.decal(center: V2(-0.07, 0.07), rx: 0.05, rz: 0.03, yaw: 0.2, lift: 0.0004, rings: 3, material: yellowed, height: fl))
            m.add(DD1HTable.decal(center: V2(0.0, -0.07), rx: 0.03, rz: 0.04, yaw: 0.7, lift: 0.0004, rings: 3, material: yellowed, height: fl))
            m.add(DD1HTable.decal(center: V2(0.085, 0.06), rx: 0.034, rz: 0.006, yaw: 0.45, lift: 0.0005, rings: 2, material: worn, height: fl))
            m.add(DD1HTable.decal(center: V2(-0.1, -0.05), rx: 0.022, rz: 0.005, yaw: -0.3, lift: 0.0005, rings: 2, material: worn, height: fl))
            m.add(DD1HTable.decal(center: V2(-0.02, 0.1), rx: 0.016, rz: 0.004, yaw: 0.9, lift: 0.0005, rings: 2, material: worn, height: fl))
        }
        groundAO(&m, height: 0.03)
        return m
    }
}
