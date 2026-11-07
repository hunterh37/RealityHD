import simd
import Foundation

/// Giant inflatable rubber duck, 18 m tall, 14 m long: a smooth body and head (each a 128x64 deformed sphere) in glossy PVC
/// with tail lift, wing swells, faint skin wrinkles and welded seam tubes, a wide flat orange bill with a darker lower bill and lip
/// seam, nostrils, and painted black eyes with white catchlights. Deflation adds a heavy wrinkle shell over the body.
/// Origin at the waterline under the body centre, bill toward +Z, up +Y.
/// Joints: `bob` -1...1 (whole duck pitches 8 degrees, positive dips the bill), `head` -1...1 (head yaw 30 degrees, positive
/// toward +X), `squash` 0...1 (body squash: the duck compresses 15 percent of its height into the water), `deflate` 0...1
/// (body sags 4.5 m, head bows 38 degrees and drops 3.5 m, wrinkle shell appears: half height at 1).
public struct GiantRubberDuck: RealArticulated {
    public static let id = "giant-rubber-duck"
    public static let summary = "Giant inflatable rubber duck, 18 m tall: glossy yellow PVC body and head with seams and faint wrinkles, flat orange bill with lip seam, painted black eyes with catchlights, joints bob, head, squash, deflate."
    public static let tags = ["prop", "toy", "water", "articulated"]
    public static let budget = 70_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 8, distance: 1.05)

    /// Vinyl skin (clearcoat PVC, warm tint).
    public var skin: MaterialKey = "plastic.gloss:FFCB12"
    /// Welded seam tubes.
    public var seam: MaterialKey = "plastic.gloss:F0B80E"
    /// Upper bill.
    public var bill: MaterialKey = "plastic.gloss:FF7410"
    /// Lower bill and nostrils.
    public var billDark: MaterialKey = "plastic.gloss:D2540A"
    /// Lip seam between the bills.
    public var lip: MaterialKey = "plastic.gloss:8C3304"
    /// Painted eyes.
    public var eye: MaterialKey = "plastic.gloss:050506"
    /// Eye catchlights.
    public var catchlight: MaterialKey = "plastic.gloss:FFFFFF"
    public init() {}

    // MARK: Shapes

    private static let bodyCenter = V3(0, 3.2, 0)
    private static let headCenter = V3(0, 14.6, 2.9)
    private static let headAxes = V3(3.25, 3.4, 3.4)

    private static func sstep(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Faint pillow wrinkles as a signed fraction of radius.
    private static func wrinkle(_ d: V3, _ amp: Float) -> Float {
        amp * (sin(d.x * 9 + d.y * 7) * sin(d.z * 8 - d.y * 5) + 0.6 * sin(d.y * 17 + d.z * 11) * sin(d.x * 13 + 2))
    }

    /// Body surface point for a unit direction. `heavy` > 0 gives the deflated shell: outward-only folds.
    private static func body(_ d: V3, heavy: Float = 0) -> V3 {
        let tz = max(-d.z, 0), t3 = tz * tz * tz
        var lx = d.x * 5.6 * (1 - 0.30 * t3)
        var ly = (d.y >= 0 ? d.y * 5.0 : d.y * 3.6) + 3.4 * t3
        var lz = d.z * 7.2 - 0.6 * t3
        var k: Float = 1
        for s: Float in [1, -1] {
            let c = simd_normalize(V3(s * 0.92, 0.25, -0.15))
            k += 0.05 * exp(-simd_length_squared(d - c) / 0.10)            // wing swell
        }
        k += wrinkle(d, 0.006)
        if heavy > 0 {
            let f = 0.5 + 0.5 * sin(d.x * 21 + d.z * 6 + sin(d.y * 9) * 2) * sin(d.z * 17 - d.x * 5 + d.y * 12)
            k += 0.012 + heavy * f * (0.5 + 0.5 * d.y)
        }
        lx *= k; ly *= k; lz *= k
        return bodyCenter + V3(lx, ly, lz)
    }

    private static func head(_ d: V3) -> V3 {
        var x = d.x * headAxes.x, y = d.y * headAxes.y, z = d.z * headAxes.z
        x *= 1 + 0.06 * exp(-pow(d.y + 0.25, 2) / 0.12) * exp(-pow(d.z, 2) / 0.4)     // cheeks
        if d.y < 0 { y *= 0.9 }
        let k = 1 + wrinkle(d, 0.004)
        return headCenter + V3(x * k, y * k, z * k)
    }

    /// Latitude/longitude grid over a unit-sphere deformation. u runs around from +Z, v from the top pole.
    private static func grid(rows: Int, cols: Int, uv: V2, material: MaterialKey, _ pos: (V3) -> V3) -> Surface {
        var s = Surface(material: material)
        var pts: [V3] = []
        for i in 0...rows {
            let th = Float.pi * Float(i) / Float(rows)
            for k in 0...cols {
                let ph = 2 * Float.pi * Float(k) / Float(cols)
                let d = V3(sin(th) * sin(ph), cos(th), sin(th) * cos(ph))
                let p = pos(d)
                pts.append(p)
                s.add(p, .up, V2(Float(k) / Float(cols) * uv.x, Float(i) / Float(rows) * uv.y))
            }
        }
        let row = cols + 1
        let centroid = pts.reduce(V3.zero, +) / Float(pts.count)
        let m = (rows / 2) * row + cols / 8
        let n = simd_cross(pts[m + 1] - pts[m], pts[m + row] - pts[m])
        let flip = simd_dot(n, pts[m] - centroid) < 0
        for i in 0..<rows { for k in 0..<cols {
            let a = UInt32(i * row + k), b = a + 1, c = a + UInt32(row) + 1, d = a + UInt32(row)
            if flip { s.quad(a, d, c, b) } else { s.quad(a, b, c, d) }
        }}
        s.recomputeNormals(weldSeams: true)
        s.computeTangents()
        return s
    }

    private static func smooth(_ pts: [V3], radii: [Float], count: Int) -> (path: [V3], r: [Float]) {
        var path: [V3] = [], r: [Float] = []
        let segs = pts.count - 1
        for i in 0..<count {
            let tt = Float(i) / Float(count - 1) * Float(segs)
            let k = min(Int(tt), segs - 1), t = tt - Float(k)
            let p0 = pts[max(0, k - 1)], p1 = pts[k], p2 = pts[k + 1], p3 = pts[min(pts.count - 1, k + 2)]
            let t2 = t * t, t3 = t2 * t
            path.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
            r.append(radii[k] + (radii[k + 1] - radii[k]) * t)
        }
        return (path, r)
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [60])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        // Drivers first so mimics resolve.
        _ = rig.part("bob", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 1.6))
        _ = rig.part("head", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 1.1))
        _ = rig.part("squash", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.35))
        _ = rig.part("deflate", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 3.0))

        let neckPivot = V3(0, 12.5, 2.9)
        // Positive rotation about +X dips the bill; positive slide moves down.
        _ = rig.part("hull", pivot: .zero, joint: Joint(.revolute, axis: X, range: -8...8, mimic: .init("bob", ratio: 8)))
        _ = rig.part("squashSlide", parent: "hull", pivot: .zero, joint: Joint(.prismatic, axis: -Y, range: 0...1.1, mimic: .init("squash", ratio: 1.1)))
        _ = rig.part("sag", parent: "squashSlide", pivot: .zero, joint: Joint(.prismatic, axis: -Y, range: 0...4.5, mimic: .init("deflate", ratio: 4.5)))
        _ = rig.part("wrinkles", parent: "sag", pivot: .zero, joint: .fixed, options: 2)
        _ = rig.part("headDrop", parent: "sag", pivot: .zero, joint: Joint(.prismatic, axis: -Y, range: 0...3.5, mimic: .init("deflate", ratio: 3.5)))
        _ = rig.part("headYaw", parent: "headDrop", pivot: neckPivot, joint: Joint(.revolute, axis: Y, range: -30...30, mimic: .init("head", ratio: 30)))
        _ = rig.part("headBow", parent: "headYaw", pivot: neckPivot, joint: Joint(.revolute, axis: X, range: 0...38, mimic: .init("deflate", ratio: 38)))
        rig.optionLinks = [RigOptionLink(part: "wrinkles", joint: "deflate", thresholds: [0.05])]

        let rows = [64, 32], cols = [128, 64], shell = [(48, 96), (24, 48)]
        let sub = [24, 12], eyeSub = [6, 4]

        for l in 0..<2 {
            // Body and head: deformed spheres.
            rig.add(Self.grid(rows: rows[l], cols: cols[l], uv: V2(22, 12), material: skin) { Self.body($0) }, to: "sag", lods: l...l)
            rig.add(Self.grid(rows: rows[l], cols: cols[l], uv: V2(12, 8), material: skin) { Self.head($0) }, to: "headBow", lods: l...l)
            rig.add(Self.grid(rows: shell[l].0, cols: shell[l].1, uv: V2(22, 12), material: skin) { Self.body($0, heavy: 0.07) },
                    to: "wrinkles", option: 1, lods: l...l)

            // Neck: flared base into the head, part of the body.
            let neck = Self.smooth([V3(0, 6.0, 2.0), V3(0, 8.5, 2.5), V3(0, 11.0, 2.8), V3(0, 13.5, 2.9)], radii: [4.3, 3.2, 2.7, 2.7], count: [16, 8][l])
            rig.add(Prim.tube(neck.path, radii: neck.r, sides: [64, 32][l], seamTile: 0.5, material: skin), to: "sag", lods: l...l)

            // Welded seams: sagittal and waist loops on the body, sagittal loop over the head.
            let nS = [160, 80][l], sides = [12, 6][l]
            func offset(_ p: V3, _ c: V3, _ o: Float) -> V3 { p + simd_normalize(p - c) * o }
            var loop: [V3] = [], waist: [V3] = [], hl: [V3] = []
            for i in 0...nS {
                let a = 2 * Float.pi * Float(i) / Float(nS)
                let d1 = V3(0, sin(a), cos(a))
                let p1 = Self.body(d1)
                if p1.y > 1.0 { loop.append(offset(p1, Self.bodyCenter, 0.03)) }
                let c: Float = (1 - 0.0144 as Float).squareRoot()
                let d2 = V3(c * sin(a), 0.12, c * cos(a))
                waist.append(offset(Self.body(d2), Self.bodyCenter, 0.03))
                let d3 = V3(0, sin(a), cos(a))
                if d3.z < 0.35 || d3.y > 0.4 { hl.append(offset(Self.head(d3), Self.headCenter, 0.025)) }
            }
            let hs = hl.filter { $0.z < Self.headCenter.z + 2.6 }
            for path in [loop, waist] where path.count > 2 {
                rig.add(Prim.tube(path, radii: path.map { _ in 0.07 }, sides: sides, seamTile: 0.2, material: seam, capEnd: false), to: "sag", lods: l...l)
            }
            if hs.count > 2 {
                rig.add(Prim.tube(hs, radii: hs.map { _ in 0.06 }, sides: sides, seamTile: 0.2, material: seam, capEnd: false), to: "headBow", lods: l...l)
            }

            // Bill: wide flat upper, darker lower, dark lip seam between, two nostrils.
            let tilt = simd_quatf(angle: -0.12, axis: X)
            rig.add(Prim.superellipsoid(V3(4.2, 1.3, 3.6), exponent: 3, subdivisions: sub[l], material: bill),
                    Xform(translation: V3(0, 13.8, 7.3), rotation: tilt), to: "headBow", lods: l...l)
            rig.add(Prim.superellipsoid(V3(3.9, 0.75, 3.2), exponent: 3, subdivisions: sub[l], material: billDark),
                    Xform(translation: V3(0, 13.05, 7.1), rotation: tilt), to: "headBow", lods: l...l)
            rig.add(Prim.superellipsoid(V3(4.22, 0.1, 3.62), exponent: 3, subdivisions: sub[l], material: lip),
                    Xform(translation: V3(0, 13.5, 7.25), rotation: tilt), to: "headBow", lods: l...l)
            for s: Float in [1, -1] {
                rig.add(Prim.superellipsoid(V3(0.35, 0.2, 0.7), exponent: 2, subdivisions: eyeSub[l], material: billDark),
                        Xform(translation: V3(s * 0.8, 14.42, 8.3), rotation: tilt), to: "headBow", lods: l...l)
            }

            // Painted eyes with catchlights, tangent to the head surface.
            for s: Float in [1, -1] {
                let d = simd_normalize(V3(s * 0.55, 0.28, 0.78))
                let p = Self.head(d)
                let a = Self.headAxes
                let n = simd_normalize(V3(d.x / (a.x * a.x), d.y / (a.y * a.y), d.z / (a.z * a.z)))
                let rot = simd_quatf(from: Z, to: n)
                let c = p - n * 0.08
                rig.add(Prim.superellipsoid(V3(1.0, 1.5, 0.5), exponent: 2, subdivisions: [10, 6][l], material: eye),
                        Xform(translation: c, rotation: rot), to: "headBow", lods: l...l)
                rig.add(Prim.superellipsoid(V3(0.28, 0.34, 0.08), exponent: 2, subdivisions: [6, 4][l], material: catchlight),
                        Xform(translation: c + rot.act(V3(-s * 0.17, 0.4, 0.18)), rotation: rot), to: "headBow", lods: l...l)
            }
        }

        rig.states = [
            RigState("rest"),
            RigState("bob-down", ["bob": 1]),
            RigState("bob-up", ["bob": -1]),
            RigState("look-left", ["head": -1]),
            RigState("look-right", ["head": 1]),
            RigState("squeak", ["squash": 1, "head": 1]),
            RigState("deflated", ["deflate": 1, "bob": 0.5], options: ["wrinkles": 1]),
        ]
        return rig
    }
}
