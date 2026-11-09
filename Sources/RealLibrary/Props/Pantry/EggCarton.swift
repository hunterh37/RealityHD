import simd
import Foundation

/// Egg carton: dozen-size moulded pulp carton, 29 x 10.5 cm. The tray is one moulded sheet with twelve
/// rounded cups in two rows, five tall separator cones on the centre line, a rolled perimeter rim and outer
/// walls that bulge over each cup. The lid is hinged at the back and stands open past vertical, showing its
/// hollow underside, with a rolled rim, two stiffening ribs and a printed label (invented brand HENLOW) on
/// its top. Ten brown eggs sit in the cups; one empty cup holds a damp stain and a shell shard.
public struct EggCarton: RealAsset {
    public static let id = "egg-carton"
    public static let summary = "Moulded pulp egg carton: 12 cups, separator cones, rolled rims, open hinged lid with printed label, ten eggs, stain."
    public static let tags = ["prop", "interior", "pantry", "paper"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 32, distance: 0.82, studio: true)

    /// Moulded pulp.
    public var pulp: MaterialKey = "pkg.pulp-carton"
    /// Damp stain in the empty cup.
    public var stain: MaterialKey = "pkg.pulp-carton:6E6A5E"
    /// Lid label (brand field tint).
    public var label: MaterialKey = "pkg.carton-matte:2F6E3A"
    /// Lid opening angle in degrees (0 closed).
    public var lidAngle: Float = 108
    public init() {}

    let pitchX: Float = 0.046, pitchZ: Float = 0.05, hx: Float = 0.145, hz: Float = 0.0525
    let yr: Float = 0.046, yb: Float = 0.011, rc: Float = 0.0215

    func cup(_ i: Int, _ j: Int) -> V2 { V2((Float(i) - 2.5) * pitchX, (Float(j) - 0.5) * pitchZ) }

    /// Tray top surface height.
    func trayH(_ x: Float, _ z: Float) -> Float {
        var b: Float = 0
        for i in 0..<6 { for j in 0..<2 {
            let c = cup(i, j), dx = abs(x - c.x) / rc, dz = abs(z - c.y) / rc
            let d = pow(pow(dx, 2.6) + pow(dz, 2.6), 1 / 2.6)
            if d < 1 { b = max(b, pow(1 - d * d, 1.3)) }
        } }
        var h = yr - (yr - yb) * b
        for k in 0..<5 {
            let d = simd_length(V2(x - (Float(k) - 2) * pitchX, z))
            h = max(h, 0.066 - 1.6 * sqrt(d * d + 0.000016))
        }
        // Flange dips slightly toward the rim.
        let e = min(hx - abs(x), hz - abs(z))
        return h - 0.002 * (1 - smoothstep(0, 0.006, e))
    }

