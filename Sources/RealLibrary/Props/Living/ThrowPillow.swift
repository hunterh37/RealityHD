import simd
import Foundation

/// Throw pillow: mustard linen square pillow with contrast piping, lightly used. Parts: plump square cushion body, piped seam welt around the edge, pinched corners, center dimple with button, linen weave cover.
public struct ThrowPillow: RealAsset {
    public static let id = "throw-pillow"
    public static let summary = "Square throw pillow, 46 cm: plump linen cover, contrast piped seam, pinched corners and a tufted center button."
    public static let tags = ["prop", "floorplan", "living", "decor", "fabric", "interior"]
    public static let budget = 4800
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.46, 0.16, 0.46)
    /// Cover fabric (tinted linen).
    public var cover: MaterialKey = "fabric.linen:C8942E"
    /// Piping fabric.
    public var piping: MaterialKey = "fabric.linen:2F3B52"
    /// Center button fabric.
    public var button: MaterialKey = "fabric.linen:2F3B52"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hy = size.y * 0.575, hz = size.z / 2
        let ph1 = rng.float(0...6.28), ph2 = rng.float(0...6.28)
        var body = Prim.superellipsoid(V3(size.x, size.y * 1.15, size.z), exponent: 4.5, subdivisions: 15, material: cover)
        body.deform { p in
            let u = p.x / hx, w = p.z / hz
            let c = pow(abs(u) * abs(w), 1.2)
            var y = p.y * (1 - 0.5 * c)
            let r2 = p.x * p.x + p.z * p.z
            let up: Float = p.y > 0 ? 1 : 0
            y -= up * 0.028 * exp(-r2 / 0.0045) * (p.y / hy)
            // Radial creases pulled toward the button and stuffing lumps.
            let ang = atan2(p.z, p.x), rr = sqrt(r2)
            y += up * 0.0035 * sin(ang * 7 + ph1) * exp(-rr / 0.09) * (p.y / hy)
            y += (p.y / hy) * 0.006 * sin(p.x * 17 + ph2) * sin(p.z * 13 + ph1)
            // Bottom settles flat on the surface.
            if y < -hy * 0.55 { y = -hy * 0.55 + (y + hy * 0.55) * 0.35 }
            // Corners pull in slightly.
            let k = (1 - 0.07 * c) * (1 - 0.12 * pow(abs(p.y) / hy, 1.0))
            return V3(p.x * k, y, p.z * k)
        }
        // Planar UVs by dominant normal axis so the weave runs straight across the cover.
        body.uvs = zip(body.positions, body.normals).map { p, n in
            let ax = abs(n.x), ay = abs(n.y), az = abs(n.z)
            if ay >= ax && ay >= az { return V2(p.x, p.z) }
            return ax > az ? V2(p.z, p.y) : V2(p.x, p.y)
        }
        body.computeTangents()
        m.add(body, Xform(translation: V3(0, hy, 0)))
        // Piped seam welt around the equator.
        let outline = Shape2D.superellipse(size.x, size.z, exponent: 4.5, segments: 56)
        let path = outline.map { o -> V3 in
            let c = pow(abs(o.x / hx) * abs(o.y / hz), 1.2), k = (1 - 0.07 * c) * 0.99
            return V3(o.x * k, hy, o.y * k)
        }
        m.add(Prim.sweep(Shape2D.circle(0.0052, segments: 8), along: path, up: .up, closedPath: true, caps: false, material: piping))
        // Care label sewn into the seam, hanging slightly askew.
        m.add(Prim.roundedBox(V3(0.034, 0.026, 0.0022), radius: 0.0007, bevelSegments: 1, material: "fabric.canvas:EFEAE0"),
              Xform(translation: V3(0.09, hy - 0.016, hz * 0.995 + 0.0015), rotation: simd_quatf(degrees: 8, axis: V3(0, 0, 1)) * simd_quatf(degrees: -12, axis: V3(1, 0, 0))))
        // Center button in the dimple.
        let topY = size.y - 0.028 + 0.0005
        m.add(Prim.lathe([V2(0, 0), V2(0.011, 0.0), V2(0.0125, 0.004), V2(0.009, 0.0085), V2(0, 0.0095)], segments: 16, seamTile: 0.05, material: button),
              Xform(translation: V3(0, topY - 0.0045, 0)))
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.03, floor: 0.6)
        return LODModel(m)
    }
}
