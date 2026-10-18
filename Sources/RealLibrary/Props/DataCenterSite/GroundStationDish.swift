import simd
import Foundation

/// Satellite ground station dish, 8 x 10 x 8 m: 7.5 m segmented aluminum reflector (24 gores, 2 seam rings, brushed seam strips),
/// back truss with hub, spokes, ring and diagonals, quadripod feed horn with LNA box, steel az-el yoke on a slew bearing,
/// tapered pedestal tower with door, ladder and bolted flange, and a square concrete foundation with anchor bolts.
/// Parts: base foundation and tower, dish-slew (azimuth, yoke), dish-elevate (reflector, truss, feed; child of dish-slew).
/// States: park (zenith-ish), track (default), horizon.
public struct GroundStationDish: RealArticulated {
    public static let id = "ground-station-dish"
    public static let summary = "Satellite ground station dish: panelled parabolic reflector, back truss, quadripod feed horn, az-el pedestal on a concrete foundation, slewing dish."
    public static let tags = ["prop", "articulated", "space", "metal", "datacenter"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.0, studio: true)

    /// Reflector radius (m).
    public var dishRadius: Float = 3.95
    /// Focal length over diameter.
    public var focalRatio: Float = 0.38
    /// Gores (radial panels).
    public var gores = 24
    /// Resting boresight elevation above the horizon (degrees).
    public var elevation: Float = 40
    public var reflector: MaterialKey = "metal.painted:E9EBEC"
    public var seam: MaterialKey = "metal.aluminum-brushed"
    public var truss: MaterialKey = "metal.galvanized"
    public var tower: MaterialKey = "metal.painted:D3D7D9"
    public var steel: MaterialKey = "metal.steel"
    public var pad: MaterialKey = "concrete.rough"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let R = dishRadius, f = 2 * R * focalRatio * 2 / 2 * 1.0 // f = D * ratio
        let focal = 2 * R * focalRatio
        _ = f
        let depth = R * R / (4 * focal)
        let H: Float = 5.1                       // elevation axis height
        let off: Float = 1.05                    // vertex distance above the elevation axis along the boresight
        let tilt = simd_quatf(degrees: -(90 - elevation), axis: V3(0, 0, 1))
        func para(_ r: Float) -> Float { r * r / (4 * focal) + off }
        func B(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.004, to part: String? = nil) {
            let (a, x) = OK.box(s, c, mat, r: r)
            if let part { rig.add(a, x, to: part) } else { rig.base[0].add(a, x) }
        }

