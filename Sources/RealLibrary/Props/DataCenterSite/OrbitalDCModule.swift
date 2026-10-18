import simd
import Foundation

/// Orbital data-center module, 20 x 6 x 6 m: a 15 m pressurized hull (white Whipple-shield skin with aluminum shield straps)
/// inside a 17 m square truss of carbon-grey chords, ring frames, diagonals and hull struts; gold MLI blanket end cones,
/// two axial docking ports with capture ring, petals, alignment pins and bolt circles, two radial ports, eight radiator
/// mounts with MLI hoses and blue/red quick disconnects, six external compute ORU boxes with handles and connector panels,
/// a grapple fixture, star tracker and omni antenna. Axis along X, base y = 0.
public struct OrbitalDCModule: RealAsset {
    public static let id = "orbital-dc-module"
    public static let summary = "Pressurized orbital compute module: Whipple-shield hull in a square truss, gold MLI end cones, docking ports, radiator mounts and external compute boxes."
    public static let tags = ["prop", "space", "datacenter", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 22, distance: 26, studio: true)

    /// Hull radius (m) and cylinder half length (m).
    public var hullRadius: Float = 2.0
    public var hullHalf: Float = 7.5
    public var hull: MaterialKey = "thermal.radiator-white:DDDDD7"
    public var strap: MaterialKey = "metal.aluminum-brushed"
    public var blanket: MaterialKey = "mli.blanket"
    public var truss: MaterialKey = "composite.carbon"
    public var node: MaterialKey = "metal.titanium"
    public var oru: MaterialKey = "metal.powdercoat:C9CBCC"
    public var panel: MaterialKey = "plastic.matte:1B1D22"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = hullRadius, H = hullHalf, cy: Float = 3
        func put(_ t: (Surface, Xform)) { m.add(t.0, t.1) }
        // Hull: closed lathe about X with rounded shoulders.
        let hp: [V2] = [V2(0, 0), V2(R - 0.3, 0), V2(R - 0.08, 0.1), V2(R, 0.3), V2(R, 2 * H - 0.3), V2(R - 0.08, 2 * H - 0.1), V2(R - 0.3, 2 * H), V2(0, 2 * H)]
        m.add(Prim.lathe(hp, segments: 32, seamTile: 1.0, material: hull), Xform(translation: V3(-H, cy, 0), rotation: OK.qx))
        // Whipple shield straps, with a weld-seam bead each side.
        for k in 0...5 {
            let x = -H + 0.6 + Float(k) * (2 * H - 1.2) / 5
            let p: [V2] = [V2(R - 0.002, 0), V2(R + 0.035, 0.012), V2(R + 0.035, 0.1), V2(R - 0.002, 0.112)]
            m.add(Prim.lathe(p, segments: 28, seamTile: 1.0, material: strap), Xform(translation: V3(x - 0.056, cy, 0), rotation: OK.qx))
        }
        // End cones in gold MLI, collars, docking ports.
        for s: Float in [-1, 1] {
            let cp: [V2] = [V2(0.95, 0), V2(1.05, 0.5), V2(1.4, 1.0), V2(R - 0.3, 1.25), V2(R - 0.3, 1.3)]
            let q = s < 0 ? OK.qx : simd_quatf(degrees: 90, axis: V3(0, 0, 1))
            m.add(Prim.lathe(cp, segments: 28, seamTile: 1.0, material: blanket), Xform(translation: V3(s * (H + 1.3), cy, 0), rotation: q))
            put(OK.cylX(0.98, 0.55, x0: s < 0 ? -H - 1.85 : H + 1.3, y: cy, z: 0, strap, seg: 28))
            put(OK.cylX(0.72, 0.2, x0: s < 0 ? -H - 2.05 : H + 1.85, y: cy, z: 0, node, seg: 28))
            let ring = Prim.torus(major: 0.84, minor: 0.07, segments: 24, sides: 6, material: node)
            m.add(ring, Xform(translation: V3(s * (H + 2.1 + 0.05) , cy, 0), rotation: OK.qx))
            // Hatch plate with a window, alignment pins, capture petals.
            put(OK.cylX(0.55, 0.03, x0: s < 0 ? -H - 1.95 - 0.04 : H + 1.95 + 0.01, y: cy, z: 0, panel, seg: 24))
            for k in 0..<3 {
                let a = Float(k) * 2 * .pi / 3 + 0.5
                let c = V3(s * (H + 2.0 + 0.1), cy + 0.84 * cos(a), 0.84 * sin(a))
                let (p, xf) = OK.box(V3(0.22, 0.12, 0.2), c, node, r: 0.012)
                m.add(p, Xform(translation: xf.translation, rotation: simd_quatf(degrees: -a * 180 / .pi + 90, axis: V3(1, 0, 0))))
                let pin = V3(s * (H + 2.2), cy + 0.62 * cos(a + 1.05), 0.62 * sin(a + 1.05))
                m.add(Prim.cylinder(radius: 0.022, height: 0.22, bevel: 0.004, segments: 8, bevelSegments: 1, material: "metal.steel"), Xform(translation: pin - V3(0.11, 0, 0) , rotation: OK.qx))
            }
            var b = Model(name: "bc")
            for k in 0..<8 {
                let a = Float(k) * 2 * .pi / 8
                hexBolt(&b, at: V3(s * (H + 1.55 + (s < 0 ? -0.0 : 0)), cy + 1.02 * cos(a), 1.02 * sin(a)) , normal: V3(s, 0, 0), size: 0.03, material: node)
            }
            m.add(b)
        }
        // Truss: 4 chords, 9 ring frames, diagonals, hull struts, corner nodes.
        let hs: Float = 2.75, x0: Float = -8.5, bays = 8, bay = 17 / Float(bays)
        let ys: [Float] = [cy - hs, cy + hs]
        for yy in ys { for zz: Float in [-hs, hs] {
            m.add(OK.rod(V3(x0, yy, zz), V3(-x0, yy, zz), r: 0.085, truss, sides: 6)) } }
        for i in 0...bays {
            let x = x0 + Float(i) * bay
            for (a, b) in [(V3(x, ys[0], -hs), V3(x, ys[0], hs)), (V3(x, ys[1], -hs), V3(x, ys[1], hs)), (V3(x, ys[0], -hs), V3(x, ys[1], -hs)), (V3(x, ys[0], hs), V3(x, ys[1], hs))] {
                m.add(OK.rod(a, b, r: 0.055, truss))
            }
            for yy in ys { for zz: Float in [-hs, hs] { put(OK.box(V3(0.2, 0.2, 0.2), V3(x, yy, zz), node, r: 0.012)) } }
            // Struts from frame mid-sides to the hull.
            let dirs: [(V3, V3)] = [(V3(x, ys[0], 0), V3(x, cy - R * 0.97, 0)), (V3(x, ys[1], 0), V3(x, cy + R * 0.97, 0)),
                                    (V3(x, cy, -hs), V3(x, cy, -R * 0.97)), (V3(x, cy, hs), V3(x, cy, R * 0.97))]
            for (a, b) in dirs { m.add(OK.rod(a, b, r: 0.05, truss)) }
            if i < bays {
                let x1 = x + bay, f: Float = i % 2 == 0 ? 1 : -1
                m.add(OK.rod(V3(x, ys[0], -hs * f), V3(x1, ys[0], hs * f), r: 0.04, truss))
                m.add(OK.rod(V3(x, ys[1], hs * f), V3(x1, ys[1], -hs * f), r: 0.04, truss))
                m.add(OK.rod(V3(x, ys[0] , -hs), V3(x1, ys[1], -hs), r: 0.04, truss))
                m.add(OK.rod(V3(x, ys[1] , hs), V3(x1, ys[0], hs), r: 0.04, truss))
            }
        }
        // Radiator mounts on both Z faces: plate, hinge pins, QD pair, MLI hoses.
        var bolts = Model(name: "mb")
        for s: Float in [-1, 1] { for xm: Float in [-6.375, -2.125, 2.125, 6.375] {
            put(OK.box(V3(0.55, 0.55, 0.06), V3(xm, cy, s * (hs + 0.12)), strap, r: 0.01))
            for dy: Float in [-0.17, 0.17] {
                put(OK.cylZ(0.04, 0.22, x: xm + dy * 0, y: cy + dy, z0: s < 0 ? -hs - 0.19 : hs + 0.05, "metal.steel", seg: 12))
                put(OK.cylZ(0.05, 0.03, x: xm, y: cy + dy, z0: s < 0 ? -hs - 0.2 : hs + 0.17, dy < 0 ? "plastic.matte:2A6BD6" : "plastic.matte:D62A1E", seg: 12))
            }
            put(OK.cylX(0.04, 0.5, x0: xm - 0.25, y: cy - 0.32, z: s * (hs + 0.12), node, seg: 10))
            m.add(Prim.tube(catmull([V3(xm - 0.15, cy - 0.17, s * (hs + 0.15)), V3(xm - 0.35, cy - 0.4, s * (hs + 0.2)), V3(xm - 0.55, cy - 0.6, s * (hs + 0.12))], per: 4),
                            radii: Array(repeating: 0.028, count: 9), sides: 8, seamTile: 0.3, material: blanket))
            for (bx, by) in [(-0.22, -0.22), (0.22, 0.22)] {
                hexBolt(&bolts, at: V3(xm + Float(bx), cy + Float(by), s * (hs + 0.19)), normal: V3(0, 0, s), size: 0.03, material: node)
            }
        } }
        m.add(bolts)
        // Compute ORUs on the hull top: white boxes with handles and dark connector panels.
        let topY = cy + R
        for (ix, x) in [-4.6, 0.0, 4.6].enumerated() { for sz: Float in [-1, 1] {
            let c = V3(Float(x), topY + 0.3 + 0.03, sz * 0.7)
            put(OK.box(V3(1.5, 0.6, 1.1), c, oru, r: 0.02))
            put(OK.box(V3(1.3, 0.1, 0.9), V3(c.x, topY + 0.03 - 0.02, c.z), strap, r: 0.01))
            put(OK.box(V3(1.1, 0.012, 0.35), V3(c.x, c.y + 0.3 + 0.004, c.z - sz * 0.25), panel, r: 0.003))
            let bh = barHandle(length: 0.45, standoff: 0.06, radius: 0.012, material: "metal.stainless")
            m.add(bh, Xform(translation: V3(c.x - 0.45, c.y + 0.3, c.z + sz * 0.3), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            m.add(bh, Xform(translation: V3(c.x + 0.45, c.y + 0.3, c.z + sz * 0.3), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            // Connector row on the panel.
            for k in 0..<5 { put(OK.cylY(0.026, 0.02, at: V3(c.x - 0.4 + Float(k) * 0.2, c.y + 0.31, c.z - sz * 0.25), node, seg: 10)) }
            _ = ix
        } }
        // Grapple fixture, star tracker and omni antenna.
        put(OK.cylY(0.07, 0.25, at: V3(-6.2, topY, 0), node, seg: 12))
        put(OK.cylY(0.14, 0.03, at: V3(-6.2, topY + 0.25, 0), node, seg: 16))
        put(OK.cylY(0.035, 0.08, at: V3(-6.2, topY + 0.28, 0), "metal.steel", seg: 8))
        put(OK.box(V3(0.3, 0.24, 0.3), V3(6.4, topY + 0.12, 0), strap, r: 0.01))
        put(OK.cylY(0.1, 0.35, at: V3(6.4, topY + 0.24, 0), panel, seg: 14))
        m.add(OK.rod(V3(-0.5, topY + 0.02, -1.4), V3(-0.5, topY + 1.6 - 0.3, -1.4), r: 0.025, "metal.stainless", sides: 8))
        put(OK.cylY(0.06, 0.1, at: V3(-0.5, topY + 1.3, -1.4), panel, seg: 12))
        // Radial ports on +Z mid-hull sides? kept on the hull flanks between struts: nadir and zenith hatches.
        put(OK.cylY(0.5, 0.2, at: V3(2.1, topY, 0), strap, seg: 24))
        put(OK.cylY(0.4, 0.04, at: V3(2.1, topY + 0.2, 0), panel, seg: 20))
        // Re-seat on the ground and report.
        m.add(Prim.roundedBox(V3(0.5, 0.01, 0.5), radius: 0.003, bevelSegments: 1, material: node), Xform(translation: V3(0, 0.005, 0)))
        groundAO(&m, height: 0.25, floor: 0.6)
        _ = rng
        return LODModel(m)
    }
}
