import simd
import Foundation

/// LCRNS-style lunar relay smallsat, bus 1.2 x 1.2 x 1.8 m, wings spanning 7.4 m: gold and black MLI-wrapped box bus with
/// taped panel seams, two two-panel solar wings with cell grids, 0.8 m Ka dish on a two-link boom, S-band patches,
/// main engine bell, RCS thrusters and star trackers. Bus +Z is the antenna face, wings extend along X.
public struct LunarRelaySatellite: RealAsset {
    public static let id = "lunar-relay-satellite"
    public static let summary = "LCRNS-style lunar relay smallsat: gold/black MLI bus with seams, two solar wings with cell grid, 0.8 m Ka dish on boom, S-band patches, thrusters, star trackers."
    public static let tags = ["prop", "aerospace", "metal", "electronics", "vehicle"]
    public static let budget = 30000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.5, studio: true)

    /// Bus size (m): x width, y height, z length.
    public var bus: V3 = V3(1.2, 1.2, 1.8)
    /// Ka-band dish diameter (m).
    public var dishDiameter: Float = 0.8
    /// Solar panel length and width (m), two panels per wing.
    public var panelLength: Float = 1.45
    public var panelWidth: Float = 1.5
    /// Cells per panel along length and width.
    public var cellsX: Int = 8
    public var cellsZ: Int = 6
    public init() {}

    static let blackMLI: MaterialKey = "plastic.black"
    static let cellBlue = "screen.off:12213D"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        typealias K = LunarKit
        var levels: [Model] = []
        let cy: Float = bus.y / 2 + 0.06   // bus centre height, thrusters hang below
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = 1
            let hx = bus.x / 2, hy = bus.y / 2, hz = bus.z / 2
            // Structural core, slightly smaller than the MLI skin.
            m.add(Prim.roundedBox(V3(bus.x - 0.04, bus.y - 0.04, bus.z - 0.04), radius: 0.02, bevelSegments: 1, material: K.white), Xform(translation: V3(0, cy, 0)))
            // MLI quilted panels: each face split into 2 x 2 blankets with pillowy edges and silver tape seams between.
            func blanket(_ size: V3, _ at: V3, _ mat: MaterialKey) {
                m.add(Prim.roundedBox(size, radius: 0.028, bevelSegments: bs, material: mat), Xform(translation: at + V3(0, cy, 0), rotation: simd_quatf(angle: rng.float(-0.006...0.006), axis: V3(0, 1, 0))))
            }
            let t: Float = 0.05
            // +-X faces (wing sides): gold, with black patch.
            for s: Float in [-1, 1] {
                for (iz, zc) in [-bus.z / 4, bus.z / 4].enumerated() {
                    for (iy, yc) in [-bus.y / 4, bus.y / 4].enumerated() {
                        let mat = (iz + iy) % 2 == 0 ? K.gold : Self.blackMLI
                        blanket(V3(t, bus.y / 2 - 0.02, bus.z / 2 - 0.02), V3(s * (hx - t / 2 + 0.012), yc, zc), mat)
                    }
                }
            }
            // -Y face (anti-sun): white radiator plate with fin lines, black MLI frame.
            m.add(Prim.roundedBox(V3(bus.x - 0.05, 0.03, bus.z - 0.05), radius: 0.01, bevelSegments: 1, material: Self.blackMLI), Xform(translation: V3(0, cy - hy + 0.004, 0)))
            // +Y face: gold quilt, 2 x 3 blankets.
            for ix in 0..<2 { for iz in 0..<3 {
                let w = (bus.x - 0.04) / 2, d = (bus.z - 0.04) / 3
                blanket(V3(w - 0.02, t, d - 0.02), V3(-hx + 0.02 + w * (Float(ix) + 0.5), hy - t / 2 + 0.012, -hz + 0.02 + d * (Float(iz) + 0.5)), (ix + iz) % 3 == 1 ? Self.blackMLI : K.gold)
            } }
            // -Y face: gold blankets around the radiator.
            for s: Float in [-1, 1] {
                blanket(V3(0.3, t, bus.z - 0.1), V3(s * (hx - 0.18), -hy + t / 2 - 0.012, 0), K.gold)
            }
            m.add(Prim.roundedBox(V3(0.5, 0.012, bus.z - 0.2), radius: 0.004, bevelSegments: 1, material: K.white), Xform(translation: V3(0, cy - hy - 0.004, 0)))
            // +-Z faces: -Z gold with engine opening, +Z black with antenna deck.
            for ix in 0..<2 { for iy in 0..<2 {
                let w = (bus.x - 0.04) / 2, h = (bus.y - 0.04) / 2
                let p = V3(-hx + 0.02 + w * (Float(ix) + 0.5), -hy + 0.02 + h * (Float(iy) + 0.5), 0)
                blanket(V3(w - 0.02, h - 0.02, t), p + V3(0, 0, -hz + t / 2 - 0.012), (ix + iy) % 2 == 0 ? K.gold : Self.blackMLI)
                blanket(V3(w - 0.02, h - 0.02, t), p + V3(0, 0, hz - t / 2 + 0.012), (ix + iy) % 2 == 0 ? Self.blackMLI : K.gold)
            } }
            // Silver Kapton tape seams on the bus edges and mid-lines.
            func tape(_ size: V3, _ at: V3) {
                m.add(Prim.roundedBox(size, radius: 0.003, bevelSegments: 1, material: K.silver), Xform(translation: at + V3(0, cy, 0)))
            }
            let ts: Float = 0.014
            for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
                tape(V3(ts, ts, bus.z + 0.012), V3(sx * (hx + 0.002), sy * (hy + 0.002), 0))
                tape(V3(ts, bus.y + 0.012, ts), V3(sx * (hx + 0.002), 0, sy * (hz + 0.002)))
                tape(V3(bus.x + 0.012, ts, ts), V3(0, sx * (hy + 0.002), sy * (hz + 0.002)))
            } }
            tape(V3(ts, bus.y + 0.01, ts), V3(hx + 0.012, 0, 0)); tape(V3(ts, bus.y + 0.01, ts), V3(-hx - 0.012, 0, 0))
            for s: Float in [-1, 1] {
                tape(V3(0.012, ts, bus.z), V3(s * (hx + 0.014), 0, 0))
                tape(V3(0.012, bus.y, ts), V3(s * (hx + 0.014), 0, 0))
            }
            tape(V3(bus.x, 0.012, ts), V3(0, hy + 0.014, 0))
            tape(V3(ts, 0.012, bus.z), V3(0, hy + 0.014, 0))
            tape(V3(ts, bus.y, 0.012), V3(0, 0, hz + 0.014))
            tape(V3(bus.x, ts, 0.012), V3(0, 0, hz + 0.014))
            // Hold-down tie cords and velcro tabs along seams.
            if l == 0 {
                for k in 0..<10 {
                    let z = -hz + 0.15 + Float(k) * (bus.z - 0.3) / 9
                    for s: Float in [-1, 1] {
                        m.add(Prim.roundedBox(V3(0.02, 0.05, 0.02), radius: 0.004, bevelSegments: 1, material: K.orange), Xform(translation: V3(s * (hx + 0.022), cy + (k % 2 == 0 ? 0.3 : -0.3), z)))
                    }
                }
            }
            // Corner brackets / launch separation ring on -Z.
            m.add(Prim.cylinder(radius: 0.32, height: 0.05, bevel: 0.006, segments: l == 0 ? 36 : 18, material: K.silver),
                  Xform(translation: V3(0, cy - 0.12, -hz - 0.05), rotation: K.toZ))
            // Main engine bell on -Z.
            m.add(Prim.lathe([V2(0.04, 0), V2(0.05, -0.04), V2(0.09, -0.16), V2(0.15, -0.3), V2(0.152, -0.31), V2(0.14, -0.31), V2(0.085, -0.16), V2(0.035, -0.02)], segments: l == 0 ? 28 : 14, seamTile: 0.3, material: "metal.anodized-gunmetal"),
                  Xform(translation: V3(0, cy - 0.12, -hz - 0.07), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
            // RCS thruster pods at four corners of the -Z end: nozzle cones plus gold heat shield.
            for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
                let p = V3(sx * (hx + 0.07), cy + sy * (hy - 0.12), -hz + 0.2)
                m.add(Prim.roundedBox(V3(0.1, 0.1, 0.16), radius: 0.015, bevelSegments: bs, material: K.silver), Xform(translation: p))
                m.add(Prim.lathe([V2(0.012, 0), V2(0.018, 0.03), V2(0.03, 0.07), V2(0.026, 0.07), V2(0.015, 0.03), V2(0.01, 0)], segments: 12, seamTile: 0.2, material: "metal.anodized-gunmetal"),
                      Xform(translation: p + V3(sx * 0.02, 0, -0.08), rotation: simd_quatf(angle: sx * 0.35, axis: V3(0, 0, 1)) * simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                m.add(Prim.roundedBox(V3(0.12, 0.012, 0.1), radius: 0.003, bevelSegments: 1, material: K.gold), Xform(translation: p + V3(0, sy * 0.058, 0.02)))
            } }
            // Radiator-side vent / fill-drain valve.
            m.add(Prim.cylinder(radius: 0.018, height: 0.04, bevel: 0.004, segments: 10, material: K.orange), Xform(translation: V3(hx + 0.03, cy + 0.1, 0.3), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))))

            // Solar wings: yoke, SADA drive, two panels each.
            for s: Float in [-1, 1] {
                let sada = V3(s * (hx + 0.23), cy, 0)
                m.add(Prim.cylinder(radius: 0.11, height: 0.2, bevel: 0.015, segments: l == 0 ? 24 : 12, material: K.silver),
                      Xform(translation: V3(s * (hx + 0.12), cy, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))))
                m.add(Prim.cylinder(radius: 0.13, height: 0.05, bevel: 0.01, segments: l == 0 ? 24 : 12, material: K.gold),
                      Xform(translation: V3(s * (hx + 0.26), cy, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))))
                // Yoke arms to panel.
                let x0 = s * (hx + 0.31)
                for z: Float in [-1, 1] {
                    m.add(Prim.tube([V3(x0, cy, z * 0.04), V3(x0 + s * 0.2, cy, z * 0.3), V3(x0 + s * 0.3, cy, z * (panelWidth / 2 - 0.05))], radii: [0.02, 0.018, 0.018], sides: 8, seamTile: 0.1, material: K.silver))
                }
                _ = sada
                for p in 0..<2 {
                    let px = x0 + s * (0.3 + Float(p) * (panelLength + 0.06)) + s * panelLength / 2
                    panel(&m, cx: px, y: cy, lod: l, rng: &rng, hinge: s)
                }
                // Hinge barrel between panels and tip latch.
                m.add(Prim.cylinder(radius: 0.014, height: panelWidth - 0.1, bevel: 0.002, segments: 8, material: K.silver),
                      Xform(translation: V3(x0 + s * (0.3 + panelLength + 0.03), cy + 0.01, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
                _ = sada
            }

            // Ka-band HGA: dish on gimbal, two-link boom from the +Z/+Y corner.
            let base = V3(0.0, cy + hy, hz - 0.35)
            let elbow = base + V3(0, 0.42, 0.18)
            let gimbal = elbow + V3(0, 0.12, 0.38)
            m.add(Prim.cylinder(radius: 0.09, height: 0.07, bevel: 0.01, segments: 16, material: K.silver), Xform(translation: base + V3(0, 0.03, 0)))
            m.add(Prim.tube([base, elbow], radii: [0.036, 0.03], sides: 12, seamTile: 0.1, material: K.white))
            m.add(Prim.cylinder(radius: 0.045, height: 0.09, bevel: 0.02, segments: 14, material: K.silver), Xform(translation: elbow))
            m.add(Prim.tube([elbow, gimbal], radii: [0.03, 0.026], sides: 12, seamTile: 0.1, material: K.white))
            m.add(Prim.roundedBox(V3(0.14, 0.12, 0.1), radius: 0.015, bevelSegments: bs, material: K.silver), Xform(translation: gimbal))
            let R = dishDiameter / 2, f = R * 0.42
            let tilt = simd_quatf(angle: -0.25, axis: V3(1, 0, 0)) * K.toZ  // dish axis +Z, tilted toward nadir
            let dishAt = gimbal + V3(0, 0.0, 0.07)
            for sfc in K.dish(R: R, f: f, thick: 0.008, segments: l == 0 ? 44 : 20, rings: 6, front: K.white, back: K.gold) {
                m.add(sfc, Xform(translation: dishAt, rotation: tilt))
            }
            // Feed boom: three struts to the subreflector and horn.
            let axisDir = tilt.act(V3(0, 1, 0))
            let focus = dishAt + axisDir * f
            for k in 0..<3 {
                let a = Float(k) * 2 * .pi / 3 + 0.5
                let rimPt = dishAt + tilt.act(V3(cos(a) * R * 0.78, (R * 0.78) * (R * 0.78) / (4 * f), sin(a) * R * 0.78))
                m.add(Prim.tube([rimPt, focus + axisDir * 0.02], radii: [0.008, 0.005], sides: 6, seamTile: 0.1, material: K.silver))
            }
            m.add(Prim.cylinder(radius: 0.045, height: 0.012, bevel: 0.003, segments: 16, material: K.silver), Xform(translation: focus + axisDir * 0.02, rotation: tilt))
            m.add(Prim.lathe([V2(0.012, 0), V2(0.03, 0.06), V2(0.032, 0.062), V2(0.016, 0.0)], segments: 12, seamTile: 0.1, material: K.gold),
                  Xform(translation: dishAt + axisDir * 0.012, rotation: tilt))

            // S-band patch antennas on the +Z and -Z faces and the +Y deck.
            func patch(_ at: V3, _ rot: simd_quatf) {
                m.add(Prim.roundedBox(V3(0.16, 0.012, 0.16), radius: 0.004, bevelSegments: 1, material: K.silver), Xform(translation: at, rotation: rot))
                m.add(Prim.roundedBox(V3(0.11, 0.008, 0.11), radius: 0.003, bevelSegments: 1, material: "plastic.white"), Xform(translation: at + rot.act(V3(0, 0.008, 0)), rotation: rot))
            }
            patch(V3(-0.35, cy + 0.0, hz + 0.03), K.toZ); patch(V3(0.35, cy + 0.0, hz + 0.03), K.toZ)
            patch(V3(0, cy + 0.38, -hz - 0.03), K.toZ * simd_quatf(angle: .pi, axis: V3(1, 0, 0)))
            patch(V3(0, cy + hy + 0.03, -0.55), simd_quatf(angle: 0, axis: V3(0, 1, 0)))
            // UHF whip and GPS-style puck.
            m.add(Prim.tube([V3(0.4, cy + hy + 0.01, -0.2), V3(0.4, cy + hy + 0.45, -0.2)], radii: [0.012, 0.004], sides: 6, seamTile: 0.1, material: K.silver))
            m.add(Prim.cylinder(radius: 0.05, height: 0.035, bevel: 0.006, segments: 16, material: "plastic.white"), Xform(translation: V3(-0.38, cy + hy + 0.03, -0.1)))

            // Star trackers: baffle tubes on the +Y deck angled away, dark lens, sun shades.
            for (k, sx) in [Float(-0.3), 0.3].enumerated() {
                let at = V3(sx, cy + hy + 0.01, 0.35)
                let q = simd_quatf(angle: (k == 0 ? 0.5 : -0.5), axis: V3(0, 0, 1)) * simd_quatf(angle: -0.3, axis: V3(1, 0, 0))
                m.add(Prim.cylinder(radius: 0.06, height: 0.05, bevel: 0.006, segments: 16, material: K.silver), Xform(translation: at + V3(0, 0.02, 0)))
                m.add(Prim.lathe([V2(0.04, 0), V2(0.05, 0.0), V2(0.06, 0.14), V2(0.052, 0.14), V2(0.04, 0.04)], segments: 18, seamTile: 0.2, material: K.dark),
                      Xform(translation: at + V3(0, 0.04, 0), rotation: q))
                m.add(Prim.cylinder(radius: 0.038, height: 0.006, bevel: 0.001, segments: 14, material: "glass.lens-coated"), Xform(translation: at + V3(0, 0.05, 0) + q.act(V3(0, 0.1, 0)), rotation: q))
            }
            // Sun sensors, camera, and propulsion tank bulge on -Y.
            m.add(Prim.cylinder(radius: 0.022, height: 0.014, bevel: 0.003, segments: 12, material: "glass.lens-coated"), Xform(translation: V3(0.5, cy + hy + 0.03, 0.7)))
            m.add(Prim.cylinder(radius: 0.022, height: 0.014, bevel: 0.003, segments: 12, material: "glass.lens-coated"), Xform(translation: V3(-0.5, cy + hy + 0.03, 0.7)))
            m.add(Prim.roundedBox(V3(0.1, 0.07, 0.07), radius: 0.012, bevelSegments: bs, material: K.dark), Xform(translation: V3(0.0, cy - hy - 0.04, hz - 0.2)))
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [12])
    }

    /// One solar panel centred at cx, lying in the XZ plane at height y, cells facing +Y.
    func panel(_ m: inout Model, cx: Float, y: Float, lod: Int, rng: inout SeededRNG, hinge: Float) {
        typealias K = LunarKit
        let L = panelLength, W = panelWidth, fr: Float = 0.025, th: Float = 0.022
        let bs = 1
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(L, th, fr), radius: 0.004, bevelSegments: bs, material: K.silver), Xform(translation: V3(cx, y, s * (W / 2 - fr / 2))))
            m.add(Prim.roundedBox(V3(fr, th, W - 2 * fr + 0.002), radius: 0.004, bevelSegments: bs, material: K.silver), Xform(translation: V3(cx + s * (L / 2 - fr / 2), y, 0)))
        }
        m.add(Prim.roundedBox(V3(L - 2 * fr + 0.004, 0.01, W - 2 * fr + 0.004), radius: 0.001, bevelSegments: 1, material: "composite.carbon"), Xform(translation: V3(cx, y, 0)))
        // Mid ribs on the back.
        m.add(Prim.roundedBox(V3(0.02, 0.018, W - 2 * fr), radius: 0.003, bevelSegments: 1, material: K.silver), Xform(translation: V3(cx, y - 0.008, 0)))
        let iw = L - 2 * fr, id = W - 2 * fr
        let cw = iw / Float(cellsX), cd = id / Float(cellsZ)
        if lod > 0 {
            m.add(Prim.roundedBox(V3(iw, 0.002, id), radius: 0.0008, bevelSegments: 1, material: Self.cellBlue), Xform(translation: V3(cx, y + 0.007, 0)))
        } else {
            for i in 0..<cellsX { for k in 0..<cellsZ {
                let j = rng.float(-3...3)
                let hex = String(format: "%02X%02X%02X", Int(0x12 + j), Int(0x21 + j), Int(0x3D + j * 1.5))
                let w = cw - 0.006, d = cd - 0.006
                m.add(Prim.extrude([V2(-w / 2, -d / 2), V2(w / 2, -d / 2), V2(w / 2, d / 2), V2(-w / 2, d / 2)], depth: 0.002, bevel: 0, bevelSegments: 0, material: "screen.off:" + hex),
                      Xform(translation: V3(cx - iw / 2 + cw * (Float(i) + 0.5), y + 0.007, -id / 2 + cd * (Float(k) + 0.5)), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            } }
            for i in 1..<cellsX { m.add(Prim.roundedBox(V3(0.003, 0.0012, id), radius: 0.0004, bevelSegments: 1, material: K.silver), Xform(translation: V3(cx - iw / 2 + iw * Float(i) / Float(cellsX), y + 0.0075, 0))) }
            for k in 1..<cellsZ { m.add(Prim.roundedBox(V3(iw, 0.0012, 0.003), radius: 0.0004, bevelSegments: 1, material: K.silver), Xform(translation: V3(cx, y + 0.0075, -id / 2 + id * Float(k) / Float(cellsZ)))) }
        }
        // Gold-foil back.
        m.add(Prim.roundedBox(V3(iw, 0.0015, id), radius: 0.0005, bevelSegments: 1, material: K.gold), Xform(translation: V3(cx, y - 0.0062, 0)))
    }
}
