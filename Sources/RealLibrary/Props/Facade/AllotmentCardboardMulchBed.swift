import simd
import Foundation

/// Allotment cardboard mulch bed: a 2 m square no-dig bed sheet-mulched with flattened brown
/// corrugated boxes laid with generous overlaps. The card has softened and darkened in the wet,
/// edges curl and tear to show the fluting, strips of parcel tape remain, and bricks and stones
/// hold it down. A drift of woodchip has been started at one end and weeds push up at the joins.
public struct AllotmentCardboardMulchBed: RealAsset {
    public static let id = "allotment-cardboard-mulch-bed"
    public static let summary = "2 m square no-dig allotment bed sheet-mulched with weathered corrugated cardboard, weighed down with bricks and stones, part covered in woodchip."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 36, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Soil margin height (m).
    public var base: Float = 0.012
    /// Corrugated board thickness (m).
    public var board: Float = 0.004
    /// Dry kraft card colour.
    public var dryCard: MaterialKey = "paper.screwbox-kraft:8E6C47"
    /// Rain-darkened card colour.
    public var wetCard: MaterialKey = "paper.screwbox-kraft:5E4530"
    /// Soil.
    public var soil: MaterialKey = "ground.dirt:4A3725"
    /// Woodchip pieces in the drift.
    public var chips: Int = 52
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        func ground(_ p: V2) -> Float {
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let k = max(0, min(1, (e - 0.04) / 0.1))
            return base + (0.006 + 0.006 * Noise.fbm(V3(p.x * 3, 0, p.y * 3), octaves: 3, seed: sd)) * k
                + 0.003 * Noise.fbm(V3(p.x * 20, 0, p.y * 20), octaves: 2, seed: sd + 1)
        }
        var m = Model(name: Self.id)
        AK.field(&m, w: w, d: d, base: base, segments: 30, material: soil, ground)

