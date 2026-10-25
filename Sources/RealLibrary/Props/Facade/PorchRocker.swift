import simd
import Foundation

/// Southern vernacular porch rocker, 0.65 m wide: bentwood-style runners with pegged leg tenons, turned front legs that
/// continue as arm posts, raked turned back posts with ball finials, five back slats under an arched crest rail, a
/// seven-slat bullnose seat screwed to side rails, turned stretchers, rounded arms with bare-sanded tops and dowel plugs.
/// Cream paint in slightly different tones per part, chipped at edges and worn through on the runners. One seat slat is a
/// raw replacement board.
public struct PorchRocker: RealAsset {
    public static let id = "porch-rocker"
    public static let summary = "Southern porch rocking chair, 0.65 m wide: painted slat back and seat on turned legs, curved rockers, rounded arms."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 10, distance: 2.3)

    /// Paint for frame and slats (worn).
    public var paintKey = "wood.painted-shaker-worn"
    /// Cream base paint colour (sRGB hex).
    public var paint: UInt32 = 0xE6E0CE
    /// Rocker arc radius in meters.
    public var rockerRadius: Float = 1.6
    /// Back rake in degrees.
    public var rake: Float = 6
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    func hex(_ r: Int, _ g: Int, _ b: Int) -> String {
        String(format: "%02X%02X%02X", max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pr = Int((paint >> 16) & 0xFF), pg = Int((paint >> 8) & 0xFF), pb = Int(paint & 0xFF)
        func tone(_ d: Int) -> MaterialKey { "\(paintKey):" + hex(pr + d, pg + d, pb + d - d / 3) }
        let seg = lite ? 8 : 12
        let legX: Float = 0.285, legZ: Float = 0.27
        let R = rockerRadius
        func arc(_ z: Float) -> Float { R - (R * R - z * z).squareRoot() }
        let rockT: Float = 0.04, rockW: Float = 0.03
        let rockTop = rockT + arc(legZ)
        let th = rake * .pi / 180
        let up = V3(0, cos(th), -sin(th)), nf = V3(0, sin(th), cos(th))
        let postY0: Float = rockTop - 0.008
        let postO = V3(0, postY0, -legZ)
        func post(_ h: Float) -> V3 { postO + up * h }
        func rearZ(_ y: Float) -> Float { post((y - postY0) / cos(th)).z }
        func screw(_ p: V3, _ n: V3, _ size: Float = 0.0075) {
            m.add(Prim.cylinder(radius: size * 0.5, height: size * 0.4, bevel: 0, segments: 6, bevelSegments: 1, material: "metal.steel"), Xform(translation: p, rotation: facing(n)))
        }
        // Runners: curved bands, pegged tenons, worn bare along the contact edge.
        for sx: Float in [-1, 1] {
            let x = sx * (legX + 0.012)
            var lower: [V2] = [], upper: [V2] = []
            let n = 16
            for i in 0...n {
                let z = -0.4 + 0.8 * Float(i) / Float(n)
                lower.append(V2(z, arc(z)))
            }
            for p in lower.reversed() { upper.append(V2(p.x, p.y + rockT - (abs(p.x) > 0.34 ? (abs(p.x) - 0.34) * 0.35 : 0))) }
            let outline = Shape2D.rounded(Shape2D.deduped(lower + upper), radius: 0.012)
            m.add(Prim.extrude(outline, depth: rockW, bevel: 0.004, bevelSegments: 1, material: tone(-26 + rng.int(-4...4))),
                  Xform(translation: V3(x, 0, 0), rotation: FA.q(90, FA.Y)))
            // Bare, polished wear strip on the contact edge.
            var wl: [V2] = [], wu: [V2] = []
            for i in 0...n {
                let z = -0.33 + 0.66 * Float(i) / Float(n)
                wl.append(V2(z, arc(z) - 0.0004))
            }
            for p in wl.reversed() { wu.append(V2(p.x, p.y + 0.007)) }
            m.add(Prim.extrude(Shape2D.deduped(wl + wu), depth: rockW + 0.0006, bevel: 0.0012, bevelSegments: 1, material: "wood.weathered:8D7C66"),
                  Xform(translation: V3(x, 0, 0), rotation: FA.q(90, FA.Y)))
            // Dowel pegs through the runner at each leg.
            if !lite {
                for lz in [legZ, -legZ] {
                    m.add(Prim.cylinder(radius: 0.0075, height: 0.003, bevel: 0.0008, segments: 10, bevelSegments: 1, material: "wood.pine-aged"),
                          Xform(translation: V3(x + sx * rockW / 2, arc(lz) + 0.02, lz), rotation: FA.q(sx * -90, FA.Z)))
                }
            }
        }
        // Front legs continuing as arm posts.
        let frontProfile: [(Float, Float)] = [(0, 0.055), (0.0155, 0.055), (0.0155, 0.09), (0.0195, 0.095), (0.0195, 0.13), (0.0155, 0.145), (0.0145, 0.19), (0.0185, 0.22), (0.0185, 0.26), (0.0135, 0.285), (0.0145, 0.32), (0.0205, 0.345), (0.0205, 0.385), (0.0165, 0.4), (0.0225, 0.41), (0.0225, 0.455), (0.0165, 0.468), (0.0135, 0.5), (0.0125, 0.56), (0.0165, 0.6), (0.0195, 0.63), (0.0155, 0.655), (0.0125, 0.665), (0.0125, 0.68), (0, 0.68)]
        for sx: Float in [-1, 1] {
            m.add(turned(frontProfile, segments: seg, material: tone(-10 + rng.int(-4...4)), seamTile: 0.1, grainVertical: true),
                  Xform(translation: V3(sx * legX, 0, legZ)))
        }
        // Raked back posts with ball finials.
        let postL: Float = 0.95
        let rearProfile: [(Float, Float)] = [(0, 0), (0.0155, 0), (0.0155, 0.035), (0.0195, 0.04), (0.0195, 0.07), (0.0155, 0.085), (0.0145, 0.13), (0.0185, 0.155), (0.0185, 0.19), (0.0145, 0.21), (0.0145, 0.33), (0.0205, 0.345), (0.0225, 0.355), (0.0225, 0.405), (0.0165, 0.42), (0.0155, 0.5), (0.0155, 0.84), (0.019, 0.855), (0.019, 0.875), (0.0145, 0.89), (0.011, 0.9), (0.0165, 0.915), (0.0175, 0.93), (0.0135, 0.945), (0.006, 0.955), (0, 0.957)]
        for sx: Float in [-1, 1] {
            m.add(turned(rearProfile, segments: seg, material: tone(-14 + rng.int(-4...4)), seamTile: 0.1, grainVertical: true),
                  Xform(translation: postO + V3(sx * legX, 0, 0), rotation: FA.q(-rake, FA.X)))
        }
        _ = postL
        // Seat: seven bullnose slats tilted back, side rails and front/back aprons below.
        let aSeat: Float = 4 * .pi / 180
        let seatFrontY: Float = 0.462, seatFrontZ: Float = 0.305
        let slatT: Float = 0.018
        let sn = V3(0, cos(aSeat), -sin(aSeat))
        var seatTops: [V3] = []
        for k in 0..<7 {
            let s = 0.0375 + Float(k) * 0.0805
            let top = V3(0, seatFrontY - s * sin(aSeat), seatFrontZ - s * cos(aSeat))
            seatTops.append(top)
            let mat: MaterialKey = k == 4 ? "wood.weathered:B0A48C" : tone(rng.int(-14...8))
            m.add(Prim.roundedBox(V3(0.532, slatT, 0.075), radius: k == 0 ? 0.0075 : 0.004, bevelSegments: k == 0 ? 2 : 1, material: mat),
                  Xform(translation: top - sn * (slatT / 2), rotation: FA.q(-4, FA.X)))
        }
        let railH: Float = 0.05
        let railMid = V3(0, seatFrontY - 0.29 * sin(aSeat), seatFrontZ - 0.29 * cos(aSeat))
        for sx: Float in [-1, 1] {
            let x = sx * 0.248
            m.add(Prim.roundedBox(V3(0.03, railH, 0.62), radius: 0.004, bevelSegments: 1, material: tone(-26)),
                  Xform(translation: railMid + V3(x, 0, 0) - sn * (slatT + railH / 2 - 0.001), rotation: FA.q(-4, FA.X)))
            if !lite {
                for k in 0..<7 { screw(seatTops[k] + V3(x, 0.0007, 0), sn) }
            }
        }
        FA.box(&m, V3(0.53, 0.05, 0.026), V3(0, 0.425, legZ), tone(-24), r: 0.004)
        let rz = rearZ(0.425)
        FA.box(&m, V3(0.53, 0.05, 0.026), V3(0, 0.425, rz), tone(-24), r: 0.004)
        // Turned stretchers: front, rear and both sides, tenons into the legs.
        func stretcher(_ a: V3, _ b: V3) {
            let L = simd_length(b - a)
            let prof: [(Float, Float)] = [(0, 0), (0.009, 0), (0.0095, 0.012), (0.0125, 0.03), (0.0125, L * 0.4 - 0.012), (0.0095, L * 0.4), (0.0165, L * 0.5), (0.0095, L * 0.6), (0.0125, L * 0.6 + 0.012), (0.0125, L - 0.03), (0.0095, L - 0.012), (0.009, L), (0, L)]
            m.add(turned(prof, segments: lite ? 6 : 10, material: tone(-18), seamTile: 0.1, grainVertical: true),
                  Xform(translation: a, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_normalize(b - a))))
        }
        let sY: Float = 0.215
        stretcher(V3(-legX, sY, legZ), V3(legX, sY, legZ))
        stretcher(V3(-legX, sY, rearZ(sY)), V3(legX, sY, rearZ(sY)))
        for sx: Float in [-1, 1] {
            stretcher(V3(sx * legX, sY - 0.04, legZ), V3(sx * legX, sY - 0.04, rearZ(sY - 0.04)))
        }
        // Back: five slats between the posts under an arched crest rail.
        var slatCentres: [V3] = []
        for k in 0..<5 {
            let c = post(0.47 + Float(k) * 0.085)
            slatCentres.append(c)
            let mat: MaterialKey = tone(rng.int(-14...8))
            m.add(Prim.roundedBox(V3(0.55, 0.06, 0.015), radius: 0.004, bevelSegments: 1, material: mat),
                  Xform(translation: c, rotation: FA.q(-rake, FA.X)))
            if !lite {
                for sx: Float in [-1, 1] {
                    screw(c + nf * 0.0079 + V3(sx * 0.2, 0, 0), nf, 0.007)
                }
            }
        }
        var crest: [V2] = []
        for i in 0...20 {
            let u = Float(i) / 20
            crest.append(V2(-0.275 + 0.55 * u, 0.045 + 0.028 * sin(u * .pi) * sin(u * .pi)))
        }
        crest.append(V2(0.275, -0.04)); crest.append(V2(-0.275, -0.04))
        m.add(Prim.extrude(Shape2D.rounded(Shape2D.deduped(crest), radius: 0.008), depth: 0.022, bevel: 0.004, bevelSegments: 2, material: tone(-6)),
              Xform(translation: post(0.865), rotation: FA.q(-rake, FA.X)))
        // Arms: rounded boards from the front post tops back to the rear posts, bare-sanded tops, dowel plugs.
        let armY: Float = 0.675
        let armBackZ = rearZ(armY) - 0.012
        let armLen = 0.31 - armBackZ
        for sx: Float in [-1, 1] {
            let x = sx * legX
            m.add(Prim.extrude(Shape2D.roundedRect(0.064, armLen, radius: 0.028, segments: lite ? 2 : 4), depth: 0.024, bevel: 0.006, bevelSegments: 1, material: tone(rng.int(-14 ... -4))),
                  Xform(translation: V3(x, armY, (0.31 + armBackZ) / 2), rotation: FA.q(90, FA.X)))
            m.add(cuboid(V3(0.04, 0.0008, 0.22), material: "wood.weathered:A19480"), Xform(translation: V3(x, armY + 0.0123, 0.12)))
            if !lite {
                m.add(Prim.cylinder(radius: 0.0085, height: 0.002, bevel: 0.0006, segments: 8, bevelSegments: 1, material: "wood.pine-aged"), Xform(translation: V3(x, armY + 0.0123, legZ)))
                screw(V3(x, armY + 0.0123, armBackZ + 0.03), FA.Y, 0.011)
                for _ in 0..<4 {
                    m.add(cuboid(V3(rng.float(0.008...0.03), 0.0009, rng.float(0.003...0.007)), material: "wood.weathered"),
                          Xform(translation: V3(x + sx * 0.0305, armY + 0.0121, rng.float(-0.2...0.29)), rotation: simd_quatf(angle: rng.float(-0.3...0.3), axis: FA.Y)))
                }
            }
        }
        // Paint chips and scuffs: seat slat edges, back slat edges, leg bases.
        if !lite {
            for _ in 0..<22 {
                let side: Float = rng.chance(0.5) ? -1 : 1
                let yaw = rng.float(-0.25...0.25)
                if rng.chance(0.5) {
                    let top = seatTops[rng.int(0...6)]
                    let edge: Float = rng.chance(0.6) ? 0.037 : -0.037
                    m.add(cuboid(V3(rng.float(0.01...0.06), 0.0009, rng.float(0.003...0.007)), material: "wood.weathered"),
                          Xform(translation: V3(side * rng.float(0.03...0.24), top.y + 0.0004 + edge * sin(aSeat), top.z - edge * cos(aSeat)), rotation: FA.q(-4, FA.X) * simd_quatf(angle: yaw, axis: FA.Y)))
                } else {
                    let c = slatCentres[rng.int(0...4)] + nf * 0.0078 + up * (rng.chance(0.5) ? 0.03 : -0.03) + V3(side * rng.float(0.03...0.24), 0, 0)
                    m.add(cuboid(V3(rng.float(0.01...0.06), rng.float(0.003...0.007), 0.0009), material: "wood.weathered"),
                          Xform(translation: c, rotation: FA.q(-rake, FA.X) * simd_quatf(angle: yaw, axis: FA.Z)))
                }
            }
            for sx: Float in [-1, 1] {
                m.add(cuboid(V3(0.012, 0.03, 0.0009), material: "wood.weathered"), Xform(translation: V3(sx * legX + 0.002, 0.095 + rockT, legZ + 0.0154)))
            }
        }
        _ = rng
        return FC.place(m)
    }
}
