import simd
import Foundation

/// Hot aisle containment module: clear anodized aluminum frame, hazy polycarbonate roof and transom panels, bi-parting sliding end doors ("door-left", "door-right", slide joints 0...0.2 m) with push handles, EPDM seals, labels and brush-sealed cable penetrations.
public struct HotAisleContainment: RealArticulated {
    public static let id = "hot-aisle-containment"
    public static let summary = "Hot aisle containment module: anodized aluminum frame, hazy polycarbonate roof and transom panels, end-of-row bi-parting sliding doors with push handles, rubber seals, labels and brush-sealed cable penetrations."
    public static let tags = ["prop", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 3.4, studio: true)

    /// Aisle width (x), height (y), module length (z) in meters. Doors face +Z.
    public var size = V3(1.2, 3.0, 2.4)
    /// Frame extrusion material.
    public var frameMaterial: MaterialKey = "metal.aluminum"
    /// Roof and door panel material.
    public var panelMaterial: MaterialKey = "glass.polycarbonate"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [7])
        let al = frameMaterial, pc = panelMaterial
        let seal: MaterialKey = "rubber.seal", steel: MaterialKey = "metal.stainless"
        let W = size.x, H = size.y - 0.22, L = size.z - 0.1
        let hx = W / 2, hz = L / 2
        let fw: Float = 0.065          // extrusion section
        let doorTop: Float = 2.3, track: Float = 2.36

        func box(_ m: inout Model, _ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.004) {
            let b = min(r, min(s.x, min(s.y, s.z)) * 0.45)
            m.add(Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: b, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        func panel(_ m: inout Model, _ s: V3, _ c: V3) { m.add(cuboid(s, material: pc), Xform(translation: c)) }
        func label(_ m: inout Model, _ c: V3, _ w: Float, _ h: Float, _ mat: MaterialKey, bars: Int, flip: Bool = false, ry: Float = 0) {
            let q = simd_quatf(degrees: ry, axis: V3(0, 1, 0))
            let n: Float = flip ? -1 : 1
            m.add(cuboid(V3(w, h, 0.002), material: mat), Xform(translation: c, rotation: q))
            for i in 0..<bars {
                let y = h / 2 - h * (Float(i) + 1) / Float(bars + 1)
                let bw = w * (i == 0 ? 0.7 : 0.5 + 0.08 * Float(i % 3))
                m.add(cuboid(V3(bw, h * 0.07, 0.0014), material: "plastic.matte:151515"),
                      Xform(translation: c + q.act(V3(0, y, n * 0.0016)), rotation: q))
            }
        }

        for l in 0..<2 {
            var m = Model(name: Self.id)
            let d = l == 0
            // Posts: corners and mid-line, floor shoe plates.
            for sx: Float in [-1, 1] {
                for z: Float in [-hz + fw / 2, 0, hz - fw / 2] {
                    box(&m, V3(fw, H, fw), V3(sx * (hx - fw / 2), H / 2, z), al)
                    box(&m, V3(0.09, 0.006, 0.09), V3(sx * (hx - fw / 2), 0.003, z), steel, r: 0.0015)
                }
                // side upper rails (top of rack line) and side transom panels
                for z0: Float in [-1, 1] {
                    let zc = z0 * hz / 2 + (z0 > 0 ? -fw / 4 : fw / 4)
                    box(&m, V3(fw, 0.06, hz - fw), V3(sx * (hx - fw / 2), 2.45, zc), al)
                    panel(&m, V3(0.006, H - 2.48 - fw, hz - fw - 0.02), V3(sx * (hx - fw / 2), (H + 2.48 - fw) / 2, zc))
                    if d { box(&m, V3(0.01, 0.01, hz - fw - 0.02), V3(sx * (hx - fw / 2 + 0.014), 2.5, zc), seal, r: 0.003) }
                }
            }
            // Roof perimeter rails and cross members.
            box(&m, V3(W, fw, fw), V3(0, H - fw / 2, -hz + fw / 2), al)
            box(&m, V3(W, fw, fw), V3(0, H - fw / 2, hz - fw / 2), al)
            box(&m, V3(W, fw, fw), V3(0, H - fw / 2, 0), al)
            for sx: Float in [-1, 1] { box(&m, V3(fw, fw, L), V3(sx * (hx - fw / 2), H - fw / 2, 0), al) }
            for z: Float in [-0.6, 0.6] { box(&m, V3(W - 2 * fw, 0.03, 0.035), V3(0, H - 0.02, z), al) }
            box(&m, V3(0.035, 0.03, L - 2 * fw), V3(0, H - 0.02, 0), al)
            for z: Float in [-1.2, -0.6, 0, 0.6, 1.2] where abs(z) < hz - 0.05 { if d { box(&m, V3(W - 2 * fw, 0.006, 0.012), V3(0, H - 0.003, z + (z == 0 ? 0 : 0)), seal, r: 0.001) } }
            // Roof panels: 8 bays with a seal bead under each edge.
            for (i, zc) in [Float(-0.9), -0.3, 0.3, 0.9].enumerated() {
                for sx: Float in [-1, 1] {
                    let xc = sx * (hx - fw) / 2 - sx * 0.004
                    let wx = hx - fw - 0.0175 - 0.004
                    panel(&m, V3(wx, 0.007, 0.545 - (i == 1 ? 0 : 0)), V3(xc + sx * 0.0125, H - 0.0075, zc))
                    if d { box(&m, V3(0.008, 0.004, 0.54), V3(sx * (hx - fw - 0.02), H - 0.032, zc), seal, r: 0.0015) }
                }
            }
            // End wall at -Z: open run into the next module, header beam only.
            box(&m, V3(W - 2 * fw, 0.1, 0.04), V3(0, 2.45, -hz + 0.02), al)
            panel(&m, V3(W - 2 * fw - 0.02, H - 2.5 - fw, 0.006), V3(0, (H + 2.5 - fw) / 2, -hz + 0.02))

            // End at +Z: sidelights, header, transom, track.
            let sideW: Float = 0.2, zE = hz - fw / 2
            for sx: Float in [-1, 1] {
                let xc = sx * (hx - fw - sideW / 2)
                box(&m, V3(sideW, doorTop, 0.03), V3(xc, doorTop / 2 + 0.02, zE - 0.015 + 0.0), al, r: 0.002)
                panel(&m, V3(sideW - 0.05, doorTop - 0.12, 0.006), V3(xc, doorTop / 2 + 0.02, zE))
                box(&m, V3(sideW - 0.045, 0.022, 0.012), V3(xc, 0.06, zE + 0.011), al, r: 0.002)
            }
            box(&m, V3(W - 2 * fw, 0.14, 0.05), V3(0, 2.43, zE - 0.005), al)
            panel(&m, V3(W - 2 * fw - 0.02, H - 2.5 - fw, 0.006), V3(0, (H + 2.5 - fw) / 2, zE))
            box(&m, V3(W - 2 * fw, 0.02, 0.015), V3(0, 2.495, zE + 0.03), al)
            // Overhead track and floor guide, extended past the frame for door travel.
            let tl = W
            box(&m, V3(tl, 0.07, 0.06), V3(0, track + 0.045, hz + 0.045), al, r: 0.004)
            box(&m, V3(tl, 0.012, 0.04), V3(0, track + 0.012, hz + 0.045), steel, r: 0.0015)
            box(&m, V3(tl, 0.012, 0.04), V3(0, 0.006, hz + 0.045), steel, r: 0.0015)
            box(&m, V3(0.008, 0.02, 0.05), V3(-tl / 2 + 0.02, 0.016, hz + 0.045), seal, r: 0.002)
            box(&m, V3(0.008, 0.02, 0.05), V3(tl / 2 - 0.02, 0.016, hz + 0.045), seal, r: 0.002)
            // Cable penetrations: brush frame in two roof bays, bundles rising through.
            for (k, (x, z)) in [(Float(0.27), Float(-0.3)), (Float(-0.27), Float(0.3))].enumerated() {
                let by = H + 0.001
                box(&m, V3(0.34, 0.012, 0.16), V3(x, by + 0.006, z), al, r: 0.003)
                box(&m, V3(0.26, 0.016, 0.07), V3(x, by + 0.01, z), seal, r: 0.003)
                box(&m, V3(0.26, 0.02, 0.006), V3(x, by + 0.012, z - 0.025), "plastic.matte:0A0A0A", r: 0.001)
                box(&m, V3(0.26, 0.02, 0.006), V3(x, by + 0.012, z + 0.025), "plastic.matte:0A0A0A", r: 0.001)
                if d {
                    for i in 0..<4 {
                        let ox = x - 0.08 + 0.055 * Float(i), ph = rng.float(-0.03...0.03)
                        let path = catmull([V3(ox, by + 0.01, z), V3(ox + ph, by + 0.12, z + 0.01), V3(ox + ph * 2.5, by + 0.16, z + 0.07 * (k == 0 ? 1 : -1)), V3(ox + ph * 3, by + 0.2, z + 0.16 * (k == 0 ? 1 : -1))], per: 3)
                        m.add(Prim.tube(path, radii: [Float](repeating: 0.011, count: path.count), sides: 6, seamTile: 0.05,
                                        material: i % 2 == 0 ? "plastic.matte:1A1A1C" : "plastic.matte:1D4F9C", capEnd: true))
                    }
                    for dx: Float in [-0.15, 0.15] { hexBolt(&m, at: V3(x + dx, by + 0.012, z + 0.06), normal: .up, size: 0.007, material: steel) }
                }
            }
            for i in 0..<6 { m.add(cuboid(V3(0.1, 0.0015, 0.09), material: i % 2 == 0 ? "plastic.yellow" : "plastic.matte:151515"), Xform(translation: V3(-0.3 + 0.12 * Float(i), 0.0008, hz + 0.2), rotation: simd_quatf(degrees: 35, axis: .up))) }
            // Labels.
            label(&m, V3(0, 2.43, zE + 0.0225), 0.30, 0.07, "plastic.white", bars: 2)
            label(&m, V3(-hx + 0.01, 2.2, -0.6), 0.2, 0.08, "plastic.yellow", bars: 3, flip: false, ry: 90)
            label(&m, V3(hx - 0.01, 2.2, 0.6), 0.2, 0.08, "plastic.yellow", bars: 3, flip: false, ry: -90)
            label(&m, V3(-hx + fw + 0.1, 1.55, zE + 0.0165), 0.1, 0.06, "plastic.white", bars: 2)
            rig.base[l] = m
        }

        // Sliding leaves.
        let opening = W - 2 * fw - 0.4, leafW = opening / 2 + 0.02, zD = hz + 0.045
        rig.part("door-left", pivot: V3(-opening / 4, 1.2, zD), joint: .slide(axis: V3(-1, 0, 0), 0...0.2, duration: 1.1))
        rig.part("door-right", pivot: V3(opening / 4, 1.2, zD), joint: .slide(axis: V3(1, 0, 0), 0...0.2, duration: 1.1))
        for (name, sx) in [("door-left", Float(-1)), ("door-right", Float(1))] {
            let cx = sx * (leafW / 2 - 0.01), zl = zD + sx * 0.0 + (sx < 0 ? 0.012 : -0.012)
            let dh = doorTop - 0.04, cy = 0.04 + dh / 2
            let ft: Float = 0.04
            // frame rails and stiles
            rig.add(Prim.extrude(Shape2D.rect(leafW, ft), depth: 0.035, bevel: 0.002, bevelSegments: 1, material: al), Xform(translation: V3(cx, 0.04 + ft / 2, zl)), to: name)
            rig.add(Prim.extrude(Shape2D.rect(leafW, ft), depth: 0.035, bevel: 0.002, bevelSegments: 1, material: al), Xform(translation: V3(cx, 0.04 + dh - ft / 2, zl)), to: name)
            for e: Float in [-1, 1] {
                rig.add(Prim.extrude(Shape2D.rect(ft, dh), depth: 0.035, bevel: 0.002, bevelSegments: 1, material: al), Xform(translation: V3(cx + e * (leafW / 2 - ft / 2), cy, zl)), to: name)
            }
            rig.add(cuboid(V3(leafW - 2 * ft + 0.01, dh - 2 * ft + 0.01, 0.006), material: pc), Xform(translation: V3(cx, cy, zl)), to: name)
            // gasket lips around the glazing
            for (s, c) in [(V3(leafW - 2 * ft, 0.006, 0.012), V3(cx, cy + dh / 2 - ft - 0.003, zl)), (V3(leafW - 2 * ft, 0.006, 0.012), V3(cx, cy - dh / 2 + ft + 0.003, zl)),
                           (V3(0.006, dh - 2 * ft, 0.012), V3(cx - leafW / 2 + ft + 0.003, cy, zl)), (V3(0.006, dh - 2 * ft, 0.012), V3(cx + leafW / 2 - ft - 0.003, cy, zl))] {
                rig.add(cuboid(s, material: seal), Xform(translation: c), to: name)
            }
            // meeting-stile seal and bottom brush
            let mx = cx - sx * (leafW / 2) * -1  // meeting edge at inner side
            rig.add(cuboid(V3(0.012, dh - 0.02, 0.016), material: seal), Xform(translation: V3(sx * -1 * 0 + (-sx) * (-(leafW / 2) + 0.0) * 0 + (cx - sx * (leafW / 2) * -1) * 0 + (sx < 0 ? cx + leafW / 2 : cx - leafW / 2) + (sx < 0 ? -0.006 : 0.006), cy, zl)), to: name)
            _ = mx
            rig.add(cuboid(V3(leafW - 0.02, 0.025, 0.01), material: "plastic.matte:0A0A0A"), Xform(translation: V3(cx, 0.04 - 0.002 + 0.0, zl)), to: name)
            // hangers to the track
            for hxo: Float in [-0.12, 0.12] {
                rig.add(cuboid(V3(0.04, 0.12, 0.012), material: steel), Xform(translation: V3(cx + hxo, track - 0.01 + (doorTop - track) * 0 + 0.0 - 0.0 + 0.0 + 0.0 + 0.0 - 0.0 + 0.0, zl)), to: name, lods: 0...0)
                rig.add(Prim.cylinder(radius: 0.014, height: 0.012, bevel: 0.003, segments: 12, material: steel),
                        Xform(translation: V3(cx + hxo, track + 0.03, zD + 0.02), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: name, lods: 0...0)
            }
            // push handle on the outer face near the meeting stile, label plate
            let hxp = sx < 0 ? cx + leafW / 2 - 0.07 : cx - leafW / 2 + 0.07
            rig.add(barHandle(length: 0.7, standoff: 0.04, radius: 0.0115, overhang: 0.03, material: steel),
                    Xform(translation: V3(hxp, 1.1, zl + 0.0175), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))), to: name)
            rig.add(cuboid(V3(0.16, 0.06, 0.002), material: "plastic.yellow"), Xform(translation: V3(cx, 1.62, zl + 0.0185)), to: name)
            rig.add(cuboid(V3(0.1, 0.006, 0.0014), material: "plastic.matte:151515"), Xform(translation: V3(cx, 1.62, zl + 0.0201)), to: name)
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["door-left": 0.2, "door-right": 0.2]), RigState("ajar", ["door-left": 0.08, "door-right": 0.08])]
        return rig
    }
}