    /// Lid outer surface height in the closed frame.
    func lidH(_ x: Float, _ z: Float) -> Float {
        let e = min(hx + 0.002 - abs(x), hz + 0.002 - abs(z))
        let rib = 0.0016 * (exp(-pow((abs(z) - 0.034) / 0.003, 2)) * smoothstep(0.02, 0.03, e))
        return yr + 0.028 * pow(smoothstep(0, 0.016, e), 0.6) + rib
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, hi: true), make(seed: seed, hi: false)], switchDistances: [3])
    }

    func make(seed: UInt64, hi: Bool) -> Model {
        typealias K = GroceryKit
        var rng = SeededRNG(seed: seed &+ 41)
        var m = Model(name: Self.id)
        // Tray sheet.
        m.add(K.sheet(cols: hi ? 66 : 30, rows: hi ? 24 : 10, uSpan: 2 * hx, vSpan: 2 * hz, pulp) { s, t in
            let x = -hx + s * 2 * hx, z = hz - t * 2 * hz
            return V3(x, trayH(x, z), z)
        })
        // Outer walls: front and back bulge over each cup and taper toward the foot.
        let edgeY = yr - 0.002
        for side: Float in [1, -1] {
            m.add(K.sheet(cols: hi ? 48 : 12, rows: 4, uSpan: 2 * hx, vSpan: edgeY, pulp) { s, t in
                let x = side * (-hx + s * 2 * hx), y = t * edgeY
                let bump = 0.5 + 0.5 * cos((x / pitchX - 0.5) * 2 * .pi)
                let z = hz - 0.007 * (1 - t) - 0.0035 * (1 - bump) * (1 - 0.6 * t)
                return V3(x, y, side * z)
            })
            m.add(K.sheet(cols: hi ? 12 : 4, rows: 4, uSpan: 2 * hz, vSpan: edgeY, pulp) { s, t in
                let z = side * (hz - s * 2 * hz), y = t * edgeY
                let bump = 0.5 + 0.5 * cos((z / pitchZ - 0.5) * 2 * .pi)
                return V3(side * (hx - 0.007 * (1 - t) - 0.003 * (1 - bump) * (1 - 0.6 * t)), y, z)
            })
        }
        // Rolled rim around the tray.
        let rimPath = Shape2D.roundedRect(2 * hx, 2 * hz, radius: 0.006, segments: hi ? 4 : 2).map { V3($0.x, edgeY, -$0.y) }
        m.add(Prim.sweep(Shape2D.circle(0.0016, segments: hi ? 8 : 4), along: rimPath, closedPath: true, material: pulp))
        // Latch nubs on the front rim.
        for x: Float in [-0.06, 0.06] {
            m.add(Prim.superellipsoid(V3(0.014, 0.008, 0.006), exponent: 2.6, subdivisions: hi ? 4 : 2, material: pulp), Xform(translation: V3(x, edgeY + 0.001, hz + 0.001)))
        }
        // Lid, built closed relative to the hinge line and swung open.
        let hinge = V3(0, edgeY, -hz - 0.002)
        var lid = Model(name: "lid")
        let lc = hi ? 36 : 16, lr = hi ? 14 : 6
        lid.add(K.sheet(cols: lc, rows: lr, uSpan: 2 * hx, vSpan: 2 * hz, pulp) { s, t in
            let x = -hx - 0.002 + s * (2 * hx + 0.004), z = hz + 0.002 - t * (2 * hz + 0.004)
            return V3(x, lidH(x, z), z) - hinge
        })
        lid.add(K.sheet(cols: lc, rows: lr, uSpan: 2 * hx, vSpan: 2 * hz, pulp) { s, t in
            let x = hx + 0.002 - s * (2 * hx + 0.004), z = hz + 0.002 - t * (2 * hz + 0.004)
            return V3(x * 0.985, lidH(x, z) - 0.0025, z * 0.96) - hinge
        })
        let lidRim = Shape2D.roundedRect(2 * hx + 0.004, 2 * hz + 0.004, radius: 0.007, segments: hi ? 4 : 2).map { V3($0.x, edgeY + 0.0008, -$0.y) - hinge }
        lid.add(Prim.sweep(Shape2D.circle(0.0018, segments: hi ? 8 : 4), along: lidRim, closedPath: true, material: pulp))
        // Printed label on the lid top: carton-matte design rows 0.6...1 on 0.15 x 0.054 m.
        let lw: Float = 0.15, lh: Float = 0.054, top = yr + 0.028 + 0.0004
        lid.add(K.sheet(cols: 2, rows: 2, uSpan: 0.15, vSpan: -0.088, v0: 0.088, label) { s, t in
            V3(-lw / 2 + s * lw, top, lh / 2 - t * lh) - hinge
        })
        if hi {
            K.printSmooth(&lid, "HENLOW", height: 0.011, at: V3(-lw / 2 + 0.7 * lw, top + 0.0004, lh / 2 - 0.5 * lh) - hinge, "paper.sheet:FFFFFF",
                          rot: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0)), maxWidth: 0.06, weight: 1.3)
            K.printSmooth(&lid, "12 LARGE EGGS", height: 0.006, at: V3(-lw / 2 + 0.7 * lw, top + 0.0004, lh / 2 - 0.16 * lh) - hinge, "paper.sheet:FFFFFF",
                          rot: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0)), maxWidth: 0.06, weight: 1.1)
        }
        m.add(lid, Xform(translation: hinge, rotation: simd_quatf(angle: -lidAngle * .pi / 180, axis: V3(1, 0, 0))))
        // Folded hinge.
        m.add(Prim.tube([V3(-hx, edgeY - 0.0005, -hz - 0.002), V3(hx, edgeY - 0.0005, -hz - 0.002)], radii: [0.0022, 0.0022], sides: hi ? 8 : 4, seamTile: 0.02, material: pulp))
        // Eggs: ten in the cups, front cup 2 and back cup 5 empty.
        for i in 0..<6 { for j in 0..<2 {
            let c = cup(i, j)
            if (i == 1 && j == 1) || (i == 4 && j == 0) { continue }
            let shade = rng.float(0.9...1.06)
            let col = GroceryKit.shade(0xB48A66, shade)
            let egg = Prim.superellipsoid(V3(0.0435, 0.0565, 0.0435), exponent: 2, subdivisions: hi ? 4 : 2, material: GroceryKit.tint("paper.sheet", col)) { d in 1 - 0.07 * d.y }
            let tilt = simd_quatf(angle: rng.float(-0.12...0.12), axis: V3(1, 0, 0)) * simd_quatf(angle: rng.float(-0.12...0.12), axis: V3(0, 0, 1))
            m.add(egg, Xform(translation: V3(c.x, yb + 0.0365, c.y), rotation: tilt))
        } }
        if hi {
            // Damp stain and a shell shard in the empty front cup.
            let c = cup(1, 1)
            m.add(K.sheet(cols: 12, rows: 12, uSpan: 0.03, vSpan: 0.03, stain) { s, t in
                let x = c.x - 0.014 + s * 0.028, z = c.y + 0.014 - t * 0.028
                return V3(x, trayH(x, z) + 0.0004, z)
            })
            m.add(Prim.superellipsoid(V3(0.013, 0.0016, 0.009), exponent: 2.2, subdivisions: 3, material: "paper.sheet:EFE6D6") { d in 1 + 0.25 * d.x * d.x },
                  Xform(translation: V3(c.x + 0.003, yb + 0.006, c.y - 0.002), rotation: simd_quatf(angle: 0.5, axis: V3(0, 0, 1)) * simd_quatf(angle: 0.7, axis: .up)))
            // Inkjet date stamp on the front wall.
            K.printSmooth(&m, "BEST BY 11 30", height: 0.0045, at: V3(0.07, 0.022, hz - 0.0035), "paper.sheet:4A3A7A", maxWidth: 0.05, weight: 0.85)
        }
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }
}
