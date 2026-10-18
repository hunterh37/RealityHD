import simd
import Foundation

/// Shared fab-equipment parts built on ClusterKit.
public enum FabParts {
    /// SEMI load port with docked FOUP on a front face at `z` (face normal +Z). `fy` is the port shelf height.
    public static func loadPort(_ k: ClusterKit, x px: Float, z ezf: Float, frame: MaterialKey, skin: MaterialKey) {
        let hi = k.hi, fy: Float = 0.98, y0: Float = 0.12
        let anod: MaterialKey = "metal.anodized", dk: MaterialKey = "plastic.matte:2A2C2F", dk2: MaterialKey = "plastic.matte:3A3C40"
        k.bx(V3(0.46, fy - y0, 0.3), V3(px, (fy + y0) / 2, ezf + 0.15), skin, r: 0.006)
        k.bx(V3(0.5, 0.03, 0.42), V3(px, fy - 0.015, ezf + 0.21), anod, r: 0.004)
        k.bx(V3(0.46, 0.66, 0.025), V3(px, fy + 0.33, ezf + 0.0125), frame, r: 0.004)
        k.bx(V3(0.34, 0.3, 0.01), V3(px, fy + 0.2, ezf + 0.03), "metal.powdercoat:1A1C1F", r: 0.002)
        k.bx(V3(0.05, 0.016, 0.006), V3(px + 0.17, fy + 0.58, ezf + 0.028), "glass.lamp:40E060", r: 0.001)
        k.bx(V3(0.05, 0.016, 0.006), V3(px - 0.17, fy + 0.58, ezf + 0.028), "glass.lamp:F0A020", r: 0.001)
        let zc = ezf + 0.19
        k.bx(V3(0.316, 0.29, 0.26), V3(px, fy + 0.162, zc + 0.01), "plastic.polycarbonate-tint", r: 0.004)
        k.bx(V3(0.33, 0.30, 0.012), V3(px, fy + 0.167, zc - 0.12), dk, r: 0.003)
        k.bx(V3(0.3, 0.012, 0.28), V3(px, fy + 0.011, zc), dk, r: 0.002)
        k.cyl(0.013, 0.03, V3(px, fy + 0.307, zc), dk2, seg: 12)
        k.bx(V3(0.19, 0.008, 0.09), V3(px, fy + 0.341, zc), dk2, r: 0.002)
        if hi { for q in 0..<3 { k.bx(V3(0.29, 0.07, 0.26), V3(px, fy + 0.08 + Float(q) * 0.085, zc + 0.01), "silicon.thinfilm", r: 0) } }
    }

    /// Four-lamp status tower.
    public static func statusTower(_ k: ClusterKit, _ p: V3) {
        k.cyl(0.03, 0.02, p, "metal.anodized", seg: 12)
        k.cyl(0.011, 0.14, p + V3(0, 0.02, 0), "metal.stainless", seg: 8)
        for (q, col) in ["E03020", "F0A020", "30C050", "F4F8FF"].enumerated() {
            k.cyl(0.032, 0.05, p + V3(0, 0.16 + Float(q) * 0.052, 0), MaterialKey(stringLiteral: "glass.lamp:" + col), seg: 14)
        }
        k.cyl(0.03, 0.012, p + V3(0, 0.37, 0), "plastic.matte:1E2023", seg: 12)
    }

    /// Cleanroom grate floor, w x d, top at y 0.05.
    public static func grate(_ k: ClusterKit, w: Float, d: Float) {
        k.m.add(Prim.extrude(Shape2D.rect(w, d), depth: 0.05, bevel: 0.004, bevelSegments: 1, material: "metal.grate-iron"),
                Xform(translation: V3(0, 0.025, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }
}