        // Foundation: square pad with chamfer, plinth, anchor bolts, grout.
        rig.base[0].add(Prim.roundedBox(V3(7.8, 0.6, 7.8), radius: 0.04, bevelSegments: 2, material: pad), Xform(translation: V3(0, 0.3, 0)))
        rig.base[0].add(Prim.cylinder(radius: 1.35, height: 0.22, bevel: 0.02, segments: 32, bevelSegments: 1, material: "concrete.smooth"), Xform(translation: V3(0, 0.6, 0)))
        // Tower: tapered tube, base flange with anchor bolts, door, ladder, cable tray.
        var prof: [V2] = [V2(0, 0.82), V2(1.1, 0.82), V2(1.1, 0.9), V2(0.98, 0.9), V2(0.98, 1.0), V2(0.9, 1.0),
                          V2(0.9, 1.1), V2(0.84, 2.6), V2(0.74, 2.6), V2(0, 2.6)]
        prof = prof.map { $0 }
        rig.base[0].add(Prim.lathe(prof, segments: 28, seamTile: 1.2, material: tower), .identity)
        var bolts = Model(name: "anchors")
        for k in 0..<16 {
            let a = Float(k) / 16 * 2 * .pi
            OK.bolt(&bolts, at: V3(cos(a) * 1.04, 0.9, sin(a) * 1.04), size: 0.05, steel)
        }
        for k in 0..<4 { let a = (Float(k) + 0.5) / 4 * 2 * .pi
            B(V3(0.5, 0.05, 0.5), V3(cos(a) * 3.0, 0.62, sin(a) * 3.0), "metal.galvanized", r: 0.003)   // leveling plates
            OK.bolt(&bolts, at: V3(cos(a) * 3.0, 0.67, sin(a) * 3.0), size: 0.05, steel) }
        rig.base[0].add(bolts)
        // Door (faces +Z), with frame, handle and hazard plate.
        B(V3(0.62, 1.25, 0.03), V3(0, 1.75, 0.915), "metal.painted:C9CED1", r: 0.003)
        B(V3(0.7, 1.33, 0.02), V3(0, 1.75, 0.90), "metal.galvanized", r: 0.003)
        B(V3(0.05, 0.16, 0.03), V3(0.2, 1.7, 0.95), steel, r: 0.003)
        B(V3(0.2, 0.2, 0.01), V3(0, 2.25, 0.935), "metal.painted:E0B000", r: 0.002)
        // Ladder on -X side.
        for sz: Float in [-0.2, 0.2] { rig.base[0].add(OK.rod(V3(-0.97, 0.9, sz), V3(-0.88, 2.55, sz), r: 0.018, "metal.galvanized", sides: 6)) }
        for k in 0..<9 { let y = 1.05 + Float(k) * 0.17
            rig.base[0].add(OK.rod(V3(-0.96 + (y - 0.9) * 0.054, y, -0.2), V3(-0.96 + (y - 0.9) * 0.054, y, 0.2), r: 0.012, "metal.galvanized", sides: 4)) }
        // Cable tray with cables running up the +X side and into the foundation.
        B(V3(0.18, 1.7, 0.08), V3(0.93, 1.75, -0.2), "metal.galvanized", r: 0.003)
        rig.base[0].add(Prim.tube([V3(0.95, 0.3, -0.2), V3(1.6, 0.35, -0.5), V3(3.3, 0.05, -0.6)], radii: [0.05, 0.05, 0.05], sides: 8, seamTile: 0.3, material: "plastic.black"))

        // Azimuth: slew ring, deck, yoke arms with gussets, bearing caps.
        rig.part("dish-slew", pivot: V3(0, 2.6, 0), joint: .hinge(axis: .up, -120...120, duration: 10))
        rig.add(Prim.cylinder(radius: 0.95, height: 0.14, bevel: 0.01, segments: 28, bevelSegments: 1, material: steel), Xform(translation: V3(0, 2.6, 0)), to: "dish-slew")
        rig.add(Prim.cylinder(radius: 1.0, height: 0.08, bevel: 0.01, segments: 28, bevelSegments: 1, material: "metal.casework"), Xform(translation: V3(0, 2.74, 0)), to: "dish-slew")
        var sb = Model(name: "slewbolts")
        for k in 0..<16 { let a = Float(k) / 16 * 2 * .pi
            OK.bolt(&sb, at: V3(cos(a) * 0.88, 2.74, sin(a) * 0.88), size: 0.04, "metal.titanium") }
        rig.add(sb, to: "dish-slew", lod: 0)
        B(V3(1.5, 0.2, 3.4), V3(0, 2.92, 0), tower, r: 0.006, to: "dish-slew")
        let arm = Shape2D.rounded([V2(-0.75, 0), V2(0.75, 0), V2(0.34, 1.85), V2(-0.34, 1.85)], radius: 0.03)
        for sz: Float in [-1, 1] {
            rig.add(Prim.extrude(arm, depth: 0.16, bevel: 0.006, bevelSegments: 1, material: tower), Xform(translation: V3(0, 3.0, sz * 1.62)), to: "dish-slew")
            let (cap, cx) = OK.cylZ(0.3, 0.26, x: 0, y: H, z0: sz * 1.62 + (sz > 0 ? 0.08 : -0.34), steel, seg: 24, bevel: 0.01)
            rig.add(cap, cx, to: "dish-slew")
            var ab = Model(name: "capbolts")
            for k in 0..<6 { let a = Float(k) / 6 * 2 * .pi
                ab.add(Prim.cylinder(radius: 0.02, height: 0.03, bevel: 0, segments: 6, bevelSegments: 1, material: "metal.titanium"),
                       Xform(translation: V3(cos(a) * 0.22, H + sin(a) * 0.22, sz * 1.62 + (sz > 0 ? 0.34 : -0.37)), rotation: OK.qz)) }
            rig.add(ab, to: "dish-slew", lod: 0)
            // Elevation drive housing on the outboard face.
            B(V3(0.36, 0.34, 0.2), V3(0.0, 3.55, sz * 1.82), "metal.painted:2F3438", r: 0.005, to: "dish-slew")
        }
        B(V3(0.7, 0.5, 0.9), V3(-0.8, 3.25, 0), "metal.painted:2F3438", r: 0.006, to: "dish-slew")   // az drive cabinet
        // Elevation jackscrew from the deck to the reflector hub.
        rig.add(OK.rod(V3(-0.5, 3.0, 0.0), V3(-0.65, 4.4, 0.0), r: 0.07, "metal.casework", sides: 8), to: "dish-slew")

