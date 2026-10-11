import RealityKit
import RealCore
import RealMaterials

public extension RealMaterialCache {
    /// Heat shield at a char amount 0 (virgin) ... 1 (fully charred): the `RealHeat.ablativeKey` texture
    /// with its base color darkened up to 30 % across each key's band. PhysicallyBasedMaterial copy; call
    /// again as heat changes and assign to `ModelComponent.materials`.
    func ablativeMaterial(heat: Float) -> any RealityKit.Material {
        let h = max(0, min(1, heat))
        let key = RealHeat.ablativeKey(heat: h)
        let band = h < 0.33 ? h / 0.33 : h < 0.67 ? (h - 0.33) / 0.34 : (h - 0.67) / 0.33
        return material(key, brightness: 1 - 0.3 * band)
    }

    /// Engine bell at wall temperature `kelvin`: `metal.heat-tint-cold` textures plus a blackbody
    /// emissive (none below 800 K, orange at 1300 K, yellow-white near 2000 K). PhysicallyBasedMaterial copy.
    func engineBellMaterial(kelvin: Float) -> any RealityKit.Material {
        let base = material("metal.heat-tint-cold")
        guard var m = base as? PhysicallyBasedMaterial else { return base }
        let g = RealHeat.glow(kelvin: kelvin)
        guard g > 0 else { return m }
        let c = RealHeat.blackbody(kelvin: kelvin)
        m.emissiveColor = .init(color: .init(c))
        m.emissiveIntensity = min(8, g * 2)
        return m
    }
}
