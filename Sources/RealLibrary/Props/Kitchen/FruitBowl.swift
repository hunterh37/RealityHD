import simd
import Foundation

/// Fruit bowl, 32 x 16 cm: a thick-walled glazed stoneware bowl on a turned foot ring (31.6 cm rim, 7.8 cm tall) holding five apples
/// with stems, three lemons and a banana bunch laid over the heap. Fruit is placed by a small contact solver against the bowl wall,
/// so every apple and lemon rests on the glaze or on the fruit below it. Parts: wide stoneware bowl on a foot, apples with stems,
/// lemons, banana bunch draped over the rim.
public struct FruitBowl: RealAsset {
    public static let id = "fruit-bowl"
    public static let summary = "Stoneware fruit bowl with apples, lemons and a banana bunch over the rim."
    public static let tags = ["prop", "floorplan", "kitchen", "ceramic", "decor", "interior", "food"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 32, distance: 0.75, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.32, 0.16, 0.32)
    /// Outer radius of the bowl rim (m).
    public var rimRadius: Float = 0.158
    /// Height of the rim above the table (m).
    public var rimHeight: Float = 0.078
    /// Stoneware wall thickness (m).
    public var wall: Float = 0.0055
    /// Bowl glaze and the unglazed foot ring.
    public var glaze: MaterialKey = "ceramic.stoneware:D6CCB6"
    public var foot: MaterialKey = "ceramic.stoneware:9C7B5C"
    /// Dipped glaze band on the outer rim.
    public var rimGlaze: MaterialKey = "ceramic.stoneware:8A6B4A"
    /// Apple skins, one tint per apple in turn.
    public var appleSkins: [MaterialKey] = ["food.tomato:8E1B1B", "food.tomato:A32A20", "food.tomato:7C1A1C", "food.tomato:A8B440", "food.tomato:92241E"]
    /// Lemon skin.
    public var lemonSkin: MaterialKey = "food.lemon"
    /// Banana peel.
    public var bananaPeel: MaterialKey = "food.banana-peel"
    /// Stems and banana crown.
    public var stemKey: MaterialKey = "food.stem-green:5C4326"
    public init() {}

    // MARK: Bowl

    private func outerPoint(_ t: Float) -> V2 {
        let a = t * .pi / 2
        let r0: Float = 0.052, y0: Float = 0.013
        return V2(r0 + (rimRadius - r0) * pow(sin(a), 0.82), y0 + (rimHeight - y0) * (1 - cos(a)))
    }

    /// Inner wall polyline (r, y) from the floor center out to the rim, used by the lathe and the fruit solver.
    private func innerWall() -> [V2] {
        let floorY: Float = 0.019
        var pts: [V2] = [V2(0, floorY)]
        for k in 0...12 {
            let t = Float(k) / 12
            let o = outerPoint(t)
            pts.append(V2(max(0.03, o.x - wall * (1.05 - 0.2 * t)), max(floorY, o.y + wall * (0.9 - 0.6 * t))))
        }
        return pts
    }

    private func bowlSurface(_ seg: Int, _ steps: Int) -> Surface {
        var pts: [V2] = [V2(0, 0.0035), V2(0.034, 0.0032), V2(0.040, 0.0006), V2(0.046, 0), V2(0.0505, 0.0012), V2(0.0515, 0.0045), V2(0.0505, 0.0085)]
        for k in 1...steps { pts.append(outerPoint(Float(k) / Float(steps))) }
        let top = outerPoint(1)
        // Rounded rim lip.
        pts.append(V2(top.x - 0.0006, top.y + 0.0014))
        pts.append(V2(top.x - wall * 0.5, top.y + 0.0022))
        pts.append(V2(top.x - wall + 0.0006, top.y + 0.0012))
        let wallPts = innerWall()
        for p in wallPts.dropFirst().reversed() { pts.append(p) }
        pts.append(V2(0.03, wallPts[0].y))
        pts.append(V2(0.028, wallPts[0].y - 0.004))
        pts.append(V2(0, wallPts[0].y - 0.004))
        var s = Prim.lathe(pts, segments: seg, seamTile: 0.3, material: glaze)
        polarUVs(&s)
        return s
    }

    /// Azimuthal-equidistant UVs: arc length from the axis around each point, no pole pinch and no seam.
    private func polarUVs(_ s: inout Surface) {
        s.uvs = s.positions.map { p in
            let rad = sqrt(p.x * p.x + p.z * p.z), arc = rad + 1.2 * p.y
            let c: Float = rad > 1e-6 ? p.x / rad : 1, sn: Float = rad > 1e-6 ? p.z / rad : 0
            return V2(arc * c, arc * sn)
        }
        s.computeTangents()
    }

    // MARK: Fruit

