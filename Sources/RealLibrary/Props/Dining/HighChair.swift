import simd
import Foundation

/// Child high chair, 55 x 90 x 60 cm, seat top at 50 cm: four splayed beech legs (the rear pair rise as raked
/// back posts), a three-slat back, a padded seat with a crotch post, a tray with a raised rim and white insert
/// on two side rails, a footrest plank, apron rails and a teal three-point harness with a steel buckle.
public struct HighChair: RealAsset {
    public static let id = "high-chair"
    public static let summary = "Child high chair: splayed wooden legs, slat back, padded seat, tray with rim, footrest, three-point harness."
    public static let tags = ["prop", "floorplan", "dining", "furniture", "wood", "fabric", "interior"]
    public static let budget = 9800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 16, distance: 1.05, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.55, 0.9, 0.6)
    /// Frame wood.
    public var wood: MaterialKey = "wood.beech-stained"
    /// Tray rim wood.
    public var trayWood: MaterialKey = "wood.beech-stained:D6B27C"
    /// Tray insert.
    public var insert: MaterialKey = "laminate.white"
    /// Harness webbing.
    public var webbing: MaterialKey = "fabric.webbing:3E8E9E"
    /// Seat pad.
    public var pad: MaterialKey = "vinyl.seat-grey"
    /// Buckle metal.
    public var metal: MaterialKey = "metal.stainless-smudged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seatY: Float = 0.5, H = size.y
        // Leg centrelines.
        func frontLeg(_ s: Float, _ y: Float) -> V3 { V3(s * (0.255 - 0.05 * y / seatY), y, 0.28 - 0.1 * y / seatY) }
        func rearLeg(_ s: Float, _ y: Float) -> V3 {
            let t = y / seatY
            if y <= seatY { return V3(s * (0.255 - 0.06 * t), y, -0.285 + 0.1 * t) }
            let u = (y - seatY) / (H - seatY)
            return V3(s * (0.195 - 0.012 * u), y, -0.185 - 0.05 * u)
        }
        for s: Float in [-1, 1] {
            let fy: [Float] = [0, 0.15, 0.3, seatY - 0.03]
            m.add(Prim.sweep(Shape2D.roundedRect(0.036, 0.036, radius: 0.005, segments: 1), along: fy.map { frontLeg(s, $0) }, up: V3(0, 0, 1),
                             scales: [0.75, 0.85, 0.93, 1], caps: true, grainAlongPath: true, material: wood))
            let ry: [Float] = [0, 0.15, 0.3, seatY, 0.65, 0.8, H - 0.012]
            m.add(Prim.sweep(Shape2D.roundedRect(0.036, 0.032, radius: 0.005, segments: 1), along: ry.map { rearLeg(s, $0) }, up: V3(0, 0, 1),
                             scales: [0.75, 0.82, 0.92, 1, 1, 0.97, 0.9], caps: true, grainAlongPath: true, material: wood))
            // Rubber feet.
            for p in [frontLeg(s, 0), rearLeg(s, 0)] {
                m.add(Prim.cylinder(radius: 0.017, height: 0.006, bevel: 0.0015, segments: 10, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(p.x, 0, p.z)))
            }
        }
        // Aprons under the seat.
        let aY = seatY - 0.05
        let fL = frontLeg(1, aY), rL = rearLeg(1, aY)
        m.add(Prim.roundedBox(V3(2 * fL.x - 0.03, 0.05, 0.02), radius: 0.004, bevelSegments: 1, material: wood), Xform(translation: V3(0, aY, fL.z)))
        m.add(Prim.roundedBox(V3(2 * rL.x - 0.03, 0.05, 0.02), radius: 0.004, bevelSegments: 1, material: wood), Xform(translation: V3(0, aY, rL.z)))
        let sideLen = fL.z - rL.z
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.02, 0.05, sideLen), radius: 0.004, bevelSegments: 1, material: wood),
                  Xform(translation: V3(s * (fL.x + rL.x) / 2, aY, (fL.z + rL.z) / 2)))
        }
        // Low stretchers (front-to-back) and the footrest plank.
        for s: Float in [-1, 1] {
            let a = frontLeg(s, 0.12), b = rearLeg(s, 0.12)
            m.add(Prim.sweep(Shape2D.circle(0.0105, segments: 8), along: [a, b], caps: true, grainAlongPath: true, material: wood))
        }
        let fr = frontLeg(1, 0.22)
        m.add(Prim.roundedBox(V3(2 * fr.x - 0.03, 0.02, 0.09), radius: 0.005, bevelSegments: 2, material: wood),
              Xform(translation: V3(0, 0.22, fr.z - 0.01), rotation: simd_quatf(degrees: -10, axis: V3(1, 0, 0))))
        // Seat board, crotch post, pad.
        let seatZ0 = rL.z + 0.03, seatZ1 = fL.z + 0.01
        let seatD = seatZ1 - seatZ0, seatW = 2 * rL.x - 0.02
        m.add(Prim.roundedBox(V3(seatW, 0.025, seatD), radius: 0.008, bevelSegments: 2, material: wood),
              Xform(translation: V3(0, seatY - 0.0125, (seatZ0 + seatZ1) / 2)))
        var padS = Prim.superellipsoid(V3(seatW - 0.03, 0.022, seatD - 0.04), exponent: 5, subdivisions: detail ? 8 : 4, material: pad)
        padS.deform { p in p - V3(0, (p.y > 0 ? 0.004 : 0.001) * max(0, 1 - pow(p.x / 0.15, 2)) * max(0, 1 - pow(p.z / 0.15, 2)), 0) }
        m.add(padS, Xform(translation: V3(0, seatY + 0.008, (seatZ0 + seatZ1) / 2 - 0.005)))
        let postZ = fL.z - 0.07
        m.add(Prim.roundedBox(V3(0.035, 0.085, 0.032), radius: 0.012, bevelSegments: 3, material: wood), Xform(translation: V3(0, seatY + 0.04, postZ)))
        // Tray rails and tray.
        let trayY: Float = 0.665
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.022, 0.03, 0.34), radius: 0.006, bevelSegments: 2, material: wood), Xform(translation: V3(s * 0.235, trayY - 0.03, 0.09)))
            // Rail post down to the leg top.
            let a = frontLeg(s, seatY - 0.03)
            m.add(Prim.sweep(Shape2D.roundedRect(0.026, 0.024, radius: 0.004, segments: 1), along: [V3(a.x, a.y, a.z), V3(s * 0.235, trayY - 0.03, 0.2)],
                             up: V3(0, 0, 1), caps: true, grainAlongPath: true, material: wood))
        }
        let trayW: Float = 0.5, trayD: Float = 0.34, trayZ: Float = 0.12
        m.add(Prim.roundedBox(V3(trayW - 0.04, 0.008, trayD - 0.04), radius: 0.003, bevelSegments: 1, material: insert), Xform(translation: V3(0, trayY - 0.001, trayZ)))
        m.add(Prim.roundedBox(V3(trayW, 0.018, trayD), radius: 0.005, bevelSegments: 2, material: trayWood), Xform(translation: V3(0, trayY - 0.012, trayZ)))
        // Raised rim: four boards around the insert.
        for (w, d, x, z) in [(trayW, 0.02, Float(0), trayZ + trayD / 2 - 0.01), (trayW, 0.02, 0, trayZ - trayD / 2 + 0.01),
                              (0.02, trayD - 0.04, trayW / 2 - 0.01, trayZ), (0.02, trayD - 0.04, -trayW / 2 + 0.01, trayZ)] as [(Float, Float, Float, Float)] {
            m.add(Prim.roundedBox(V3(w, 0.02, d), radius: 0.005, bevelSegments: 2, material: trayWood), Xform(translation: V3(x, trayY + 0.003, z)))
        }
        // Back: three slats and a top rail between the posts.
        let slatYs: [Float] = [0.6, 0.69, 0.78]
        for y in slatYs {
            let l = rearLeg(-1, y), r = rearLeg(1, y)
            let pts = (0...8).map { k -> V3 in
                let t = Float(k) / 8, x = l.x + (r.x - l.x) * t
                return V3(x, y, l.z - 0.012 * (1 - pow(2 * t - 1, 2)) + 0.003)
            }
            m.add(Prim.sweep(Shape2D.roundedRect(0.065, 0.014, radius: 0.004, segments: 1), along: pts, up: V3(0, 1, 0), caps: true, grainAlongPath: true, material: wood))
        }
        let tl = rearLeg(-1, H - 0.05), tr = rearLeg(1, H - 0.05)
        let topPts = (0...10).map { k -> V3 in
            let t = Float(k) / 10, x = tl.x + (tr.x - tl.x) * t
            return V3(x, H - 0.05, tl.z - 0.01 * (1 - pow(2 * t - 1, 2)) + 0.003)
        }
        m.add(Prim.sweep(Shape2D.roundedRect(0.085, 0.022, radius: 0.007, segments: 2), along: topPts, up: V3(0, 1, 0), caps: true, grainAlongPath: true, material: wood))
        // Harness: shoulder straps down the back, lap straps to the buckle at the crotch post.
        let faceZ = rearLeg(0, 0.7).z + 0.016
        for s: Float in [-1, 1] {
            let x = s * 0.07
            m.add(Prim.sweep(Shape2D.roundedRect(0.004, 0.026, radius: 0.001, segments: 1),
                             along: [V3(x, 0.8, faceZ), V3(x, 0.7, faceZ + 0.003), V3(x, 0.6, faceZ + 0.004), V3(x * 1.1, seatY + 0.045, faceZ + 0.006), V3(x * 0.9, seatY + 0.03, faceZ + 0.05)],
                             up: V3(0, 0, 1), caps: true, material: webbing))
            let side = V3(s * (rL.x - 0.025), seatY + 0.026, rL.z + 0.05)
            m.add(Prim.sweep(Shape2D.roundedRect(0.004, 0.026, radius: 0.001, segments: 1), along: [side, side + (V3(s * 0.03, seatY + 0.065, postZ + 0.01) - side) * 0.5 + V3(0, 0.012, 0), V3(s * 0.03, seatY + 0.065, postZ + 0.01)],
                             up: V3(0, 1, 0), caps: true, material: webbing))
        }
        if detail {
            // Strap adjusters and stitched boxes on the shoulder straps.
            for s in [-1, 1] as [Float] {
                let x = s * 0.07
                m.add(Prim.roundedBox(V3(0.034, 0.008, 0.008), radius: 0.002, bevelSegments: 1, material: metal), Xform(translation: V3(x, 0.66, faceZ + 0.006)))
                let box = [V3(x - 0.01, 0.74, faceZ + 0.0035), V3(x + 0.01, 0.74, faceZ + 0.0035), V3(x + 0.01, 0.71, faceZ + 0.0035), V3(x - 0.01, 0.71, faceZ + 0.0035), V3(x - 0.01, 0.74, faceZ + 0.0035)]
                m.add(stitches(along: box, normal: { _ in V3(0, 0, 1) }, pitch: 0.005, thread: 0.0006, material: webbing))
            }
            // Bolts at the tray-rail posts and the leg-apron joints.
            for s in [-1, 1] as [Float] {
                hexBolt(&m, at: V3(s * 0.235, trayY - 0.03, 0.2) + V3(s * 0.011, 0, 0), normal: V3(s, 0, 0), size: 0.011, material: metal)
                hexBolt(&m, at: V3(fL.x * s + s * 0.018, aY, fL.z), normal: V3(s, 0, 0), size: 0.011, material: metal)
                hexBolt(&m, at: V3(rL.x * s + s * 0.018, aY, rL.z), normal: V3(s, 0, 0), size: 0.011, material: metal)
            }
        }
        // Buckle on the crotch post.
        m.add(Prim.roundedBox(V3(0.05, 0.026, 0.012), radius: 0.004, bevelSegments: 2, material: metal), Xform(translation: V3(0, seatY + 0.065, postZ + 0.02)))
        if detail {
            m.add(Prim.roundedBox(V3(0.022, 0.012, 0.014), radius: 0.003, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0, seatY + 0.065, postZ + 0.028)))
        }
        _ = rng.float()
        groundAO(&m, height: 0.15, floor: 0.5)
        return m
    }
}
