import simd
import Foundation

/// Stainless countertop microwave: wrap-around shell, door with tinted perforated window, vertical bar
/// handle, side control panel with display, keypad and dial, rear vent slots, rubber feet.
public struct MicrowaveOven: RealAsset {
    public static let id = "microwave-oven"
    public static let summary = "Stainless microwave oven: window door with bar handle, display, keypad and dial, vent slots, feet."
    public static let tags = ["prop", "interior", "kitchen", "metal", "appliance"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth) including the handle.
    public var size = V3(0.50, 0.30, 0.40)
    /// Shell material.
    public var shell: MaterialKey = "metal.satin-aluminum"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias K = DD1DKitchen
        let W = size.x, H = size.y, D = size.z
        let foot: Float = 0.012
        let hOff: Float = 0.052
        let zB = -D / 2, zF = D / 2 - hOff     // body front plane; handle stands proud of it
        let bd = zF - zB
        let bz = (zF + zB) / 2
        let sw: MaterialKey = "metal.stainless-smudged"
        _ = rng.float()

        K.feet(&m, w: W, d: bd, inset: 0.035, h: foot, r: 0.013, zc: bz)
        // Shell: top and two sides wrap, back plate, base pan.
        K.box(&m, V3(W, 0.012, bd), V3(0, H - 0.006, bz), shell, r: 0.005)
        for sx: Float in [-1, 1] { K.box(&m, V3(0.012, H - foot, bd), V3(sx * (W / 2 - 0.006), foot + (H - foot) / 2, bz), shell, r: 0.005) }
        K.box(&m, V3(W - 0.02, H - foot - 0.01, 0.008), V3(0, foot + (H - foot) / 2, zB + 0.004), "metal.galvanized", r: 0.002)
        K.box(&m, V3(W - 0.02, 0.012, bd - 0.01), V3(0, foot + 0.006, bz), shell, r: 0.002)
        // Cavity: white enamel, inside faces, with lamp and glass turntable.
        let doorW: Float = 0.345, doorX0 = -W / 2 + 0.008
        let cx = doorX0 + doorW / 2
        let cLo = foot + 0.02, cHi = H - 0.022
        let cavD = bd - 0.04
        m.add(Prim.roundedBox(V3(doorW - 0.03, cHi - cLo, cavD), radius: 0.008, bevelSegments: 1, material: "metal.powder-white").flipped(),
              Xform(translation: V3(cx, (cLo + cHi) / 2, zB + 0.012 + cavD / 2)))
        K.cyl(&m, r: 0.12, h: 0.005, at: V3(cx, cLo + 0.012, bz), "glass.clear", bevel: 0.0015, seg: 36)
        K.cyl(&m, r: 0.018, h: 0.008, at: V3(cx, cLo + 0.004, bz), K.dark, seg: 16)
        K.box(&m, V3(0.04, 0.006, 0.05), V3(cx, cHi - 0.003, bz + 0.05), "emissive.warm", r: 0.002)
        // Front frame, divider, door.
        K.box(&m, V3(doorW, 0.022, 0.012), V3(cx, cHi + 0.011, zF - 0.006), shell, r: 0.002)
        K.box(&m, V3(doorW, 0.02, 0.012), V3(cx, cLo - 0.01, zF - 0.006), shell, r: 0.002)
        let dh = H - foot - 0.01, dcy = foot + 0.005 + dh / 2
        let dT: Float = 0.032
        let rail: Float = 0.03
        K.box(&m, V3(doorW, rail, dT), V3(cx, dcy + dh / 2 - rail / 2, zF + dT / 2 - 0.004), shell, r: 0.005)
        K.box(&m, V3(doorW, rail, dT), V3(cx, dcy - dh / 2 + rail / 2, zF + dT / 2 - 0.004), shell, r: 0.005)
        K.box(&m, V3(rail, dh - 2 * rail + 0.004, dT), V3(doorX0 + rail / 2, dcy, zF + dT / 2 - 0.004), shell, r: 0.004)
        K.box(&m, V3(rail + 0.01, dh - 2 * rail + 0.004, dT), V3(doorX0 + doorW - rail / 2 - 0.005, dcy, zF + dT / 2 - 0.004), sw, r: 0.004)
        let ww = doorW - 2 * rail - 0.01 + 0.004, wh = dh - 2 * rail + 0.004
        let wx = cx - 0.002
        m.add(cuboid(V3(ww + 0.01, wh + 0.01, 0.006), material: K.dark), Xform(translation: V3(wx, dcy, zF + 0.012)))
        m.add(cuboid(V3(ww, wh, 0.004), material: "glass.tinted"), Xform(translation: V3(wx, dcy, zF + 0.0155)))
        m.add(cuboid(V3(ww - 0.004, wh - 0.004, 0.002), material: "glass.wire-mesh"), Xform(translation: V3(wx, dcy, zF + 0.0175)))
        // Door gasket seen at the gap.
        K.box(&m, V3(doorW - 0.02, 0.006, 0.004), V3(cx, dcy + dh / 2 - 0.004, zF - 0.002), "rubber.silicone-gray", r: 0.001)
        // Vertical bar handle on the free edge, standing 22 mm proud of the door face.
        let hx = doorX0 + doorW - 0.022
        let doorFace = zF + dT - 0.004
        K.cyl(&m, r: 0.0085, h: 0.2, at: V3(hx, dcy - 0.1, doorFace + 0.016), "metal.stainless-smudged", bevel: 0.003, seg: 14)
        for hy: Float in [-0.085, 0.085] {
            K.cylZ(&m, r: 0.006, len: 0.016, at: V3(hx, dcy + hy, doorFace), shell, bevel: 0.0015, seg: 10)
        }
        // Control panel: black fascia, display, keypad, dial, release button.
        let panelX0 = doorX0 + doorW + 0.006
        let pw = W / 2 - 0.006 - panelX0, pcx = (panelX0 + W / 2 - 0.006) / 2
        K.box(&m, V3(pw, H - foot - 0.012, 0.012), V3(pcx, foot + (H - foot) / 2, zF - 0.006 + 0.003), "plastic.matte:2A2A2C", r: 0.004)
        K.display(&m, at: V3(pcx, H - 0.058, zF + 0.0), w: pw - 0.02, h: 0.036)
        for r in 0..<4 { for c in 0..<3 {
            K.box(&m, V3(0.026, 0.016, 0.005), V3(pcx + (Float(c) - 1) * 0.034, H - 0.105 - Float(r) * 0.026, zF + 0.0035), "plastic.matte:8A8C90", r: 0.003)
        } }
        K.dial(&m, at: V3(pcx, foot + 0.07, zF + 0.0), r: 0.021, mat: "metal.stainless")
        K.box(&m, V3(0.035, 0.012, 0.008), V3(pcx, foot + 0.025, zF + 0.002), "plastic.matte:3A3A3D", r: 0.003)
        // Rear vent slots and side louvres.
        K.vents(&m, n: 12, at: V3(0, H - 0.04, zB - 0.0005), pitch: 0.03, size: V3(0.018, 0.003, 0.002))
        for sx: Float in [-1, 1] { for i in 0..<5 {
            K.seam(&m, V3(0.0016, 0.004, 0.04), V3(sx * (W / 2 + 0.0006), H - 0.05 - Float(i) * 0.012, bz - 0.06))
        } }
        // Door seam.
        K.seam(&m, V3(0.001, dh - 0.008, 0.002), V3(doorX0 + doorW + 0.002, dcy, zF + 0.002))
        K.cord(&m, from: V3(0.18, 0.05, zB), to: V3(0.24, 0, zB - 0.012))
        // Story: sauce spatters on the window and a used start key.
        K.drip(&m, at: V3(wx - 0.05, dcy + 0.02, zF + 0.0185), w: 0.006, len: 0.05, "food.tomato-sauce")
        K.drip(&m, at: V3(wx + 0.04, dcy + 0.05, zF + 0.0185), w: 0.004, len: 0.035, "food.tomato-sauce")
        K.blob(&m, V3(wx + 0.01, dcy - 0.05, zF + 0.0185), V3(0.02, 0.012, 0.003), "food.tomato-sauce")
        K.box(&m, V3(0.03, 0.02, 0.0015), V3(pcx, H - 0.19, zF + 0.0065), "plastic.matte:C8C8CC", r: 0.002)
        groundAO(&m)
        return LODModel(m)
    }
}
