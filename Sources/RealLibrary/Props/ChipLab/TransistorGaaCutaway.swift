import simd
import Foundation

/// Gate-all-around nanosheet FET at 1e6x scale (0.5 m cube): three stacked silicon nanosheets wrapped by hafnium oxide
/// and a tungsten gate cut away at the front plane, inner and outer spacers, source and drain epi, tungsten contacts with
/// copper M0 pads, a backside power rail with a tungsten backside via under the source. Parts: rail, substrate,
/// nanosheet-1..3, gate-oxide, gate-metal, spacers, epi-source, epi-drain, contacts; state "exploded" separates layers.
public struct TransistorGaaCutaway: RealArticulated {
    public static let id = "transistor-gaa-cutaway"
    public static let summary = "GAA nanosheet FET cutaway at 1e6x scale: 3 nanosheets wrapped by HfO2 and tungsten gate, epi source/drain, spacers, contacts, backside power rail; explodes by layer."
    public static let tags = ["prop", "chiplab", "micro-scale", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 26, distance: 1.5, studio: true)

    /// Nanosheet count.
    public var sheets = 3
    public var sheetMat: MaterialKey = "silicon.die"
    public var bodyMat: MaterialKey = "silicon.die-edge"
    public var oxideMat: MaterialKey = "oxide.hafnium"
    public var gateMat: MaterialKey = "metal.tungsten"
    public var wireMat: MaterialKey = "metal.copper"
    public var spacerMat: MaterialKey = "oxide.lowk"
    public init() {}

