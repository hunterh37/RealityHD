import simd
import Foundation

/// 36 in bathroom vanity: painted shaker carcass on a recessed toe kick, two doors and a false drawer
/// front with brushed nickel bar pulls, eased quartz top with backsplash, undermount oval basin, widespread
/// chrome faucet with lever handles and a lift rod. Back at z = -0.275, front +Z, top at 0.82 m.
public struct BathroomVanity: RealAsset {
    public static let id = "bathroom-vanity"
    public static let summary = "36 in bathroom vanity: painted shaker doors and false drawer, quartz top and backsplash, undermount basin, widespread chrome faucet."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "furniture", "stone", "ceramic", "interior"]
    public static let budget = 10500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 2.1, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.92, 0.88, 0.55)
    public var paint: MaterialKey = "wood.painted-shaker:5C6B73"
    /// Bottom rails and kick: scuffed paint.
    public var worn: MaterialKey = "wood.painted-shaker-worn:5C6B73"
    public var top: MaterialKey = "stone.marble-honed"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    /// Counter top height.
    public var topHeight: Float = 0.82
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let W = size.x, back = -size.z / 2, front = size.z / 2
            let th: Float = 0.025, kick: Float = 0.095
            let cabTop = topHeight - th
            // Counter with undermount hole, centered 3 cm forward.
            let hole = (center: V2(0, 0.02625), size: V2(0.46, 0.34), radius: Float(0.15))
            let sd = size.z - 0.0125, sc: Float = -0.00625
            var slab = KitchenFit.counterSlab(width: W, depth: sd, thickness: th, ease: 0.0035, corner: 0.004, hole: hole, material: top)
            slab.bakeCavityAO(strength: 0.3)
            m.add(slab, Xform(translation: V3(0, cabTop, sc)))
            m.add(Prim.roundedBox(V3(W - 0.004, 0.05, 0.018), radius: 0.004, bevelSegments: hi ? 2 : 1, material: top), Xform(translation: V3(0, topHeight + 0.025 - 0.0005, back + 0.009)))
            // Carcass and toe kick.
            let cf = front - 0.0125 - 0.014 - 0.019
            let cd = cf - (back + 0.004)
            m.add(Prim.roundedBox(V3(W - 0.03, cabTop - kick, cd), radius: 0.003, bevelSegments: 1, material: paint),
                  Xform(translation: V3(0, (kick + cabTop) / 2, back + 0.004 + cd / 2)))
            let kd = cd - 0.06
            m.add(Prim.roundedBox(V3(W - 0.034, kick, kd), radius: 0.002, bevelSegments: 1, material: worn), Xform(translation: V3(0, kick / 2, back + 0.004 + kd / 2)))
            // Fronts: false drawer and two doors, 3 mm reveals.
            let df = cf + 0.019
            let rv: Float = 0.003
            let drawerH: Float = 0.13
            let dTop = cabTop - 0.004, dBot = dTop - drawerH
            KitchenFit.shakerFront(&m, width: W - 0.03 - 2 * rv, height: drawerH, t: 0.019, frame: 0.04, at: V3(0, (dTop + dBot) / 2, df), material: paint, lite: !hi)
            m.add(barHandle(length: 0.128, standoff: 0.022, radius: 0.0055, overhang: 0.02, material: hardware), Xform(translation: V3(0, (dTop + dBot) / 2, df)))
            let oTop = dBot - rv * 2, oBot = kick + 0.002
            let dw = (W - 0.03 - 3 * rv) / 2
            for sx: Float in [-1, 1] {
                let cx = sx * (dw / 2 + rv / 2)
                KitchenFit.shakerFront(&m, width: dw, height: oTop - oBot, t: 0.019, frame: 0.06, at: V3(cx, (oTop + oBot) / 2, df), material: paint, bottomRail: worn, lite: !hi)
                m.add(barHandle(length: 0.1, standoff: 0.022, radius: 0.0055, overhang: 0.02, material: hardware),
                      Xform(translation: V3(sx * (rv / 2 + 0.04), oTop - 0.09 - 0.05, df), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                if hi {
                    for y in [oBot + 0.09, oTop - 0.09] {
                        m.add(Prim.roundedBox(V3(0.012, 0.045, 0.004), radius: 0.001, bevelSegments: 1, material: "metal.galvanized"),
                              Xform(translation: V3(sx * (W / 2 - 0.0175), y, df - 0.0015)))
                    }
                }
            }
            // Basin, faucet and lift rod.
            BathFit.undermountBasin(&m, center: V3(hole.center.x, 0, hole.center.y + sc), size: hole.size, topY: topHeight - 0.0005 - 0.0, depth: 0.16, radius: hole.radius, hi: hi)
            let fz = back + 0.065
            BathFit.faucet(&m, at: V3(0, topHeight, fz), finish: "metal.chrome", spread: 0.2, reach: 0.125, height: 0.042, hi: hi)
            m.add(Prim.cylinder(radius: 0.0042, height: 0.04, bevel: 0.0012, segments: hi ? 10 : 6, material: "metal.chrome"), Xform(translation: V3(0, topHeight, fz - 0.032)))
            m.add(Prim.cylinder(radius: 0.0085, height: 0.008, bevel: 0.003, segments: hi ? 12 : 8, material: "metal.chrome"), Xform(translation: V3(0, topHeight + 0.038, fz - 0.032)))
            groundAO(&m, height: 0.2, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [5])
    }
}
