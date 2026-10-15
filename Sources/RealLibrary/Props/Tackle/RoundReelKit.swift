import simd
import Foundation

/// Round reels (round baitcasters and lever-drag conventionals), spool axis across the rod (Z), front +X.
enum RoundReelKit {
    struct Spec {
        /// Side plate radius and frame inner width (between the plates).
        var R: Float
        var width: Float
        var plateThick: Float
        /// Spool axis height above the foot underside.
        var yc: Float
        var levelWind: Bool
        var leverDrag: Bool
        var twinKnobs: Bool
        var harnessLugs: Bool
        var gear: Float
        var footLength: Float
        var body: MaterialKey
        var trim: MaterialKey
        var line: MaterialKey
    }

    static func rig(name: String, _ s: Spec, offset o: V3) -> Rig {
        var rig = Rig(name: name)
        let yc = s.yc, R = s.R, w = s.width, t = s.plateThick
        let frame: MaterialKey = "metal.anodized-gunmetal", chrome: MaterialKey = "metal.chrome", dark: MaterialKey = "plastic.black"
        func add(_ x: Surface, _ f: Xform = .identity, _ part: String) { ReelKit.add(&rig, x, f, to: part, offset: o) }
        let c = V3(0, yc, 0)
        let zL = -w / 2, zR = w / 2

        rig.part("body", pivot: c + o, joint: .fixed)
        add(ReelKit.foot(length: s.footLength, width: 0.012, thick: 0.0032, mat: frame), .identity, "body")
        // Foot pillar and a cross bar web under the spool.
        add(Prim.roundedBox(V3(s.footLength * 0.55, yc - R + 0.006, 0.012), radius: 0.002, bevelSegments: 1, material: frame), Xform(translation: V3(0, (yc - R + 0.006) / 2 + 0.002, 0)), "body")
        add(Prim.roundedBox(V3(0.02, 0.004, w + 0.002), radius: 0.0015, bevelSegments: 1, material: frame), Xform(translation: V3(0, yc - R + 0.006, 0)), "body")
        // Side plates: machined rings with a bevelled rim, a domed cap, and polished screws around the rim.
        for side: Float in [-1, 1] {
            let z0 = side < 0 ? zL - t : zR
            add(ReelKit.latheZ([V2(0, 0), V2(R - 0.002, 0), V2(R, 0.0012), V2(R, t - 0.0012), V2(R - 0.002, t), V2(0, t)], z0: z0, x: 0, y: yc, seg: 56, tile: 0.05, s.body), .identity, "body")
            add(ReelKit.latheZ([V2(R - 0.0045, 0), V2(R - 0.0042, 0.0012), V2(R - 0.0055, 0.0018), V2(R - 0.0068, 0.0018)], z0: side < 0 ? zL - t - 0.0016 : zR + t - 0.0002, x: 0, y: yc, seg: 56, s.trim), .identity, "body")
            for k in 0..<3 {
                let a = Float(k) / 3 * 2 * .pi + 0.5
                let p = V3(cos(a) * (R - 0.0045), yc + sin(a) * (R - 0.0045), side < 0 ? zL - t - 0.0012 : zR + t)
                add(ReelKit.latheZ([V2(0, 0), V2(0.0021, 0.0002), V2(0.0021, 0.0006), V2(0.0015, 0.0011), V2(0, 0.0012)], z0: p.z, x: p.x, y: p.y, seg: 12, chrome),
                    .identity, "body")
            }
            // Domed bearing cap in the centre of each plate.
            add(Prim.superellipsoid(V3(R * 0.62, R * 0.62, 0.008), exponent: 2.2, subdivisions: 7, material: s.body), Xform(translation: c + V3(0, 0, side * (w / 2 + t))), "body")
        }
        // Frame pillars between the plates: front top, rear top (thumb rest), rear bottom.
        for (a, r) in [(Float(0.55), Float(0.0028)), (2.35, 0.0034), (3.75, 0.003)] {
            add(ReelKit.latheZ([V2(r, 0), V2(r, w)], z0: zL, x: cos(a) * (R - 0.004), y: yc + sin(a) * (R - 0.004), seg: 14, frame), .identity, "body")
        }
        // Clicker button on the palming side, bait clicker / free-spool lever.
        add(Prim.roundedBox(V3(0.008, 0.005, 0.004), radius: 0.0015, bevelSegments: 1, material: dark), Xform(translation: V3(-R * 0.5, yc - R * 0.55, zL - t - 0.004)), "body")
        if s.levelWind {
            var worm: [V2] = []
            for i in 0...30 { worm.append(V2(i % 2 == 0 ? 0.0026 : 0.0022, w * Float(i) / 30)) }
            add(ReelKit.latheZ(worm, z0: zL, x: R * 0.82, y: yc - R * 0.45, seg: 14, chrome), .identity, "body")
            add(ReelKit.latheZ([V2(0.0015, 0), V2(0.0015, w)], z0: zL, x: R * 0.9, y: yc - R * 0.28, seg: 10, chrome), .identity, "body")
            add(Prim.roundedBox(V3(0.009, 0.017, 0.009), radius: 0.002, bevelSegments: 2, material: dark), Xform(translation: V3(R * 0.88, yc - R * 0.36, 0.003)), "body")
            add(Prim.torus(major: 0.0022, minor: 0.0007, segments: 14, sides: 6, material: "ceramic.guide-insert").transformed(Xform(translation: V3(R * 0.88 + 0.0048, yc - R * 0.28, 0.003), rotation: RodKit.alongX)), .identity, "body")
        }
        // Gear housing bulge on the handle side.
        add(ReelKit.latheZ([V2(0, 0.007), V2(0.012, 0.0066), V2(0.0175, 0.004), V2(0.018, 0), V2(0.01, 0)].reversed(), z0: zR + t, x: -R * 0.12, y: yc - R * 0.05, seg: 32, s.body), .identity, "body")

        // Lever drag: a curved lever on top of the handle-side plate, pivoting about the spool axis.
        if s.leverDrag {
            rig.part("lever", pivot: c + o, joint: .hinge(axis: V3(0, 0, 1), -40...0, duration: 0.3))
            var path: [V3] = []
            for i in 0...10 { let a = 1.15 + 0.6 * Float(i) / 10; path.append(V3(cos(a) * (R + 0.003), yc + sin(a) * (R + 0.003), zR + t + 0.006)) }
            add(Prim.sweep(Shape2D.roundedRect(0.004, 0.006, radius: 0.0015), along: path, up: V3(0, 0, 1), material: frame), .identity, "lever")
            add(Prim.superellipsoid(V3(0.012, 0.009, 0.01), exponent: 2.4, subdivisions: 5, material: s.trim), Xform(translation: path.last! + V3(-0.003, 0.002, 0)), "lever")
            add(ReelKit.latheZ([V2(0.007, 0), V2(0.007, 0.006), V2(0, 0.0065)], z0: zR + t + 0.003, x: 0, y: yc, seg: 20, frame), .identity, "lever")
        }

        // Handle: hub on +Z behind the spool centre, optional star drag, arm with knobs.
        let hub = V3(-R * 0.12, yc - R * 0.05, zR + t + (s.leverDrag ? 0.01 : 0.0085))
        rig.part("handle", pivot: hub + o, joint: .hinge(axis: V3(0, 0, 1), 0...360, duration: 1.0))
        rig.part("spool", pivot: c + o, joint: Joint(.revolute, axis: V3(0, 0, 1), range: 0...(360 * s.gear), mimic: .init("handle", ratio: s.gear)))
        for z in [zL + 0.0005, zR - 0.0025] {
            add(ReelKit.latheZ([V2(0.004, 0), V2(R - 0.0045, 0.0002), V2(R - 0.004, 0.001), V2(R - 0.0045, 0.0018), V2(0.004, 0.002)], z0: z, x: 0, y: yc, seg: 44, frame), .identity, "spool")
        }
        add(ReelKit.latheZ(ReelKit.lineFill(r: R - 0.0085, core: R * 0.3, len: w - 0.004), z0: zL + 0.0025, x: 0, y: yc, seg: 44, tile: 0.02, s.line), .identity, "spool")
        if !s.leverDrag {
            var star: [V2] = []
            for i in 0..<10 { let a = Float(i) / 10 * 2 * .pi + .pi / 2; let r: Float = i % 2 == 0 ? 0.0135 : 0.007; star.append(V2(cos(a) * r, sin(a) * r)) }
            add(Prim.extrude(Shape2D.rounded(star, radius: 0.0017), depth: 0.0038, bevel: 0.0006, bevelSegments: 1, material: s.trim), Xform(translation: hub + V3(0, 0, -0.002)), "handle")
        }
        add(ReelKit.latheZ([V2(0.0055, 0), V2(0.0055, 0.006), V2(0.004, 0.0075), V2(0, 0.008)], z0: hub.z, x: hub.x, y: hub.y, seg: 20, chrome), .identity, "handle")
        let armLen: Float = s.twinKnobs ? 0.042 : 0.05
        let tilt = simd_quatf(angle: 0.4, axis: V3(0, 0, 1))
        let a0: Float = s.twinKnobs ? -armLen : -0.012
        let arm = Shape2D.rounded([V2(a0, -0.0042), V2(-0.004, -0.007), V2(0.004, -0.007), V2(armLen, -0.0045), V2(armLen, 0.0045), V2(0.004, 0.007), V2(-0.004, 0.007), V2(a0, 0.0042)], radius: 0.003)
        add(Prim.extrude(arm, depth: 0.0032, bevel: 0.0008, bevelSegments: 1, material: chrome), Xform(translation: hub + V3(0, 0, 0.009), rotation: tilt), "handle")
        add(ReelKit.latheZ([V2(0.0045, 0), V2(0.0048, 0.002), V2(0.0038, 0.004), V2(0, 0.0042)], z0: hub.z + 0.0105, x: hub.x, y: hub.y, seg: 16, chrome), .identity, "handle")
        for sgn: Float in (s.twinKnobs ? [-1, 1] : [1]) {
            let k = hub + tilt.act(V3(sgn * (armLen - 0.005), 0, 0))
            add(ReelKit.latheZ([V2(0.0017, 0), V2(0.0017, 0.005)], z0: hub.z + 0.0105, x: k.x, y: k.y, seg: 10, chrome), .identity, "handle")
            if s.twinKnobs {
                add(Prim.superellipsoid(V3(0.012, 0.022, 0.012), exponent: 2.4, subdivisions: 6, material: dark), Xform(translation: V3(k.x, k.y, hub.z + 0.021), rotation: tilt), "handle")
            } else {
                // T-bar power knob for heavy lever-drag reels.
                add(Prim.superellipsoid(V3(0.034, 0.014, 0.024), exponent: 2.6, subdivisions: 6, material: "rubber"), Xform(translation: V3(k.x, k.y, hub.z + 0.026), rotation: tilt), "handle")
            }
        }
        // Harness lugs on top of both plates (stand-up fishing harness clips).
        if s.harnessLugs {
            for side: Float in [-1, 1] {
                let z = side < 0 ? zL - t * 0.5 : zR + t * 0.5
                var loop: [V3] = []
                for i in 0...12 { let a = Float(i) / 12 * .pi; loop.append(V3(-0.006 + 0.012 * Float(i) / 12, yc + R - 0.001 + 0.007 * sin(a), z)) }
                add(Prim.tube(loop, radii: loop.map { _ in 0.0016 }, sides: 8, seamTile: 0.01, material: chrome), .identity, "body")
            }
        }
        rig.states = s.leverDrag ? [RigState("rest"), RigState("strike", ["lever": -25]), RigState("cranked", ["handle": 120])]
                                 : [RigState("rest"), RigState("cranked", ["handle": 120])]
        groundAO(&rig, height: 0.02, floor: 0.6)
        return rig
    }
}
