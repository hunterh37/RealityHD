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
        // Clear glass-core interposer: pale blue-green, mostly transparent, TGV columns visible through it.
        MaterialSpec(key: "glass.substrate-clear", program: nil).with {
            $0.baseColor = V3(0.62, 0.74, 0.72); $0.roughness = 0.04; $0.specular = 0.6; $0.mode = .transparent; $0.opacity = 0.32; $0.twoSided = true
        },
        // Dark display glass: near-black, glossy, opaque, clearcoated.
        MaterialSpec(key: "glass.display", program: nil).with {
            $0.baseColor = V3(0.012, 0.016, 0.022); $0.roughness = 0.03; $0.specular = 0.8; $0.clearcoat = 1
        },
        // Holo-table grid lines: dim cyan emissive.
        MaterialSpec(key: "emissive.holo-grid", program: nil).with {
            $0.baseColor = V3(0.05, 0.3, 0.38); $0.mode = .emissive; $0.emissive = V3(0.15, 0.8, 1); $0.emissiveIntensity = 1.2
        },
        // Die block tile emissive tints, one per block type, kept dim.
        MaterialSpec(key: "emissive.die-tensor", program: nil).with {
            $0.baseColor = V3(0.2, 0.08, 0.35); $0.mode = .emissive; $0.emissive = V3(0.6, 0.25, 1); $0.emissiveIntensity = 0.5
        },
        MaterialSpec(key: "emissive.die-sram", program: nil).with {
            $0.baseColor = V3(0.04, 0.2, 0.3); $0.mode = .emissive; $0.emissive = V3(0.1, 0.7, 1); $0.emissiveIntensity = 0.45
        },
        MaterialSpec(key: "emissive.die-noc", program: nil).with {
            $0.baseColor = V3(0.3, 0.2, 0.04); $0.mode = .emissive; $0.emissive = V3(1, 0.7, 0.15); $0.emissiveIntensity = 0.5
        },
        MaterialSpec(key: "emissive.die-hbmphy", program: nil).with {
            $0.baseColor = V3(0.05, 0.3, 0.12); $0.mode = .emissive; $0.emissive = V3(0.2, 1, 0.4); $0.emissiveIntensity = 0.45
        },
        MaterialSpec(key: "emissive.die-io", program: nil).with {
            $0.baseColor = V3(0.3, 0.08, 0.1); $0.mode = .emissive; $0.emissive = V3(1, 0.3, 0.35); $0.emissiveIntensity = 0.45
        },
        // Design workbench holo plane: pale cyan translucent-looking emissive sheet.
        MaterialSpec(key: "emissive.holo-plane", program: nil).with {
            $0.baseColor = V3(0.1, 0.35, 0.45); $0.mode = .emissive; $0.emissive = V3(0.3, 0.85, 1); $0.emissiveIntensity = 0.8
        },
        // Hafnium oxide high-k gate dielectric: pale yellow-green translucent-looking satin film.
        MaterialSpec(key: "oxide.hafnium", program: .brushedMetal).with {
            $0.colorA = linear(0xC9D08A); $0.colorB = linear(0x9AA463)
            $0.knobs = V4(0.1, 0.1, 0.1, 0.05); $0.seed = 9820; $0.tileSize = 0.01; $0.normalStrength = 0.1
            $0.hasMetallicMap = true; $0.metallic = 0.1; $0.roughness = 0.25
        },
        // Tungsten gate fill and contact plugs: dark blue-grey satin metal.
        MaterialSpec(key: "metal.tungsten", program: .brushedMetal).with {
            $0.colorA = linear(0x6E7480); $0.colorB = linear(0x484C56)
            $0.knobs = V4(0.3, 0.3, 0.3, 0.2); $0.seed = 9821; $0.tileSize = 0.01; $0.normalStrength = 0.25
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.32
        },
        // Low-k interlayer dielectric (carbon-doped oxide): translucent-looking pale amber-grey.
        MaterialSpec(key: "oxide.lowk", program: .plastic).with {
            $0.colorA = linear(0x8F8A78); $0.knobs = V4(0.1, 0.1, 0.3, 0); $0.seed = 9822
            $0.tileSize = 0.02; $0.resolution = 512; $0.normalStrength = 0.1
        },
    ]
}
