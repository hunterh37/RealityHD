import simd
import RealCore

/// Shared rig for the fish pack. Parts: `body` (fixed), `tail` (yaw at the caudal peduncle), `jaw` (lower jaw
/// hinge at the mouth corner). States: rest, swim-left, swim-right, mouth-open. Nose at +X, back +Y,
/// centred on X/Z, lowest point at y = 0. `extra.x` runs 0 at the snout to 1 at the tail tip.
public enum FishRig {
    /// Where the body is cut for the tail part.
    static let tailSplit: Float = 0.8

    public static func rig(id: String, shape base: FishShape, seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var f = base
        f.depth = rng.vary(f.depth, 0.03)
        f.width = rng.vary(f.width, 0.04)
        let finScale = rng.vary(1, 0.05)
        if var d = f.dorsal { d.height *= finScale; f.dorsal = d }
        if var a = f.anal { a.height *= finScale; f.anal = a }

        let levels = [parts(f, detail: 1), parts(f, detail: 0)]
        // Centre on X/Z, lowest point to y = 0.
        var all = Model(name: id)
        for (b, t, j) in [levels[0]] { all.add(b); all.add(t); all.add(j) }
        let bb = all.bounds
        let shift = V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, 0)
        let snoutX = bb.max.x + shift.x, tailX = bb.min.x + shift.x
        func place(_ m: Model) -> Model {
            var out = m.transformed(Xform(translation: shift))
            for i in out.surfaces.indices {
                out.surfaces[i].extra = out.surfaces[i].positions.map { V2(saturate((snoutX - $0.x) / (snoutX - tailX)), 0) }
            }
            return out
        }

        var rig = Rig(name: id, lods: 2, switchDistances: [2.5])
        rig.part("body", pivot: V3(0, f.halfDepth(0.4) + shift.y, 0), joint: .fixed)
        let tailPivot = V3(f.x(tailSplit), (f.top(tailSplit) + f.bottom(tailSplit)) / 2, 0) + shift
        rig.part("tail", parent: "body", pivot: tailPivot, joint: .hinge(axis: .up, -26...26, duration: 0.35))
        let jawPivot = V3(f.x(f.mouthEnd) - 0.004 * f.length, f.mouthLine(f.mouthEnd), 0) + shift
        rig.part("jaw", parent: "body", pivot: jawPivot, joint: .hinge(axis: V3(0, 0, 1), -34...0, duration: 0.3))
        for (l, lv) in levels.enumerated() {
            rig.base[l] = Model(name: id)
            rig.add(place(lv.0), to: "body", lod: l)
            rig.add(place(lv.1), to: "tail", lod: l)
            rig.add(place(lv.2), to: "jaw", lod: l)
        }
        rig.states = [RigState("rest"), RigState("swim-left", ["tail": 20]), RigState("swim-right", ["tail": -20]),
                      RigState("mouth-open", ["jaw": -28])]
        groundAO(&rig, height: f.length * 0.08, floor: 0.6)
        return rig
    }

    /// (body, tail, jaw) models for one LOD.
    static func parts(_ f: FishShape, detail: Int) -> (Model, Model, Model) {
        let sides = detail > 0 ? 44 : 22
        var body = Model(name: "body"), tail = Model(name: "tail"), jaw = Model(name: "jaw")
        let mE = f.mouthEnd
        let head = FishBody.loft(f, 0...mE, rings: detail > 0 ? 10 : 5, sides: sides, mode: 1, capFront: true, capBack: false)
        let trunk = FishBody.loft(f, mE...tailSplit, rings: detail > 0 ? 40 : 18, sides: sides, mode: 0, capFront: false, capBack: false)
        for s in head + trunk { body.add(s) }
        for s in FishBody.loft(f, tailSplit...1, rings: detail > 0 ? 8 : 4, sides: sides, mode: 0, capFront: false, capBack: true) { tail.add(s) }
        let ub = f.underbite * f.length
        for s in FishBody.loft(f, 0...mE, rings: detail > 0 ? 10 : 5, sides: sides, mode: 2, capFront: true, capBack: true,
                               xShift: { s in ub * (1 - s / mE) }) { jaw.add(s) }
        body.add(FishBody.eyes(f, detail: detail))
        if let d = f.dorsal {
            if d.end > tailSplit {
                var a = d; a.end = tailSplit; body.add(FishFins.median(f, a, up: true, material: f.fin, detail: detail))
            } else { body.add(FishFins.median(f, d, up: true, material: f.fin, detail: detail)) }
        }
        if var a = f.anal { a.end = min(a.end, tailSplit); body.add(FishFins.median(f, a, up: false, material: f.fin, detail: detail)) }
        if f.adipose { tail.add(FishFins.adipose(f, material: f.fin)) }
        tail.add(FishFins.caudal(f, material: f.fin, detail: detail))
        let ps = f.operculum + 0.02
        body.add(FishFins.paired(f, at: ps, y: f.bottom(ps) * 0.45, zScale: 1, length: f.pectoral, fan: -15...35, out: 0.4,
                                 material: f.fin, detail: detail))
        let vs = f.pelvicAt
        body.add(FishFins.paired(f, at: vs, y: f.bottom(vs) * 0.92, zScale: 0.55, length: f.pelvic, fan: 18...40, out: 0.35,
                                 material: f.fin, detail: detail))
        if f.earFlap > 0 { body.add(FishFins.earFlap(f, material: f.earFlapMaterial, detail: detail)) }
        if f.barbels > 0 {
            body.add(FishFins.barbels(f, chin: false, material: "fish.barbel"))
            jaw.add(FishFins.barbels(f, chin: true, material: "fish.barbel"))
        }
        return (body, tail, jaw)
    }
}