        // Reflector and back structure, authored relative to the elevation axis, then tilted.
        rig.part("dish-elevate", parent: "dish-slew", pivot: V3(0, H, 0), joint: .hinge(axis: V3(0, 0, 1), -35...50, duration: 8))
        let P = V3(0, H, 0)
        func put(_ s: Surface, _ mat: MaterialKey? = nil) { rig.add(s, Xform(translation: P, rotation: tilt), to: "dish-elevate") }
        // Shell: front skin then rim then back skin.
        var shell: [V2] = []
        let steps = 10
        for i in 0...steps { let r = R * Float(i) / Float(steps); shell.append(V2(max(r, 0.001), para(r))) }
        shell.append(V2(R + 0.03, para(R) + 0.0)); shell.append(V2(R + 0.03, para(R) - 0.07))
        for i in stride(from: steps, through: 0, by: -1) { let r = R * Float(i) / Float(steps); shell.append(V2(max(r, 0.001), para(r) - 0.07)) }
        put(Prim.lathe(Array(shell.reversed()), segments: 48, seamTile: 3.0, material: reflector))
        // Gore seams: brushed strips along the surface, plus two seam rings.
        let seamH: Float = 0.012
        for g in 0..<gores { let a = Float(g) / Float(gores) * 2 * .pi
            var pts: [V3] = []
            for i in 1...5 { let r = R * Float(i) / 5 * 0.99 + 0.5 * (Float(i) == 1 ? 0 : 0); pts.append(V3(cos(a) * r, para(r) + seamH, sin(a) * r)) }
            put(Prim.tube(pts, radii: Array(repeating: 0.016, count: 5), sides: 4, seamTile: 0.2, material: seam)) }
        for rr in [R * 0.42, R * 0.72] {
            var pts: [V3] = []
            for k in 0...36 { let a = Float(k) / 36 * 2 * .pi; pts.append(V3(cos(a) * rr, para(rr) + seamH, sin(a) * rr)) }
            put(Prim.tube(pts, radii: Array(repeating: 0.014, count: pts.count), sides: 4, seamTile: 0.2, material: seam)) }
        // Rim roll: tubular stiffening ring.
        var rim: [V3] = []
        for k in 0...48 { let a = Float(k) / 48 * 2 * .pi; rim.append(V3(cos(a) * (R + 0.03), para(R) - 0.035, sin(a) * (R + 0.03))) }
        put(Prim.tube(rim, radii: Array(repeating: 0.04, count: rim.count), sides: 6, seamTile: 0.2, material: truss))
        // Hub: cone, cylinder, axle through the yoke.
        put(Prim.lathe([V2(0.001, 0.0), V2(0.55, 0.0), V2(0.55, 0.95), V2(0.001, 0.95)].map { V2($0.x, $0.y + 0.0) }, segments: 16, seamTile: 1, material: "metal.casework"))
        put(Prim.tube([V3(0, 0, -1.9), V3(0, 0, 1.9)], radii: [0.2, 0.2], sides: 16, seamTile: 0.5, material: steel))
        // Back truss: spokes from hub to a mid ring and rim, ring, diagonals.
        let rRing = R * 0.62, rBack: Float = 0.2
        func backPt(_ r: Float, _ a: Float) -> V3 { V3(cos(a) * r, para(r) - 0.07 - rBack * (r / R), sin(a) * r) }
        let nS = 10
        var ring: [V3] = []
        for k in 0...36 { ring.append(backPt(rRing, Float(k) / 36 * 2 * .pi)) }
        put(Prim.tube(ring, radii: Array(repeating: 0.05, count: ring.count), sides: 4, seamTile: 0.3, material: truss))
        for k in 0..<nS { let a = Float(k) / Float(nS) * 2 * .pi
            let hubP = V3(cos(a) * 0.5, 0.55 + 0.05, sin(a) * 0.5)
            put(OK.rod(hubP, backPt(rRing, a), r: 0.055, truss, sides: 4))
            put(OK.rod(backPt(rRing, a), backPt(R * 0.98, a), r: 0.045, truss, sides: 4))
            let a2 = a + .pi / Float(nS)
            put(OK.rod(backPt(rRing, a), backPt(R * 0.98, a2), r: 0.03, truss, sides: 4))
            put(OK.rod(backPt(rRing, a), backPt(R * 0.98, a - .pi / Float(nS)), r: 0.03, truss, sides: 4))
        }
        // Hub to ring cross braces.
        for k in 0..<nS { let a = Float(k) / Float(nS) * 2 * .pi + .pi / Float(nS)
            put(OK.rod(V3(cos(a) * 0.5, 0.2, sin(a) * 0.5), backPt(rRing, a), r: 0.025, truss, sides: 4)) }
        // Quadripod feed support: four struts from the rim to the feed cabin at the focus, rim gussets.
        let focus = V3(0, focal + off, 0)
        for k in 0..<4 { let a = Float(k) / 4 * 2 * .pi + .pi / 4
            let rimP = V3(cos(a) * (R * 0.97), para(R * 0.97) + 0.03, sin(a) * (R * 0.97))
            let mid = (rimP + focus) / 2 + V3(0, 0, 0)
            put(Prim.tube([rimP, mid, focus + V3(cos(a) * 0.14, 0.14, sin(a) * 0.14)], radii: [0.055, 0.04, 0.035], sides: 6, seamTile: 0.25, material: seam))
            rig.add(Prim.cylinder(radius: 0.09, height: 0.05, bevel: 0.005, segments: 8, bevelSegments: 1, material: "metal.titanium"), Xform(translation: P + tilt.act(rimP + V3(0, -0.04, 0)), rotation: tilt), to: "dish-elevate") }
        // Feed horn: corrugated cone opening toward the dish, cover disc, LNA box and waveguide.
        let fy = focus.y
        let horn: [V2] = [V2(0.001, fy - 0.42), V2(0.3, fy - 0.42), V2(0.31, fy - 0.38), V2(0.25, fy - 0.36), V2(0.26, fy - 0.3), V2(0.2, fy - 0.28),
                          V2(0.21, fy - 0.2), V2(0.14, fy - 0.18), V2(0.14, fy + 0.1), V2(0.001, fy + 0.1)]
        put(Prim.lathe(horn, segments: 28, seamTile: 0.5, material: "metal.aluminum-brushed"))
        put(Prim.lathe([V2(0.001, fy - 0.405), V2(0.28, fy - 0.405), V2(0.28, fy - 0.395), V2(0.001, fy - 0.395)], segments: 28, seamTile: 0.5, material: "plastic.matte:D8D4C6"))
        let (lna, lx) = OK.box(V3(0.34, 0.3, 0.34), V3(0, fy + 0.25, 0), "metal.painted:C7CBCD", r: 0.006); rig.add(lna, Xform(translation: P + tilt.act(lx.translation), rotation: tilt), to: "dish-elevate")
        put(Prim.tube([V3(0.1, fy + 0.1, 0.0), V3(0.5, fy + 0.2, 0.3), V3(1.0, fy - 0.6, 0.6)], radii: [0.03, 0.03, 0.03], sides: 8, seamTile: 0.3, material: "plastic.black"))
        // Aviation red beacon on the LNA box.
        put(Prim.lathe([V2(0.001, fy + 0.4), V2(0.07, fy + 0.4), V2(0.07, fy + 0.46), V2(0.001, fy + 0.5)], segments: 12, seamTile: 0.3, material: "emissive.signal-red"))

        groundAO(&rig, height: 0.6, floor: 0.6)
        let deg: (Float) -> Float = { $0 }
        _ = deg
        rig.states = [RigState("track"), RigState("park", ["dish-elevate": -50, "dish-slew": 0]),
                      RigState("horizon", ["dish-elevate": 40, "dish-slew": 60])]
        return rig
    }
}
