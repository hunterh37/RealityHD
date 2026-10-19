import simd
import Foundation

/// EUV light source (laser-produced plasma), generic, 6 x 4 x 4 m. White CO2 laser drive cabinet on the left, a dark steel
/// tin-droplet vessel with a concave collector mirror, droplet generator, plasma glow and tin catcher, beam transport tube
/// with bellows, and heavy copper and steel cooling plumbing on the right. Named part: cutaway-cover (slides off the vessel front).
public struct EuvLightSource: RealArticulated {
    public static let id = "euv-light-source"
    public static let summary = "EUV light source: CO2 laser drive cabinet, tin vessel with collector mirror, cutaway cover, copper and steel plumbing."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 1.0, studio: true)

    /// Cabinet powdercoat (sRGB hex).
    public var color: UInt32 = 0xE9E9E4
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [12])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", steel: MaterialKey = "metal.steel", cu: MaterialKey = "metal.copper"
        let anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023", mirror: MaterialKey = "metal.chrome"
        let y0: Float = 0.14
        // Vessel: x vx0...vx1, y vy0...vy1, z -vz...vz. Open face at +z is closed by the cutaway cover.
        let vx0: Float = 0.0, vx1: Float = 2.5, vy0: Float = 0.6, vy1: Float = 3.5, vz: Float = 1.3
        let vcx = (vx0 + vx1) / 2, vcy = (vy0 + vy1) / 2
        rig.part("cutaway-cover", pivot: V3(vcx, vcy, vz), joint: .slide(axis: V3(0, 0, 1), 0...1.8, duration: 2.0))
        let alongX = simd_quatf(degrees: 90, axis: V3(0, 0, 1)), alongZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))

        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            func pan(_ s: V3, _ c: V3, _ mat: MaterialKey, name: String? = nil) {
                k.bx(s, c, mat, r: 0, name: name)
            }
            func pcyl(_ r: Float, _ len: Float, _ c: V3, _ mat: MaterialKey, axis: Int, seg: Int = 16, name: String? = nil) {
                let q = axis == 0 ? alongX : axis == 2 ? alongZ : simd_quatf.identity
                k.put(Prim.cylinder(radius: r, height: len, bevel: 0, segments: hi ? seg : max(6, seg / 2), material: mat), Xform(translation: c, rotation: q), name)
            }
            func flange(_ c: V3, _ r: Float, axis: Int, mat: MaterialKey = steel) {
                pcyl(r, 0.035, c, mat, axis: axis, seg: 16)
                if hi { for i in 0..<4 {
                    let a = Float(i) * .pi / 2
                    let o = axis == 1 ? V3(cos(a), 0, sin(a)) * (r * 0.8) : axis == 0 ? V3(0, cos(a), sin(a)) * (r * 0.8) : V3(cos(a), sin(a), 0) * (r * 0.8)
                    pcyl(0.011, 0.045, c + o, black, axis: axis, seg: 6)
                } }
            }
            func pipe(_ pts: [V3], _ r: Float, _ mat: MaterialKey, flanges: Bool = true) {
                k.tube(catmull(pts, per: hi ? 3 : 2), r, mat, sides: 8)
                guard hi, flanges else { return }
                for p in [pts.first!, pts.last!] { _ = p }
            }
            FabParts.grate(k, w: 6.0, d: 4.0)
            k.bx(V3(5.9, y0 - 0.04, 3.9), V3(0, (y0 + 0.05) / 2, 0), dark)

            // ---- CO2 laser drive cabinet x -3...-0.8, z -1.7...1.7, top 2.6 ----
            let cx0: Float = -3.0, cx1: Float = -0.8, ct: Float = 2.6, cz: Float = 1.7
            let ccx = (cx0 + cx1) / 2
            k.bx(V3(cx1 - cx0 - 0.1, ct - y0, 2 * cz - 0.1), V3(ccx, (ct + y0) / 2, 0), dark)
            let nu = 3, nv = 3
            let du = (cx1 - cx0) / Float(nu), dv = (ct - y0) / Float(nv)
            for i in 0..<nu { for j in 0..<nv {
                let x = cx0 + du * (Float(i) + 0.5), y = y0 + dv * (Float(j) + 0.5)
                pan(V3(du - 0.01, dv - 0.01, 0.03), V3(x, y, cz - 0.015), white)
                pan(V3(du - 0.01, dv - 0.01, 0.03), V3(x, y, -cz + 0.015), white)
            } }
            let nz = 2, dz = 2 * cz / Float(nz)
            for j in 0..<nv { for i in 0..<nz {
                let z = -cz + dz * (Float(i) + 0.5), y = y0 + dv * (Float(j) + 0.5)
                pan(V3(0.03, dv - 0.01, dz - 0.01), V3(cx0 + 0.015, y, z), white)
            } }
            for i in 0..<nu { for q in 0..<nz {
                let x = cx0 + du * (Float(i) + 0.5), z = -cz + dz * (Float(q) + 0.5)
                pan(V3(du - 0.01, 0.03, dz - 0.01), V3(x, ct - 0.015, z), white)
            } }
            // Cabinet right face toward vessel, half covered.
            pan(V3(0.03, ct - y0, 2 * cz - 0.02), V3(cx1 - 0.015, (ct + y0) / 2, 0), white)
            // Doors with handles and vents on the front, wear at the grips.
            for (i, dx) in [ccx - 0.55, ccx + 0.55].enumerated() {
                k.bx(V3(0.5, 1.2, 0.012), V3(dx, 0.95, cz + 0.006), dark, r: 0)
                if hi {
                    k.handle(V3(dx + (i == 0 ? 0.2 : -0.2), 0.95, cz), len: 0.3)
                    for q in 0..<5 { k.bx(V3(0.4, 0.012, 0.008), V3(dx, 0.55 + Float(q) * 0.035, cz + 0.014), black, r: 0) }
                }
            }
            k.bx(V3(0.14, 0.09, 0.006), V3(ccx, 1.8, cz + 0.002), "glass.lamp:40E060", r: 0)
            if hi {
                k.scuffs(V3(ccx - 0.55, 1.5, cz + 0.004), w: 0.4, h: 0.6, n: 5)
                k.scuffs(V3(ccx + 0.55, 0.45, cz + 0.004), w: 0.5, h: 0.2, n: 4)
                k.bx(V3(0.5, 0.2, 0.004), V3(ccx, 2.25, cz + 0.002), "plastic.matte:C8C8C2", r: 0)   // data plate
                for i in 0..<3 { for q in 0..<6 { k.bx(V3(0.012, 0.35, 0.01), V3(cx0 + 0.2 + 0.1 * Float(q) + Float(i) * 0.7, ct + 0.005, 0), black, r: 0) } }
            }
            FabParts.statusTower(k, V3(cx0 + 0.35, ct + 0.03, cz - 0.4))
            for fx: Float in [-2.8, -1.0] { for fz: Float in [-1.5, 1.5] { k.cyl(0.05, 0.02, V3(fx, 0.05 - 0.01, fz), steel, seg: 12) } }

            // ---- Beam transport tube from cabinet to vessel at y 2.1 with bellows and flanges ----
            pcyl(0.14, 0.9, V3(-0.35, 2.1, 0), steel, axis: 0, seg: 20)
            for q in 0..<(hi ? 10 : 3) { pcyl(0.18, 0.025, V3(-0.65 + Float(q) * 0.065, 2.1, 0), "metal.stainless", axis: 0, seg: 20) }
            flange(V3(-0.78, 2.1, 0), 0.22, axis: 0)
            flange(V3(-0.05, 2.1, 0), 0.22, axis: 0)

            // ---- Vessel ----
            k.bx(V3(vx1 - vx0, 0.1, 2 * vz), V3(vcx, vy0 + 0.05, 0), steel, r: 0.005)             // bottom
            k.bx(V3(vx1 - vx0, 0.1, 2 * vz), V3(vcx, vy1 - 0.05, 0), steel, r: 0.005)             // top
            k.bx(V3(0.1, vy1 - vy0 - 0.2, 2 * vz), V3(vx0 + 0.05, vcy, 0), steel, r: 0.005)       // left
            k.bx(V3(0.1, vy1 - vy0 - 0.2, 2 * vz), V3(vx1 - 0.05, vcy, 0), steel, r: 0.005)       // right
            k.bx(V3(vx1 - vx0 - 0.2, vy1 - vy0 - 0.2, 0.1), V3(vcx, vcy, -vz + 0.05), "metal.powdercoat:9A9EA3", r: 0)   // back lining
            // Front frame flange around the opening.
            k.bx(V3(vx1 - vx0 + 0.16, 0.14, 0.06), V3(vcx, vy1 + 0.0, vz + 0.0), steel, r: 0.004)
            k.bx(V3(vx1 - vx0 + 0.16, 0.14, 0.06), V3(vcx, vy0 + 0.0, vz + 0.0), steel, r: 0.004)
            k.bx(V3(0.14, vy1 - vy0, 0.06), V3(vx0 - 0.01, vcy, vz), steel, r: 0.004)
            k.bx(V3(0.14, vy1 - vy0, 0.06), V3(vx1 + 0.01, vcy, vz), steel, r: 0.004)
            // Vessel stand and ribs.
            k.bx(V3(vx1 - vx0 + 0.2, vy0 - y0, 0.2), V3(vcx, (vy0 + y0) / 2, -vz + 0.4), dark, r: 0.004)
            k.bx(V3(vx1 - vx0 + 0.2, vy0 - y0, 0.2), V3(vcx, (vy0 + y0) / 2, vz - 0.4), dark, r: 0.004)
            if hi { for q in 0..<4 {
                k.bx(V3(0.06, 0.06, 2 * vz + 0.1), V3(vx0 + 0.4 + Float(q) * 0.5, vy1 + 0.03, 0), steel, r: 0.002)
                k.bx(V3(0.06, 0.06, 2 * vz + 0.1), V3(vx0 + 0.4 + Float(q) * 0.5, vy0 - 0.03, 0), steel, r: 0.002)
            } }

            // ---- Collector mirror: concave dish on the back wall, opening toward +z ----
            let cc = V3(vcx, 2.0, -vz + 0.1)
            var prof: [V2] = [V2(0, 0)]
            for q in 1...(hi ? 12 : 6) {
                let r = 0.95 * Float(q) / Float(hi ? 12 : 6)
                prof.append(V2(r, 0.28 * (r / 0.95) * (r / 0.95) + 0.015))
            }
            prof.append(V2(0.97, 0.3)); prof.append(V2(0.97, 0.0)); prof.append(V2(0, 0))
            k.put(Prim.lathe(prof, segments: hi ? 32 : 14, material: mirror), Xform(translation: cc, rotation: alongZ))
            k.put(Prim.torus(major: 0.97, minor: 0.025, segments: hi ? 32 : 14, sides: 6, material: steel), Xform(translation: cc + V3(0, 0, 0.3), rotation: alongZ))
            for s: Float in [-1, 1] { k.bx(V3(0.1, 0.06, 0.2), cc + V3(s * 0.55, 0, 0.0) + V3(0, -0.9, 0), steel, r: 0.002) }
            // Intermediate-focus cone toward the scanner (front left) and beam entry aperture.
            k.put(Prim.cylinder(radius: 0.07, height: 0.25, bevel: 0, segments: hi ? 12 : 6, material: black), Xform(translation: V3(vx0 + 0.15, 2.1, 0), rotation: alongX))
            // Plasma glow, droplet generator above, tin catcher below.
            k.put(Prim.superellipsoid(V3(0.22, 0.22, 0.22), exponent: 2, subdivisions: hi ? 8 : 4, material: "glass.lamp:A8E0FF"), Xform(translation: V3(vcx, 2.0, cc.z + 0.55)))
            pcyl(0.07, 0.4, V3(vcx, vy1 - 0.3, cc.z + 0.55), anod, axis: 1, seg: 14)
            pcyl(0.02, 0.5, V3(vcx, 2.75, cc.z + 0.55), "metal.stainless", axis: 1, seg: 8)
            k.put(Prim.cylinder(radius: 0.015, height: 0.18, bevel: 0, segments: 6, material: "glass.lamp:A8E0FF"), Xform(translation: V3(vcx, 2.28, cc.z + 0.55)))
            k.put(Prim.lathe([V2(0, 0), V2(0.14, 0), V2(0.2, 0.12), V2(0.2, 0.25), V2(0.15, 0.25), V2(0, 0.1)], segments: hi ? 16 : 8, material: "metal.powdercoat:5A5E63"), Xform(translation: V3(vcx, vy0 + 0.1, cc.z + 0.55)))
            // Tin splash shields.
            if hi { for q in 0..<5 { k.bx(V3(1.9, 0.015, 0.2), V3(vcx, 1.0 + Float(q) * 0.0, cc.z + 0.4), "metal.stainless", r: 0) ; _ = q } }

            // ---- Cutaway cover: plate with viewport, bolts, lifting handles ----
            let cn = "cutaway-cover"
            // Cut-away frame: plate with a 1.9 m round-cornered opening over the collector, section edge painted safety orange.
            let ow: Float = 1.9, ox0 = vcx - ow / 2, ox1 = vcx + ow / 2, oy0: Float = 2.0 - ow / 2, oy1: Float = 2.0 + ow / 2
            let pw = vx1 - vx0 + 0.1, ph = vy1 - vy0 - 0.12, zc = vz + 0.055
            k.bx(V3(pw, oy0 - (vcy - ph / 2), 0.05), V3(vcx, (oy0 + vcy - ph / 2) / 2, zc), "metal.powdercoat:A8ACB0", r: 0.004, name: cn)
            k.bx(V3(pw, vcy + ph / 2 - oy1, 0.05), V3(vcx, (oy1 + vcy + ph / 2) / 2, zc), "metal.powdercoat:A8ACB0", r: 0.004, name: cn)
            k.bx(V3(ox0 - (vcx - pw / 2), ow, 0.05), V3((ox0 + vcx - pw / 2) / 2, 2.0, zc), "metal.powdercoat:A8ACB0", r: 0.004, name: cn)
            k.bx(V3(vcx + pw / 2 - ox1, ow, 0.05), V3((ox1 + vcx + pw / 2) / 2, 2.0, zc), "metal.powdercoat:A8ACB0", r: 0.004, name: cn)
            let od: MaterialKey = "metal.powdercoat:E8601A"
            k.bx(V3(ow + 0.04, 0.03, 0.06), V3(vcx, oy0 - 0.005, zc + 0.005), od, r: 0, name: cn)
            k.bx(V3(ow + 0.04, 0.03, 0.06), V3(vcx, oy1 + 0.005, zc + 0.005), od, r: 0, name: cn)
            k.bx(V3(0.03, ow, 0.06), V3(ox0 - 0.005, 2.0, zc + 0.005), od, r: 0, name: cn)
            k.bx(V3(0.03, ow, 0.06), V3(ox1 + 0.005, 2.0, zc + 0.005), od, r: 0, name: cn)
            if hi {
                for i in 0..<12 {
                    let a = Float(i) / 12 * 2 * .pi
                    k.put(Prim.cylinder(radius: 0.014, height: 0.02, bevel: 0, segments: 6, material: "metal.stainless"),
                          Xform(translation: V3(vcx + cos(a) * 1.15, 2.0 + sin(a) * 1.15, vz + 0.1), rotation: alongZ), cn)
                }
                for q in 0..<2 {
                    let bxp = vcx + (q == 0 ? -1 : 1) * 1.0
                    k.put(Prim.cylinder(radius: 0.02, height: 0.3, bevel: 0, segments: 8, material: "metal.stainless"), Xform(translation: V3(bxp, 3.1, vz + 0.17), rotation: alongX), cn)
                    k.put(Prim.cylinder(radius: 0.025, height: 0.12, bevel: 0, segments: 8, material: "metal.stainless"), Xform(translation: V3(bxp - 0.12, 3.1, vz + 0.11), rotation: alongZ), cn)
                    k.put(Prim.cylinder(radius: 0.025, height: 0.12, bevel: 0, segments: 8, material: "metal.stainless"), Xform(translation: V3(bxp + 0.12, 3.1, vz + 0.11), rotation: alongZ), cn)
                }
                k.put(cuboid(V3(0.4, 0.002, 0.2), material: "plastic.matte:C8C8C2"), Xform(translation: V3(vcx, 0.95, vz + 0.082), rotation: alongZ), cn)
            }
            // Bolt rows on the front frame.
            if hi { for q in 0..<8 {
                let x = vx0 + 0.15 + Float(q) * (vx1 - vx0 - 0.3) / 7
                for y in [vy0, vy1] { k.put(Prim.cylinder(radius: 0.016, height: 0.022, bevel: 0, segments: 6, material: black), Xform(translation: V3(x, y, vz + 0.035), rotation: alongZ)) }
            } }

            // ---- Heavy copper and steel plumbing, right side x 2.5...3.0 ----
            let px: Float = 2.75
            k.bx(V3(0.5, 0.45, 1.2), V3(px, 3.65, -0.2), dark, r: 0.004)                                     // chiller manifold on top
            for (i, zz) in [Float(-0.55), -0.2, 0.15].enumerated() {
                pipe([V3(vx1 - 0.05, 3.1 - Float(i) * 0.4, zz), V3(px - 0.1, 3.1 - Float(i) * 0.4, zz), V3(px, 2.8 - Float(i) * 0.4, zz), V3(px, 0.9, zz)], 0.055, cu)
                if hi { for yy: Float in [3.0 - Float(i) * 0.4, 1.2, 1.9, 2.5] {
                    flange(V3(px, yy, zz), 0.1, axis: 1, mat: cu)
                } }
            }
            pipe([V3(px, 0.9, -0.55), V3(px, 0.4, -0.55), V3(px - 0.5, 0.3, -1.0), V3(px - 1.0, 0.3, -1.6)], 0.075, steel)
            pipe([V3(px, 0.9, -0.2), V3(px, 0.4, -0.2), V3(px - 0.4, 0.3, 0.8), V3(px - 1.0, 0.3, 1.6)], 0.075, steel)
            pipe([V3(vcx, vy1, 0.5), V3(vcx, 3.9, 0.5), V3(vcx + 0.7, 3.85, 0.2), V3(px, 3.85, -0.1)], 0.07, cu)
            pipe([V3(vcx - 0.6, vy1, -0.5), V3(vcx - 0.6, 3.95, -0.5), V3(vcx + 0.2, 3.92, -0.5), V3(px, 3.92, -0.4)], 0.05, steel)
            if hi {
                for (zz, yy) in [(Float(-0.55), Float(1.5)), (-0.2, 2.2), (0.15, 1.5)] {
                    k.cyl(0.04, 0.12, V3(px + 0.0, yy + 0.1, zz), black, seg: 8)
                    k.put(Prim.torus(major: 0.07, minor: 0.012, segments: 12, sides: 5, material: "metal.anodized-black"), Xform(translation: V3(px, yy + 0.18, zz)))
                }
                for q in 0..<6 { pcyl(0.013, 0.1, V3(px - 0.05 + Float(q % 2) * 0.1, 3.88, -0.2 + 0.08 * Float(q)), "metal.copper", axis: 0, seg: 6) }
                pcyl(0.07, 0.06, V3(px + 0.1, 0.9, 0.15), "metal.copper", axis: 0, seg: 12)
                pcyl(0.035, 0.12, V3(px + 0.25, 2.05, -0.55), black, axis: 0, seg: 10)
                k.bx(V3(0.18, 0.12, 0.004), V3(px, 3.65, 0.42), "plastic.matte:E8C21A", r: 0)          // warning label
            }
            // Floor drain collar and pump skid at the vessel front right.
            k.bx(V3(0.8, 0.5, 0.6), V3(2.5, 0.4, 1.6), dark, r: 0.004)
            k.cyl(0.18, 0.25, V3(2.5, 0.75, 1.6), cu, seg: 16)
            if hi { for q in 0..<4 { k.bx(V3(0.012, 0.3, 0.004), V3(2.2 + Float(q) * 0.2, 0.4, 1.905), black, r: 0) } }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("cutaway", ["cutaway-cover": 1.8])]
        return rig
    }
}
