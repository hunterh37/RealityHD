import simd
import Foundation

/// Tudor half-timber panel: a jettied two-storey oak frame, 2.4 m wide and tall. Sill, corner posts, mid
/// rails, close studs, arch braces and St Andrew's down-braces are pegged oak; the infill is lime stucco
/// set 15 mm behind the timber face. Joist ends carry a moulded bressumer under the overhanging upper storey.
public struct TudorHalfTimberPanel: RealAsset {
    public static let id = "tudor-half-timber-panel"
    public static let summary = "Tudor Revival half-timber wall panel, 2.4 m: oak sill, posts, rails, braces and studs over rough lime stucco infill, pegged joints."
    public static let tags = ["prop", "architecture", "facade", "wood", "trim"]
    public static let budget = 13500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 3.2)

    /// Panel width in meters.
    public var width: Float = 2.4
    /// Panel height in meters.
    public var height: Float = 2.4
    /// Timber depth in meters.
    public var timberDepth: Float = 0.12
    /// Upper storey jetty projection in meters.
    public var jetty: Float = 0.06
    /// Fresh oak timber material.
    public var oak: MaterialKey = "wood.oak:4A3424"
    /// Weathered oak for the sill and ground-floor posts.
    public var weathered: MaterialKey = "wood.weathered:6B5B4A"
    /// Stucco infill material.
    public var stucco: MaterialKey = "paint.stucco:D6C8A8"
    /// Splashed stucco at the base of the ground storey.
    public var soot: MaterialKey = "stone.limestone-sooted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, D = timberDepth, hw = W / 2
        let postW: Float = 0.14, inner = hw - postW
        func timber(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, _ z0: Float, _ z1: Float, _ mat: MaterialKey, r: Float = 0.004, tilt: Float = 0) {
            FA.box(&m, V3(x1 - x0, y1 - y0, z1 - z0), V3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), mat, r: r, rot: FA.q(tilt, FA.Z))
        }
        func peg(_ x: Float, _ y: Float, _ zFace: Float) {
            FA.cylZ(&m, r: 0.0085, h: 0.008, at: V3(x + rng.float(-0.002...0.002), y, zFace - 0.002), "wood.oak:8A6642", bevel: 0.002, segments: 8)
        }
        // Curved arch brace: quadratic curve from the post (px, py) to the plate (px + sx * dx, plateY), band of width bw.
        func archBrace(_ px: Float, _ py: Float, _ sx: Float, _ dx: Float, _ plateY: Float, _ zc: Float, _ mat: MaterialKey) {
            let p0 = V2(px, py), p1 = V2(px, plateY), p2 = V2(px + sx * dx, plateY)
            var a: [V2] = [], b: [V2] = []
            let n = 10, bw: Float = 0.045
            for i in 0...n {
                let t = Float(i) / Float(n), u = 1 - t
                let p = p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t)
                let d = (p1 - p0) * (2 * u) + (p2 - p1) * (2 * t)
                let l = max(simd_length(d), 1e-5)
                let nrm = V2(-d.y, d.x) / l
                a.append(p + nrm * bw); b.append(p - nrm * bw)
            }
            let outline = a + b.reversed()
            m.add(Prim.extrude(outline, depth: D - 0.002, bevel: 0.003, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, zc)))
        }
        // Diagonal straight brace between two points on the frame face plane.
        func diag(_ a: V2, _ b: V2, _ zc: Float, _ mat: MaterialKey) {
            let d = b - a, len = simd_length(d)
            let ang = atan2(d.y, d.x) * 180 / .pi
            FA.box(&m, V3(len, 0.08, D - 0.002), V3((a.x + b.x) / 2, (a.y + b.y) / 2, zc), mat, r: 0.004, rot: FA.q(ang, FA.Z))
        }
        func storey(yb: Float, yt: Float, zo: Float, lowerMat: MaterialKey, arch: Bool) {
            let zc = zo + D / 2, zf = zo + D
            let mid = (yb + yt) / 2
            // Stucco infill, recessed behind the timber face; the ground storey takes a sooted splash band.
            timber(-inner, inner, yb, yt, zo + 0.01, zf - 0.03, stucco, r: 0.003)
            var coat = Prim.terrain(size: V2(inner * 2, yt - yb), segments: 28, material: stucco) { p in
                0.0035 * Noise.fbm(V3(p.x * 6, p.y * 6, Float(zo) * 9), octaves: 3, seed: 41) + 0.0012 * Noise.fbm(V3(p.x * 30, p.y * 30, 3), octaves: 2, seed: 7)
            }
            coat.uvs = coat.positions.map { V2($0.x, -$0.z) }; coat.computeTangents()
            m.add(coat, Xform(translation: V3(0, (yb + yt) / 2, zf - 0.0185), rotation: FA.q(90, FA.X)))
            if yb < 0.5 { timber(-inner - 0.001, inner + 0.001, yb, yb + 0.22, zo + 0.01, zf - 0.0135, soot, r: 0.003) }
            timber(-inner, inner, yt - 0.07, yt, zo + 0.01, zf - 0.0135, soot, r: 0.002)
            timber(-inner, inner, mid - 0.12, mid - 0.05, zo + 0.01, zf - 0.0135, soot, r: 0.002)
            for e: Float in [-1, 1] {
                timber(e * hw + (e > 0 ? -postW : 0), e * hw + (e > 0 ? 0 : postW), yb, yt, zo, zf, lowerMat)
                peg(e * (hw - postW / 2), mid + 0.03, zf); peg(e * (hw - postW / 2), mid - 0.03, zf)
                peg(e * (hw - postW / 2), yb + 0.08, zf); peg(e * (hw - postW / 2), yt - 0.08, zf)
            }
            timber(-inner, inner, mid - 0.05, mid + 0.05, zo, zf - 0.001, oak)
            for x in stride(from: -0.70 as Float, through: 0.71, by: 0.35) {
                let sm: MaterialKey = rng.chance(0.3) ? weathered : oak
                timber(x - 0.045, x + 0.045, yb, mid - 0.05, zo + 0.002, zf - 0.002 - rng.float(0...0.003), sm, r: 0.003, tilt: rng.float(-0.7...0.7))
                timber(x - 0.045, x + 0.045, mid + 0.05, yt, zo + 0.002, zf - 0.002 - rng.float(0...0.003), sm, r: 0.003, tilt: rng.float(-0.7...0.7))
                peg(x, mid + 0.0, zf - 0.002); peg(x, mid + 0.075, zf - 0.002)
            }
            if arch {
                for e: Float in [-1, 1] { archBrace(e * inner, yt - 0.34, -e, 0.5, yt, zc, oak) }
            } else {
                for e: Float in [-1, 1] {
                    diag(V2(e * inner, yb), V2(e * 0.70, mid - 0.05), zc, oak)
                    diag(V2(e * inner, yt), V2(e * 0.70, mid + 0.05), zc, oak)
                    peg(e * 0.78, yb + 0.08, zf - 0.002); peg(e * 0.78, yt - 0.08, zf - 0.002)
                }
            }
        }
        let y1: Float = 1.08, y2: Float = 1.42
        // Ground storey: sill on the ground, head plate at y1.
        // Common-bond brick plinth course the sill sits on.
        timber(-hw, hw, 0, 0.12, 0.0, D, "brick.common", r: 0.004)
        
        timber(-hw, hw, 0.12, 0.25, 0.0, D, weathered, r: 0.005)
        timber(-hw, hw, y1, y1 + 0.12, 0, D, oak, r: 0.005)
        storey(yb: 0.25, yt: y1, zo: 0, lowerMat: weathered, arch: true)
        // Jetty: joist ends cantilever over the plate, bressumer with ovolo moulding on top.
        for x in stride(from: -1.05 as Float, through: 1.06, by: 0.35) {
            timber(x - 0.05, x + 0.05, y1 + 0.12, y1 + 0.2, 0.0, D + jetty - 0.004, oak, r: 0.004)
            // Dragon-beam style end chamfer: a slim cap on each joist end.
            timber(x - 0.045, x + 0.045, y1 + 0.125, y1 + 0.195, D + jetty - 0.004, D + jetty, weathered, r: 0.002)
        }
        let bress: [V2] = [V2(0, 0), V2(D + jetty - 0.06, 0), V2(D + jetty - 0.06, 0.02), V2(D + jetty - 0.02, 0.05), V2(D + jetty, 0.08), V2(D + jetty, 0.12), V2(D + jetty - 0.06, 0.14), V2(0, 0.14)]
        // bress profile: x is depth from the wall, y up. Extruded along X by FA.run.
        FA.run(&m, bress.map { V2($0.x, $0.y) }, length: W, at: V3(0, y1 + 0.2, 0), oak, bevel: 0.003)
        // Upper storey: projects by the jetty.
        timber(-hw, hw, 2.28, 2.4, jetty, D + jetty, oak, r: 0.005)
        storey(yb: y2 + 0.06, yt: 2.28, zo: jetty, lowerMat: oak, arch: false)
        // Story detail: one stud has split along a shake.
        FA.box(&m, V3(0.006, 0.34, 0.004), V3(0.35, 1.0, D - 0.0005), "wood.deadwood", r: 0.001)
        groundAO(&m, height: 0.2, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
