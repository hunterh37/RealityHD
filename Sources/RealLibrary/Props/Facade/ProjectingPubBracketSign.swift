import simd
import Foundation

/// Projecting pub bracket sign, English Tudor: 900 mm wide, 800 mm high, 50 mm deep. A wrought iron wall plate on four
/// hex bolts, a 20 mm square arm with a scroll brace and a curled finial, two hanging rings with hooks, and a 600 mm
/// square timber sign board in a moulded frame with a dark green painted panel, gilded "THE RED LION" lettering, a gilded
/// medallion ring and corner rosettes. Wear: flaking paint to bare oak, rust bleed from the bracket, gilding loss.
public struct ProjectingPubBracketSign: RealAsset {
    public static let id = "projecting-pub-bracket-sign"
    public static let summary = "Projecting pub bracket sign, English Tudor facade prop, 0.9 x 0.8 x 0.05 m."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 8, distance: 1.7)

    /// Wrought iron bracket.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Painted panel.
    public var panel: MaterialKey = "wood.painted-shaker-worn:1F4A33"
    /// Board frame and back.
    public var oak: MaterialKey = "wood.oak"
    /// Gilded lettering.
    public var gilt: MaterialKey = "metal.gold-leaf"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let zA: Float = 0.027                          // arm and board centre plane
        let xP: Float = -0.425                        // wall plate centre
        let yArm: Float = 0.775
        // Wall plate on four bolts.
        FA.box(&m, V3(0.05, 0.26, 0.012), V3(xP, 0.66, 0.006), iron, r: 0.003)
        for dy: Float in [-0.1, -0.035, 0.035, 0.1] { hexBolt(&m, at: V3(xP, 0.66 + dy, 0.012), normal: FA.Z, size: 0.012, material: "metal.bolt-bright") }
        // Arm: square bar with a collar at the plate and end, running to the finial curl.
        FA.box(&m, V3(0.86 - 0.05, 0.02, 0.02), V3(0.0 + 0.0, yArm, zA), iron, r: 0.0022)
        FA.box(&m, V3(0.04, 0.034, 0.034), V3(xP + 0.02, yArm, zA), iron, r: 0.004)
        FA.cylZ(&m, r: 0.0125, h: zA - 0.012, at: V3(xP, yArm, 0.012), iron, bevel: 0.002, segments: 12)   // boss from the plate to the arm
        // Scroll brace from the plate up under the arm, with a curl at its foot.
        let brace: [V3] = [V3(xP + 0.01, 0.50, zA), V3(xP + 0.045, 0.56, zA), V3(xP + 0.1, 0.64, zA), V3(xP + 0.2, 0.715, zA), V3(xP + 0.32, 0.765, zA)]
        FA.path(&m, catmull(brace, per: 6), r: 0.0072, iron, sides: 10)
        var curl: [V3] = []
        for k in 0...22 {
            let t = Float(k) / 22, a = (-70 + t * 410) * .pi / 180, r = 0.034 * (1 - 0.72 * t)
            curl.append(V3(xP + 0.045 + cos(a) * r - 0.034, 0.50 - 0.034 + sin(a) * r + 0.02, zA))
        }
        FA.path(&m, curl, r: 0.0052, iron, sides: 8)
        // Finial: a spiral curl below the arm tip and a ball.
        var tip: [V3] = []
        for k in 0...24 {
            let t = Float(k) / 24, a = (90 - t * 460) * .pi / 180, r = 0.05 * (1 - 0.78 * t)
            tip.append(V3(0.385 + cos(a) * r, yArm - 0.05 + sin(a) * r - 0.01, zA))
        }
        FA.path(&m, tip, r: 0.0058, iron, sides: 8)
        FA.ball(&m, r: 0.014, at: V3(0.44, yArm + 0.0, zA), iron)
        FA.box(&m, V3(0.014, 0.014, 0.014), V3(0.4, yArm - 0.015, zA), iron, r: 0.0015)
        // Hanging rings and hooks.
        let bx: Float = 0.2
        let board0: Float = 0.0, bh: Float = 0.6, bw: Float = 0.6
        let boardTop = board0 + bh
        for sgn: Float in [-1, 1] {
            let x = sgn * bx
            m.add(Prim.torus(major: 0.014, minor: 0.0028, segments: 16, sides: 6, material: iron), Xform(translation: V3(x, yArm - 0.02, zA), rotation: FA.q(90, FA.X)))
            m.add(Prim.torus(major: 0.0125, minor: 0.0026, segments: 16, sides: 6, material: iron), Xform(translation: V3(x, boardTop + 0.026, zA), rotation: FA.q(90, FA.X) * FA.q(90, FA.Y)))
            FA.rod(&m, V3(x, yArm - 0.032, zA), V3(x, boardTop + 0.04, zA), r: 0.0032, iron, sides: 6)
            FA.box(&m, V3(0.016, 0.01, 0.034), V3(x, boardTop + 0.0025, zA), iron, r: 0.002)   // eye plate on the frame
        }
        // Timber board: moulded frame (four rails with a stepped moulding) and a recessed painted panel.
        let fw: Float = 0.045, bd: Float = 0.03
        let cy = board0 + bh / 2
        FA.box(&m, V3(bw - 0.01, bh - 0.01, 0.018), V3(0, cy, zA - 0.004), oak, r: 0.003)           // back board
        FA.box(&m, V3(bw - 2 * fw + 0.004, bh - 2 * fw + 0.004, 0.012), V3(0, cy, zA + 0.0), panel, r: 0.002)
        // Frame rails with a bead and cove profile.
        let rail: [V2] = [V2(0, 0), V2(fw, 0), V2(fw, 0.034), V2(fw - 0.008, 0.04), V2(fw - 0.015, 0.0385), V2(fw - 0.019, 0.032), V2(fw - 0.026, 0.0295), V2(0.012, 0.0315), V2(0.004, 0.0345), V2(0, 0.03)]
        _ = rail
        for (sx, sy, len, vertical) in [(0, 1, bw, false), (0, -1, bw, false), (1, 0, bh - 2 * fw, true), (-1, 0, bh - 2 * fw, true)] as [(Float, Float, Float, Bool)] {
            let c = V3(sx * (bw / 2 - fw / 2), cy + sy * (bh / 2 - fw / 2), zA)
            FA.box(&m, vertical ? V3(fw, len, bd) : V3(len, fw, bd), c, oak, r: 0.004)
            // Raised bead along the inner edge and a cove line along the outer.
            if vertical { FA.box(&m, V3(0.008, len, 0.008), V3(c.x - sx * (fw / 2 - 0.004), c.y, zA + bd / 2 + 0.0015), oak, r: 0.0028); FA.box(&m, V3(0.006, len, 0.004), V3(c.x + sx * 0.012, c.y, zA + bd / 2 + 0.0005), "wood.weathered", r: 0.0015) }
            else { FA.box(&m, V3(len - 2 * fw, 0.008, 0.008), V3(c.x, c.y - sy * (fw / 2 - 0.004), zA + bd / 2 + 0.0015), oak, r: 0.0028); FA.box(&m, V3(len, 0.006, 0.004), V3(c.x, c.y + sy * 0.012, zA + bd / 2 + 0.0005), "wood.weathered", r: 0.0015) }
        }
        // Corner rosettes (gilded) and mitre pegs.
        for sx: Float in [-1, 1] {
            for sy: Float in [-1, 1] {
                let c = V3(sx * (bw / 2 - fw / 2), cy + sy * (bh / 2 - fw / 2), zA + bd / 2)
                m.add(Prim.cylinder(radius: 0.012, height: 0.004, bevel: 0.0012, segments: 14, bevelSegments: 1, material: gilt), Xform(translation: c - V3(0, 0, 0.0005), rotation: FA.q(90, FA.X)))
                FC.bead(&m, r: 0.0036, at: c + V3(0, 0, 0.0028), gilt)
            }
        }
        // Gilded medallion ring with "THE" and the lettering "RED" / "LION".
        let zT = zA + 0.0065
        m.add(Prim.torus(major: 0.082, minor: 0.0042, segments: 40, sides: 8, material: gilt), Xform(translation: V3(0, cy + 0.15, zT), rotation: FA.q(90, FA.X)))
        m.add(Prim.torus(major: 0.068, minor: 0.0022, segments: 32, sides: 6, material: gilt), Xform(translation: V3(0, cy + 0.15, zT), rotation: FA.q(90, FA.X)))
        let hT: Float = 0.052
        let wT = FSO.width("THE", h: hT)
        FSO.text(&m, "THE", origin: V2(-wT / 2, cy + 0.15 - hT / 2), h: hT, w: 0.0075, z: zT + 0.0015, t: 0.0028, gilt)
        let hR: Float = 0.105
        for (word, y) in [("RED", cy - 0.012), ("LION", cy - 0.14)] as [(String, Float)] {
            let w = FSO.width(word, h: hR)
            FSO.text(&m, word, origin: V2(-w / 2, y - hR / 2), h: hR, w: 0.0135, z: zT + 0.0015, t: 0.0028, gilt)
        }
        // Gilded rules above and below the lettering.
        FA.box(&m, V3(0.4, 0.004, 0.003), V3(0, cy - 0.215, zT + 0.0015), gilt, r: 0.001)
        FA.box(&m, V3(0.4, 0.004, 0.003), V3(0, cy + 0.015 + 0.065, zT + 0.0015), gilt, r: 0.001)
        // Weathering: paint flaking to bare oak, gilding loss, rust bleed from the hooks and bracket, bird lime on top.
        for _ in 0..<16 {
            FSO.blob(&m, at: V3(rng.float(-0.23...0.23), rng.float(board0 + 0.06...boardTop - 0.06), zT + 0.0004), size: V3(rng.float(0.014...0.04), rng.float(0.01...0.03), 0.0012), "wood.weathered")
        }
        for _ in 0..<10 {
            FSO.blob(&m, at: V3(rng.float(-0.2...0.2), rng.float(cy - 0.2...cy + 0.2), zT + 0.0044), size: V3(rng.float(0.004...0.01), rng.float(0.004...0.01), 0.001), "wood.weathered")
        }
        for sgn: Float in [-1, 1] {
            FSO.blob(&m, at: V3(sgn * bx, boardTop - 0.06, zA + bd / 2 + 0.0006), size: V3(0.012, rng.float(0.09...0.14), 0.0012), "metal.rust")
            FSO.blob(&m, at: V3(sgn * bx + 0.01, yArm - 0.0, zA + 0.0108), size: V3(0.016, 0.012, 0.0012), "metal.rust")
        }
        for dy: Float in [-0.1, 0.1] { FSO.blob(&m, at: V3(xP + 0.004, 0.66 + dy - 0.03, 0.0124), size: V3(0.008, 0.05, 0.0012), "metal.rust") }
        for _ in 0..<5 { FSO.blob(&m, at: V3(rng.float(-0.25...0.25), boardTop + 0.0005, zA + rng.float(-0.01...0.01)), size: V3(rng.float(0.02...0.04), 0.0012, 0.012), "stone.limestone") }
        FSO.blob(&m, at: V3(0.0, cy - 0.215, zT + 0.0035), size: V3(0.03, 0.006, 0.0012), "wood.weathered")
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}
