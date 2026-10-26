import simd
import Foundation

/// Parisian scalloped canvas awning, 1.6 m wide, 0.9 m tall, 0.9 m projection: two wall bracket plates with bolts,
/// wrought-iron side arms with lower braces and clamps, three intermediate ribs, a round front bar with ball finials,
/// eight alternating cream and bordeaux canvas gores that sag between the ribs, cord piping along every seam, a 300 mm
/// scalloped valance with a stitched hem and piped edge, and triangular drop sides. Wear: sun-faded cream, grime and
/// mildew speckle along the valance edge, bird droppings on the slope, a patched tear with its own stitching, rust on
/// the iron.
public struct CanvasAwningScalloped: RealAsset {
    public static let id = "canvas-awning-scalloped"
    public static let summary = "Parisian scalloped canvas awning 1.6 m: iron frame, striped canvas, scalloped valance."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 36, elevation: 18, distance: 3.2)

    /// Cream gores.
    public var cream: MaterialKey = "fabric.canvas:E6DDC6"
    /// Coloured gores.
    public var stripe: MaterialKey = "fabric.canvas:7B2230"
    /// Frame iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.6, yTop: Float = 0.9, yFront: Float = 0.3, zWall: Float = 0.012, zFront: Float = 0.875
        let stripes = 8, sw = W / Float(stripes)
        let ribs: [Float] = [-0.8 + 0.1, -0.4, 0, 0.4, 0.8 - 0.1]
        let slope = (yTop - yFront) / (zFront - zWall)

        // Canvas surface height at (x, z): linear slope, sagging between ribs and a little along the run.
        func surfY(_ x: Float, _ z: Float) -> Float {
            var d: Float = 1
            for i in 0..<(ribs.count - 1) where x >= ribs[i] && x <= ribs[i + 1] {
                let t = (x - ribs[i]) / (ribs[i + 1] - ribs[i])
                d = 4 * t * (1 - t)
            }
            if x < ribs[0] || x > ribs.last! { d = 0 }
            let along = sin(.pi * min(max((z - zWall) / (zFront - zWall), 0), 1))
            return yTop + 0.004 - slope * (z - zWall) - 0.016 * d * (0.35 + 0.65 * along) - 0.012 * d
        }

        // Gores: top and under surfaces, 6 x 14 grid each, alternating colours.
        for i in 0..<stripes {
            let x0 = -W / 2 + Float(i) * sw, x1 = x0 + sw
            let mat = i % 2 == 0 ? cream : stripe
            for side in 0..<2 {
                var s = Surface(material: mat)
                let nx = 4, nz = 10
                for kz in 0...nz {
                    for kx in 0...nx {
                        let x = x0 + sw * Float(kx) / Float(nx), z = zWall + (zFront - zWall) * Float(kz) / Float(nz)
                        let y = surfY(x, z) - (side == 0 ? 0 : 0.0032)
                        s.add(V3(x, y, z), .up, V2(x, z / cos(atan(slope))))
                    }
                }
                let row = UInt32(nx + 1)
                for kz in 0..<nz { for kx in 0..<nx {
                    let a = UInt32(kz) * row + UInt32(kx)
                    s.quad(a, a + row, a + row + 1, a + 1)
                }}
                s.recomputeNormals(weldSeams: false)
                s.computeTangents()
                m.add(side == 0 ? s : s.flipped())
            }
            // Piping at the seam between gores, following the sag.
            let seam: [V3] = (0...8).map { k in
                let z = zWall + (zFront - zWall) * Float(k) / 8
                return V3(x0, surfY(x0, z) + 0.0018, z)
            }
            if i > 0 { FA.path(&m, seam, r: 0.0034, cream, sides: 6) }
        }
        // Edge piping at both ends and the top seam at the wall.
        for e: Float in [-1, 1] {
            let x = e * W / 2
            FA.path(&m, (0...8).map { k in let z = zWall + (zFront - zWall) * Float(k) / 8; return V3(x, surfY(x, z) + 0.0018, z) }, r: 0.0036, stripe, sides: 6)
        }
        FA.rod(&m, V3(-W / 2, yTop + 0.006, zWall), V3(W / 2, yTop + 0.006, zWall), r: 0.0042, "fabric.canvas:C9BFA6", sides: 6)

        // Wall brackets: plates with a rolled top edge and four bolts, pivot lugs.
        for e: Float in [-1, 1] {
            let x = e * 0.72
            FA.box(&m, V3(0.07, 0.3, 0.007), V3(x, 0.75, 0.0035), iron, r: 0.0025)
            for (dx, dy) in [(-0.022, -0.12), (0.022, -0.12), (-0.022, 0.12), (0.022, 0.12)] as [(Float, Float)] {
                hexBolt(&m, at: V3(x + dx, 0.75 + dy, 0.007), normal: FA.Z, size: 0.012, material: "metal.bolt-bright")
            }
            FA.box(&m, V3(0.03, 0.04, 0.03), V3(x, 0.875, 0.02), iron, r: 0.003)
            FA.box(&m, V3(0.03, 0.04, 0.03), V3(x, 0.66, 0.02), iron, r: 0.003)
        }
        // Arms: end arms (stout) with lower braces, plus three light ribs under the canvas.
        func armY(_ z: Float) -> Float { surfY(0.72, z) - 0.012 }
        for e: Float in [-1, 1] {
            let x = e * 0.72
            let arm: [V3] = (0...10).map { k in let z = zWall + 0.01 + (zFront - zWall - 0.01) * Float(k) / 10; return V3(x, armY(z), z) }
            FA.path(&m, arm, r: 0.0095, iron, sides: 10)
            FA.rod(&m, V3(x, 0.66, 0.024), V3(x, armY(0.52) + 0.0, 0.52), r: 0.0075, iron, sides: 8)
            FA.cylX(&m, r: 0.0125, h: 0.016, at: V3(x - 0.008, armY(0.52), 0.52), iron, bevel: 0.002, segments: 12)          // clamp
            hexBolt(&m, at: V3(x + 0.0085, armY(0.52), 0.52), normal: V3(1, 0, 0), size: 0.011, material: "metal.bolt-bright")
            // Scroll in the angle between brace and arm.
            m.add(Prim.torus(major: 0.032, minor: 0.0042, segments: 18, sides: 6, arc: 4.2, material: iron),
                  Xform(translation: V3(x, armY(0.3) - 0.04, 0.3), rotation: FA.q(90, FA.Z) * FA.q(-30, FA.X)))
            // Arm-to-front-bar socket.
            FA.box(&m, V3(0.03, 0.04, 0.04), V3(x, armY(zFront - 0.01), zFront - 0.01), iron, r: 0.004)
        }
        for x in [-0.36, 0.0, 0.36] as [Float] {
            let rib: [V3] = (0...10).map { k in let z = zWall + 0.01 + (zFront - zWall - 0.01) * Float(k) / 10; return V3(x, surfY(x, z) - 0.010, z) }
            FA.path(&m, rib, r: 0.0052, iron, sides: 8)
        }
        // Front bar with ball finials.
        let fy = armY(zFront - 0.01)
        FA.rod(&m, V3(-W / 2 + 0.02, fy, zFront - 0.01), V3(W / 2 - 0.02, fy, zFront - 0.01), r: 0.0105, iron, sides: 12)
        for e: Float in [-1, 1] { FC.bead(&m, r: 0.0165, at: V3(e * (W / 2 - 0.012), fy, zFront - 0.01), iron, sub: 5) }

        // Valance: scalloped gores hanging from the front bar, hem stitching and piping on each scallop.
        let vz: Float = zFront + 0.012, vTop = fy + 0.012, vBot: Float = 0.07, vt: Float = 0.004
        for i in 0..<stripes {
            let x0 = -W / 2 + Float(i) * sw, x1 = x0 + sw, xm = (x0 + x1) / 2
            let mat = i % 2 == 0 ? cream : stripe
            var pts: [V2] = []
            for k in 0...12 {
                let t = Float.pi + Float(k) / 12 * .pi
                pts.append(V2(xm + (sw / 2 - 0.0008) * cos(t), vBot + (vBot - 0.0) * sin(t)))
            }
            pts.append(V2(x1 - 0.0008, vTop)); pts.append(V2(x0 + 0.0008, vTop))
            m.add(Prim.extrude(Shape2D.deduped(pts), depth: vt, bevel: 0.001, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, vz)))
            // Piping around the scallop (cord, contrasting colour) and a stitch row set 12 mm inside.
            let edge: [V3] = (0...12).map { k in
                let t = Float.pi + Float(k) / 12 * .pi
                return V3(xm + (sw / 2 - 0.0008) * cos(t), vBot + vBot * sin(t), vz + vt / 2 + 0.0015)
            }
            FA.path(&m, edge, r: 0.0036, i % 2 == 0 ? stripe : cream, sides: 6)
            let hem: [V3] = (2...10).map { k in
                let t = Float.pi + Float(k) / 12 * .pi
                return V3(xm + (sw / 2 - 0.014) * cos(t), vBot + (vBot - 0.012) * sin(t) + 0.0, vz + vt)
            }
            m.add(stitches(along: hem, normal: { _ in FA.Z }, pitch: 0.012, thread: 0.0008, material: "fabric.canvas:B8AE96"))
        }
        // Seam cords between valance gores and the top hem roll over the front bar.
        for i in 1..<stripes {
            let x = -W / 2 + Float(i) * sw
            FA.rod(&m, V3(x, vBot + 0.0, vz + 0.0045), V3(x, vTop, vz + 0.0045), r: 0.0026, cream, sides: 5)
        }
        FA.rod(&m, V3(-W / 2, vTop, vz + 0.003), V3(W / 2, vTop, vz + 0.003), r: 0.007, stripe, sides: 8)

        // Drop sides: triangular gores, flat to the arm plane, piped along the hypotenuse.
        for e: Float in [-1, 1] {
            let x = e * (W / 2) + e * 0.0
            let tri: [V2] = [V2(zWall, yTop + 0.002), V2(zFront + 0.012, 0.075), V2(zFront + 0.012, yFront + 0.002)]
            m.add(Prim.extrude(tri, depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: e > 0 ? stripe : cream),
                  Xform(translation: V3(x + e * 0.002, 0, 0), rotation: FA.q(-90, FA.Y)))
            FA.rod(&m, V3(x + e * 0.004, yTop, zWall), V3(x + e * 0.004, 0.075, zFront + 0.012), r: 0.0028, e > 0 ? cream : stripe, sides: 5)
        }

        // Wear: faded sun side, grime and mildew speckle at the scallops, droppings, a patched tear.
        for _ in 0..<16 {
            let i = rng.int(0...(stripes - 1))
            let x = -W / 2 + (Float(i) + rng.float(0.15...0.85)) * sw
            let t = rng.float(0.05...0.95) * .pi
            let xm = -W / 2 + (Float(i) + 0.5) * sw
            _ = x
            let px = xm + (sw / 2 - 0.02) * -cos(t) * rng.float(0.2...1), py = vBot - (vBot - 0.002) * sin(t) * rng.float(0.5...0.95) - 0.004
            m.add(Prim.superellipsoid(V3(rng.float(0.006...0.02), rng.float(0.004...0.014), 0.0012), exponent: 2, subdivisions: 1, material: "metal.rust-grime"),
                  Xform(translation: V3(px, max(py, 0.01), vz + vt + 0.0006)))
        }
        for _ in 0..<7 {                                                      // bird droppings, flat on the slope
            let x = rng.float(-0.7...0.7), z = rng.float(0.25...0.8)
            m.add(Prim.superellipsoid(V3(rng.float(0.012...0.03), 0.002, rng.float(0.012...0.03)), exponent: 2, subdivisions: 1, material: "stone.limestone"),
                  Xform(translation: V3(x, surfY(x, z) + 0.0012, z), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        for _ in 0..<5 {                                                      // dark water stains along gore seams
            let x = -W / 2 + Float(rng.int(1...7)) * sw + rng.float(-0.03...0.03), z = rng.float(0.3...0.8)
            m.add(Prim.superellipsoid(V3(0.05, 0.002, rng.float(0.06...0.16)), exponent: 2, subdivisions: 1, material: "stone.limestone-sooted"),
                  Xform(translation: V3(x, surfY(x, z) + 0.0008, z)))
        }
        // Patched tear on a cream gore: a lapped panel with its own stitch rows.
        let px: Float = -W / 2 + 2 * sw + sw / 2, pz: Float = 0.55
        m.add(Prim.superellipsoid(V3(0.13, 0.002, 0.12), exponent: 6, subdivisions: 3, material: "fabric.canvas:D3C8AB"),
              Xform(translation: V3(px, surfY(px, pz) + 0.0012, pz)))
        for dz: Float in [-0.05, 0.05] {
            let path: [V3] = (0...8).map { k in let dx = -0.05 + Float(k) * 0.0125; return V3(px + dx, surfY(px + dx, pz + dz) + 0.0028, pz + dz) }
            m.add(stitches(along: path, normal: { _ in FA.Y }, pitch: 0.012, thread: 0.0008, material: "fabric.canvas:5E5642"))
        }
        // Rust on the iron: bolt weeps and the arm joints.
        for e: Float in [-1, 1] {
            FJ.slab(&m, V3(0.012, 0.09, 0.0012), V3(e * 0.72 + 0.01, 0.66, 0.0072), "metal.rust")
            FJ.slab(&m, V3(0.018, 0.0012, 0.05), V3(e * 0.72, armY(0.52) - 0.012, 0.52), "metal.rust")
        }
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
