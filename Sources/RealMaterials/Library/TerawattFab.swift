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
    ]
}
