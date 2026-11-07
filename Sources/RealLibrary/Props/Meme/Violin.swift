import simd
import Foundation

/// Violin: two-bout flame maple body with arched spruce top, f-holes, purfling, ebony fingerboard, scroll and pegs, four steel strings, bridge, tailpiece, chinrest and a bow on its own part. Lying on its back, scroll toward -Z.
public struct Violin: RealArticulated {
    public static let id = "violin"
    public static let summary = "Full-size violin, 59 cm, with a bow: flame maple, f-holes, ebony fingerboard, scroll, pegs, strings, bridge, chinrest."
    public static let tags = ["prop", "wood", "handheld", "articulated"]
    public static let budget = 15000
    public static let author = "realityhd"

    public init() {}

    private static let drop: Float = 0.0425       // back plate underside, lifts the instrument onto y = 0
    private static let ribDepth: Float = 0.030

    /// Body outline in loft space: (x, -z), z from 0 at the upper end to 0.355 at the tail.
    private static func bodyOutline() -> [V2] {
        let ctrl: [(Float, Float)] = [(0.000, 0.000), (0.006, 0.034), (0.022, 0.056), (0.050, 0.074), (0.080, 0.084), (0.105, 0.078), (0.130, 0.062),
                                      (0.150, 0.053), (0.168, 0.056), (0.190, 0.074), (0.225, 0.098), (0.262, 0.106), (0.300, 0.096), (0.332, 0.070),
                                      (0.349, 0.036), (0.355, 0.000)]
        let right = Profile.smooth(ctrl.map { V2($0.1, -$0.0) }, per: 4)
        let left = right.dropFirst().dropLast().reversed().map { V2(-$0.x, $0.y) }
        let all = right + left
        return Shape2D.area(all) >= 0 ? all : all.reversed()
    }

    private static func scaled(_ o: [V2], _ s: Float) -> [V2] {
        let c = V2(0, -0.1775)
        return o.map { c + ($0 - c) * s }
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id)
        var m = Model(name: Self.id)
        let sh = Self.drop
        func put(_ s: Surface, _ x: Xform = .identity) { m.add(s, Xform(translation: V3(0, sh, 0)).then2(x)) }
        let maple: MaterialKey = "wood.maple-natural:B5651D", spruce: MaterialKey = "wood.pine:DDB06A", ebony: MaterialKey = "wood.walnut:100A06"
        let outline = Self.bodyOutline()

