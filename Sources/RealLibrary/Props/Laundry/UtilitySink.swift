import simd
import Foundation

/// Freestanding laundry utility sink, 24 x 20 in: deep light-grey plastic tub with a rolled rim, a wide
/// back ledge carrying a chrome gooseneck faucet with two cross handles, washboard ribs on the left
/// inner wall, a chrome drain with a slotted strainer over a white P-trap, and a galvanized steel frame
/// of four round legs with rails and rubber foot caps.
public struct UtilitySink: RealAsset {
    public static let id = "utility-sink"
    public static let summary = "Freestanding laundry utility sink: deep plastic tub with washboard ribs on a galvanized steel leg frame, gooseneck faucet with two handles, drain and P-trap."
    public static let tags = ["prop", "floorplan", "laundry", "plumbing", "plastic", "metal", "interior"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 20, distance: 1.7, studio: true)

    /// Overall size in meters (x width, y height to the faucet peak, z depth).
    public var size = V3(0.6, 0.9, 0.5)
    /// Rim height.
    public var rimY: Float = 0.81
    /// Tub depth from the rim.
    public var tubDepth: Float = 0.33
    /// Tub plastic (sRGB hex tint).
    public var tubColor: UInt32 = 0xC4C7C4
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        func level(_ hi: Bool) -> Model {
            let W = size.x, D = size.z
            let plastic: MaterialKey = "plastic.matte:" + String(format: "%06X", tubColor)
            let steel: MaterialKey = "metal.galvanized"
            let chrome: MaterialKey = "metal.chrome"
            let wall: Float = 0.022, floorT: Float = 0.02
            let top = rimY, bot = rimY - tubDepth
            let segs = hi ? 12 : 8
            var m = Model(name: Self.id)
            func rb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.006) {
                m.add(hi || r < 0.003 ? (r < 0.003 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat)) : cuboid(s, material: mat), Xform(translation: c))
            }
            // Tub walls and floor; the back wall is a wide ledge.
            let ledge: Float = 0.075
            let h = top - bot
            rb(V3(W, floorT, D), V3(0, bot + floorT / 2, 0), "plastic.medical-grey-worn", r: 0.01)
            for sx: Float in [-1, 1] { rb(V3(wall, h, D), V3(sx * (W / 2 - wall / 2), (top + bot) / 2, 0), plastic, r: 0.008) }
            rb(V3(W - 2 * wall + 0.004, h, wall), V3(0, (top + bot) / 2, D / 2 - wall / 2), plastic, r: 0.008)
            rb(V3(W - 2 * wall + 0.004, h, ledge), V3(0, (top + bot) / 2, -D / 2 + ledge / 2), plastic, r: 0.008)
            // Rolled rim bead around the opening.
            let bead: Float = 0.012
            rb(V3(W, bead, 0.03), V3(0, top - bead / 2 + 0.002, D / 2 - 0.015), plastic, r: 0.005)
            for sx: Float in [-1, 1] { rb(V3(0.03, bead, D), V3(sx * (W / 2 - 0.015), top - bead / 2 + 0.002, 0), plastic, r: 0.005) }
            // Back splash lip.
            rb(V3(W, 0.06, 0.016), V3(0, top + 0.03 - 0.002, -D / 2 + 0.008), plastic, r: 0.005)
            // Washboard ribs on the left inner wall.
            if hi { for i in 0..<8 {
                m.add(Prim.roundedBox(V3(0.008, 0.012, D - 0.17), radius: 0.004, bevelSegments: 1, material: plastic),
                      Xform(translation: V3(-W / 2 + wall + 0.002, top - 0.06 - Float(i) * 0.026, 0.03)))
            }}
            // Floor-to-wall coves.
            if hi {
                for sx: Float in [-1, 1] {
                    m.add(Prim.cylinder(radius: 0.014, height: D - ledge - wall, bevel: 0.004, segments: 10, bevelSegments: 1, material: plastic),
                          Xform(translation: V3(sx * (W / 2 - wall - 0.008), bot + floorT + 0.004, -D / 2 + ledge), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
                m.add(Prim.cylinder(radius: 0.014, height: W - 2 * wall - 0.03, bevel: 0.004, segments: 10, bevelSegments: 1, material: plastic),
                      Xform(translation: V3(-(W - 2 * wall - 0.03) / 2, bot + floorT + 0.004, D / 2 - wall - 0.008), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            }
            // Drain: chrome ring, slotted strainer, overflow port.
            let dc = V3(0, bot + floorT, 0.04)
            m.add(Prim.lathe([V2(0.032, 0), V2(0.045, 0.0), V2(0.045, 0.004), V2(0.036, 0.007), V2(0.03, 0.002)], segments: segs, seamTile: 0.2, material: chrome), Xform(translation: dc))
            m.add(Prim.lathe([V2(0.001, 0.004), V2(0.03, 0.004), V2(0.03, 0.008), V2(0.001, 0.008)], segments: segs, seamTile: 0.2, material: "plastic.matte:1C1C1E"), Xform(translation: dc))
            if hi { for i in -2...2 {
                m.add(cuboid(V3(0.05, 0.001, 0.004), material: chrome), Xform(translation: dc + V3(0, 0.0085, Float(i) * 0.01)))
            }}
            // Stopper on a ball chain hooked to the back ledge.
            if hi {
                m.add(Prim.cylinder(radius: 0.03, height: 0.012, bevel: 0.004, segments: 14, bevelSegments: 1, material: "rubber.silicone-gray:2A2A2C"), Xform(translation: dc + V3(0.07, 0.0, 0.07)).jittered(&rng, deg: 2, offset: 0))
                let cp = catmull([dc + V3(0.07, 0.012, 0.07), dc + V3(0.05, 0.03, 0.0), V3(0.03, top - 0.004, -D / 2 + 0.05)], per: 4)
                m.add(Prim.tube(cp, radii: Array(repeating: 0.0018, count: cp.count), sides: 5, seamTile: 0.01, material: chrome))
            }
            // P-trap: down from the tailpiece, back around a U bend, and into the wall stub.
            let trap: [V3] = [V3(0, bot, 0.04), V3(0, bot - 0.06, 0.04), V3(0, bot - 0.11, 0.03), V3(0, bot - 0.14, 0.0), V3(0, bot - 0.11, -0.04), V3(0, bot - 0.06, -0.08)]
            m.add(Prim.tube(catmull(trap, per: hi ? 5 : 2), radii: Array(repeating: 0.019, count: catmull(trap, per: hi ? 5 : 2).count), sides: hi ? 10 : 8, seamTile: 0.1, material: "plastic.white"))
            // Frame: four round legs, side rails, front and back rails, foot caps.
            let lx = W / 2 - 0.035, lz = D / 2 - 0.035
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0165, height: bot - 0.006, bevel: 0.002, segments: segs, bevelSegments: 1, material: steel), Xform(translation: V3(sx * lx, 0.02, sz * lz)))
                m.add(Prim.cylinder(radius: 0.02, height: 0.022, bevel: 0.004, segments: segs, bevelSegments: 1, material: "plastic.matte:1C1C1E"), Xform(translation: V3(sx * lx, 0, sz * lz)))
            }}
            for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.011, height: 2 * lx, bevel: 0.002, segments: hi ? 12 : 6, bevelSegments: 1, material: steel),
                      Xform(translation: V3(-lx, 0.26, sz * lz), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            }
            for sx: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.011, height: 2 * lz, bevel: 0.002, segments: hi ? 12 : 6, bevelSegments: 1, material: steel),
                      Xform(translation: V3(sx * lx, 0.26, -lz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                // Top rail under the tub.
                m.add(cuboid(V3(0.04, 0.012, 2 * lz), material: steel), Xform(translation: V3(sx * lx, bot - 0.006, 0)))
            }
            // Faucet on the back ledge: base plate, gooseneck, two cross handles.
            let fz = -D / 2 + 0.04, fy = top
            m.add(Prim.cylinder(radius: 0.03, height: 0.012, bevel: 0.003, segments: segs, bevelSegments: 1, material: chrome), Xform(translation: V3(0, fy, fz)))
            m.add(Prim.cylinder(radius: 0.017, height: 0.033, bevel: 0.003, segments: segs, bevelSegments: 1, material: chrome), Xform(translation: V3(0, fy + 0.012, fz)))
            var arc: [V3] = [V3(0, fy + 0.045, fz)]
            for i in 1...10 {
                let t = Float(i) / 10
                let a = t * .pi * 0.92
                arc.append(V3(0, fy + 0.045 + 0.042 * sin(a) - 0.01 * t, fz + 0.1 * (1 - cos(a)) * 0.5 + 0.045 * t))
            }
            let arcP = catmull(arc, per: hi ? 3 : 1)
            m.add(Prim.tube(arcP, radii: Array(repeating: 0.0115, count: arcP.count), sides: hi ? 12 : 8, seamTile: 0.05, material: chrome))
            if let last = arcP.last {
                m.add(Prim.cylinder(radius: 0.0135, height: 0.016, bevel: 0.002, segments: segs, bevelSegments: 1, material: chrome), Xform(translation: last + V3(0, -0.012, 0)))
            }
            for sx: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.011, height: 0.036, bevel: 0.003, segments: segs, bevelSegments: 1, material: chrome), Xform(translation: V3(sx * 0.1, fy, fz)))
                m.add(Prim.cylinder(radius: 0.017, height: 0.01, bevel: 0.004, segments: segs, bevelSegments: 1, material: chrome), Xform(translation: V3(sx * 0.1, fy + 0.036, fz)))
                let cap: MaterialKey = sx < 0 ? "plastic.matte:2B6CB0" : "plastic.matte:C0392B"
                m.add(Prim.cylinder(radius: 0.0072, height: 0.004, bevel: 0.001, segments: 10, bevelSegments: 1, material: cap), Xform(translation: V3(sx * 0.1, fy + 0.046, fz)))
                m.add(Prim.roundedBox(V3(0.07, 0.01, 0.014), radius: 0.004, bevelSegments: 1, material: chrome), Xform(translation: V3(sx * 0.1, fy + 0.032, fz)).jittered(&rng, deg: 4, offset: 0))
            }
            groundAO(&m, height: 0.15, floor: 0.7)
            return m
        }
        return LODModel(levels: [level(true), level(false)], switchDistances: [4])
    }
}
