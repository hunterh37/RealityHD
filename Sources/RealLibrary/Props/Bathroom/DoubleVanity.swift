import simd
import Foundation

/// 60 in double bathroom vanity: painted shaker carcass on a recessed toe kick, two doors with false
/// drawer fronts either side of a three-drawer bank, brushed nickel bar pulls, one-piece eased marble
/// top with backsplash, two undermount oval basins and two widespread chrome faucets with lift rods.
/// Back at z = -0.275, front +Z, top at 0.82 m.
public struct DoubleVanity: RealAsset {
    public static let id = "double-vanity"
    public static let summary = "60 in double bathroom vanity: painted shaker doors and drawer bank, one-piece marble top, two undermount basins, two widespread chrome faucets."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "furniture", "stone", "ceramic", "interior"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 2.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.5, 0.88, 0.55)
    public var paint: MaterialKey = "wood.painted-shaker:5C6B73"
    /// Bottom rails and kick: scuffed paint.
    public var worn: MaterialKey = "wood.painted-shaker-worn:5C6B73"
    public var top: MaterialKey = "stone.marble-honed"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    /// Counter top height.
    public var topHeight: Float = 0.82
    /// Basin center spacing from the vanity centerline.
    public var basinOffset: Float = 0.38
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let W = size.x, back = -size.z / 2, front = size.z / 2
            let th: Float = 0.025, kick: Float = 0.095
            let cabTop = topHeight - th
            let sd = size.z - 0.0125, sc: Float = -0.00625
            let holeZ: Float = 0.02625
            let holes = [-basinOffset, basinOffset].map { (center: V2($0, holeZ), size: V2(0.46, 0.34), radius: Float(0.15)) }
            var slab = BathFit.vanityTop(width: W, depth: sd, thickness: th, ease: 0.0035, corner: 0.004, holes: holes, material: top)
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
            // Shaker panels on both end panels.
            if hi {
                for sx: Float in [-1, 1] {
                    var sm = Model(name: "side")
                    BathFit.shakerLean(&sm, width: cd - 0.06, height: cabTop - kick - 0.06, t: 0.012, frame: 0.05, at: V3(0, (kick + cabTop) / 2, 0), material: paint)
                    m.add(sm, Xform(translation: V3(sx * ((W - 0.03) / 2 + 0.0005), 0, back + 0.004 + cd / 2), rotation: simd_quatf(degrees: sx * 90, axis: .up)))
                }
            }
            // Fronts.
            func fascia(width: Float, height: Float, frame: Float, at c: V3, material: MaterialKey, bottomRail: MaterialKey? = nil) {
                if hi { BathFit.shakerLean(&m, width: width, height: height, frame: frame, at: c, material: material, bottomRail: bottomRail) }
                else { KitchenFit.shakerFront(&m, width: width, height: height, t: 0.019, frame: frame, at: c, material: material, bottomRail: bottomRail, lite: true) }
            }
            let df = cf + 0.019
            let rv: Float = 0.003
            let drawerH: Float = 0.13
            let dTop = cabTop - 0.004, dBot = dTop - drawerH
            let oTop = dBot - rv * 2, oBot = kick + 0.002
            let Wi = W - 0.03
            let cw: Float = 0.46                       // center drawer bank width
            let dw = (Wi - cw - 4 * rv) / 2           // door width
            let doorCX = cw / 2 + rv + dw / 2
            // Side false drawers and doors.
            for sx: Float in [-1, 1] {
                let cx = sx * doorCX
                fascia(width: dw, height: drawerH, frame: 0.04, at: V3(cx, (dTop + dBot) / 2, df), material: paint)
                m.add(BathFit.pull(length: 0.1, standoff: 0.022, radius: 0.0055, overhang: 0.02, material: hardware), Xform(translation: V3(cx, (dTop + dBot) / 2, df)))
                fascia(width: dw, height: oTop - oBot, frame: 0.06, at: V3(cx, (oTop + oBot) / 2, df), material: paint, bottomRail: worn)
                m.add(BathFit.pull(length: 0.1, standoff: 0.022, radius: 0.0055, overhang: 0.02, material: hardware),
                      Xform(translation: V3(sx * (cw / 2 + rv + 0.04), oTop - 0.09 - 0.05, df), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                if hi {
                    for y in [oBot + 0.09, oTop - 0.09] {
                        m.add(Prim.roundedBox(V3(0.012, 0.045, 0.004), radius: 0.001, bevelSegments: 1, material: "metal.galvanized"),
                              Xform(translation: V3(sx * (W / 2 - 0.0175), y, df - 0.0015)))
                    }
                }
            }
            // Center bank: three drawers (top shallow).
            let bankTop = dTop, bankBot = oBot
            let hs: [Float] = [0.13, (bankTop - bankBot - 0.13 - 2 * rv * 2) / 2, (bankTop - bankBot - 0.13 - 2 * rv * 2) / 2]
            var y = bankTop
            for (i, h) in hs.enumerated() {
                let yc = y - h / 2
                fascia(width: cw, height: h, frame: 0.045, at: V3(0, yc, df), material: paint, bottomRail: i == 2 ? worn : nil)
                m.add(BathFit.pull(length: 0.128, standoff: 0.022, radius: 0.0055, overhang: 0.02, material: hardware), Xform(translation: V3(0, yc, df)))
                y -= h + 2 * rv
            }
            // Basins, faucets, lift rods.
            let fz = back + 0.065
            for sx: Float in [-1, 1] {
                let bx = sx * basinOffset
                BathFit.undermountBasin(&m, center: V3(bx, 0, holeZ + sc), size: V2(0.46, 0.34), topY: topHeight - 0.0005, depth: 0.16, radius: 0.15, hi: hi)
                BathFit.faucet(&m, at: V3(bx, topHeight, fz), finish: "metal.chrome", spread: 0.2, reach: 0.125, height: 0.042, hi: hi)
                m.add(Prim.cylinder(radius: 0.0042, height: 0.04, bevel: 0.0012, segments: hi ? 10 : 6, material: "metal.chrome"), Xform(translation: V3(bx, topHeight, fz - 0.032)))
                m.add(Prim.cylinder(radius: 0.0085, height: 0.008, bevel: 0.003, segments: hi ? 12 : 8, material: "metal.chrome"), Xform(translation: V3(bx, topHeight + 0.038, fz - 0.032)))
            }
            groundAO(&m, height: 0.2, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [5])
    }
}