    func box(_ s: V3, _ r: Float, _ mat: MaterialKey, seg: Int = 1) -> Surface {
        Prim.roundedBox(s, radius: r, bevelSegments: seg, material: mat)
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        rig.base[0] = Model(name: Self.id)
        func part(_ n: String, _ axis: V3, _ d: Float) {
            _ = rig.part(n, pivot: V3(0, 0, 0), joint: .slide(axis: axis, 0...d, duration: 0.9))
        }
        func at(_ x: Float, _ y: Float, _ z: Float) -> Xform { Xform(translation: V3(x, y, z)) }

        // Vertical stack (m): rail 0..0.05, substrate 0.05..0.15, gate bottom fill to 0.20, sheets pitch 0.065.
        let t: Float = 0.026, pitch: Float = 0.072, y0: Float = 0.215
        let hf: Float = 0.012
        let gx: Float = 0.085        // half gate length
        let zc: Float = 0.030        // gate cut plane (front)
        let zb: Float = -0.20        // gate back
        let sheetZ: Float = 0.15     // half sheet width
        let topSheet = y0 + Float(sheets - 1) * pitch + t
        let gateTop = topSheet + hf + 0.04

        part("rail", V3(0, -1, 0), 0.12)
        rig.add(box(V3(0.34, 0.05, 0.12), 0.006, wireMat, seg: 2), at(-0.08, 0.025, 0), to: "rail")
        rig.add(box(V3(0.34, 0.012, 0.12), 0.004, wireMat, seg: 1), at(-0.08, 0.001, 0), to: "rail")

        part("substrate", V3(0, -1, 0), 0.06)
        rig.add(box(V3(0.5, 0.10, 0.50), 0.006, bodyMat, seg: 2), at(0, 0.10, 0), to: "substrate")
        // Backside via through the substrate under the source epi.
        rig.add(Prim.lathe([V2(0.032, 0), V2(0.032, 0.11)], segments: 16, seamTile: 1, material: gateMat), at(-0.145, 0.05, 0), to: "substrate")
        // Oxide-lined trench stripe along the cut face.
        rig.add(box(V3(0.5, 0.014, 0.02), 0.003, spacerMat), at(0, 0.143, 0.23), to: "substrate")

        for i in 0..<sheets {
            let n = "nanosheet-\(i + 1)"
            let y = y0 + Float(i) * pitch
            part(n, V3(0, 1, 0), Float(i + 1) * 0.06)
            rig.add(box(V3(0.34, t, sheetZ * 2), 0.004, sheetMat, seg: 2), at(0, y + t / 2, 0), to: n)
        }

        // Hafnium oxide: four slabs around each sheet, ending at the cut plane so the ring section is visible.
        part("gate-oxide", V3(0, 1, 0), 0.30)
        let oz = (zc - zb) / 2, ozc = (zc + zb) / 2
        for i in 0..<sheets {
            let y = y0 + Float(i) * pitch
            rig.add(box(V3(gx * 2, hf, oz * 2), 0.002, oxideMat), at(0, y - hf / 2, ozc), to: "gate-oxide")
            rig.add(box(V3(gx * 2, hf, oz * 2), 0.002, oxideMat), at(0, y + t + hf / 2, ozc), to: "gate-oxide")
        }
        // Back-side face wrap and sheet side walls beyond the sheet width.
        for s: Float in [-1, 1] {
            for i in 0..<sheets {
                let y = y0 + Float(i) * pitch
                rig.add(box(V3(gx * 2, t + 2 * hf, hf), 0.002, oxideMat), at(0, y + t / 2, s * (sheetZ + hf / 2)), to: "gate-oxide")
            }
        }

        // Tungsten fill between and above the oxide wraps, cut at the front plane. The wrap rings stay visible
        // because the fill stops before the oxide at the cut face.
        part("gate-metal", V3(0, 1, 0), 0.50)
        let gapH = pitch - t - 2 * hf
        let fz = (zc - 0.012 - zb) / 2, fzc = (zc - 0.012 + zb) / 2
        let bottom = y0 - hf
        rig.add(box(V3(gx * 2, bottom - 0.15, fz * 2), 0.003, gateMat), at(0, 0.15 + (bottom - 0.15) / 2, fzc), to: "gate-metal")
        for i in 1..<sheets {
            let yb = y0 + Float(i - 1) * pitch + t + hf
            rig.add(box(V3(gx * 2, gapH, fz * 2), 0.002, gateMat), at(0, yb + gapH / 2, fzc), to: "gate-metal")
        }
        let capB = topSheet + hf
        rig.add(box(V3(gx * 2 + 0.03, gateTop - capB, fz * 2), 0.006, gateMat, seg: 2), at(0, capB + (gateTop - capB) / 2, fzc), to: "gate-metal")

        // Spacers: outer sidewalls at both gate ends, inner spacers between sheets under the outer ones.
        part("spacers", V3(0, 1, 0), 0.40)
        for s: Float in [-1, 1] {
            let sx = s * (gx + 0.016)
            rig.add(box(V3(0.032, gateTop - 0.15, oz * 2), 0.004, spacerMat), at(sx, 0.15 + (gateTop - 0.15) / 2, ozc), to: "spacers")
        }

        for (nm, s) in [("epi-source", Float(-1)), ("epi-drain", Float(1))] {
            part(nm, V3(s, 0, 0), 0.20)
            let w: Float = 0.133, h = topSheet - 0.15 + 0.012
            // Faceted epi: wide rounded body with a chamfered crown.
            rig.add(box(V3(w, h, 0.30), 0.018, bodyMat, seg: 2), at(s * (gx + 0.032 + w / 2), 0.15 + h / 2, 0), to: nm)
            rig.add(box(V3(w - 0.03, 0.012, 0.26), 0.004, sheetMat), at(s * (gx + 0.032 + w / 2), 0.15 + h + 0.002, 0), to: nm)
        }

        part("contacts", V3(0, 1, 0), 0.70)
        let capTop = topSheet + 0.026
        for s: Float in [-1, 1] {
            let x = s * 0.165, base = capTop + 0.002
            rig.add(Prim.lathe([V2(0.028, 0), V2(0.020, 0.07)], segments: 16, seamTile: 1, material: gateMat), at(x, base, 0), to: "contacts")
            rig.add(box(V3(0.10, 0.018, 0.24), 0.005, wireMat, seg: 2), at(x, base + 0.079, 0), to: "contacts")
        }
        rig.add(Prim.lathe([V2(0.024, 0), V2(0.018, 0.06)], segments: 16, seamTile: 1, material: gateMat), at(0, gateTop, fzc), to: "contacts")
        rig.add(box(V3(0.09, 0.018, 0.14), 0.005, wireMat, seg: 2), at(0, gateTop + 0.069, fzc), to: "contacts")

        let names = ["rail": Float(1), "substrate": 0.5, "nanosheet-1": 0.5, "nanosheet-2": 1.0, "nanosheet-3": 1.5,
                     "gate-oxide": 1.0, "gate-metal": 1.6, "spacers": 1.0, "epi-source": 1.0, "epi-drain": 1.0, "contacts": 2.0]
        let lim: [String: Float] = ["rail": 0.12, "substrate": 0.06, "nanosheet-1": 0.06, "nanosheet-2": 0.12, "nanosheet-3": 0.18,
                                    "gate-oxide": 0.30, "gate-metal": 0.50, "spacers": 0.40, "epi-source": 0.20, "epi-drain": 0.20, "contacts": 0.70]
        _ = names
        rig.states = [RigState("assembled"), RigState("exploded", lim)]
        return rig
    }
}
