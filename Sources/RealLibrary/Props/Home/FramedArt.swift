import simd
import Foundation

/// framed art: walnut frame with cream mat around a muted landscape print, matte finish, lightly aged. Parts: stepped walnut moulding frame with mitered corners, off-white mat with beveled window, landscape print (layered hills, sun), glass pane in rabbet, backing board with wire hanger and screw eyes, rubber bumpers.
public struct FramedArt: RealAsset {
    public static let id = "framed-art"
    public static let summary = "Wall art, 0.9 x 0.6 m: walnut stepped frame, cream matted landscape print under glass, wire hanger on the back."
    public static let tags = ["prop", "floorplan", "home", "decor", "wood", "wall", "interior"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Authored with the back face at z = -depth / 2 and the lowest point at y = 0.
    public var size = V3(0.9, 0.6, 0.035)
    /// Frame wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Mat board.
    public var mat: MaterialKey = "paint.wall:EFE8D8"
    public init() {}

    private func box(_ m: inout Model, _ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.001) {
        m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: 1, material: key), Xform(translation: c))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z, fw: Float = 0.03
        let cx = w / 2, cy = h / 2
        // Stepped moulding swept around a rounded rectangle (profile x = depth, y = lateral).
        let pw = w - fw, ph = h - fw
        let rect = Shape2D.rounded([V2(0, 0), V2(pw, 0), V2(pw, ph), V2(0, ph)], radius: 0.003)
        let path = rect.map { V3(cx - pw / 2 + $0.x, cy - ph / 2 + $0.y, 0) }
        let prof: [V2] = [V2(0, -0.015), V2(d - 0.001, -0.015), V2(d, -0.0135), V2(d, -0.005), V2(d - 0.005, 0.003), V2(d - 0.008, 0.009), V2(d - 0.008, 0.015), V2(0, 0.015)]
        m.add(Prim.sweep(prof, along: path, up: V3(0, 0, 1), closedPath: true, caps: false, grainAlongPath: true, material: wood))
        let iw = w - 2 * 0.0285, ih = h - 2 * 0.0285       // opening behind the lip
        // Backing board, mat, glass.
        box(&m, V3(iw, ih, 0.004), V3(cx, cy, 0.004), "wood.plywood")
        let zm: Float = 0.0095
        let ow: Float = 0.64, oh: Float = 0.34, oyc = cy + 0.012
        let matT: Float = 0.0035
        box(&m, V3(iw, (oyc - oh / 2) - (cy - ih / 2), matT), V3(cx, (cy - ih / 2 + oyc - oh / 2) / 2, zm), mat, r: 0.0006)
        box(&m, V3(iw, (cy + ih / 2) - (oyc + oh / 2), matT), V3(cx, (oyc + oh / 2 + cy + ih / 2) / 2, zm), mat, r: 0.0006)
        let sideW = (iw - ow) / 2
        for s: Float in [-1, 1] { box(&m, V3(sideW, oh, matT), V3(cx + s * (ow / 2 + sideW / 2), oyc, zm), mat, r: 0.0006) }
        // Inner mat bevel: thin lighter core line around the window.
        let core: MaterialKey = "paint.wall:FBF8F0"
        box(&m, V3(ow + 0.006, 0.003, 0.0012), V3(cx, oyc + oh / 2 + 0.0015, zm + matT / 2 + 0.0002), core, r: 0.0004)
        box(&m, V3(ow + 0.006, 0.003, 0.0012), V3(cx, oyc - oh / 2 - 0.0015, zm + matT / 2 + 0.0002), core, r: 0.0004)
        for s: Float in [-1, 1] { box(&m, V3(0.003, oh, 0.0012), V3(cx + s * (ow / 2 + 0.0015), oyc, zm + matT / 2 + 0.0002), core, r: 0.0004) }
        // Print: sky board, sun, three layered hill silhouettes, a tree line and a pond streak.
        let z0: Float = 0.0075
        let ph1 = rng.float(0...6), ph2 = rng.float(0...6)
        let sky = Prim.roundedBox(V3(ow + 0.004, oh + 0.004, 0.001), radius: 0.0003, bevelSegments: 1, material: "paint.wall:E7D9BC")
        m.add(sky, Xform(translation: V3(cx, oyc, z0)))
        m.add(Prim.cylinder(radius: 0.045, height: 0.0007, bevel: 0.0001, segments: 28, material: "paint.wall:D98B52"),
              Xform(translation: V3(cx + 0.12, oyc + 0.04, z0 + 0.0005), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        func hills(_ base: Float, _ amp: Float, _ f: Float, _ ph: Float, _ tint: String, _ zo: Float) {
            var pts: [V2] = []
            let n = 48
            for i in 0...n {
                let x = -ow / 2 + ow * Float(i) / Float(n)
                let y = base + amp * (0.6 * sin(f * x * 6.28 + ph) + 0.4 * sin(f * 2.3 * x * 6.28 + ph * 1.7))
                pts.append(V2(x, min(y, oh / 2 - 0.004)))
            }
            pts.append(V2(ow / 2, -oh / 2)); pts.append(V2(-ow / 2, -oh / 2))
            // Order for a counter-clockwise outline.
            let ccw = Array(pts.reversed())
            let sfc = Prim.extrude(ccw, depth: 0.0007, bevel: 0.0001, bevelSegments: 1, material: MaterialKey(tint))
            m.add(sfc, Xform(translation: V3(cx, oyc, z0 + zo)))
        }
        hills(0.01, 0.045, 0.9, ph1, "paint.wall:B8A27A", 0.0009)
        hills(-0.035, 0.05, 1.3, ph2, "paint.wall:8B8A60", 0.0017)
        hills(-0.09, 0.04, 1.8, ph1 + 2, "paint.wall:4F5B45", 0.0025)
        hills(-0.15, 0.025, 2.4, ph2 + 1, "paint.wall:2F3A33", 0.0033)
        // Glass pane in the rabbet, very slightly smaller than the opening.
        m.add(Prim.roundedBox(V3(iw - 0.002, ih - 0.002, 0.002), radius: 0.0005, bevelSegments: 1, material: "glass.clear"), Xform(translation: V3(cx, cy, 0.0205)))
        // Back: screw eyes and picture wire, felt bumpers.
        let brass: MaterialKey = "metal.brass-aged"
        for s: Float in [-1, 1] {
            m.add(Prim.torus(major: 0.0045, minor: 0.0009, segments: 12, sides: 5, material: brass),
                  Xform(translation: V3(cx + s * 0.28, cy + 0.16, -0.001), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.0012, height: 0.008, bevel: 0.0003, segments: 8, material: brass),
                  Xform(translation: V3(cx + s * 0.28, cy + 0.16, 0.0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            box(&m, V3(0.012, 0.012, 0.0025), V3(cx + s * (w / 2 - 0.02), 0.02, -0.0012), "plastic.black:222222", r: 0.0008)
        }
        let wire = catmull([V3(cx - 0.28, cy + 0.16, -0.003), V3(cx - 0.12, cy + 0.2, -0.004), V3(cx, cy + 0.218, -0.0045), V3(cx + 0.12, cy + 0.2, -0.004), V3(cx + 0.28, cy + 0.16, -0.003)], per: 5)
        m.add(Prim.tube(wire, radii: wire.map { _ in 0.0007 }, sides: 5, seamTile: 0.01, material: "metal.steel", capEnd: true))
        // Authoring frame: lowest point y = 0, back face (frame back at z = 0, bumpers behind) at z = -d / 2.
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -d / 2)))
        return LODModel(m)
    }
}