        // Arched top plate, rim to crown, and back plate, crown to rim (normals out).
        let topRings: [(Float, Float)] = [(1, 0), (0.93, 0.0035), (0.8, 0.0095), (0.6, 0.0135), (0.4, 0.0155), (0.2, 0.0163), (0.03, 0.0165)]
        put(Prim.loft(topRings.map { Prim.ring(Self.scaled(outline, $0.0), y: $0.1) }, capEnd: true, material: spruce))
        let backRings: [(Float, Float)] = [(0.03, -0.0425), (0.2, -0.0415), (0.4, -0.0395), (0.6, -0.036), (0.8, -0.0325), (0.93, -0.0305), (1, -0.030)]
        put(Prim.loft(backRings.map { Prim.ring(Self.scaled(outline, $0.0), y: $0.1 + 0.0) }, capStart: true, material: maple))
        // Ribs with a small overhang lip of the top.
        put(Prim.loft([Prim.ring(outline, y: -0.030), Prim.ring(outline, y: 0.0)], material: maple))
        // Purfling: black-white-black inlay line just inside the top edge.
        let pur = Shape2D.offset(outline, -0.0055)
        let purPath = stride(from: 0, to: pur.count, by: 2).map { V3(pur[$0].x, 0.0036, -pur[$0].y) }
        put(Prim.sweep(Shape2D.circle(0.0009, segments: 6), along: purPath, up: .up, closedPath: true, caps: false, material: "plastic.matte:0C0C0C"))
        // f-holes: curved inlaid slits either side of the bridge.
        for s: Float in [-1, 1] {
            let pts: [V3] = ([(0.026, 0.150), (0.031, 0.168), (0.0275, 0.186), (0.0305, 0.205), (0.0395, 0.220), (0.0415, 0.232)] as [(Float, Float)]).map { V3(s * $0.0, 0.0138, $0.1) }
            let f = catmull(pts, per: 6)
            put(Prim.tube(f, radii: f.indices.map { (i: Int) -> Float in 0.0017 - 0.0006 * abs(Float(i) / Float(f.count) - 0.5) }, sides: 8, seamTile: 0.01, material: "plastic.matte:060606"))
            put(Prim.cylinder(radius: 0.0030, height: 0.003, bevel: 0.0005, segments: 16, material: "plastic.matte:060606"), Xform(translation: V3(s * 0.0255, 0.0132, 0.148)))
            put(Prim.cylinder(radius: 0.0030, height: 0.003, bevel: 0.0005, segments: 16, material: "plastic.matte:060606"), Xform(translation: V3(s * 0.0415, 0.0128, 0.2335)))
        }
        // Neck: tapered round shaft carrying the fingerboard wedge.
        let neckZ: [Float] = [0.020, -0.010, -0.040, -0.070, -0.100, -0.126]
        let neck = neckZ.map { V3(0, 0.0095 - 0.0120 * (0.020 - $0) / 0.146, $0) }
        put(Prim.tube(neck, radii: [0.0118, 0.0116, 0.0112, 0.0108, 0.0105, 0.0102], sides: 32, seamTile: 0.03, material: maple))
        let fb = (0...14).map { k -> V3 in let z = -0.128 + 0.268 * Float(k) / 14; return V3(0, 0.0105 + 0.025 * (z + 0.130) / 0.270 - 0.00275, z) }
        put(Prim.sweep(Shape2D.roundedRect(0.0055, 0.024, radius: 0.0016, segments: 3), along: fb, up: .up,
                       scales: (0...14).map { 1 + 0.75 * Float($0) / 14 }, grainAlongPath: true, material: ebony))
        put(Prim.roundedBox(V3(0.024, 0.0042, 0.0035), radius: 0.0012, bevelSegments: 2, material: "plastic.matte:EDE6D2"), Xform(translation: V3(0, 0.0120, -0.1305)))
        // Pegbox: two cheeks, floor and back wall, then the scroll curling over the front.
        for s: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0042, 0.0235, 0.066), radius: 0.0018, bevelSegments: 3, material: maple), Xform(translation: V3(s * 0.0098, 0.0040, -0.1615)))
        }
        put(Prim.roundedBox(V3(0.0225, 0.0045, 0.066), radius: 0.0015, bevelSegments: 2, material: maple), Xform(translation: V3(0, -0.0070, -0.1615)))
        put(Prim.roundedBox(V3(0.0225, 0.0235, 0.005), radius: 0.0015, bevelSegments: 2, material: maple), Xform(translation: V3(0, 0.0040, -0.1915)))
        let c = V2(-0.2060, 0.0060), turns: Float = 2.2, steps = 52
        let spiral = (0...steps).map { k -> V3 in
            let t = Float(k) / Float(steps), phi = t * turns * 2 * .pi, r = 0.0205 * (1 - 0.80 * t)
            return V3(0, c.y + r * sin(phi), c.x + r * cos(phi))
        }
        put(Prim.sweep(Shape2D.roundedRect(0.0075, 0.0200, radius: 0.0025, segments: 2), along: spiral, up: .up,
                       scales: (0...steps).map { 1 - 0.45 * Float($0) / Float(steps) }, material: maple))
        // Pegs: ebony, shaft through the cheeks and a flared head, two a side.
        let peg: [(Float, Float)] = [(0, 0), (0.0027, 0), (0.0031, 0.012), (0.0031, 0.022), (0.0058, 0.0245), (0.0105, 0.029), (0.0112, 0.034), (0.0092, 0.0385), (0, 0.0390)]
        for (s, z, y) in [(-1, -0.150, 0.0040), (-1, -0.173, 0.0040), (1, -0.1615, 0.0040), (1, -0.1835, 0.0040)] as [(Float, Float, Float)] {
            put(turned(peg, segments: 28, material: ebony), Xform(translation: V3(-s * 0.0035, y, z), rotation: simd_quatf(degrees: s > 0 ? -90 : 90, axis: V3(0, 0, 1))))
        }
        // Bridge: maple, carved waist and arched top.
        let br: [V2] = [V2(-0.0205, 0), V2(-0.0150, 0), V2(-0.0115, 0.0055), V2(0.0115, 0.0055), V2(0.0150, 0), V2(0.0205, 0), V2(0.0195, 0.011), V2(0.0170, 0.018),
                        V2(0.0175, 0.0255), V2(0.0140, 0.0315), V2(0, 0.0330), V2(-0.0140, 0.0315), V2(-0.0175, 0.0255), V2(-0.0170, 0.018), V2(-0.0195, 0.011)]
        put(Prim.extrude(br, depth: 0.0035, bevel: 0.0006, bevelSegments: 2, material: "wood.maple-natural:E3C08A"), Xform(translation: V3(0, 0.0155, 0.195)))
        // Tailpiece (ebony) with a gut loop to the end button, chinrest and end button.
        let tp = Shape2D.rounded([V2(-0.0105, -0.232), V2(0.0105, -0.232), V2(0.0185, -0.335), V2(-0.0185, -0.335)], radius: 0.006, segments: 6)
        put(Prim.extrude(tp, depth: 0.0095, bevel: 0.0020, bevelSegments: 3, material: ebony),
            Xform(translation: V3(0, 0.0125 + 0.0048, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        let loop = catmull([V3(0, 0.0170, 0.330), V3(0, 0.0110, 0.345), V3(0, -0.0060, 0.354), V3(0, -0.0140, 0.352)], per: 6)
        put(Prim.tube(loop, radii: loop.map { _ in 0.0011 }, sides: 8, seamTile: 0.01, material: "plastic.matte:D8CDB0"))
        put(turned([(0, -0.002), (0.0046, -0.002), (0.0052, 0.002), (0.0048, 0.008), (0.0088, 0.012), (0.0094, 0.016), (0.0074, 0.020), (0, 0.0205)], segments: 32, material: ebony),
            Xform(translation: V3(0, -0.0140, 0.350), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        put(Prim.superellipsoid(V3(0.088, 0.024, 0.078), exponent: 3, subdivisions: 9, material: ebony), Xform(translation: V3(0.058, 0.0270, 0.287)))
        // Strings, G D A E: wound and plain steel, nut to tailpiece over the bridge.
        let mats: [MaterialKey] = ["metal.tinned-copper", "metal.nickel", "metal.satin-aluminum", "metal.steel"]
        for (i, mat) in mats.enumerated() {
            let f = Float(i) - 1.5
            let pts: [V3] = [V3(f * 0.0072, 0.0125, -0.150), V3(f * 0.0072, 0.0125, -0.130), V3(f * 0.0092, 0.0425, 0.140), V3(f * 0.0092, 0.0492, 0.195), V3(f * 0.0058, 0.0262, 0.240), V3(f * 0.0058, 0.0240, 0.320)]
            put(Prim.tube(pts, radii: pts.map { _ in i < 2 ? 0.00048 : 0.00036 }, sides: 8, seamTile: 0.01, material: mat))
        }
        rig.base[0] = m.transformed(Xform())

        // Bow on its own part: pernambuco stick with camber, ebony frog, nickel mounts and ribbon hair.
        var bow = Model(name: "bow")
        let bx: Float = 0.175, by: Float = 0.0055, z0: Float = -0.313, z1: Float = 0.427
        let stick = (0...28).map { k -> V3 in let u = Float(k) / 28; return V3(bx + 0.003 + 0.022 * sin(u * .pi), by, z0 + (z1 - z0) * u) }
        bow.add(Prim.tube(stick, radii: stick.indices.map { (i: Int) -> Float in 0.0033 + 0.0012 * Float(i) / 28 }, sides: 20, seamTile: 0.02, material: "wood.mahogany"))
        let hair = [V3(bx, by, -0.300), V3(bx, by, 0.0), V3(bx, by, 0.368)]
        bow.add(Prim.sweep(Shape2D.roundedRect(0.0100, 0.0016, radius: 0.0007, segments: 2), along: hair, up: .up, material: "fabric.linen:F1EBDC"))
        bow.add(Prim.roundedBox(V3(0.0085, 0.0125, 0.034), radius: 0.003, bevelSegments: 3, material: "plastic.matte:EDE6D2"), Xform(translation: V3(bx + 0.001, by, z0 + 0.010)))
        bow.add(Prim.roundedBox(V3(0.0125, 0.0135, 0.058), radius: 0.003, bevelSegments: 3, material: ebony), Xform(translation: V3(bx + 0.0015, by, 0.378)))
        bow.add(Prim.roundedBox(V3(0.0132, 0.0142, 0.010), radius: 0.002, bevelSegments: 2, material: "metal.nickel"), Xform(translation: V3(bx + 0.0015, by, 0.398)))
        bow.add(turned([(0, 0), (0.0046, 0), (0.0048, 0.004), (0.0048, 0.020), (0.0040, 0.0215), (0, 0.0220)], segments: 24, material: ebony),
                Xform(translation: V3(bx + 0.003, by, 0.405), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        bow.add(turned([(0.0049, 0.0010), (0.0053, 0.0022), (0.0053, 0.0050), (0.0049, 0.0062)], segments: 24, material: "metal.nickel"),
                Xform(translation: V3(bx + 0.003, by, 0.410), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        let pivot = V3(bx, by, 0.057)
        rig.part("bow", pivot: pivot, joint: .slide(axis: V3(0, 0, 1), -0.12...0.12))
        rig.set(bow, part: "bow", lod: 0)
        rig.states = [RigState("rest"), RigState("stroke", ["bow": 0.10])]
        return rig
    }
}

private extension Xform {
    /// self applied after `x`: `x` first, then `self`.
    func then2(_ x: Xform) -> Xform {
        Xform(translation: translation + x.translation, rotation: x.rotation, scale: x.scale)
    }
}
