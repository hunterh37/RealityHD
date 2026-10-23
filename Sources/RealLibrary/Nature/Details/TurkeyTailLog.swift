import simd
import Foundation

/// Dead log 60 cm long and about 18 cm thick covered in overlapping turkey tail brackets, 2-5 cm fans with
/// brown, blue-grey and cream growth bands. LOD1: coarser fans and log.
public struct TurkeyTailLog: RealAsset {
    public static let id = "turkey-tail-log"
    public static let summary = "Dead log 60 cm long with 18-22 overlapping turkey tail brackets, 2-5 cm fans in brown, blue-grey and cream bands; 2 LODs."
    public static let tags = ["nature", "fungus", "wood"]
    public static let budget = 4_100
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 0.9)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var levels: [Model] = []
        for lod in 0..<2 {
            var rng = SeededRNG(seed: seed)
            var local = Model(name: Self.id)
            let L: Float = 0.6, r = rng.float(0.085...0.095)
            for s in DetailKit13.log(L: L, r: r, segs: lod == 0 ? 16 : 8, rings: lod == 0 ? 10 : 4, rng: &rng) { local.add(s) }
            let patches = (0..<5).map { _ in (y: rng.float(0.08...(L - 0.08)), u: rng.float(-2.4...2.4)) }
            var shelfRng = rng
            for i in 0..<21 {
                let p = patches[i % patches.count]
                let y = min(L - 0.02, max(0.02, p.y + shelfRng.float(-0.06...0.06)))
                let u = p.u + shelfRng.float(-0.28...0.28)
                let n = V3(-cos(u), 0, sin(u)), tang = V3(sin(u), 0, cos(u))
                let psi = shelfRng.float(0...6.28)
                let x0 = V3(0, 1, 0) * cos(psi) + tang * sin(psi)
                let q = DetailKit13.frame(x: x0 + n * 0.3, up: n)
                let R = shelfRng.float(0.028...0.06)
                var fr = shelfRng.fork(i)
                let rows = lod == 0 ? 5 : 3
                let surfs = DetailKit13.fan(R: R, spread: shelfRng.float(0.9...1.3), thick: 0.0022, droop: 0.12, rows: rows, cols: lod == 0 ? 8 : 5, edge: 0.1,
                    zones: [(0, "fungus.cap:6B5240"), (rows / 3, "fungus.cap:8A9199"), (rows * 2 / 3, "fungus.cap:4E3B2C"), (rows - 1, "fungus.cap:D8CBB0")],
                    under: "fungus.gills:E6DCC2", rng: &fr)
                var sh = Model(name: Self.id)
                for s in surfs { sh.add(s) }
                local.add(sh, Xform(translation: n * (r * 0.96) + V3(0, y, 0), rotation: q))
            }
            var m = Model(name: Self.id)
            m.add(local, Xform(translation: V3(-L / 2, r - 0.003, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))))
            groundAO(&m, height: 0.1)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [4])
    }
}
