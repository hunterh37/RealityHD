import simd
import Foundation

/// Mediterranean stucco wall niche, 0.8 x 1.4 m: thick round-arched plaster reveal with a moulded
/// archivolt, keystone, scallop-shell conch hood, limestone sill ledge and a terracotta amphora standing in it.
/// Wall face at z = 0.25, the recess runs back toward -Z.
public struct StuccoArchedNiche: RealAsset {
    public static let id = "stucco-arched-niche"
    public static let summary = "Mediterranean stucco niche, 0.8 x 1.4 m: arched plaster reveal, archivolt, shell conch, limestone sill, terracotta amphora."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 2.0)

    /// Plaster finish of the wall and reveal.
    public var plaster: MaterialKey = "paint.stucco:E4D2B0"
    /// Older plaster on the exposed mouldings.
    public var plasterAged: MaterialKey = "paint.stucco:CDB88F"
    /// Limestone sill.
    public var sill: MaterialKey = "stone.limestone"
    /// Terracotta amphora.
    public var clay: MaterialKey = "ceramic.terracotta"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.8, D: Float = 0.205
        let openW: Float = 0.5, spring: Float = 0.95
        let hw = openW / 2
        let jambW = (W - openW) / 2
        // Wall block with the opening: left and right piers, lintel segment above the arch drawn as the arch ring.
        let top = FC.archRise(width: openW, spring: spring, pointed: false)   // apex of the opening
        let wallTop: Float = 1.33
        // Piers beside the opening, full height to the spring line, then spandrels follow the arch.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(jambW, spring, D), V3(s * (hw + jambW / 2), spring / 2, D / 2), plaster, r: 0.004)
        }
        // Spandrel and head block built as an extrusion with the arch cut as outline of a U (outer rect minus arch):
        // approximated by two corner blocks with an arched inner edge.
        for s: Float in [-1, 1] {
            var o: [V2] = [V2(s * hw, spring)]
            let steps = 12
            for i in 0...steps {
                let a = Float(i) / Float(steps) * (.pi / 2)
                o.append(V2(s * hw * cos(a), spring + hw * sin(a)))
            }
            o.append(V2(s * (hw + jambW), wallTop))
            o.append(V2(s * (hw + jambW), spring))
            // Remove duplicate/degenerate points and ensure the polygon is a clean quad-fan.
            let outline: [V2] = [V2(s * hw, spring), V2(s * (hw + jambW), spring), V2(s * (hw + jambW), wallTop),
                                 V2(0, wallTop)] + (0...steps).reversed().map { i in
                let a = Float(i) / Float(steps) * (.pi / 2)
                return V2(s * hw * cos(a), spring + hw * sin(a))
            }
            _ = o
            let clean = Shape2D.deduped(outline)
            FM.prism(&m, clean, front: D, depth: D, plaster, bevel: 0.007)
        }
        // Back wall of the niche with its own arched outline, set 0.19 m behind the face.
        let back = FC.archOutline(width: openW - 0.004, spring: spring, pointed: false, steps: 16)
        m.add(Prim.extrude(back, depth: 0.02, bevel: 0.002, bevelSegments: 1, material: plasterAged), Xform(translation: V3(0, 0, 0.03)))
        // Moulded archivolt: sweep a stepped profile along the arch path on the face.
        let pathR = FC.archPath(width: openW + 0.07, spring: spring, pointed: false, z: D, steps: 16)
        let arcOnly = Array(pathR[0..<(pathR.count - 1)])
        let prof: [V2] = [V2(-0.035, 0), V2(0.035, 0), V2(0.035, 0.012), V2(0.025, 0.012), V2(0.025, 0.022),
                          V2(0.015, 0.022), V2(0.015, 0.03), V2(-0.01, 0.03), V2(-0.01, 0.02), V2(-0.035, 0.014)]
        m.add(Prim.sweep(prof.map { V2($0.y, $0.x) }, along: arcOnly, up: FA.Z, caps: true, material: plasterAged))
        // Jamb mouldings continue down each side as a flat architrave with a bead.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.07, spring - 0.1, 0.018), V3(s * (hw + 0.035), 0.1 + (spring - 0.1) / 2, D + 0.009), plasterAged, r: 0.003)
            FA.box(&m, V3(0.016, spring - 0.1, 0.012), V3(s * (hw + 0.058), 0.1 + (spring - 0.1) / 2, D + 0.024), plaster, r: 0.005)
        }
        // Keystone block breaking the moulding at the crown.
        FA.box(&m, V3(0.1, 0.1, 0.04), V3(0, top + 0.02, D + 0.014), plasterAged, r: 0.004)
        FA.box(&m, V3(0.075, 0.016, 0.012), V3(0, top + 0.07, D + 0.027), plaster, r: 0.003)
        // Scallop shell conch filling the head: 13 fluted ribs fanning from the spring-line centre, ringed by a scalloped edge.
        let cy = spring + 0.02
        let ribN = 13
        for i in 0..<ribN {
            let a = Float.pi * (Float(i) + 0.5) / Float(ribN)
            let rr = hw - 0.016
            let c = V3(cos(a) * rr * 0.5, cy + sin(a) * rr * 0.5, 0.05)
            FA.box(&m, V3(rr, 0.017, 0.034), c, i % 2 == 0 ? plaster : plasterAged, r: 0.006, rot: FA.q(a * 180 / .pi, FA.Z))
            // Scallop bulge at the rim of each rib.
            FC.bead(&m, r: 0.016, at: V3(cos(a) * (hw - 0.026), cy + sin(a) * (hw - 0.026), 0.058), plaster, sub: 4)
        }
        var rim: [V3] = []
        for i in 0...20 {
            let a = Float(i) / 20 * .pi
            rim.append(V3(cos(a) * (hw - 0.012), cy + sin(a) * (hw - 0.012), 0.05))
        }
        FA.path(&m, rim, r: 0.008, plaster, sides: 6)
        // Limestone sill/shelf inside the niche, projecting past the reveal with a rounded nosing.
        FA.box(&m, V3(openW + 0.08, 0.05, 0.13), V3(0, 0.275, D - 0.03), sill, r: 0.007)
        FA.box(&m, V3(openW + 0.12, 0.04, 0.05), V3(0, 0.23, D + 0.005), sill, r: 0.005)
        // Plinth base course under the wall piers.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(jambW, 0.22, D), V3(s * (hw + jambW / 2), 0.11, D / 2), plasterAged, r: 0.004)
        }
        FA.box(&m, V3(openW, 0.2, 0.14), V3(0, 0.1, 0.07), plaster, r: 0.003)
        // Terracotta amphora on the shelf: turned body, neck, rolled lip, two strap handles, a chipped lip.
        let ax: Float = 0.02, ay: Float = 0.3
        m.add(turned([(0.0, 0), (0.04, 0.0), (0.075, 0.02), (0.11, 0.1), (0.12, 0.18), (0.1, 0.27), (0.055, 0.34), (0.04, 0.4),
                      (0.052, 0.42), (0.056, 0.435), (0.045, 0.44), (0.032, 0.43), (0.0, 0.43)], segments: 28, material: clay, seamTile: 0.2),
              Xform(translation: V3(ax, ay, 0.1), scale: V3(repeating: 0.62)))
        for s: Float in [-1, 1] {
            var hp: [V3] = []
            for k in 0...8 {
                let t = Float(k) / 8
                hp.append(V3(ax + s * (0.0285 + 0.031 * sin(t * .pi)), ay + 0.248 - t * 0.074, 0.1))
            }
            m.add(Prim.tube(hp, radii: Array(repeating: 0.005, count: hp.count), sides: 7, seamTile: 0.1, material: clay, capEnd: true))
        }
        FC.bead(&m, r: 0.004, at: V3(ax + 0.025, ay + 0.272, 0.1 + rng.float(0.006...0.012)), plasterAged, sub: 2)
        // Plaster damage: a cracked patch of exposed brick-red ground under the left archivolt.
        FA.box(&m, V3(0.06, 0.1, 0.0022), V3(-hw - 0.06, 0.55, D + 0.0012), "brick.unit-red-light", r: 0.001)
        // Wear: hairline cracks radiating from the keystone and sill, spalled plaster showing brick, a newer patch, sill algae.
        var wr = rng.fork(21)
        for _ in 0..<9 {
            let x = wr.float(-0.35...0.35), y = wr.float(0.3...1.35)
            if abs(x) < hw + 0.01 && y > 0.2 && y < spring + 0.3 { continue }
            let len = wr.float(0.06...0.2)
            FA.box(&m, V3(0.0018, len, 0.0016), V3(x, y, D + 0.0008), "paint.stucco:6E5E45", r: 0.0003, rot: FA.q(wr.float(-25...25), FA.Z))
        }
        // Spalled plaster: irregular blobs showing sooty brick, ringed by a darker feather edge.
        func blob(_ cx: Float, _ cy: Float, _ rx: Float, _ ry: Float, _ mat: MaterialKey, _ z: Float, _ depth: Float) {
            var pts: [V2] = []
            for k in 0..<9 {
                let a = Float(k) / 9 * 2 * .pi
                let j = wr.float(0.65...1.15)
                pts.append(V2(cx + cos(a) * rx * j, cy + sin(a) * ry * j))
            }
            m.add(Prim.extrude(Shape2D.deduped(pts), depth: depth, bevel: 0.0006, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, z)))
        }
        for (px, py, pw, ph) in [(Float(-0.345), Float(0.58), Float(0.032), Float(0.045)), (Float(0.35), Float(1.12), Float(0.028), Float(0.035)), (Float(-0.335), Float(1.22), Float(0.022), Float(0.026))] {
            blob(px, py, pw * 1.5, ph * 1.4, plasterAged, D + 0.0008, 0.0016)
            blob(px, py, pw, ph, "brick.unit-sooted", D + 0.0018, 0.0014)
        }
        blob(0.335, 0.5, 0.055, 0.14, "paint.stucco:EADAB8", D + 0.0015, 0.003)
        FA.box(&m, V3(0.5, 0.01, 0.1), V3(0, 0.302, D - 0.03), "moss.cushion", r: 0.002)
        blob(-0.1, 1.28, 0.16, 0.035, "paint.stucco:B4A584", D + 0.0008, 0.0012)
        // Terracotta barrel-tile coping on a limestone drip slab, tiles slightly out of line with a cracked end.
        FA.box(&m, V3(W - 0.008, 0.03, D + 0.03), V3(0, wallTop + 0.015, D / 2 + 0.005), sill, r: 0.004)
        for k in 0..<10 {
            let x = -W / 2 + 0.04 + Float(k) * (W - 0.08) / 9
            let jt = wr.float(-0.0015...0.0015)
            FA.cylZ(&m, r: 0.04, h: D + 0.03, at: V3(x + jt, wallTop + 0.03, -0.005), k % 4 == 1 ? "ceramic.bisque" : clay, bevel: 0.002, segments: 14)
        }
        // Soot drips below the coping, rising damp on the plinth, and meandering cracks.
        for k in 0..<8 {
            let x = -W / 2 + 0.06 + Float(k) * (W - 0.12) / 7 + wr.float(-0.02...0.02)
            blob(x, wallTop - wr.float(0.05...0.14), wr.float(0.012...0.03), wr.float(0.05...0.12), "paint.stucco:A39573", D + 0.0007, 0.0011)
        }
        for s: Float in [-1, 1] {
            blob(s * (hw + jambW / 2), 0.2, jambW * 0.46, 0.17, "paint.stucco:A89A78", D + 0.0105, 0.001)
        }
        func crack(_ x0: Float, _ y0: Float, _ dir: Float) {
            var p = V3(x0, y0, D + 0.0012)
            for _ in 0..<7 {
                let q = p + V3(wr.float(-0.02...0.02) + dir * 0.012, -wr.float(0.025...0.06), 0)
                FA.rod(&m, p, q, r: 0.0011, "paint.stucco:5B4C36", sides: 4)
                p = q
            }
        }
        crack(0.17, spring + 0.38, 1)
        crack(-0.3, 1.15, -1)
        crack(0.3, 0.95, 1)
        groundAO(&m, height: 0.25, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
