import simd
import Foundation

/// Cicada nymph shell, 3 cm long amber exoskeleton clinging to a 10 cm dead twig, split along the back.
public struct CicadaShell: RealAsset {
    public static let id = "cicada-shell"
    public static let summary = "Cicada exoskeleton 3 cm long, amber and hollow with a split back and hooked legs, gripping a dead twig."
    public static let tags = ["nature", "wood"]
    public static let budget = 3_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 30, distance: 0.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [0.8])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let amber: MaterialKey = "insect.chitin-soft:B98B47"
        let tw = rng.float(0.0075...0.0095), tl: Float = 0.1
        let tpath = DetailKit02.limbPath(from: V3(-tl / 2, tw, 0), dir: V3(1, 0.0, 0.04), len: tl, segs: 8, wobble: 0.05, rng: &rng).map { V3($0.x, max($0.y, tw * 0.9), $0.z) }
        var twig = Surface(material: "wood.weathered")
        twig.append(Prim.tube(tpath, radii: (0...8).map { tw * (1 - 0.15 * Float($0) / 8) * rng.float(0.93...1.07) }, sides: lod == 0 ? 9 : 6, seamTile: 0.08, material: "wood.weathered", capEnd: true))
        twig.computeTangents()
        let top = tpath[4].y + tw * 0.9
        let cz = tpath[4].z, cx = tpath[4].x + rng.float(-0.01...0.01)
        let sub = lod == 0 ? 5 : 3
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        func blob(_ c: V3, _ a: V3, _ squash: Float = 1) -> Surface {
            Prim.cubeSphere(subdivisions: sub, material: amber) { d in
                let w = 1 + 0.02 * sin(d.x * 8 + ph[0]) * cos(d.z * 6 + ph[1]) + 0.012 * sin(d.y * 9 + ph[2])
                return c + V3(d.x * a.x, d.y * a.y * (d.y < 0 ? squash : 1), d.z * a.z) * w
            }
        }
        var shell = Surface(material: amber)
        let by = top + 0.0048
        shell.append(blob(V3(cx - 0.0085, by - 0.0006, cz), V3(0.0105, 0.0058, 0.0055), 0.8))   // abdomen
        shell.append(blob(V3(cx + 0.0035, by + 0.0008, cz), V3(0.0072, 0.0064, 0.0062), 0.85))  // thorax
        shell.append(blob(V3(cx + 0.0115, by, cz), V3(0.0042, 0.0044, 0.0064), 0.8))            // head
        for s: Float in [-1, 1] { shell.append(blob(V3(cx + 0.0128, by + 0.0006, cz + s * 0.0045), V3(0.0022, 0.0024, 0.0022))) } // eyes
        // legs: three pairs, front pair thick and held forward, hooked tarsi gripping the twig
        for p in 0..<3 {
            for s: Float in [-1, 1] {
                let x0 = cx + [0.0075, 0.0025, -0.0015][p] + rng.float(-0.001...0.001)
                let fwd: Float = p == 0 ? 0.006 : (p == 1 ? 0.0015 : -0.004)
                let r0: Float = p == 0 ? 0.0015 : 0.0010
                let pts = [V3(x0, by - 0.0035, cz + s * 0.0035),
                           V3(x0 + fwd * 0.4, by - 0.0006, cz + s * 0.0086),
                           V3(x0 + fwd * 0.9, top + 0.0012, cz + s * (tw + 0.0020)),
                           V3(x0 + fwd, top - tw * 0.55, cz + s * (tw + 0.0004)),
                           V3(x0 + fwd + 0.0012, top - tw * 0.9, cz + s * (tw * 0.55))]
                shell.append(Prim.tube(pts, radii: [r0, r0 * 0.9, r0 * 0.65, r0 * 0.4, r0 * 0.2], sides: lod == 0 ? 5 : 4, seamTile: 0.01, material: amber, capEnd: true))
            }
        }
        shell.computeTangents()
        // dark dorsal split along the thorax
        var slit = Surface(material: "insect.chitin-matte:2B2016")
        slit.append(blob(V3(cx + 0.0025, by + 0.0059, cz), V3(0.0052, 0.0007, 0.0007)))
        slit.computeTangents()
        m.add(twig); m.add(shell); m.add(slit)
        groundAO(&m, height: 0.03, floor: 0.6)
        return m
    }
}
