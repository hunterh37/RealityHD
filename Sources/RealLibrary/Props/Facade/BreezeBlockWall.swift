import simd
import Foundation

/// Mid-century breeze block wall: twelve courses of painted pierced concrete screen blocks in stack bond,
/// alternating circle and quatrefoil openings, set in recessed mortar between two galvanized steel
/// reinforcing posts, on a concrete plinth under a cap course. Wall plane centered on Z, base at y = 0.
public struct BreezeBlockWall: RealAsset {
    public static let id = "breeze-block-wall"
    public static let summary = "Mid-century breeze block wall, 2.4 x 2.4 m: stack-bond pierced screen blocks with circle and quatrefoil openings, steel posts, plinth and cap."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 4.4)

    public var width: Float = 2.4
    public var height: Float = 2.4
    public var depth: Float = 0.2
    public var columns = 12
    public var courses = 12
    public var plinth: Float = 0.08
    public var cap: Float = 0.05
    public var post: Float = 0.06
    public var paint: MaterialKey = "paint.stucco:EEE9DC"
    public var paintGrimy: MaterialKey = "paint.stucco:D3CCBA"
    public var accent: MaterialKey = "paint.stucco:6FB3AE"
    public var mortar: MaterialKey = "concrete.rough"
    public var concrete: MaterialKey = "concrete.smooth"
    public var steel: MaterialKey = "metal.galvanized"
    public init() {}

    private func circleBlock(_ b: Float, _ d: Float, r: Float, mat: MaterialKey) -> Surface {
        pierced(b, d, r: r, n: 12, mat: mat) { _ in 1 }
    }
    private func quatrefoil(_ b: Float, _ d: Float, r: Float, mat: MaterialKey) -> Surface {
        pierced(b, d, r: r, n: 18, mat: mat) { a in 0.5 + 0.5 * pow(abs(cos(2 * a)), 0.8) }
    }
    /// Square block outline with an opening joined to the bottom edge by a 4 mm casting slit (extrude has no holes).
    private func pierced(_ b: Float, _ d: Float, r: Float, n: Int, mat: MaterialKey, radius k: (Float) -> Float) -> Surface {
        let h = b / 2, s: Float = 0.002
        var pts: [V2] = [V2(s, -h), V2(h, -h), V2(h, h), V2(-h, h), V2(-h, -h), V2(-s, -h)]
        let dl = asin(s / r)
        for i in 0..<n {
            let a = -Float.pi / 2 - dl - (2 * Float.pi - 2 * dl) * Float(i) / Float(n - 1)
            pts.append(V2(r * k(a) * cos(a), r * k(a) * sin(a)))
        }
        return Prim.extrude(Shape2D.deduped(pts), depth: d, bevel: 0, bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, D = depth
        let pw = (W - 2 * post) / Float(columns)
        let ph = (H - plinth - cap) / Float(courses)
        let bw = pw - 0.006, bh = ph - 0.006
        let bs = min(bw, bh)

        // Plinth, cap course, back mortar bed.
        FA.box(&m, V3(W, plinth, D), V3(0, plinth / 2, 0), "masonry.cmu", r: 0.004)
        FA.box(&m, V3(W - 2 * post, cap, D), V3(0, H - cap / 2, 0), concrete, r: 0.004)
        FA.box(&m, V3(W - 2 * post - 0.01, 0.004, D), V3(0, H - cap - 0.002, 0), concrete, r: 0.001)
        // Mortar beds and heads as plain prisms (cheap), recessed 4 mm from the block faces, horizontal beds and vertical heads.
        for r in 0...courses {
            let y = plinth + Float(r) * ph
            m.add(Prim.extrude([V2(-0.5, -0.003), V2(0.5, -0.003), V2(0.5, 0.003), V2(-0.5, 0.003)].map { V2($0.x * (W - 2 * post), $0.y) }, depth: D - 0.008, bevel: 0, material: mortar), Xform(translation: V3(0, y, 0)))
        }
        for c in 1..<columns {
            let x = -W / 2 + post + Float(c) * pw
            m.add(Prim.extrude([V2(-0.003, 0), V2(0.003, 0), V2(0.003, H - plinth - cap), V2(-0.003, H - plinth - cap)], depth: D - 0.008, bevel: 0, material: mortar), Xform(translation: V3(x, plinth, 0)))
        }

        // Blocks: circle and quatrefoil alternating in a checkerboard; a turquoise accent diagonal and a grimy few.
        let accents: Set<Int> = [3 * 12 + 3, 4 * 12 + 4, 5 * 12 + 5, 6 * 12 + 6, 7 * 12 + 7, 8 * 12 + 8]
        for r in 0..<courses {
            for c in 0..<columns {
                let isCircle = (r + c) % 2 == 0
                let idx = r * columns + c
                var mat = paint
                if accents.contains(idx) { mat = accent }
                else {
                    let dirt: Float = r < 2 ? 0.75 : (r < 4 ? 0.35 : 0.1)
                    if rng.chance(dirt) { mat = rng.chance(0.5) ? paintGrimy : "paint.stucco:BDB49C" }
                    else if r < 3 && rng.chance(0.12) { mat = "paint.stucco:A9B08F" }   // algae at the splash zone
                    else if rng.chance(0.03) { mat = concrete }                          // paint spalled to bare concrete
                }
                let blk = isCircle ? circleBlock(bs, D, r: bs * 0.4, mat: mat) : quatrefoil(bs, D, r: bs * 0.45, mat: mat)
                let x = -W / 2 + post + (Float(c) + 0.5) * pw
                let y = plinth + (Float(r) + 0.5) * ph
                m.add(blk, Xform(translation: V3(x, y, 0)))
            }
        }

        // Galvanized steel posts: square tube with base plate, anchor bolts and cap plate, ties to the wall.
        for s: Float in [-1, 1] {
            let x = s * (W / 2 - post / 2)
            FA.box(&m, V3(post, H - plinth - 0.02, D - 0.02), V3(x, plinth + (H - plinth - 0.02) / 2 + 0.005, 0), steel, r: 0.005)
            FA.box(&m, V3(post, 0.012, D), V3(x, plinth + 0.006, 0), steel, r: 0.003)
            FA.box(&m, V3(post, 0.012, D), V3(x, H - 0.006 - 0.01, 0), steel, r: 0.003)
            for bx: Float in [-1, 1] {
                for bz: Float in [-1, 1] {
                    FA.cylZ(&m, r: 0.007, h: 0.008, at: V3(x + bx * 0.02, plinth + 0.012 + 0.004, bz * 0.088 + 0.0), steel, bevel: 0.001, segments: 6)
                }
            }
            // weld seam bead down the post front
            FA.rod(&m, V3(x - post / 2 + 0.003, plinth + 0.05, D / 2 - 0.008), V3(x - post / 2 + 0.003, H - 0.1, D / 2 - 0.008), r: 0.002, steel, sides: 5)
        }
        // Weathering: dark rain streaks under the cap, rust bleed from the post base plates.
        for _ in 0..<7 {
            let x = rng.float(-1.0...1.0)
            let len = rng.float(0.2...0.5)
            FA.box(&m, V3(0.018, len, 0.002), V3(x, H - cap - len / 2, D / 2 + 0.0005), "paint.stucco:8F897B", r: 0.0005)
        }
        for s: Float in [-1, 1] {
            let x = s * (W / 2 - post / 2)
            FA.box(&m, V3(0.03, 0.25, 0.002), V3(x, plinth + 0.012 + 0.125, D / 2 + 0.0005), "paint.stucco:8A5A3A", r: 0.0005)
        }

        groundAO(&m, height: 0.15, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
