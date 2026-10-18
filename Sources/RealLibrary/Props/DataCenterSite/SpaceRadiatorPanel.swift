import simd
import Foundation

/// Deployable spacecraft heat-rejection radiator, 10 x 0.09 x 4 m: two 4.77 m honeycomb panels with machined aluminum
/// edge rails, six white-coated face tiles each, 40 pumped-loop coolant tubes and two headers, a hinged root bracket with
/// knuckles, bolts, gold MLI-wrapped flex hoses and quick disconnects, a mid-span fold hinge and a tip launch-lock bar.
/// Parts: base bracket, deploy (hinge, panel 1), fold (mid hinge, panel 2), tubes1, tubes2 (option 1 = glowing).
/// States: deployed, half, stowed, deployed-hot. Base y = 0, panels lie along +X from the root at x = -5.
public struct SpaceRadiatorPanel: RealArticulated {
    public static let id = "space-radiator-panel"
    public static let summary = "Deployable two-panel spacecraft radiator: white-coated honeycomb tiles, coolant tubes that glow when hot, hinge brackets with MLI-wrapped hoses."
    public static let tags = ["prop", "articulated", "space", "metal", "datacenter"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 38, distance: 1.0, studio: true)

    /// Panel width along Z (m).
    public var panelWidth: Float = 4
    /// Coolant tube pitch along the panel (m).
    public var tubeSpacing: Float = 0.24
    /// Face coating, lightly toned per tile.
    public var coating: MaterialKey = "thermal.radiator-white"
    public var frame: MaterialKey = "metal.aluminum-brushed"
    public var tube: MaterialKey = "metal.stainless"
    /// Coolant tube material when hot (the heat glow knob: swap for any emissive key).
    public var glow: MaterialKey = "thermal.radiator-glow"
    public var blanket: MaterialKey = "mli.blanket"
    public var hardware: MaterialKey = "metal.titanium"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let W = panelWidth, T: Float = 0.078, px: Float = -4.78, py: Float = 0.045
        let L: Float = 4.77, rail: Float = 0.04
        let kx: Float = 0.0   // mid hinge x
        func B(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002) { let (a, x) = OK.box(s, c, mat, r: r); rig.base[0].add(a, x) }
        // Root bracket: machined block, hinge ears, bolts.
        B(V3(0.22, 0.09, W), V3(-4.89, 0.045, 0), frame, r: 0.004)
        B(V3(0.05, 0.09, W - 0.1), V3(-4.995, 0.045, 0), hardware, r: 0.003)
        var bolts = Model(name: "bolts")
        for k in 0..<6 { let z = -W / 2 + 0.2 + Float(k) * (W - 0.4) / 5
            OK.bolt(&bolts, at: V3(-4.9, 0.09, z), size: 0.016, hardware) }
        rig.base[0].add(bolts)
        for k in 0..<4 {
            let z = -1.5 + Float(k) * 1.0
            let (a, x) = OK.cylZ(0.04, 0.4, x: px, y: py, z0: z - 0.2, hardware, seg: 8); rig.base[0].add(a, x)
            let (c, y) = OK.cylZ(0.022, 0.5, x: px, y: py, z0: z - 0.25, "metal.steel", seg: 8); rig.base[0].add(c, y)
        }
        // Fluid lines: gold MLI hoses with QD couplers entering the bracket from behind.
        for z: Float in [-1.2, 1.2] {
            rig.base[0].add(Prim.tube(catmull([V3(-4.98, 0.05, z), V3(-5.0, 0.07, z + 0.15 * (z < 0 ? -1 : 1)), V3(-4.9, 0.06, z + 0.3 * (z < 0 ? -1 : 1))], per: 4),
                                      radii: [0.028, 0.028, 0.028, 0.028, 0.028, 0.028, 0.028, 0.028, 0.028], sides: 8, seamTile: 0.3, material: blanket))
            let (q, qx) = OK.cylX(0.032, 0.07, x0: -4.99, y: 0.05, z: z, "plastic.matte:2A6BD6", seg: 8); rig.base[0].add(q, qx)
        }

        rig.part("deploy", pivot: V3(px, py, 0), joint: .hinge(axis: V3(0, 0, 1), 0...90, duration: 4))
        rig.part("tubes1", parent: "deploy", pivot: V3(px, py, 0), joint: .fixed, options: 2)
        rig.part("fold", parent: "deploy", pivot: V3(kx, py, 0), joint: Joint(.revolute, axis: V3(0, 0, 1), range: -180...0, duration: 4, mimic: .init("deploy", ratio: -2)))
        rig.part("tubes2", parent: "fold", pivot: V3(kx, py, 0), joint: .fixed, options: 2)

