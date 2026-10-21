import simd
import Foundation

/// Bank of four school-gym steel lockers, 1.2 m wide, 1.8 m high, 0.5 m deep including a door left ajar: blue powder-coated carcass and doors with louvre vents top and bottom, three hinges per door, recessed latch handle with a padlock hasp, brass number plates, sloped top, dark kick base, scuffed edges, one touched-up door. The ajar locker shows a galvanized interior with a shelf and a coat hook rail. Doors face +Z.
public struct LockersBank: RealAsset {
    public static let id = "lockers-bank"
    public static let summary = "Bank of four steel lockers, 1.2 m: louvered doors, hinges, latches, number plates, sloped top, one door ajar."
    public static let tags = ["prop", "floorplan", "commercial", "furniture", "metal", "interior"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 3.2, studio: true)

    /// Overall size in meters (x width, y height, z depth including the ajar door).
    public var size = V3(1.2, 1.8, 0.5)
    /// Number of lockers across.
    public var lockers = 4
    /// Index of the locker whose door stands ajar (-1 for none).
    public var ajar = 2
    /// Door opening angle in degrees.
    public var ajarAngle: Float = 14
    /// Body and door powder coat.
    public var paint: MaterialKey = "metal.powdercoat:4C6E8E"
    /// Touched-up door (slightly different blue).
    public var touchUp: MaterialKey = "metal.powdercoat:57799A"
    /// Interior and chipped edges.
    public var raw: MaterialKey = "metal.galvanized"
    /// Number plates and hook hardware.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Kick base and vent backing.
    public var dark: MaterialKey = "plastic.matte:101112"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bs = detail ? 2 : 1
        func box(_ t: inout Model, _ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.002, flat: Bool = false) {
            if flat { t.add(cuboid(sz, material: key), Xform(translation: c)); return }
            t.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: bs, material: key), Xform(translation: c))
        }
        let W = size.x, n = lockers
        let doorT: Float = 0.012, sideT: Float = 0.012
        let kick: Float = 0.1, topY: Float = 1.72, H = topY - kick - 0.012   // door height
        let D = size.z - 0.07 - doorT                                       // carcass depth leaves room for the ajar door
        let zf = D / 2
        let cw = W / Float(n)
        // Carcass: back, floor and ceiling plates, dividers.
        box(&m, V3(W, topY - kick, 0.01), V3(0, (topY + kick) / 2, -D / 2 + 0.005), paint, r: 0.002)
        box(&m, V3(W, 0.012, D), V3(0, topY - 0.006, 0), paint, r: 0.002)
        box(&m, V3(W, 0.012, D), V3(0, kick + 0.006, 0), raw, r: 0.002)
        for i in 0...n {
            let x = -W / 2 + Float(i) * cw
            let sx = i == 0 ? x + sideT / 2 : (i == n ? x - sideT / 2 : x)
            box(&m, V3(sideT, topY - kick, D), V3(sx, (topY + kick) / 2, 0), paint, r: 0.002)
        }
        // Frame lip at the front so the door edges have something to meet.
        box(&m, V3(W, 0.02, 0.012), V3(0, topY - 0.01, zf - 0.006), paint, r: 0.002)
        // Kick base, recessed.
        box(&m, V3(W - 0.02, kick, D - 0.04), V3(0, kick / 2, -0.005), dark, r: 0.004)
        // Sloped top: wedge falling toward the front, with a small front lip.
        let wz0 = -D / 2, wz1 = zf + doorT + 0.006
        let wedge = Shape2D.rounded([V2(-wz1, topY), V2(-wz0, topY), V2(-wz0, 1.8), V2(-wz1, 1.752)], radius: 0.004)
        m.add(Prim.extrude(wedge, depth: W, bevel: 0.003, bevelSegments: 1, material: paint),
              Xform(translation: V3(0, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
        // Open locker interior: shelf and coat hook rail.
        if ajar >= 0 && ajar < n {
            let x = -W / 2 + (Float(ajar) + 0.5) * cw
            box(&m, V3(cw - 2 * sideT - 0.004, 0.01, D - 0.03), V3(x, 1.32, -0.012), raw, r: 0.002)
            box(&m, V3(cw - 0.06, 0.03, 0.006), V3(x, 1.58, -D / 2 + 0.013), brass, r: 0.002)
            for hx: Float in [-0.06, 0.06] {
                let hook = catmull([V3(x + hx, 1.575, -D / 2 + 0.016), V3(x + hx, 1.575, -D / 2 + 0.04), V3(x + hx, 1.585, -D / 2 + 0.056), V3(x + hx, 1.61, -D / 2 + 0.06)], per: 4)
                m.add(Prim.tube(hook, radii: hook.map { _ in 0.0032 }, sides: 6, seamTile: 0.02, material: brass, capEnd: true))
            }
        }
        // Doors, built in hinge-local space (hinge axis at the origin, door extends +X).
        for i in 0..<n {
            var d = Model(name: "door")
            let w = cw - 0.006
            let key: MaterialKey = i == 1 ? touchUp : paint
            box(&d, V3(w, H, doorT), V3(w / 2, H / 2, 0), key, r: 0.003)
            // Louvre vents: dark backing panel with tilted slats.
            for (vy, count) in [(H - 0.145, 7), (0.13, 6)] as [(Float, Int)] {
                let vh = Float(count) * 0.0185 + 0.012
                box(&d, V3(w - 0.1, vh, 0.002), V3(w / 2, vy, doorT / 2), dark, flat: true)
                for k in 0..<count {
                    let y = vy - vh / 2 + 0.012 + Float(k) * 0.0185
                    d.add(cuboid(V3(w - 0.11, 0.0028, 0.009), material: key),
                          Xform(translation: V3(w / 2, y, doorT / 2 + 0.001), rotation: simd_quatf(degrees: 32, axis: V3(1, 0, 0))))
                }
            }
            // Number plate with two rivets.
            box(&d, V3(0.05, 0.026, 0.0022), V3(w / 2, H - 0.045, doorT / 2 + 0.0011), brass, flat: true)
            // Hinges: barrel on the hinge edge, leaf screwed to the door.
            for hy in [0.2, 0.8, 1.4] as [Float] {
                d.add(Prim.cylinder(radius: 0.0045, height: 0.07, bevel: 0.001, segments: detail ? 10 : 6, material: raw),
                      Xform(translation: V3(-0.002, hy - 0.035, doorT / 2 + 0.002)))
                box(&d, V3(0.022, 0.07, 0.0025), V3(0.011, hy, doorT / 2 + 0.0012), raw, flat: true)
            }
            // Latch: recessed pull handle on the free edge, hasp below it.
            box(&d, V3(0.036, 0.11, 0.004), V3(w - 0.03, H * 0.52, doorT / 2 + 0.002), raw, r: 0.0015)
            box(&d, V3(0.02, 0.07, 0.008), V3(w - 0.03, H * 0.52 + 0.005, doorT / 2 + 0.007), dark, r: 0.003)
            box(&d, V3(0.03, 0.05, 0.003), V3(w - 0.03, H * 0.52 - 0.075, doorT / 2 + 0.0015), raw, flat: true)
            if i == 0 || i == 3 {
                // Padlock hanging through the hasp.
                let py = H * 0.52 - 0.108
                box(&d, V3(0.036, 0.04, 0.016), V3(w - 0.03, py, doorT / 2 + 0.01), "metal.steel", r: 0.004)
                d.add(Prim.torus(major: 0.011, minor: 0.0025, segments: detail ? 12 : 6, sides: 6, arc: .pi, material: "metal.steel"),
                      Xform(translation: V3(w - 0.03, py + 0.018, doorT / 2 + 0.01), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            // Scuffs: bare-metal nicks on the edges.
            for _ in 0..<(detail ? 5 : 0) {
                let onSide = rng.chance(0.5)
                let p = onSide ? V3(rng.chance(0.5) ? 0.002 : w - 0.002, rng.float(0.05...H - 0.05), doorT / 2 + 0.0004)
                                : V3(rng.float(0.05...w - 0.05), rng.chance(0.5) ? 0.003 : H - 0.003, doorT / 2 + 0.0004)
                box(&d, onSide ? V3(0.003, rng.float(0.012...0.04), 0.0012) : V3(rng.float(0.012...0.04), 0.003, 0.0012), p, raw, flat: true)
            }
            let hx = -W / 2 + Float(i) * cw + 0.003
            if i == ajar {
                m.add(d, Xform(translation: V3(hx, kick + 0.006, zf + doorT / 2), rotation: simd_quatf(degrees: -ajarAngle, axis: V3(0, 1, 0))))
            } else {
                m.add(d, Xform(translation: V3(hx, kick + 0.006, zf + doorT / 2)))
            }
        }
        // Floor-level dirt: scuffed kick base highlights are in the material; add AO.
        groundAO(&m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        return m
    }
}
