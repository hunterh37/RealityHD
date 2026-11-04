import RealCore

public extension MaterialLibrary {
    /// Environment pack: volcanic (lava, scoria, obsidian, ash), glacial ice, open ocean, hemp rope, cavern crystal.
    /// `lava.*` use `lavaFlow` (unlit emitter): coverage knob is the fraction of the surface under dark crust.
    static let environment: [MaterialSpec] = {
        func lava(_ k: String, cover: Float, plates: Float, crack: Float, stretch: Float, hot: UInt32, mid: UInt32, tile: Float, seed: UInt32) -> MaterialSpec {
            MaterialSpec(key: k, program: .lavaFlow).with {
                $0.colorA = linear(hot); $0.colorB = linear(mid); $0.colorC = linear(0x120A07)
                $0.knobs = V4(cover, plates, crack, stretch); $0.seed = seed; $0.tileSize = tile; $0.resolution = 1024
                $0.mode = .emissive; $0.emissiveIntensity = 1; $0.normalStrength = 1; $0.hasAOMap = false
            }
        }
        func crystal(_ k: String, base: V3, glow: V3, k2: Float) -> MaterialSpec {
            MaterialSpec(key: k, program: nil).with {
                $0.baseColor = base; $0.roughness = 0.07; $0.clearcoat = 1; $0.specular = 0.9; $0.mode = .emissive
                $0.emissive = glow; $0.emissiveIntensity = k2
            }
        }
        return [
            // Molten rock: active channel with broken plates, lake surface with thin crust, and a nearly bare rivulet.
            lava("lava.molten", cover: 0.74, plates: 3, crack: 0.12, stretch: 3, hot: 0xFFD25A, mid: 0xF0560C, tile: 6, seed: 8101),
            lava("lava.lake", cover: 0.4, plates: 4, crack: 0.12, stretch: 1.2, hot: 0xFFC845, mid: 0xE84708, tile: 12, seed: 8102),
            lava("lava.rivulet", cover: 0.12, plates: 4, crack: 0.08, stretch: 3, hot: 0xFFE48A, mid: 0xFF6A12, tile: 2.5, seed: 8103),
            // Cooling flow: mostly crust, orange cracks.
            lava("lava.crusted", cover: 0.95, plates: 3, crack: 0.06, stretch: 2, hot: 0xFF9A30, mid: 0xB5340A, tile: 8, seed: 8104),
            MaterialSpec(key: "emissive.lava-core", program: nil).with {
                $0.baseColor = V3(1, 0.4, 0.06); $0.mode = .emissive; $0.emissive = V3(1, 0.36, 0.05); $0.emissiveIntensity = 5
            },
            // Vesicular scoria: red-black, pitted, rough.
            MaterialSpec(key: "rock.scoria", program: .rockGranite).with {
                $0.colorA = linear(0x231C19); $0.colorB = linear(0x3C2C25); $0.colorC = linear(0x6E3A24)
                $0.knobs = V4(0.35, 0.55, 0.8, 0.1); $0.seed = 8111; $0.tileSize = 0.8; $0.normalStrength = 3.2; $0.triplanar = true
                $0.roughness = 0.92
            },
            // Volcanic glass: black, mirror-polished fracture faces.
            MaterialSpec(key: "rock.obsidian", program: nil).with {
                $0.baseColor = V3(0.012, 0.012, 0.015); $0.roughness = 0.1; $0.clearcoat = 1; $0.specular = 0.85
            },
            // Fresh ash and lapilli over scorched ground.
            MaterialSpec(key: "ground.ash", program: .sand).with {
                $0.colorA = linear(0x2E2B29); $0.colorB = linear(0x171514); $0.colorC = linear(0x56504A)
                $0.knobs = V4(1.0, 0, 0.12, 30); $0.seed = 8121; $0.tileSize = 2.5; $0.normalStrength = 3; $0.resolution = 2048
                $0.antiTile = true; $0.roughness = 0.95
                $0.splat = "ground.lava-field"; $0.splatSoftness = 0.3; $0.splatHeight = 1.4
            },
            // Cooled pahoehoe and aa: dark basalt ground, rough, fractured.
            MaterialSpec(key: "ground.lava-field", program: .gravel).with {
                $0.colorA = linear(0x262321); $0.colorB = linear(0x3A3330); $0.colorC = linear(0x5C3A2A)
                $0.knobs = V4(0.7, 0.4, 0.2, 0); $0.seed = 8122; $0.tileSize = 2.0; $0.normalStrength = 4; $0.resolution = 2048
                $0.antiTile = true; $0.roughness = 0.9
            },
            // Glacial ice: translucent-looking blue pressure ice with white fractures.
            MaterialSpec(key: "ice.glacier", program: .glacierIce).with {
                $0.colorA = linear(0x1A5C86); $0.colorB = linear(0x8CCBEA); $0.colorC = linear(0xEAF6FF)
                $0.knobs = V4(7, 1, 1, 0); $0.seed = 8131; $0.tileSize = 2.5; $0.resolution = 2048; $0.normalStrength = 2.4
                $0.roughness = 0.2; $0.clearcoat = 0.7; $0.specular = 0.6; $0.triplanar = true
            },
            // Serac: glacier ice with wind-packed snow lying on its upward faces.
            MaterialSpec(key: "ice.serac", program: .glacierIce).with {
                $0.colorA = linear(0x2A78A4); $0.colorB = linear(0xA9D8F0); $0.colorC = linear(0xEFF8FF)
                $0.knobs = V4(5, 0.8, 0.8, 0); $0.seed = 8133; $0.tileSize = 3.5; $0.resolution = 2048; $0.normalStrength = 2.4
                $0.roughness = 0.25; $0.clearcoat = 0.5; $0.specular = 0.55; $0.triplanar = true
                $0.topColor = linear(0xEDF1F6); $0.topAmount = 0.5; $0.topLow = 0.8
            },
            // Firn and snow over the glacier, blue ice painted in on the steep faces through the splat weights.
            MaterialSpec(key: "ground.glacier-snow", program: .snow).with {
                $0.colorA = linear(0xE6EBF2); $0.colorB = linear(0xBFD0E2); $0.colorC = linear(0x8FA6BE)
                $0.knobs = V4(1.0, 0.7, 0.5, 0); $0.seed = 8132; $0.tileSize = 3.0; $0.normalStrength = 3; $0.resolution = 2048
                $0.antiTile = true; $0.splat = "ice.glacier"; $0.splatSoftness = 0.25; $0.splatHeight = 1.2
            },
            // Open sea: deep green-blue, fast two-layer swell.
            MaterialSpec(key: "water.ocean", program: .water).with {
                $0.colorA = linear(0x06222E); $0.colorB = linear(0x2F6F7A); $0.knobs = V4(0.6, 0, 0, 0); $0.seed = 8141
                $0.tileSize = 14; $0.resolution = 1024; $0.normalStrength = 0.5; $0.mode = .transparent; $0.opacity = 0.82
                $0.roughness = 0.05; $0.specular = 0.6; $0.flow = 0.3; $0.hasAOMap = false
            },
            // Surf foam: white, rough, slightly translucent sheet.
            MaterialSpec(key: "water.foam", program: nil).with {
                $0.baseColor = V3(0.82, 0.88, 0.9); $0.roughness = 0.7; $0.mode = .transparent; $0.opacity = 0.7
            },
            // Hemp rope: three-strand lay, tan.
            MaterialSpec(key: "rope.hemp", program: .jute).with {
                $0.colorA = linear(0x9A7E54); $0.colorB = linear(0x3E3020); $0.colorC = linear(0x7C6340)
                $0.knobs = V4(0, 0.2, 40, 0); $0.seed = 8151; $0.tileSize = 0.12; $0.normalStrength = 2.4; $0.roughness = 0.95
            },
            // Cavern crystals: glassy faceted PBR with an inner glow; one per light color.
            crystal("crystal.cyan", base: V3(0.10, 0.45, 0.6), glow: V3(0.1, 0.7, 1.0), k2: 1.6),
            crystal("crystal.magenta", base: V3(0.5, 0.1, 0.45), glow: V3(1.0, 0.15, 0.8), k2: 1.4),
            crystal("crystal.amber", base: V3(0.6, 0.35, 0.06), glow: V3(1.0, 0.55, 0.08), k2: 1.5),
            // Bioluminescent pit lake: dark teal body with a steady glow.
            MaterialSpec(key: "emissive.abyss-lake", program: nil).with {
                $0.baseColor = V3(0.01, 0.07, 0.08); $0.roughness = 0.05; $0.clearcoat = 1; $0.mode = .emissive
                $0.emissive = V3(0.03, 0.55, 0.5); $0.emissiveIntensity = 1.3
            },
            // Mountain strata everywhere, alpine turf painted in through the splat weights on the gentler ground.
            MaterialLibrary.wild.first { $0.key == "rock.mountain" }!.with {
                $0.key = "ground.alpine-cliff"; $0.splat = "ground.alpine"; $0.splatSoftness = 0.25; $0.splatHeight = 1.2; $0.topAmount = 0
            },
            // Deep open water seen far off: dark teal, glossy, opaque.
            MaterialSpec(key: "water.deep", program: nil).with {
                $0.baseColor = V3(0.012, 0.05, 0.062); $0.roughness = 0.06; $0.clearcoat = 1; $0.specular = 0.7
            },
            // Alpine peaks: dark rock, snow only on the gentler faces.
            MaterialSpec(key: "rock.alpine-peak", program: .strataRock).with {
                $0.colorA = linear(0x3E4650); $0.colorB = linear(0x66707C); $0.colorC = linear(0x50585F)
                $0.knobs = V4(0.5, 14, 0.4, 0.3); $0.seed = 8171; $0.tileSize = 40; $0.normalStrength = 3; $0.triplanar = true
                $0.topColor = linear(0xF2F6FB); $0.topAmount = 1.0; $0.topLow = 0.5; $0.roughness = 0.85
            },
            // Damp cave limestone: dark, wet sheen.
            MaterialSpec(key: "rock.cave", program: .rockGranite).with {
                $0.colorA = linear(0x3A3836); $0.colorB = linear(0x56534F); $0.colorC = linear(0x4A4A4E)
                $0.knobs = V4(0.4, 0.4, 0.6, 0.2); $0.seed = 8161; $0.tileSize = 1.5; $0.normalStrength = 3; $0.triplanar = true
                $0.roughness = 0.55; $0.clearcoat = 0.2
            },
        ]
    }()
}