        func segment(_ part: String, _ tubes: String, x0: Float, x1: Float, tip: Bool) {
            let xc = (x0 + x1) / 2, len = x1 - x0
            func A(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002) { let (a, x) = OK.box(s, c, mat, r: r); rig.add(a, x, to: part) }
            for sz: Float in [-1, 1] { A(V3(len, T, rail), V3(xc, T / 2, sz * (W / 2 - rail / 2)), frame, r: 0.004) }
            for xe in [x0 + rail / 2, x1 - rail / 2] { A(V3(rail, T, W - 2 * rail), V3(xe, T / 2, 0), frame, r: 0.004) }
            A(V3(len - 2 * rail, T - 0.016, W - 2 * rail), V3(xc, T / 2, 0), "metal.casework", r: 0.001)
            A(V3(len - 2 * rail, 0.006, W - 2 * rail), V3(xc, 0.004, 0), "\(coating):D9D9D3", r: 0.001)
            let n = 6, gap: Float = 0.008, tw = (len - 2 * rail - Float(n + 1) * gap) / Float(n)
            for i in 0..<n {
                let tone = ["E7E7E1", "E3E2DB", "EAEAE5", "DDDCD4", "E6E5DE", "E1E1DA"][(i + (part == "fold" ? 3 : 0)) % 6]
                A(V3(tw, 0.006, W - 2 * rail - 0.016), V3(x0 + rail + gap + tw / 2 + Float(i) * (tw + gap), T - 0.01, 0), "\(coating):\(tone)", r: 0.0015)
            }
            // Orbital-debris scuff and a Kapton repair patch on one tile.
            if part == "fold" { A(V3(0.14, 0.0015, 0.14), V3(xc + 0.5, T - 0.0065, 0.6), "solar.kapton", r: 0.0005) }
            // Coolant tubes across the width plus headers along both rails.
            let ty = T - 0.012
            var x = x0 + rail + 0.12
            while x < x1 - rail - 0.06 {
                let p = [V3(x, ty, -W / 2 + rail + 0.05), V3(x, ty, W / 2 - rail - 0.05)]
                rig.add(Prim.tube(p, radii: [0.008, 0.008], sides: 4, seamTile: 0.1, material: tube), .identity, to: tubes, option: 0)
                rig.add(Prim.tube(p, radii: [0.008, 0.008], sides: 4, seamTile: 0.1, material: glow), .identity, to: tubes, option: 1)
                x += tubeSpacing
            }
            for sz: Float in [-1, 1] {
                let p = [V3(x0 + rail + 0.04, T - 0.012, sz * (W / 2 - rail - 0.03)), V3(x1 - rail - 0.04, T - 0.012, sz * (W / 2 - rail - 0.03))]
                rig.add(Prim.tube(p, radii: [0.013, 0.013], sides: 8, seamTile: 0.1, material: tube), .identity, to: tubes, option: 0)
                rig.add(Prim.tube(p, radii: [0.013, 0.013], sides: 8, seamTile: 0.1, material: glow), .identity, to: tubes, option: 1)
            }
            // Edge bolts.
            var bm = Model(name: "edge")
            var bx = x0 + 0.3
            while bx < x1 - 0.2 { for sz: Float in [-1, 1] { OK.bolt(&bm, at: V3(bx, T, sz * (W / 2 - rail / 2)), size: 0.011, hardware) }; bx += 1.2 + rng.float(0...0.02) }
            rig.add(bm, to: part, lod: 0)
            if tip { A(V3(0.2, 0.09, W - 0.2), V3(x1 + 0.1, T / 2, 0), frame, r: 0.004)   // launch-lock bar
                for k in 0..<3 { let (c, y) = OK.cylY(0.03, 0.02, at: V3(x1 + 0.1, T, -1.2 + Float(k) * 1.2), hardware, seg: 12); rig.add(c, y, to: part) } }
        }
        segment("deploy", "tubes1", x0: px + 0.0, x1: kx - 0.01, tip: false)
        segment("fold", "tubes2", x0: kx + 0.01, x1: kx + 0.01 + L, tip: true)
        // Mid-span hinge knuckles.
        for k in 0..<4 {
            let z = -1.5 + Float(k) * 1.0
            let (a, x) = OK.cylZ(0.04, 0.4, x: kx, y: py, z0: z - 0.2, hardware, seg: 8); rig.add(a, x, to: "deploy")
        }
        rig.lights = [RigLight(name: "heat", part: "tubes1", option: 1, position: V3(-2.4, 0.25, 0), direction: V3(0, -1, 0), color: V3(1, 0.35, 0.08), intensity: 600, attenuationRadius: 3)]
        groundAO(&rig, height: 0.05, floor: 0.7)
        rig.states = [RigState("deployed"), RigState("half", ["deploy": 45]), RigState("stowed", ["deploy": 90]),
                      RigState("deployed-hot", options: ["tubes1": 1, "tubes2": 1])]
        return rig
    }
}
