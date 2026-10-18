import simd
import Foundation

/// Tabletop map marker pin, 0.05 x 0.15 x 0.05 m: brushed stainless needle with a tapered tip, knurled collar and neck, a
/// brushed cap ring and a glowing orange emissive head knob inside a thin clear shell. A bent-tip scuff marks the needle.
/// Base y = 0 at the needle tip; the head sits at the top.
public struct EarthSitePin: RealAsset {
    public static let id = "earth-site-pin"
    public static let summary = "Tabletop map marker pin: brushed metal shaft, collar and a glowing emissive head knob."
    public static let tags = ["prop", "space", "datacenter", "metal"]
    public static let budget = 500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 1.0, studio: true)

    /// Head knob radius (m).
    public var headRadius: Float = 0.025
    public var metal: MaterialKey = "metal.aluminum-brushed"
    public var needle: MaterialKey = "metal.stainless"
    /// Glow of the head knob (swap for any emissive key).
    public var glow: MaterialKey = "emissive.signal-orange"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let hr = headRadius, hc = 0.15 - hr - 0.001
        // Needle: tip, shaft, shoulder.
        m.add(Prim.lathe([V2(0.0001, 0), V2(0.0006, 0.004), V2(0.0014, 0.03), V2(0.0018, 0.07), V2(0.0018, 0.078), V2(0.0001, 0.078)], segments: 10, seamTile: 0.05, material: needle), .identity)
        // Collar: stepped turned base with a chamfer, then neck.
        m.add(Prim.lathe([V2(0.0001, 0.074), V2(0.0085, 0.074), V2(0.0095, 0.076), V2(0.0095, 0.084), V2(0.0075, 0.086), V2(0.0045, 0.09), V2(0.0042, 0.108), V2(0.0001, 0.108)], segments: 16, seamTile: 0.05, material: metal), .identity)
        // Knurl ring.
        m.add(Prim.torus(major: 0.0095, minor: 0.0012, segments: 16, sides: 4, material: "metal.aluminum-brushed"), Xform(translation: V3(0, 0.08, 0)))
        // Cap ring under the head, then head shell and emissive core.
        m.add(Prim.lathe([V2(0.0001, 0.103), V2(0.0115, 0.103), V2(0.0125, 0.105), V2(0.0125, 0.11), V2(0.0085, 0.114), V2(0.0001, 0.114)], segments: 16, seamTile: 0.05, material: metal), .identity)
        m.add(Prim.cubeSphere(subdivisions: 5, material: glow) { d in d * (hr * 0.82) }, Xform(translation: V3(0, hc, 0)))
        m.add(Prim.cubeSphere(subdivisions: 5, material: "plastic.clear") { d in d * hr }, Xform(translation: V3(0, hc, 0)))
        groundAO(&m, height: 0.02, floor: 0.9)
        return LODModel(m)
    }
}
