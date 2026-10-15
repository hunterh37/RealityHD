import simd
import Foundation

/// Pueblo Revival vigas, 2.4 m: six peeled pine beams of varied diameter projecting through a battered adobe
/// plaster wall with soft rounded edges, plaster mounds ringed round each beam, weathered endgrain with radial
/// checks, a rounded parapet cap and a wooden canale water spout. Straw-flecked plaster, hairline cracks, chipped
/// patches showing the adobe brick and rain-wash stains below each beam end carry the wear.
public struct PuebloVigasBeamEnds: RealAsset {
    public static let id = "pueblo-vigas-beam-ends"
    public static let summary = "Pueblo Revival vigas, 2.4 m: six peeled round beam ends of varied diameter through a rounded adobe parapet band, with canale."
    public static let tags = ["prop", "architecture", "facade", "trim", "decor", "wood"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 1.6)

    /// Overall width in meters.
    public var width: Float = 2.4
    /// Adobe plaster.
    public var plaster: MaterialKey = "paint.stucco:C69C6D"
    /// Peeled pine pole.
    public var pole: MaterialKey = "wood.lumber-cedar"
    /// Weathered endgrain.
    public var endgrain: MaterialKey = "wood.endgrain-weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wallZ0: Float = -0.135, wallZ1: Float = 0.04, wallH: Float = 0.225
        let wd = wallZ1 - wallZ0, wc = (wallZ0 + wallZ1) / 2

