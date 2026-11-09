import RealCore

public extension MaterialLibrary {
    /// Woven fabric (`fabricWeave`). Tints replace the yarn color: `fabric.nylon:C8501E`.
    static let fabric: [MaterialSpec] = [
        // Jute hessian, about 4 threads per cm with open gaps and loose fibers.
        MaterialSpec(key: "fabric.burlap", program: .fabricWeave).with {
            $0.colorA = linear(0xA2875F); $0.colorB = linear(0x7C6442, 1); $0.colorC = linear(0x4A3A28, 0.25)
            $0.knobs = V4(24, 0.8, 0.93, 0); $0.seed = 21; $0.tileSize = 0.06; $0.normalStrength = 4
            $0.roughness = 0.93
        },
        // Cotton duck canvas, about 10 threads per cm, tight weave.
        MaterialSpec(key: "fabric.canvas", program: .fabricWeave).with {
            $0.colorA = linear(0xB9AD92); $0.colorB = linear(0xA3967A, 0.1); $0.colorC = linear(0x584836, 0.2)
            $0.knobs = V4(40, 0.3, 0.86, 0); $0.seed = 22; $0.tileSize = 0.04; $0.normalStrength = 2.5
            $0.roughness = 0.86
        },
        // Coated ripstop nylon (tent fly), 5 mm ripstop grid, low roughness sheen.
        MaterialSpec(key: "fabric.nylon", program: .fabricWeave).with {
            $0.colorA = linear(0x4A6B3E); $0.colorB = linear(0x4A6B3E, 0); $0.colorC = linear(0x5A5040, 0.12)
            $0.knobs = V4(80, 0, 0.42, 10); $0.seed = 23; $0.tileSize = 0.05; $0.normalStrength = 1
            $0.roughness = 0.45
        },
        // Felted wool blanket, thick fuzzy yarn.
        MaterialSpec(key: "fabric.wool", program: .fabricWeave).with {
            $0.colorA = linear(0x7A2A22); $0.colorB = linear(0x5C201A, 1); $0.colorC = linear(0x3A2A20, 0.1)
            $0.knobs = V4(16, 1, 0.96, 0); $0.seed = 24; $0.tileSize = 0.03; $0.normalStrength = 3
            $0.roughness = 0.96
        },
        // Heavy slub linen drapery (curtains): oatmeal, visible slubs, soft sheen. Single-sided; curtains are built as a front and a back shell 2 mm apart.
        MaterialSpec(key: "fabric.drapery", program: .fabricWeave).with {
            $0.colorA = linear(0xD8CCB0); $0.colorB = linear(0xC4B696, 0.25); $0.colorC = linear(0x6A5C44, 0.08)
            $0.knobs = V4(34, 0.55, 0.88, 0); $0.seed = 25; $0.tileSize = 0.05; $0.normalStrength = 2
            $0.roughness = 0.88; $0.translucency = 0.45
        },
        // Cotton velvet (premiere ropes, theater seats): dense short pile, deep crimson, strong grazing sheen. Tint for color.
        MaterialSpec(key: "fabric.velvet", program: .fabricWeave).with {
            $0.colorA = linear(0x8A0F1E); $0.colorB = linear(0x5E0912, 0.6); $0.colorC = linear(0xC0303C, 0.08)
            $0.knobs = V4(120, 0.9, 0.7, 0); $0.seed = 26; $0.tileSize = 0.02; $0.normalStrength = 1.2
            $0.roughness = 0.62
        },
        // Pressed fur felt (hats): fine dense fibers, no visible weave, soft sheen. Tint for color.
        MaterialSpec(key: "fabric.felt", program: .fabricWeave).with {
            $0.colorA = linear(0x1A1A1C); $0.colorB = linear(0x1A1A1C, 0); $0.colorC = linear(0x3A3632, 0.04)
            $0.knobs = V4(220, 1, 0.82, 0); $0.seed = 27; $0.tileSize = 0.03; $0.normalStrength = 0.6
            $0.roughness = 0.82
        },
        // Silk grosgrain ribbon (hat bands, bows): fine horizontal ribs, satin sheen. Tint for color.
        MaterialSpec(key: "fabric.grosgrain", program: .fabricWeave).with {
            $0.colorA = linear(0x101012); $0.colorB = linear(0x101012, 0); $0.colorC = linear(0x000000, 0)
            $0.knobs = V4(160, 0.1, 0.38, 0); $0.seed = 28; $0.tileSize = 0.02; $0.normalStrength = 1.4
            $0.roughness = 0.38; $0.specular = 0.6
        },
        // Hand-knit wool yarn (mittens, scarves): chunky fuzzy stitches, single clean color. Tint for color.
        MaterialSpec(key: "fabric.knit", program: .fabricWeave).with {
            $0.colorA = linear(0xB01C24); $0.colorB = linear(0xB01C24, 0); $0.colorC = linear(0x3A2A20, 0.05)
            $0.knobs = V4(14, 1, 0.95, 0); $0.seed = 29; $0.tileSize = 0.035; $0.normalStrength = 3.2
            $0.roughness = 0.95
        },
        // Academic gown polyester satin (graduation caps and gowns): fine twill, matte with a soft satin sheen. Tint for color.
        MaterialSpec(key: "fabric.gown", program: .fabricWeave).with {
            $0.colorA = linear(0x111114); $0.colorB = linear(0x0B0B0E, 0.35); $0.colorC = linear(0x34343A, 0.06)
            $0.knobs = V4(110, 0.25, 0.6, 0); $0.seed = 30; $0.tileSize = 0.025; $0.normalStrength = 1.3
            $0.roughness = 0.6; $0.specular = 0.55; $0.twoSided = true
        },
        // Covered button on a mortarboard: same satin pulled tight, slightly glossier. Tint for color.
        MaterialSpec(key: "fabric.gown-button", program: .fabricWeave).with {
            $0.colorA = linear(0x141417); $0.colorB = linear(0x0D0D10, 0.3); $0.colorC = linear(0x3A3A40, 0.05)
            $0.knobs = V4(150, 0.2, 0.5, 0); $0.seed = 31; $0.tileSize = 0.012; $0.normalStrength = 1
            $0.roughness = 0.5; $0.specular = 0.6
        },
        // Gown facing trim: denser satin band with stronger sheen. Tint for color.
        MaterialSpec(key: "fabric.gown-trim", program: .fabricWeave).with {
            $0.colorA = linear(0x16161A); $0.colorB = linear(0x101013, 0.25); $0.colorC = linear(0x44444C, 0.05)
            $0.knobs = V4(160, 0.1, 0.45, 0); $0.seed = 32; $0.tileSize = 0.02; $0.normalStrength = 1.1
            $0.roughness = 0.45; $0.specular = 0.65; $0.twoSided = true
        },
        // realityhd:material.fabric
    ]
}
