import simd
import Foundation

/// 36 in neo-angle corner shower: pentagon acrylic tray with curb and sloped floor, two fixed frameless glass
/// panels and a diagonal hinged door with a pull, chrome wall channels and hinges, round drain, fixed shower
/// head on an arm, valve with lever and a corner shelf. Walls at the back-left corner (-X, -Z); the door faces
/// +X +Z. Glass tops at 2.0 m.
public struct CornerShower: RealAsset {
    public static let id = "corner-shower"
    public static let summary = "36 in neo-angle corner shower: pentagon acrylic tray, three frameless glass panels with chrome hinges and pull, wall channels, shower head and valve."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "glass", "interior"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 14, distance: 3.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.9, 2.0, 0.9)
    public var tray: MaterialKey = "ceramic.vitreous"
    public var glass: MaterialKey = "glass.shelter"
    public var chrome: MaterialKey = "metal.chrome"
    /// Tray curb height.
    public var curb: Float = 0.05
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let h = size.x / 2                      // 0.45
            // Pentagon plan, counter-clockwise from above in (x, -z): wall corner A at back-left.
            let pent: [V2] = [V2(-h, h), V2(-h, -h), V2(-0.15, -h), V2(h, 0.15), V2(h, h)]
            func ring(_ inset: Float, _ y: Float) -> [V3] {
                let p = Shape2D.rounded(Shape2D.offset(pent, -inset), radius: 0.03, segments: hi ? 3 : 2)
                return Prim.ring(p, y: y)
            }
            let t = curb
            let rows: [[V3]] = [ring(0.012, 0), ring(0.0, 0.012), ring(0.0, t - 0.006), ring(0.004, t), ring(0.034, t), ring(0.045, t - 0.012), ring(0.09, 0.03), ring(0.2, 0.018)]
            m.add(Prim.loft(Array(rows[0...3]), capStart: true, material: tray))
            m.add(Prim.loft(Array(rows[3...]), capEnd: true, material: tray))
            // Drain with grate (low point of the floor).
            let dc = V3(-0.12, 0.018, -0.12)
            m.add(Prim.lathe([V2(0.001, 0.0005), V2(0.052, 0.0005), V2(0.056, 0.002), V2(0.05, 0.0045), V2(0.001, 0.0045)], segments: hi ? 26 : 12, seamTile: 0.05, material: "metal.stainless"), Xform(translation: dc))
            if hi {
                for r in [0.015, 0.032] as [Float] {
                    m.add(Prim.lathe([V2(r - 0.0025, 0.0043), V2(r + 0.0025, 0.0043), V2(r + 0.0025, 0.0055), V2(r - 0.0025, 0.0055)], segments: 24, seamTile: 0.05, material: "plastic.black"), Xform(translation: dc))
                }
            }
            // Glass: back return B-C, door C-D (hinged at C), front return D-E, 8 mm, bottom at the curb.
            let gb = t + 0.002, gt = size.y, gh = gt - gb, gy = (gb + gt) / 2
            let th: Float = 0.008
            // Panel 1 along z at x = +h.
            m.add(Prim.roundedBox(V3(th, gh, 0.3 - 0.006), radius: 0.0012, bevelSegments: 1, material: glass), Xform(translation: V3(h - th / 2, gy, -0.3 + 0.0)))
            // Panel 2 along x at z = +h.
            m.add(Prim.roundedBox(V3(0.3 - 0.006, gh, th), radius: 0.0012, bevelSegments: 1, material: glass), Xform(translation: V3(-0.3, gy, h - th / 2)))
            // Door on the diagonal C(0.45, -0.15) to D(-0.15, 0.45), 9 mm gaps at each end.
            let n = V3(1, 0, 1) / sqrt(2)
            let doorLen: Float = 0.6 * sqrt(2) - 0.018
            let mid = V3(0.15, 0, 0.15) - n * (th / 2)
            let rotDoor = simd_quatf(degrees: -135, axis: .up)
            m.add(Prim.roundedBox(V3(doorLen, gh - 0.004, th), radius: 0.0012, bevelSegments: 1, material: glass), Xform(translation: V3(mid.x, gy, mid.z), rotation: rotDoor))
            // Dried soap and hard-water runs on the inside of the door (decal strips), plus a scum ring at the drain.
            if hi {
                var rng = SeededRNG(seed: seed)
                var runs = Surface(material: "decal.soap-residue")
                let alongD = V3(-1, 0, 1) / sqrt(2)
                let inward = -n * (th / 2 + 0.0006)
                for _ in 0..<12 {
                    let u = rng.float(-0.34...0.34), len = rng.float(0.08...0.42), w = rng.float(0.003...0.009), y0 = rng.float((gb + 0.02)...(gb + 0.9))
                    let p0 = mid + inward + alongD * u + V3(0, y0, 0)
                    let a = runs.add(p0, -n, V2(0, 0)), b = runs.add(p0 + alongD * w, -n, V2(1, 0)), c = runs.add(p0 + alongD * w + V3(0, len, 0), -n, V2(1, 1)), d = runs.add(p0 + V3(0, len, 0), -n, V2(0, 1))
                    runs.quad(a, d, c, b)
                }
                runs.computeTangents()
                m.add(runs)
                m.add(Prim.lathe([V2(0.0565, 0.0003), V2(0.1, 0.0003), V2(0.102, 0.0007), V2(0.0565, 0.0007)], segments: 28, seamTile: 0.05, material: "plastic.matte:D4C8B0"), Xform(translation: dc))
            }
            // Pull handle: vertical bar on the door face, outward normal n.
            let rotPull = simd_quatf(degrees: 45, axis: .up) * simd_quatf(degrees: 90, axis: V3(0, 0, 1))
            let along = V3(-1, 0, 1) / sqrt(2)                 // from C toward D
            let pullPos = V3(0.15, 0, 0.15) + n * 0.0 + along * 0.32
            m.add(BathFit.pull(length: 0.4, standoff: 0.04, radius: 0.0075, overhang: 0.03, material: chrome), Xform(translation: V3(pullPos.x, 1.0, pullPos.z), rotation: rotPull))
            // Wall channels at B and E, glass-to-glass hinges at C, magnetic strip at D.
            m.add(Prim.roundedBox(V3(0.02, gh, 0.02), radius: 0.004, bevelSegments: 1, material: chrome), Xform(translation: V3(h - 0.01, gy, -h + 0.01)))
            m.add(Prim.roundedBox(V3(0.02, gh, 0.02), radius: 0.004, bevelSegments: 1, material: chrome), Xform(translation: V3(-h + 0.01, gy, h - 0.01)))
            let cPt = V3(h - 0.004, 0, -0.15 + 0.0), dPt = V3(-0.15, 0, h - 0.004)
            for y in [gb + 0.25, gt - 0.25] {
                m.add(Prim.roundedBox(V3(0.034, 0.1, 0.03), radius: 0.006, bevelSegments: hi ? 2 : 1, material: chrome), Xform(translation: V3(cPt.x - 0.012, y, cPt.z + 0.012), rotation: simd_quatf(degrees: -45, axis: .up)))
            }
            m.add(Prim.roundedBox(V3(0.012, gh - 0.01, 0.012), radius: 0.003, bevelSegments: 1, material: "plastic.matte:E8ECEC"), Xform(translation: V3(dPt.x + 0.002, gy, dPt.z - 0.004), rotation: simd_quatf(degrees: -45, axis: .up)))
            // Chrome base channels under the fixed panels, and a stabilizer bar from the wall to the top of the back return.
            m.add(Prim.roundedBox(V3(0.022, 0.026, 0.3 - 0.004), radius: 0.004, bevelSegments: 1, material: chrome), Xform(translation: V3(h - 0.011, t + 0.013, -0.3)))
            m.add(Prim.roundedBox(V3(0.3 - 0.004, 0.026, 0.022), radius: 0.004, bevelSegments: 1, material: chrome), Xform(translation: V3(-0.3, t + 0.013, h - 0.011)))
            m.add(Prim.tube([V3(h - 0.004, gt - 0.06, -0.3), V3(h - 0.1, gt - 0.06, -h + 0.012), V3(-0.1, gt - 0.06, -h + 0.012)], radii: [0.0075, 0.0075, 0.0075], sides: hi ? 10 : 6, seamTile: 0.04, material: chrome))
            // Bottom sweep strip under the door.
            m.add(Prim.roundedBox(V3(doorLen, 0.014, 0.004), radius: 0.001, bevelSegments: 1, material: "plastic.matte:DCE0E0"), Xform(translation: V3(mid.x, gb + 0.007, mid.z), rotation: rotDoor))
            // Wall plumbing on the back wall (z = -h), facing +Z.
            BathFit.showerHead(&m, wall: V3(-0.2, 1.9, -h), reach: 0.2, headRadius: 0.085, hi: hi)
            BathFit.valveTrim(&m, at: V3(-0.2, 1.05, -h), hi: hi)
            // Corner shelf: triangular glass-and-chrome quarter shelf at the wall corner.
            let shelf: [V2] = [V2(0, 0), V2(0.26, 0), V2(0.0, 0.26)]
            m.add(Prim.extrude(shelf, depth: 0.012, bevel: 0.002, bevelSegments: 1, material: "glass.frosted"),
                  Xform(translation: V3(-h, 1.35, -h), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            groundAO(&m, height: 0.2, floor: 0.7)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