        // Thin decals (stains, flecks, cracks) are sharp-edged slabs: 12 triangles each.
        func flat(_ size: V3, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity) {
            m.add(cuboid(size, material: mat), Xform(translation: c, rotation: rot))
        }
        // Battered adobe wall: front face leans back 3 degrees at the top; corners softened by hand-troweling.
        let prof = Shape2D.rounded([V2(-width / 2, 0), V2(width / 2, 0), V2(width / 2 - 0.012, wallH), V2(-width / 2 + 0.012, wallH)], radius: 0.022)
        m.add(Prim.extrude(Shape2D.deduped(prof), depth: wd, bevel: 0.014, bevelSegments: 2, material: plaster), Xform(translation: V3(0, 0, wc)))
        // Rounded parapet cap: a soft plaster roll along the top, slightly proud of the wall face.
        let roll = Shape2D.rounded([V2(wallZ0 - 0.006, wallH - 0.018), V2(wallZ1 + 0.01, wallH - 0.018), V2(wallZ1 + 0.01, wallH + 0.075), V2(wallZ0 - 0.006, wallH + 0.075)], radius: 0.04)
        FA.run(&m, Shape2D.deduped(roll), length: width - 0.01, plaster, bevel: 0.004)
        // Raised corner bosses on the parapet, the stepped soft corners that mark Pueblo Revival rooflines.
        for e: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.2, 0.04, wd - 0.01), exponent: 3, subdivisions: 8, material: plaster),
                  Xform(translation: V3(e * (width / 2 - 0.11), wallH + 0.055, wc)))
        }
        // Stepped plaster foot where the wall meets the ground.
        FA.box(&m, V3(width, 0.03, wd + 0.02), V3(0, 0.015, wc + 0.005), plaster, r: 0.012)

        // Vigas: six peeled poles, varied diameter and projection, slight tilt and offset like hand-set timber.
        let diam: [Float] = [0.13, 0.15, 0.118, 0.158, 0.136, 0.146]
        let faceZ = wallZ1
        var xs: [Float] = []
        for i in 0..<6 { xs.append(-width / 2 + 0.22 + Float(i) * (width - 0.44) / 5 + rng.float(-0.02...0.02)) }
        for i in 0..<6 {
            var r = rng.fork(i)
            let rad = diam[i] / 2, x = xs[i], y = 0.122 + r.float(-0.01...0.01)
            let proj = r.float(0.19...0.222), tip = faceZ + proj
            let tilt = r.float(-1.2...1.2), twist = r.float(-1.5...1.5)
            let z0 = wallZ0 + 0.03, len = tip - 0.012 - z0
            let lp: [V2] = [V2(rad * 1.0, 0), V2(rad * 1.04, len * 0.55), V2(rad * 1.0, len * 0.8), V2(rad * 0.975, len)]
            m.add(Prim.lathe(lp, segments: 20, seamTile: 0.2, material: pole, swapUV: true),
                  Xform(translation: V3(x, y, z0), rotation: FA.q(90, FA.X) * FA.q(tilt * 0.4, FA.Z)))
            // Weathered endgrain disc with a rounded arris.
            let cx = x + tilt * 0.0016, cy = y + twist * 0.0012
            FA.cylZ(&m, r: rad * 0.975, h: 0.014, at: V3(cx, cy, tip - 0.013), endgrain, bevel: 0.0035, segments: 24)
            // Radial checks and heart ring on the end face.
            let fzEnd = tip + 0.0012
            for k in 0..<(2 + r.int(0...2)) {
                let a = r.float(0...360), len = rad * r.float(0.4...0.85)
                let c = V3(cx + cos(a * .pi / 180) * len / 2, cy + sin(a * .pi / 180) * len / 2, fzEnd)
                flat(V3(len, 0.0035, 0.0014), c, "wood.deadwood", rot: FA.q(a, FA.Z))
            }
            m.add(Prim.torus(major: rad * 0.42, minor: 0.0016, segments: 16, sides: 4, material: "wood.deadwood"),
                  Xform(translation: V3(cx, cy, fzEnd + 0.0006), rotation: FA.q(90, FA.X)))
            // Plaster mound: a thick trowelled collar round the beam where it enters the wall.
            m.add(Prim.torus(major: rad + 0.012, minor: 0.017, segments: 20, sides: 6, material: plaster),
                  Xform(translation: V3(x, y, faceZ + 0.002), rotation: FA.q(90, FA.X)))
            // Gap shadow between pole and plaster, and silver weathering on the upper side of the pole.
            m.add(Prim.torus(major: rad + 0.001, minor: 0.0028, segments: 16, sides: 4, material: "wood.deadwood"),
                  Xform(translation: V3(x, y, faceZ + 0.014), rotation: FA.q(90, FA.X)))
            FA.box(&m, V3(rad * 1.2, 0.004, proj * 0.7), V3(x, y + rad * 0.975, faceZ + proj * 0.5), "wood.deadwood", r: 0.001, rot: FA.q(-tilt * 0.1, FA.X))
            // Knots where branches were trimmed: dark domes on the pole.
            for _ in 0..<2 {
                let a = r.float(30...150) * .pi / 180, kz = faceZ + r.float(0.05...proj - 0.05)
                m.add(Prim.superellipsoid(V3(0.016, 0.016, 0.008), exponent: 2, subdivisions: 2, material: "wood.deadwood"),
                      Xform(translation: V3(x + cos(a) * rad * 0.995, y + sin(a) * rad * 0.995, kz), rotation: FA.q(a * 180 / .pi - 90, FA.Z)))
            }
            // Peeled drawknife scars: shallow pale flats along the pole.
            for _ in 0..<2 {
                let a = r.float(20...160) * .pi / 180
                FA.box(&m, V3(0.006, 0.0025, r.float(0.04...0.08)), V3(x + cos(a) * rad * 0.99, y + sin(a) * rad * 0.99, faceZ + r.float(0.03...0.1)),
                       "wood.endgrain-fresh", r: 0.0006, rot: FA.q(a * 180 / .pi - 90, FA.Z))
            }
            // Rain-wash and rust-brown tannin stain below the beam on the plaster.
            flat(V3(rad * r.float(1.1...1.5), r.float(0.05...0.07), 0.0012), V3(x + r.float(-0.01...0.01), max(0.05, y - rad - 0.03), faceZ + 0.0004), "paint.stucco:9A7550")
        }

        // Cliff swallow nest: a mud cup stuck to the wall under the parapet with a dark entrance and droppings below.
        let nx = (xs[0] + xs[1]) / 2, ny: Float = 0.2
        m.add(Prim.superellipsoid(V3(0.085, 0.06, 0.08), exponent: 2, subdivisions: 6, material: "paint.stucco:6E5238"), Xform(translation: V3(nx, ny, faceZ + 0.012)))
        m.add(Prim.cylinder(radius: 0.014, height: 0.003, bevel: 0.0008, segments: 8, bevelSegments: 1, material: "paint.stucco:1E1710"),
              Xform(translation: V3(nx, ny + 0.006, faceZ + 0.0525), rotation: FA.q(90, FA.X)))
        flat(V3(0.03, 0.1, 0.0014), V3(nx + 0.005, ny - 0.095, faceZ + 0.0015), "paint.stucco:E4DCC8")
        // Canale: a wooden spout running through the parapet between the 4th and 5th beam.
        let cx = (xs[3] + xs[4]) / 2, cy: Float = 0.215
        let cz0 = wallZ0 + 0.05, cz1 = faceZ + 0.19
        FA.box(&m, V3(0.1, 0.014, cz1 - cz0), V3(cx, cy - 0.027, (cz0 + cz1) / 2), "metal.galvanized-aged", r: 0.003)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.014, 0.05, cz1 - cz0), V3(cx + s * 0.043, cy - 0.003, (cz0 + cz1) / 2), "metal.galvanized-aged", r: 0.003)
        }
        // Cut end of the canale boards and nail heads in the sides.
        for s: Float in [-1, 1] {
            for z in [faceZ + 0.05, faceZ + 0.14] {
                m.add(Prim.superellipsoid(V3(0.007, 0.007, 0.004), exponent: 2, subdivisions: 2, material: "metal.cast-iron"),
                      Xform(translation: V3(cx + s * 0.0505, cy - 0.003, z)))
            }
        }
        // Plaster collar and a dark water stain below the canale.
        FA.box(&m, V3(0.17, 0.085, 0.01), V3(cx, cy - 0.006, faceZ + 0.0015), plaster, r: 0.004)
        flat(V3(0.07, 0.15, 0.0014), V3(cx, cy - 0.12, faceZ + 0.0022), "paint.stucco:7A5C3E")
        flat(V3(0.11, 0.05, 0.0014), V3(cx, cy - 0.185, faceZ + 0.0016), "paint.stucco:A57F57")

        // Plaster wear: straw-flecked mud wash, hairline cracks, chipped patches exposing adobe brick.
        for _ in 0..<26 {
            let x = rng.float(-width / 2 + 0.04...width / 2 - 0.04), y = rng.float(0.04...wallH - 0.02)
            flat(V3(rng.float(0.006...0.02), 0.0016, 0.0012), V3(x, y, faceZ + 0.0007), "paint.stucco:E3C79A", rot: FA.q(rng.float(0...180), FA.Z))
        }
        for (x, y, len, ang): (Float, Float, Float, Float) in [(-0.82, 0.08, 0.1, 70), (0.1, 0.19, 0.12, 20), (0.95, 0.1, 0.09, -65), (-0.3, 0.05, 0.08, 100)] {
            flat(V3(0.0026, len, 0.0012), V3(x, y, faceZ + 0.0008), "paint.stucco:5A4330", rot: FA.q(ang - 90, FA.Z))
        }
        // Spalled plaster: scratch coat edge, then the adobe brick core with a mortar line between two courses.
        for (x, y, w, h): (Float, Float, Float, Float) in [(-1.0, 0.06, 0.22, 0.1), (0.66, 0.055, 0.17, 0.08), (0.98, 0.17, 0.12, 0.06), (-0.45, 0.17, 0.1, 0.05)] {
            flat(V3(w + 0.02, h + 0.02, 0.003), V3(x, y, faceZ + 0.0009), "paint.stucco:B58A5B")
            flat(V3(w, h, 0.0042), V3(x, y, faceZ + 0.0015), "paint.stucco:7E5A3A")
            flat(V3(w - 0.01, 0.004, 0.0052), V3(x, y, faceZ + 0.0017), "paint.stucco:C8AA80")
            FA.box(&m, V3(w * 0.42, h * 0.42, 0.006), V3(x - w * 0.22, y + h * 0.18, faceZ + 0.0022), "brick.common", r: 0.002)
            FA.box(&m, V3(w * 0.38, h * 0.42, 0.006), V3(x + w * 0.2, y - h * 0.2, faceZ + 0.0022), "brick.common", r: 0.002)
        }
        // Long rain runs from the parapet roll down the wall face.
        for _ in 0..<9 {
            let x = rng.float(-width / 2 + 0.06...width / 2 - 0.06), h = rng.float(0.1...0.2)
            flat(V3(rng.float(0.012...0.04), h, 0.0014), V3(x, wallH - h / 2, faceZ + 0.0013), "paint.stucco:9C7550")
        }
        // Mud-wash tonal patches: soft ellipses of lighter and darker adobe slip across the wall face.
        for i in 0..<18 {
            let x = rng.float(-width / 2 + 0.1...width / 2 - 0.1), y = rng.float(0.05...wallH - 0.03)
            let light = i % 2 == 0
            m.add(Prim.cylinder(radius: 0.05, height: 0.0012, bevel: 0.0003, segments: 8, bevelSegments: 1, material: light ? "paint.stucco:D4A97B" : "paint.stucco:B78A5C"),
                  Xform(translation: V3(x, y, faceZ + 0.0005), rotation: FA.q(90, FA.X), scale: V3(rng.float(0.9...2.0), 1, rng.float(0.5...1.0))))
        }
        // Back of the wall: tonal streaks, a vertical crack and spalled patches.
        let bz = wallZ0 - 0.0005
        for _ in 0..<10 {
            let x = rng.float(-width / 2 + 0.05...width / 2 - 0.05), h = rng.float(0.05...0.14)
            flat(V3(rng.float(0.01...0.04), h, 0.0012), V3(x, wallH - h / 2 - 0.01, bz), "paint.stucco:A98055")
        }
        flat(V3(0.003, 0.15, 0.0012), V3(0.5, 0.12, bz), "paint.stucco:5A4330", rot: FA.q(10, FA.Z))
        flat(V3(0.12, 0.06, 0.0025), V3(-0.7, 0.07, bz), "paint.stucco:8B6542")
        // Whitewash lime bloom and soil splash at the foot.
        flat(V3(width - 0.04, 0.035, 0.0014), V3(0, 0.05, faceZ + 0.0022), "paint.stucco:8E6B47")
        for _ in 0..<6 {
            flat(V3(rng.float(0.03...0.08), rng.float(0.02...0.04), 0.0012), V3(rng.float(-1.1...1.1), rng.float(0.15...0.2), faceZ + 0.0012), "paint.stucco:D6BD93")
        }
        // Parapet cap: soot line and bird stain on the roll.
        for _ in 0..<4 {
            m.add(Prim.cylinder(radius: rng.float(0.012...0.025), height: 0.0016, bevel: 0.0005, segments: 6, bevelSegments: 1, material: "paint.stucco:E8E2D0"),
                  Xform(translation: V3(rng.float(-1.1...1.1), wallH + 0.0765, wc + rng.float(-0.05...0.0))))
        }
        groundAO(&m, height: 0.08, floor: 0.8)
        // Beams stand proud of the wall in open light: keep only light AO on the poles so the wood tone reads.
        for i in m.surfaces.indices where m.surfaces[i].material == pole {
            m.surfaces[i].occlusion = m.surfaces[i].occlusion.map { 0.55 + 0.45 * $0 }
        }
        return LODModel(FA.centerZ(m))
    }
}