    private func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = max(0, min(1, (x - a) / (b - a))); return t * t * (3 - 2 * t)
    }

    /// Apple centered on its own origin: shoulders above the equator, dimpled crown and base. Returns the surface and half-height.
    private func apple(_ R: Float, _ H: Float, _ ph: Float, _ edge: Float, _ key: MaterialKey) -> Surface {
        var s = FoodMesh.revolve(edge: edge, seamTile: 0.12, material: key) { t in
            let a = Float.pi * t
            let shoulder = 1 + 0.07 * cos(a) * sin(a) * 1.4
            var y = H * (0.5 - 0.5 * cos(a))
            y -= 0.16 * H * pow(smooth(0.72, 1, 0.5 - 0.5 * cos(a)), 1.6)      // crown cavity
            y += 0.05 * H * pow(smooth(0.78, 1, 0.5 + 0.5 * cos(a)), 1.4)      // shallow base dimple
            return V2(R * sin(a) * shoulder, y - H / 2)
        }
        s.deform { p in
            let a = atan2(p.z, p.x), t = p.y / H
            let k = 1 + 0.025 * sin(2 * a + ph) * (1 - abs(2 * t)) + 0.012 * sin(5 * a + ph * 2)
            return V3(p.x * k, p.y, p.z * k)
        }
        return s
    }

    private func lemon(_ L: Float, _ R: Float, _ ph: Float, _ edge: Float) -> Surface {
        let P: [V2] = [V2(0, 0.0035), V2(R * 0.12, 0.0022), V2(R * 0.3, 0.0035), V2(R * 0.62, L * 0.09), V2(R * 0.88, L * 0.22),
                       V2(R, L * 0.42), V2(R * 0.97, L * 0.6), V2(R * 0.84, L * 0.76), V2(R * 0.56, L * 0.88),
                       V2(R * 0.26, L * 0.94), V2(R * 0.13, L * 0.975), V2(0, L)]
        var s = FoodMesh.revolve(edge: edge, seamTile: 0.05, material: lemonSkin, curve: FoodMesh.profile(P))
        s.deform { p in
            let a = atan2(p.z, p.x), t = p.y / L
            let k = 1 + 0.02 * sin(a * 2 + ph) * sin(.pi * t) + 0.008 * sin(a * 5 + ph * 1.7 + t * 9)
            return V3(p.x * k, p.y - L / 2, p.z * k)
        }
        return s
    }

    /// One banana along `path`, with stem and blossom nub.
    @discardableResult
    private func banana(_ path: [V3], _ R: Float, _ ph: Float, _ edge: Float, _ m: inout Model) -> V3 {
        let peelR: (Float) -> Float = { t in
            let body = pow(sin(.pi * min(1, max(0, t))), 0.55)
            let neck = 0.32 + 0.68 * smoothstep(0, 0.22, t)
            let blossom = 0.5 + 0.5 * (1 - smoothstep(0.82, 1, t))
            return R * max(0.12, body * neck * (0.6 + 0.4 * blossom))
        }
        m.add(RecipeMesh.sweep(path, edge: edge, endBulge: 0.3, seamTile: 0.12, material: bananaPeel) { t, a in
            peelR(t) * (1 + 0.055 * cos(5 * a + ph)) * (1 - 0.06 * sin(a) * sin(a))
        })
        let n = path.count
        let t0 = simd_normalize(path[0] - path[1])
        let stemEnd = path[0] + t0 * 0.03 + V3(0, 0.006, 0)
        m.add(FoodMesh.tube([path[0] - t0 * 0.004, path[0] + t0 * 0.012, stemEnd], radii: [0.0042, 0.0036, 0.0038],
                            sides: 8, endBulge: 0.05, material: stemKey))
        let t1 = simd_normalize(path[n - 1] - path[n - 2])
        var nub = FoodMesh.revolve(edge: 0.002, seamTile: 0.02, material: "food.banana-tip") { t in
            let a = Float.pi * t
            return V2(0.0028 * sin(a), -0.003 + 0.0055 * (0.5 - 0.5 * cos(a)))
        }
        let q = simd_quatf(from: V3(0, 1, 0), to: t1)
        let pe = path[n - 1] + t1 * 0.001
        nub.deform { p in pe + q.act(p) }
        m.add(nub)
        return stemEnd
    }

    /// Lowest center height for a sphere of radius `r` at radial position `x` that clears the inner wall and the spheres in `placed`.
    private func rest(_ wall: [V2], _ r: Float, _ x: Float, _ z: Float, _ placed: [(V3, Float)]) -> Float {
        var y: Float = wall[0].y + r * 0.5
        while y < 0.2 {
            var ok = true
            let rad = sqrt(x * x + z * z)
            for p in wall where simd_distance(V2(rad, y), p) < r * 0.96 && p.y < y { ok = false; break }
            if ok { for (c, cr) in placed where simd_distance(V3(x, y, z), c) < (r + cr) * 0.97 { ok = false; break } }
            if ok { break }
            y += 0.0015
        }
        return y
    }

    public func build(seed: UInt64) -> LODModel {
        func make(_ detail: Bool) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            m.add(bowlSurface(detail ? 64 : 28, detail ? 14 : 8))
            // Darker dipped-glaze band on the outside of the rim.
            var band: [V2] = []
            let nb = detail ? 8 : 4
            for k in 0...nb {
                let t = 1 - 0.2 * Float(nb - k) / Float(nb)
                let o = outerPoint(t)
                band.append(V2(o.x + 0.0007, o.y))
            }
            let bt = outerPoint(1)
            band.append(V2(bt.x - 0.0006, bt.y + 0.0016))
            band.append(V2(bt.x - 0.0028, bt.y + 0.0021))
            var bandS = Prim.lathe(band, segments: detail ? 64 : 28, seamTile: 0.3, material: rimGlaze)
            polarUVs(&bandS)
            m.add(bandS)
            // Interior floor disc with planar UVs, so the glaze does not pinch into rays at the pole.
            var disc = Prim.cylinder(radius: 0.0335, height: 0.0036, bevel: 0, segments: detail ? 40 : 20, material: glaze)
            polarUVs(&disc)
            m.add(disc, Xform(translation: V3(0, innerWall()[0].y - 0.0030, 0)))
            // Foot ring is unglazed clay: a thin disc ring under the glazed base.
            m.add(Prim.torus(major: 0.0465, minor: 0.0028, segments: detail ? 48 : 20, sides: 6, material: foot), Xform(translation: V3(0, 0.0014, 0)))
            let wallPts = innerWall()
            let e: Float = detail ? 0.0074 : 0.012
            var placed: [(V3, Float)] = []
            // Apples: three on the bottom, two in the gaps above.
            let slots: [(Float, Float, Float)] = [(0.083, 15, 0.0375), (0.083, 87, 0.039), (0.083, 159, 0.0365), (0.083, 231, 0.0385), (0.083, 303, 0.037)]
            for (i, sl) in slots.enumerated() {
                let a = (sl.1 + rng.float(-12...12)) * .pi / 180
                let r0 = sl.2
                let h = r0 * rng.float(1.78...1.9)
                let x = sl.0 * cos(a), z = sl.0 * sin(a)
                let y = rest(wallPts, r0, x, z, placed)
                placed.append((V3(x, y, z), r0))
                let s = apple(r0, h, rng.float(0...6.28), e, appleSkins[i % appleSkins.count])
                let q = simd_quatf(degrees: rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(-14...14), axis: V3(1, 0, 0))
                m.add(s, Xform(translation: V3(x, y, z), rotation: q))
                // Stem in the crown cavity (crown is at local +y).
                let top = q.act(V3(0, h / 2 - 0.16 * h * 0.98, 0))
                let tilt = q.act(V3(0.006 * rng.float(-1...1), 0.024, 0.006 * rng.float(-1...1)))
                let sp = V3(x, y, z) + top
                m.add(FoodMesh.tube([sp - tilt * 0.12, sp + tilt * 0.4, sp + tilt * 0.82 + V3(0.003, 0, 0), sp + tilt], radii: [0.0017, 0.0014, 0.0013, 0.0014],
                                    sides: detail ? 7 : 5, endBulge: 0.05, seamTile: 0.01, material: stemKey))
            }
            // Lemons wedge between apples.
            let lem: [(Float, Float, Float, Float)] = [(0.0, 40, 0.0285, 0.076), (0.03, 200, 0.0285, 0.08), (0.045, 330, 0.0285, 0.078)]
            for l in lem {
                let a = (l.1 + rng.float(-8...8)) * .pi / 180
                let x = l.0 * cos(a), z = l.0 * sin(a)
                let y = rest(wallPts, l.2, x, z, placed)
                placed.append((V3(x, y, z), l.2 * 1.05))
                let s = lemon(l.3, l.2, rng.float(0...6.28), detail ? 0.0078 : 0.013)
                let q = simd_quatf(degrees: rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(60...100), axis: V3(0, 0, 1))
                m.add(s, Xform(translation: V3(x, y, z), rotation: q))
            }
            // Banana bunch: three fingers fanned from a shared crown, laid over the heap and draping across the rim on +X.
            let fan: [(Float, Float, Float)] = [(-0.027, 0.0, -0.006), (0.0, 0.026, 0.0), (0.027, 0.004, 0.008)]
            var crown = V3.zero
            for f in fan {
                let zz = f.0, lift = f.1
                let ctrl: [V3] = [V3(-0.03, 0.117 + lift, zz * 0.3), V3(0.02, 0.124 + lift * 0.6, zz * 0.6), V3(0.07, 0.118 + lift * 0.4, zz * 0.9 + f.2),
                                  V3(0.115, 0.104, zz * 1.1 + f.2 * 2), V3(0.148, 0.090, zz * 1.2 + f.2 * 2), V3(0.158, 0.080, zz * 1.2 + f.2 * 3)]
                let path = catmull(ctrl, per: 5)
                crown += banana(path, rng.float(0.0192...0.0208), rng.float(0...6.28), detail ? 0.0098 : 0.015, &m)
            }
            crown /= 3
            // Crown cluster binding the three stems.
            m.add(Prim.superellipsoid(V3(0.02, 0.016, 0.026), exponent: 3, subdivisions: detail ? 2 : 1, material: stemKey), Xform(translation: crown))
            groundAO(&m, height: 0.02, floor: 0.55)
            return m
        }
        return LODModel(levels: [make(true), make(false)], switchDistances: [3])
    }
}
