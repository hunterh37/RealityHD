import simd
import Foundation

/// Wafer display stand, 0.4 x 0.5 x 0.2 m: polished chrome weighted base with brushed engraved plaque and rubber feet,
/// two chrome posts clamping a clear acrylic cradle (back plate and grooved front ring) that holds a 300 mm patterned
/// wafer disc tilted back 12 degrees, with a 26 x 33 mm iridescent die grid, edge-exclusion ring and a flat marker.
/// Parts: chrome round base, chrome stem, acrylic cradle, wafer disc, die grid, wafer edge, engraved plaque, rubber feet.
public struct WaferDisplayStand: RealAsset {
    public static let id = "wafer-display-stand"
    public static let summary = "Chrome base and clear acrylic cradle holding a 300 mm patterned wafer with iridescent die grid and an engraved plaque."
    public static let tags = ["prop", "chiplab"]
    public static let budget = 8500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.1, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.4, 0.5, 0.2)
    /// Wafer diameter (m) and thickness (m).
    public var waferDiameter: Float = 0.3
    public var waferThickness: Float = 0.0021
    /// Die pitch (m): 26 x 33 mm reticle field.
    public var diePitch = V2(0.026, 0.033)
    /// Backward tilt of the wafer plane in degrees.
    public var tilt: Float = 12
    public var chrome: MaterialKey = "metal.chrome"
    public var acrylic: MaterialKey = "plastic.acrylic"
    public var plaque: MaterialKey = "metal.stainless"
    public var engraving: MaterialKey = "plastic.matte:101014"
    public var wafer: MaterialKey = "silicon.thinfilm"
    public var foot: MaterialKey = "rubber"
    public init() {}

    func hex(h: Float, s: Float, v: Float) -> String {
        let i = Int(h * 6) % 6, f = h * 6 - floor(h * 6)
        let p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
        let (r, g, b): (Float, Float, Float) = [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)][i]
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    func flat(_ w: Float, _ h: Float, _ t: Float, _ mat: MaterialKey) -> Surface {
        Prim.extrude(Shape2D.rect(w, h), depth: t, bevel: 0, bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let baseH: Float = 0.032
        // Weighted chrome base: rounded slab with a beveled top edge, rubber feet beneath.
        m.add(Prim.roundedBox(V3(W, baseH - 0.004, D), radius: 0.008, bevelSegments: 3, material: chrome),
              Xform(translation: V3(0, 0.004 + (baseH - 0.004) / 2, 0)))
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.011, height: 0.004, bevel: 0.001, segments: 14, material: foot),
                  Xform(translation: V3(sx * (W / 2 - 0.03), 0, sz * (D / 2 - 0.025))))
        } }
        // Engraved plaque on the front of the base top: stainless plate with engraved text bars and border.
        let pw: Float = 0.24, pd: Float = 0.07, pz = D / 2 - 0.045
        m.add(Prim.roundedBox(V3(pw, 0.002, pd), radius: 0.0007, bevelSegments: 1, material: plaque),
              Xform(translation: V3(0, baseH + 0.0003, pz)))
        let py = baseH + 0.0014
        for (k, (len, dz)) in [(0.17, -0.019), (0.12, -0.003), (0.15, 0.012), (0.07, 0.026)].enumerated() {
            let h: Float = k == 0 ? 0.0036 : 0.0022
            var x: Float = -Float(len) / 2
            while x < Float(len) / 2 - 0.004 {
                let w = rng.float(0.002...0.0065)
                m.add(flat(min(w, Float(len) / 2 - x), h, 0.0004, engraving),
                      Xform(translation: V3(x + w / 2, py, pz + Float(dz)), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                x += w + rng.float(0.0015...0.004)
            }
        }
        let b: Float = 0.0006
        for sz: Float in [-1, 1] { m.add(flat(pw - 0.008, b, 0.0004, engraving), Xform(translation: V3(0, py, pz + sz * (pd / 2 - 0.004)), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))) }
        for sx: Float in [-1, 1] { m.add(flat(b, pd - 0.008, 0.0004, engraving), Xform(translation: V3(sx * (pw / 2 - 0.004), py, pz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))) }

        // Wafer assembly in local frame: disc faces +Z, centered at origin; then tilted back and lifted.
        let R = waferDiameter / 2, T = waferThickness
        let tiltQ = simd_quatf(degrees: -tilt, axis: V3(1, 0, 0))
        let centerZ: Float = -0.012
        let cy = baseH + 0.15 + (R + 0.012) * cos(tilt * .pi / 180)
        let place = { (z: Float) -> Xform in
            Xform(translation: V3(0, cy, centerZ) + tiltQ.act(V3(0, 0, z)), rotation: tiltQ)
        }
        // Wafer body: mirror silicon blank with beveled rim, lighter diced edge band.
        m.add(Prim.cylinder(radius: R, height: T, bevel: 0.0004, segments: 48, material: "silicon.die-edge"),
              Xform(translation: V3(0, cy, centerZ) + tiltQ.act(V3(0, 0, -T / 2)), rotation: tiltQ * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: R - 0.0007, height: 0.00008, bevel: 0, segments: 48, material: "silicon.die:6B7088"),
              Xform(translation: V3(0, cy, centerZ) + tiltQ.act(V3(0, 0, T / 2 - 0.00004)), rotation: tiltQ * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Die grid: one plate per full die inside the 3 mm edge exclusion, hue by radius and angle (thin-film interference).
        let usable = R - 0.003
        let ox = diePitch.x * 0.5, oz = diePitch.y * 0.25
        let cell = Prim.extrude(Shape2D.rect(diePitch.x - 0.0009, diePitch.y - 0.0009), depth: 0.00012, bevel: 0, bevelSegments: 1, material: wafer)
        for i in -6...6 { for j in -5...5 {
            let cx = Float(i) * diePitch.x + ox * 0, cz = Float(j) * diePitch.y + oz
            let hw = diePitch.x / 2, hh = diePitch.y / 2
            let corners = [(cx - hw, cz - hh), (cx + hw, cz - hh), (cx - hw, cz + hh), (cx + hw, cz + hh)]
            if corners.contains(where: { $0.0 * $0.0 + $0.1 * $0.1 > usable * usable }) { continue }
            let r = sqrt(cx * cx + cz * cz) / R, a = atan2(cz, cx)
            let hue = (0.62 + 0.5 * r + 0.08 * sin(a * 2) + rng.float(-0.012...0.012)).truncatingRemainder(dividingBy: 1)
            let mat = MaterialKey(stringLiteral: "silicon.thinfilm:" + hex(h: (round((hue < 0 ? hue + 1 : hue) * 14) / 14), s: 0.42 + 0.2 * r, v: 0.88 - 0.25 * r))
            var c = cell; c.material = mat
            m.add(c, Xform(translation: V3(0, cy, centerZ) + tiltQ.act(V3(cx, cz, T / 2 + 0.00006)), rotation: tiltQ))
        } }
        // Flat marker: notch dot at the wafer bottom edge and laser ID bar.
        m.add(Prim.roundedBox(V3(0.006, 0.0003, 0.0022), radius: 0.0001, bevelSegments: 1, material: "metal.gold"),
              Xform(translation: V3(0, cy, centerZ) + tiltQ.act(V3(0.0, -R + 0.008, T / 2 + 0.0002)), rotation: tiltQ * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

        // Acrylic cradle: back plate behind the wafer, grooved front retaining ring, chrome posts and clamp blocks.
        let ringMajor = R + 0.0045
        m.add(Prim.cylinder(radius: R + 0.011, height: 0.006, bevel: 0.0012, segments: 48, material: acrylic),
              Xform(translation: V3(0, cy, centerZ) + tiltQ.act(V3(0, 0, -T / 2 - 0.0063)), rotation: tiltQ * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.torus(major: ringMajor + 0.003, minor: 0.0045, segments: 48, sides: 8, material: acrylic),
              place(T / 2 + 0.0035).withRot(tiltQ * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.torus(major: ringMajor - 0.002, minor: 0.0016, segments: 48, sides: 8, material: acrylic),
              place(T / 2 + 0.0015).withRot(tiltQ * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Stem: chrome post with acrylic saddle under the ring.
        let ringBottom = V3(0, cy, centerZ) + tiltQ.act(V3(0, -(R + 0.011), -0.002))
        for sx: Float in [-1, 1] {
            let top = V3(sx * 0.05, ringBottom.y + 0.003, ringBottom.z)
            let bot = V3(sx * 0.05, baseH - 0.002, ringBottom.z)
            m.add(Prim.tube([bot, top], radii: [0.007, 0.007], sides: 24, seamTile: 0.05, material: chrome))
            m.add(Prim.cylinder(radius: 0.011, height: 0.003, bevel: 0.0008, segments: 24, material: chrome), Xform(translation: V3(sx * 0.05, baseH - 0.001, ringBottom.z)))
        }
        m.add(Prim.roundedBox(V3(0.13, 0.014, 0.012), radius: 0.004, bevelSegments: 2, material: acrylic),
              Xform(translation: V3(0, ringBottom.y + 0.006, ringBottom.z)))
        groundAO(&m)
        return LODModel(m)
    }
}

private extension Xform {
    func withRot(_ q: simd_quatf) -> Xform { var x = self; x.rotation = q; return x }
}
