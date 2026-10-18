import Foundation
import RealCore

public extension MaterialLibrary {
    /// Terawatt Fab family: wafer thin-film states and smoke polycarbonate for FOUP shells.
    static let terawattFab: [MaterialSpec] = [
        // Smoke-tinted polycarbonate (FOUP shell): translucent, glossy, faint grey-brown cast.
        MaterialSpec(key: "plastic.polycarbonate-tint", program: nil).with {
            $0.baseColor = V3(0.10, 0.10, 0.11); $0.roughness = 0.12; $0.specular = 0.5
            $0.mode = .transparent; $0.opacity = 0.62; $0.twoSided = true
        },
        // Equipment service window: light blue-grey tint, mostly transparent so chamber contents read.
        MaterialSpec(key: "glass.window-tint", program: nil).with {
            $0.baseColor = V3(0.30, 0.38, 0.42); $0.roughness = 0.04; $0.specular = 0.6
            $0.mode = .transparent; $0.opacity = 0.22; $0.twoSided = true
        },
        // Bare polished silicon: dark mirror, blue-grey cast.
        MaterialSpec(key: "silicon.thinfilm", program: .polishedMetal).with {
            $0.colorA = linear(0x7C8290); $0.colorB = linear(0x4A505C); $0.colorC = linear(0x8E96A8)
            $0.knobs = V4(0.2, 0.01, 8, 0.06); $0.seed = 3101; $0.tileSize = 0.3; $0.normalStrength = 0.05
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.06
        },
        // Oxide film: violet-gold interference tint.
        MaterialSpec(key: "silicon.thinfilm-oxide", program: .polishedMetal).with {
            $0.colorA = linear(0x6C5A9A); $0.colorB = linear(0x3C6C8C); $0.colorC = linear(0xB08A5A)
            $0.knobs = V4(0.3, 0.01, 6, 0.07); $0.seed = 3102; $0.tileSize = 0.3; $0.normalStrength = 0.05
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.07
        },
        // Patterned: green-teal diffraction from the die grid.
        MaterialSpec(key: "silicon.thinfilm-patterned", program: .polishedMetal).with {
            $0.colorA = linear(0x4E9A7A); $0.colorB = linear(0x7A5AA0); $0.colorC = linear(0xC0A040)
            $0.knobs = V4(0.5, 0.02, 14, 0.09); $0.seed = 3103; $0.tileSize = 0.1; $0.normalStrength = 0.1
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.09
        },
        // Metal-coated: bright copper-silver mirror.
        MaterialSpec(key: "silicon.thinfilm-metal", program: .polishedMetal).with {
            $0.colorA = linear(0xC8A890); $0.colorB = linear(0x9A8070); $0.colorC = linear(0xD8D0C8)
            $0.knobs = V4(0.2, 0.01, 8, 0.1); $0.seed = 3104; $0.tileSize = 0.3; $0.normalStrength = 0.05
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.1
        },
        // Per-die interference variants, scribe lane, exclusion rim and handling marks.
        MaterialSpec(key: "silicon.die-a", program: .polishedMetal).with {
            $0.colorA = linear(0x4FB0A8); $0.colorB = linear(0x9A60C8); $0.colorC = linear(0xE0B848)
            $0.knobs = V4(0.35, 0.02, 18, 0.08); $0.seed = 3111; $0.tileSize = 0.026; $0.normalStrength = 0.04
            $0.hasMetallicMap = true; $0.metallic = 0.55; $0.roughness = 0.22
        },
        MaterialSpec(key: "silicon.die-b", program: .polishedMetal).with {
            $0.colorA = linear(0x5C90E0); $0.colorB = linear(0xC860A8); $0.colorC = linear(0x58C8B8)
            $0.knobs = V4(0.35, 0.02, 20, 0.08); $0.seed = 3112; $0.tileSize = 0.026; $0.normalStrength = 0.04
            $0.hasMetallicMap = true; $0.metallic = 0.55; $0.roughness = 0.22
        },
        MaterialSpec(key: "silicon.die-c", program: .polishedMetal).with {
            $0.colorA = linear(0xC890C0); $0.colorB = linear(0x58A0D8); $0.colorC = linear(0xE0A860)
            $0.knobs = V4(0.35, 0.02, 16, 0.08); $0.seed = 3113; $0.tileSize = 0.026; $0.normalStrength = 0.04
            $0.hasMetallicMap = true; $0.metallic = 0.55; $0.roughness = 0.22
        },
        MaterialSpec(key: "silicon.die-d", program: .polishedMetal).with {
            $0.colorA = linear(0x58C8A0); $0.colorB = linear(0xA890D8); $0.colorC = linear(0xE0A070)
            $0.knobs = V4(0.35, 0.02, 22, 0.08); $0.seed = 3114; $0.tileSize = 0.026; $0.normalStrength = 0.04
            $0.hasMetallicMap = true; $0.metallic = 0.55; $0.roughness = 0.22
        },
        // Bare silicon: bright grey mirror for the edge exclusion ring and bevel.
        MaterialSpec(key: "silicon.bare", program: .polishedMetal).with {
            $0.colorA = linear(0xE8ECF2); $0.colorB = linear(0xC0C6D0); $0.colorC = linear(0xE0E4EA)
            $0.knobs = V4(0.1, 0.01, 6, 0.04); $0.seed = 3121; $0.tileSize = 0.3; $0.normalStrength = 0.03
            $0.hasMetallicMap = true; $0.metallic = 0.5; $0.roughness = 0.2
        },
        // Faint handling marks and laser dots: slightly rougher, lighter.
        MaterialSpec(key: "silicon.mark", program: .polishedMetal).with {
            $0.colorA = linear(0xD8DCE4); $0.colorB = linear(0xB8BEC8); $0.colorC = linear(0xF0F2F6)
            $0.knobs = V4(0.1, 0.01, 6, 0.04); $0.seed = 3122; $0.tileSize = 0.05; $0.normalStrength = 0.1
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.35
        },
        // CMP polishing pad: grey-beige closed-cell polyurethane, matte, faint slurry-stained noise.
        MaterialSpec(key: "plastic.pad", program: .plastic).with {
            $0.colorA = linear(0x8C8A84); $0.knobs = V4(0.6, 0.5, 0.5, 0); $0.tileSize = 0.12; $0.resolution = 512; $0.seed = 3140
            $0.roughness = 0.85
        },
        // Fused quartz (furnace boats, tubes): translucent milky-clear, glossy.
        MaterialSpec(key: "quartz", program: nil).with {
            $0.baseColor = V3(0.78, 0.82, 0.84); $0.roughness = 0.1; $0.specular = 0.5
            $0.mode = .transparent; $0.opacity = 0.7; $0.twoSided = true
        },
        // PVDF / polypropylene wet-bench deck: off-white, semi-matte, fine moulded grain.
        MaterialSpec(key: "plastic.pvdf", program: .plastic).with {
            $0.colorA = linear(0xD8D7CE); $0.knobs = V4(0.15, 0.1, 0.35, 0); $0.seed = 3150; $0.tileSize = 0.3; $0.resolution = 512
            $0.normalStrength = 0.25; $0.roughness = 0.42
        },
    ]
}