        // Sheets: flattened boxes in three overlapping courses, laid from the far end.
        struct Sheet { var c: V2; var size: V2; var yaw: Float; var layer: Int; var wet: Bool }
        var sheets: [Sheet] = []
        let courses: [Float] = [-0.52, 0.0, 0.5]
        for (ci, cz) in courses.enumerated() {
            var x: Float = -0.7
            var k = 0
            while x < 0.7 {
                var r = rng.fork(ci * 10 + k)
                let sw = r.float(0.5...0.68), sdp = r.float(0.62...0.72)
                sheets.append(Sheet(c: V2(x + r.float(-0.02...0.03), cz + r.float(-0.03...0.03)), size: V2(sw, sdp),
                                    yaw: r.float(-0.06...0.06), layer: ci * 4 + k % 2 * 2 + (k % 3 == 0 ? 1 : 0), wet: r.chance(0.55)))
                x += sw - r.float(0.12...0.16)
                k += 1
            }
        }
        sheets.sort { $0.layer < $1.layer }
        let half = V2(w / 2 - 0.06, d / 2 - 0.06)
        for (si, sh) in sheets.enumerated() {
            var r = rng.fork(200 + si)
            let lift = Float(si) * 0.0011 + 0.002
            let curlSide = r.int(0...3)
            let nx = 9, nz = 9
            let cs = cos(sh.yaw), sn = sin(sh.yaw)
            func world(_ u: Float, _ v: Float) -> V2 {
                var q = sh.c + V2(u * cs - v * sn, u * sn + v * cs)
                q.x = max(-half.x, min(half.x, q.x)); q.y = max(-half.y, min(half.y, q.y))
                return q
            }
            func top(_ u: Float, _ v: Float) -> Float {
                let q = world(u, v)
                let fu = u / (sh.size.x / 2), fv = v / (sh.size.y / 2)
                let edge: Float
                switch curlSide {
                case 0: edge = max(0, fu - 0.8) / 0.2
                case 1: edge = max(0, -fu - 0.8) / 0.2
                case 2: edge = max(0, fv - 0.8) / 0.2
                default: edge = max(0, -fv - 0.8) / 0.2
                }
                let cockle = 0.009 * Noise.fbm(V3(q.x * 5, Float(si), q.y * 5), octaves: 3, seed: sd + 7)
                return ground(q) + lift + board + cockle + 0.025 * edge * edge
            }
            var s = Surface(material: sh.wet ? wetCard : dryCard)
            // Top face grid.
            for j in 0...nz { for i in 0...nx {
                let u = (Float(i) / Float(nx) - 0.5) * sh.size.x, v = (Float(j) / Float(nz) - 0.5) * sh.size.y
                let q = world(u, v)
                s.add(V3(q.x, top(u, v), q.y), .up, V2(u, -v))
            }}
            let row = UInt32(nx + 1)
            for j in 0..<UInt32(nz) { for i in 0..<UInt32(nx) {
                let a = j * row + i
                s.quad(a, a + row, a + row + 1, a + 1)
            }}
            // Cut edge band (board thickness) round the perimeter.
            var ring: [(Float, Float)] = []
            for i in 0...nx { ring.append(((Float(i) / Float(nx) - 0.5) * sh.size.x, -sh.size.y / 2)) }
            for j in 1...nz { ring.append((sh.size.x / 2, (Float(j) / Float(nz) - 0.5) * sh.size.y)) }
            for i in stride(from: nx - 1, through: 0, by: -1) { ring.append(((Float(i) / Float(nx) - 0.5) * sh.size.x, sh.size.y / 2)) }
            for j in stride(from: nz - 1, through: 1, by: -1) { ring.append((-sh.size.x / 2, (Float(j) / Float(nz) - 0.5) * sh.size.y)) }
            var dist: Float = 0
            let start = UInt32(s.positions.count)
            for (k, (u, v)) in ring.enumerated() {
                let q = world(u, v)
                if k > 0 { let pq = world(ring[k - 1].0, ring[k - 1].1); dist += simd_length(q - pq) }
                let t = top(u, v)
                s.add(V3(q.x, t, q.y), .up, V2(dist, 0))
                s.add(V3(q.x, t - board - 0.001, q.y), .up, V2(dist, board))
            }
            let n = UInt32(ring.count)
            for k in 0..<n {
                let a = start + k * 2, b = start + ((k + 1) % n) * 2
                s.quad(a, a + 1, b + 1, b)
            }
            s.recomputeNormals(weldSeams: false)
            s.computeTangents()
            m.add(s)
            // Torn corner showing the fluting: short ribs along the exposed edge.
            if r.chance(0.6) {
                let u0 = r.float(-0.2...0.1) * sh.size.x
                let v0 = -sh.size.y / 2 + 0.003
                for f in 0..<10 {
                    let u = u0 + Float(f) * 0.0045
                    let q = world(u, v0), q2 = world(u, v0 + 0.035)
                    m.add(Prim.tube([V3(q.x, top(u, v0) - board * 0.5, q.y), V3(q2.x, top(u, v0 + 0.035) - board * 0.5, q2.y)],
                                    radii: [0.0018, 0.0018], sides: 4, seamTile: 0.02, material: "paper.screwbox-kraft:C9A577", capEnd: true))
                }
            }
            // Parcel tape strip across a former box seam.
            if r.chance(0.5) {
                let u = r.float(-0.25...0.25) * sh.size.x
                let q = world(u, 0)
                m.add(Prim.roundedBox(V3(0.048, 0.0006, sh.size.y * r.float(0.4...0.8)), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:8F7247"),
                      Xform(translation: V3(q.x, top(u, 0) + 0.0005, q.y), rotation: simd_quatf(angle: -sh.yaw, axis: .up)))
            }
        }
        // Topmost height at a point (for weights placed on the card).
        func surf(_ p: V2) -> Float { ground(p) + Float(sheets.count) * 0.0011 + board + 0.004 }
        // Bricks and stones holding the sheets.
        let bricks: [V2] = [V2(-0.6, -0.25), V2(0.35, -0.75), V2(0.62, 0.22), V2(-0.15, 0.27)]
        for (i, b) in bricks.enumerated() {
            var r = rng.fork(800 + i)
            let mat: MaterialKey = r.chance(0.5) ? "rock.redstone:8E3E2A" : "rock.redstone:A35A3C"
            m.add(Prim.roundedBox(V3(0.215, 0.065, 0.1025), radius: 0.004, bevelSegments: 2, material: mat),
                  Xform(translation: V3(b.x, surf(b) + 0.032, b.y), rotation: simd_quatf(degrees: r.float(0...180), axis: .up)))
        }
        for i in 0..<5 {
            var r = rng.fork(900 + i)
            let p = V2(r.float(-0.75...0.75), r.float(-0.75...0.75))
            AK.stone(&m, at: p, y: surf(p), size: r.float(0.04...0.065), rng: &r)
        }
        // Woodchip drift spread over the far course.
        for i in 0..<chips {
            var r = rng.fork(2000 + i)
            let p = V2(r.float(-0.9...0.9), r.float(0.35...0.88))
            let fall = max(0, min(1, (p.y - 0.3) / 0.15))
            guard r.float() < fall else { continue }
            let s = V3(r.float(0.02...0.05), r.float(0.004...0.008), r.float(0.012...0.025))
            m.add(Prim.roundedBox(s, radius: 0.0015, bevelSegments: 1, material: r.chance(0.7) ? "mulch.bark" : "wood.pine-aged"),
                  Xform(translation: V3(p.x, surf(p) + s.y * 0.5 + r.float(0...0.012) * fall, p.y),
                        rotation: simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: r.float(-25...25), axis: V3(1, 0, 0))))
        }
        // Weeds at the joins and the bare soil margin.
        for i in 0..<6 {
            var r = rng.fork(3000 + i)
            let edgeSide = r.int(0...3)
            let t = r.float(-0.85...0.85)
            let p: V2 = edgeSide == 0 ? V2(t, -0.95) : edgeSide == 1 ? V2(0.95, t) : edgeSide == 2 ? V2(-0.95, t) : V2(t, r.float(-0.3...0.3))
            AK.weed(&m, at: V3(p.x, (edgeSide == 3 ? surf(p) : ground(p)) - 0.003, p.y), height: r.float(0.04...0.07), count: 12, rng: &r,
                    material: r.chance(0.6) ? "grass.lawn" : "grass.dry")
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 20, material: wetCard) { p in
            abs(p.x) < half.x && abs(p.y) < half.y ? surf(p) : ground(p)
        }
        return AK.finish(&m, lite: lite, ao: 0.05)
    }
}
