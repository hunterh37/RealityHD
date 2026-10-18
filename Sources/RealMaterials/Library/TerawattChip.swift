import RealCore

public extension MaterialLibrary {
    /// Semiconductor packaging: mirror-polished silicon die, ABF build-up laminate, plated gold and nickel,
    /// SAC solder, underfill epoxy.
    static let terawattChip: [MaterialSpec] = [
        // Polished device-side silicon: dark blue-grey mirror with faint metal-layer interference.
        MaterialSpec(key: "silicon.die", program: .brushedMetal).with {
            $0.colorA = linear(0x2B3140); $0.colorB = linear(0x4A4F66)
            $0.knobs = V4(0.15, 0.1, 0.1, 0.05); $0.seed = 9801; $0.tileSize = 0.01; $0.normalStrength = 0.15
            $0.hasMetallicMap = true; $0.metallic = 0.85; $0.roughness = 0.14
        },
        // Diced silicon edge and backside grind: lighter, matte grey.
        MaterialSpec(key: "silicon.die-edge", program: .brushedMetal).with {
            $0.colorA = linear(0x7C8088); $0.colorB = linear(0x585C64)
            $0.knobs = V4(0.5, 0.5, 0.3, 0.2); $0.seed = 9802; $0.tileSize = 0.01; $0.normalStrength = 0.5
            $0.hasMetallicMap = true; $0.metallic = 0.6; $0.roughness = 0.45
        },
        // ABF build-up laminate under green-black solder mask: satin, faint weave print-through.
        MaterialSpec(key: "laminate.abf", program: .plastic).with {
            $0.colorA = linear(0x1F3A2A); $0.knobs = V4(0.2, 0.15, 0.4, 0); $0.seed = 9803
            $0.tileSize = 0.02; $0.resolution = 512; $0.normalStrength = 0.4
        },
        // ENIG gold pad plating.
        MaterialSpec(key: "metal.gold", program: .polishedMetal).with {
            $0.colorA = linear(0xE2B84E); $0.colorB = linear(0x8A6A22); $0.colorC = linear(0x8A6A22)
            $0.knobs = V4(0.08, 0.0, 0, 0.18); $0.seed = 9804; $0.tileSize = 0.02; $0.normalStrength = 0.25
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.2
        },
        // Nickel-plated copper lid (integrated heat spreader): satin, hairline machining marks.
        MaterialSpec(key: "metal.nickel", program: .brushedMetal).with {
            $0.colorA = linear(0xC4C3BE); $0.colorB = linear(0x8E8D88)
            $0.knobs = V4(0.6, 0.3, 0.4, 0.3); $0.seed = 9805; $0.tileSize = 0.03; $0.normalStrength = 0.4
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.3
        },
        // SAC305 solder: dull silver-grey.
        MaterialSpec(key: "metal.solder", program: .brushedMetal).with {
            $0.colorA = linear(0xA7A9AC); $0.colorB = linear(0x6B6D70)
            $0.knobs = V4(0.2, 0.5, 0.3, 0.1); $0.seed = 9806; $0.tileSize = 0.005; $0.normalStrength = 0.3
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.35
        },
        // Capillary underfill epoxy: dark amber-black fillet.
        MaterialSpec(key: "plastic.underfill", program: .plastic).with {
            $0.colorA = linear(0x2A2218); $0.knobs = V4(0.1, 0.1, 0.3, 0); $0.seed = 9807
            $0.tileSize = 0.01; $0.resolution = 512; $0.normalStrength = 0.2
        },
        // Glass-core interposer: pale blue-green, slightly translucent-looking satin glass with copper RDL beneath.
        MaterialSpec(key: "glass.substrate", program: .brushedMetal).with {
            $0.colorA = linear(0xB4C6C1); $0.colorB = linear(0x8FA39F)
            $0.knobs = V4(0.15, 0.2, 0.1, 0.05); $0.seed = 9808; $0.tileSize = 0.01; $0.normalStrength = 0.1
            $0.hasMetallicMap = true; $0.metallic = 0.25; $0.roughness = 0.12
        },
    ]
}
