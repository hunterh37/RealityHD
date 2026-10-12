import simd
import Foundation

/// Brutalist precast concrete fin panel: board-formed backing slab with four deep vertical fins whose tops
/// slope back, chamfered fin edges, board-line ribs, form-tie cones on a 0.6 m grid, two cast-in lifting
/// sockets at the head, galvanized base bolts and rust and lime run-off streaks. Wall plane at z = 0.
public struct BrutalistConcreteFinPanel: RealAsset {
    public static let id = "brutalist-concrete-fin-panel"
    public static let summary = "Brutalist precast concrete fin panel, 1.2 x 3.0 m: slab with four deep chamfered fins, board-formed ribs, form ties and lifting sockets."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 24000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 6, distance: 3.9)

    public var width: Float = 1.2
    public var height: Float = 3.0
    public var depth: Float = 0.45
    public var slab: Float = 0.15
    public var finCount = 4
    public var finWidth: Float = 0.13
    /// Board height (m) for the board-formed ribs.
    public var board: Float = 0.145
    public var concrete: MaterialKey = "concrete.rough"
    public var finish: MaterialKey = "concrete.smooth"
    public var steel: MaterialKey = "metal.galvanized"
    public var rebar: MaterialKey = "metal.rebar"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, D = depth, S = slab
        let pitch = (W - 0.2) / Float(finCount - 1)
        let fx = (0..<finCount).map { -((W - 0.2) / 2) + Float($0) * pitch }

        // Backing slab with 12 mm chamfered perimeter.
        m.add(Prim.roundedBox(V3(W, H, S), radius: 0.012, bevelSegments: 1, material: concrete), Xform(translation: V3(0, H / 2, S / 2)))
        // Fins: side profile (z out, y up) with a raked top, chamfered by the extrude bevel. Fin depth steps with position.
        for (i, x) in fx.enumerated() {
            let top = H - 0.18 - Float(i % 2) * 0.1
            let out = D - 0.009 - Float(i % 2 == 1 ? 0.04 : 0)
            let prof: [V2] = [V2(S - 0.01, 0.12), V2(out, 0.12), V2(out, top - 0.55), V2(out - 0.18, top), V2(S - 0.01, top)]
            FA.run(&m, prof, length: finWidth, at: V3(x, 0, 0), i % 2 == 0 ? concrete : finish, bevel: 0.012)
            // lifting-socket-style recess ties on the fin face: two form-tie cones per fin end
            for y in [Float(0.6), 1.2, 1.8] where y < top - 0.7 {
                FA.cylZ(&m, r: 0.016, h: 0.004, at: V3(x, y, out + 0.0005), "metal.rebar", bevel: 0.001, segments: 12)
            }
        }
        // Board-formed face: each 145 mm board is a thin slab of its own tone and thickness (variegation and shadow lines),
        // on the backing between fins and on the fin end faces.
        let tones: [MaterialKey] = ["paint.stucco:A7A298", "paint.stucco:9C978C", "paint.stucco:B2ADA1", "paint.stucco:918D83", "paint.stucco:ABA69B"]
        func board(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, _ z: Float, _ thick: Float, _ mat: MaterialKey) {
            let o: [V2] = [V2(x0, y0), V2(x1, y0), V2(x1, y1), V2(x0, y1)]
            m.add(Prim.extrude(o, depth: thick, bevel: 0.0007, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, z + thick / 2)))
        }
        var y: Float = 0.02
        while y < H - 0.03 {
            let y1 = min(y + self.board - 0.004, H - 0.02)
            let th = 0.002 + rng.float(0...0.0025)
            let tone = tones[rng.int(0...(tones.count - 1))]
            for k in 0...finCount {
                let x0 = (k == 0 ? -W / 2 + 0.015 : fx[k - 1] + finWidth / 2 + 0.002)
                let x1 = (k == finCount ? W / 2 - 0.015 : fx[k] - finWidth / 2 - 0.002)
                if x1 - x0 < 0.02 { continue }
                board(x0, x1, y, y1, S - 0.0005, th, rng.chance(0.2) ? tones[rng.int(0...(tones.count - 1))] : tone)
            }
            y += self.board
        }
        for (i, x) in fx.enumerated() {
            let top = H - 0.18 - Float(i % 2) * 0.1
            let out = D - 0.009 - Float(i % 2 == 1 ? 0.04 : 0)
            var yy: Float = 0.14
            while yy < top - 0.6 {
                board(x - finWidth / 2 + 0.014, x + finWidth / 2 - 0.014, yy, min(yy + self.board - 0.004, top - 0.58), out - 0.0005, 0.002 + rng.float(0...0.002), tones[rng.int(0...(tones.count - 1))])
                yy += self.board
            }
        }
        // Board-formed fin sides and slab back: same 145 mm boards in tone.
        for (i, x) in fx.enumerated() {
            let top = H - 0.18 - Float(i % 2) * 0.1
            let out = D - 0.009 - Float(i % 2 == 1 ? 0.04 : 0)
            var yy: Float = 0.14
            while yy < top - 0.6 {
                let y1 = min(yy + self.board - 0.004, top - 0.58)
                for sd: Float in [-1, 1] {
                    let th = 0.0025 + rng.float(0...0.002)
                    let xs = x + sd * (finWidth / 2) - (sd < 0 ? 0 : th) + (sd < 0 ? -th + th : 0) - (sd < 0 ? th : 0) * 0
                    let rect: [V2] = [V2(S + 0.01, yy), V2(out - 0.015, yy), V2(out - 0.015, y1), V2(S + 0.01, y1)]
                    FA.run(&m, rect, length: th, at: V3(sd < 0 ? x - finWidth / 2 - th / 2 + 0.0005 : x + finWidth / 2 + th / 2 - 0.0005, 0, 0), tones[rng.int(0...(tones.count - 1))], bevel: 0.0007)
                    _ = xs
                }
                yy += self.board
            }
        }
        var yb: Float = 0.02
        while yb < H - 0.03 {
            let th = 0.002 + rng.float(0...0.003)
            board(-W / 2 + 0.015, W / 2 - 0.015, yb, min(yb + self.board - 0.004, H - 0.02), -th + 0.0005, th, tones[rng.int(0...(tones.count - 1))])
            yb += self.board
        }
        // Form-tie holes on a 0.6 m grid on the slab face: dark conical recesses with a lime ring.
        let tieX: [Float] = [-0.3, 0.3]
        for xx in tieX {
            for yy in stride(from: Float(0.45), through: H - 0.3, by: 0.6) {
                if fx.contains(where: { abs($0 - xx) < finWidth / 2 + 0.02 }) { continue }
                FA.cylZ(&m, r: 0.022, h: 0.003, at: V3(xx, yy, S), finish, bevel: 0.001, segments: 14)
                FA.cylZ(&m, r: 0.013, h: 0.004, at: V3(xx, yy, S + 0.001), "metal.rebar", bevel: 0.0005, segments: 12)
            }
        }
        // Lifting sockets at the head: galvanized plate with a rebar loop; cast-in bolts at the base.
        for s: Float in [-1, 1] {
            let x = s * 0.35
            FA.box(&m, V3(0.1, 0.014, 0.04), V3(x, H - 0.008, S / 2), steel, r: 0.003)
            var loop: [V3] = []
            for k in 0...16 {
                let a = Float.pi * Float(k) / 16
                loop.append(V3(x + 0.04 * cos(a), H - 0.012 + 0.012 * sin(a), S / 2))
            }
            FA.path(&m, loop, r: 0.007, rebar, sides: 8)
            FA.box(&m, V3(0.12, 0.012, 0.16), V3(s * 0.33, 0.006, S / 2), steel, r: 0.002)
            for bx: Float in [-1, 1] {
                FA.cylZ(&m, r: 0.011, h: 0.012, at: V3(s * 0.33 + bx * 0.04, 0.012 + 0.006, S / 2), steel, bevel: 0.0015, segments: 6)
            }
        }
        // Weathering: rust run-off under the sockets, dark rain streaks off each fin shoulder, lime efflorescence at the base.
        for s: Float in [-1, 1] {
            let len: Float = 0.5 + 0.2 * rng.float()
            board(s * 0.35 - 0.02, s * 0.35 + 0.02, H - 0.05 - len, H - 0.05, S + 0.0045, 0.0008, "paint.stucco:7C5535")
            board(s * 0.35 - 0.008, s * 0.35 + 0.008, H - 0.05 - len * 1.4, H - 0.05 - len, S + 0.0045, 0.0008, "paint.stucco:93724F")
        }
        let gaps: [Float] = [-0.333, 0, 0.333]
        for g in gaps {
            for k in 0..<2 {
                let w = rng.float(0.03...0.06), len = rng.float(0.6...1.5)
                let x0 = g - 0.08 + Float(k) * 0.14 + rng.float(-0.02...0.02)
                board(x0, x0 + w, H - 0.03 - len, H - 0.03, S + 0.0045, 0.0008, "paint.stucco:6E6A62")
            }
        }
        for (i, x) in fx.enumerated() {
            board(x - finWidth / 2 + 0.01, x + finWidth / 2 - 0.01, 0.12, 0.2, D - 0.0095 - Float(i % 2 == 1 ? 0.04 : 0), 0.0055, "paint.stucco:D2CDBF")
        }
        board(-W / 2 + 0.02, W / 2 - 0.02, 0.0, 0.02, S - 0.0005, 0.0065, "paint.stucco:C8C3B4")

        groundAO(&m, height: 0.2, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
