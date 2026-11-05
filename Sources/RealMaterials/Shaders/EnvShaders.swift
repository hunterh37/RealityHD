// Environment surfaces: lavaFlow (emissive molten rock under a broken crust) and glacierIce.
// Both tile; UVs are meters / tileSize, u along the flow or strip, v across.

let metalEnv = #"""
// ---------------------------------------------------------------- environments
// lavaFlow: unlit emitter. Dark crust plates (Worley cells stretched along u) float on glowing melt that
// shows through the cracks and where the crust has not formed. knobs: x crust coverage 0...1, y plate cells
// per repeat across v, z crack width, w stretch of the plates along u. colorA hottest melt, colorB cooler
// orange melt, colorC crust.
S lavaFlow(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    int F = max(3, int(P.f.y + 0.5));
    float stretch = max(P.f.w, 1.0);
    int2 fr = int2(max(2, int(float(F) / stretch + 0.5)), F);
    float2 wq = uv + 0.045 * float2(fbm(uv, int2(4, 4), 3, sd + 1u), fbm(uv, int2(4, 4), 3, sd + 2u));
    float4 w = worley(wq, fr, sd + 3u, 0.9);
    float edge = w.y - w.x;
    float n = fbm(uv, int2(3, 3), 4, sd + 5u) + 0.5;
    float cover = P.f.x;
    // Plates exist where the per-plate roll and the large-scale cooling field both fall under the coverage.
    float roll = 0.65 * w.z + 0.35 * n;
    float exists = 1.0 - smoothstep(cover - 0.1, cover + 0.1, roll);
    float crack = max(P.f.z, 0.01);
    float plate = smoothstep(crack * 0.4, crack + 0.1, edge) * exists;
    // Melt: hot veins where the flow churns, cooler orange elsewhere.
    float churn = fbm(float2(uv.x * 1.0 + n * 0.3, uv.y), int2(8, 8), 4, sd + 7u) + 0.5;
    float3 melt = mix(P.colorB.rgb, P.colorA.rgb, saturate(churn * churn * 1.6 + (1.0 - edge * 3.0) * 0.25));
    // Crust: near-black basalt with a warm glow bleeding in from the cracks and a pitted, sheened top.
    float rim = 1.0 - smoothstep(0.0, 0.5, edge);
    float pit = fbm(uv, int2(48, 48), 2, sd + 9u);
    float3 crust = P.colorC.rgb * (0.6 + 0.9 * (pit + 0.5)) + P.colorB.rgb * rim * rim * 0.8;
    float3 c = mix(melt, crust, plate);
    s.albedo = c;
    s.height = 0.35 + 0.55 * plate;
    s.rough = 0.9; s.ao = 1.0; s.metal = 0.0;
    return s;
}

// glacierIce: pressure-ice. Deep blue body with foliation bands, white fracture planes and trapped air
// bubbles. knobs: x band frequency, y fracture amount, z bubble amount, w unused. colorA deep, colorB pale,
// colorC fracture and bubble white.
S glacierIce(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    float n = fbm(uv, int2(3, 3), 5, sd + 1u) + 0.5;
    float bands = 0.5 + 0.5 * sin((uv.y * max(P.f.x, 1.0) + n * 3.0) * 6.2831853);
    float3 c = mix(P.colorA.rgb, P.colorB.rgb, saturate(0.25 + 0.7 * n + 0.2 * bands));
    float2 wq = uv + 0.03 * float2(fbm(uv, int2(5, 5), 3, sd + 2u), fbm(uv, int2(5, 5), 3, sd + 3u));
    float4 w = worley(wq, int2(6, 6), sd + 4u, 1.0);
    float crack = (1.0 - smoothstep(0.0, 0.04, w.y - w.x)) * smoothstep(-0.1, 0.2, fbm(uv, int2(4, 4), 3, sd + 6u)) * P.f.y;
    float4 b = worley(uv, int2(28, 28), sd + 8u, 1.0);
    float bubble = (1.0 - smoothstep(0.08, 0.2, b.x)) * step(0.68, b.z) * P.f.z;
    c = mix(c, P.colorC.rgb, saturate(crack * 0.75 + bubble * 0.5));
    float frost = smoothstep(0.55, 0.9, fbm(uv, int2(16, 16), 4, sd + 10u) + 0.5);
    c = mix(c, P.colorC.rgb, frost * 0.18);
    s.albedo = c;
    s.height = 0.5 - 0.4 * crack + 0.12 * n - 0.08 * bubble;
    s.rough = clamp(0.16 + 0.5 * crack + 0.25 * bubble + 0.3 * frost, 0.1, 0.9);
    s.ao = 1.0 - 0.4 * crack;
    return s;
}
// banknote: printed note face, one note per tile (u along the length, v across, note height = 0.4375 of the
// tile). Cream-green paper, guilloche border, oval portrait with engraved hatching, corner denomination
// blocks, serial numbers, seal and fine micro-lines. colorA paper, colorB ink, colorC seal and serial tint.
// knobs: x guilloche density, y wear, z unused, w unused.
S banknote(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    float2 q = float2(fract(uv.x), uv.y / 0.4375);
    float inNote = step(0.0, q.y) * step(q.y, 1.0);
    q.y = fract(q.y);
    float2 p = float2(q.x * 2.3636, q.y);            // aspect 156:66, p.x 0...2.3636
    float fib = fbm(uv, int2(48, 48), 3, sd + 1u);
    float form = fbm(uv, int2(6, 6), 4, sd + 2u);
    float3 paper = P.colorA.rgb * (0.96 + 0.05 * form + 0.03 * fib);
    float ink = 0.0;
    // border: two frame lines plus a woven guilloche band
    float2 e = float2(min(p.x, 2.3636 - p.x), min(p.y, 1.0 - p.y));
    float d = min(e.x, e.y);
    float frame = smoothstep(0.012, 0.006, abs(d - 0.045)) + smoothstep(0.008, 0.004, abs(d - 0.115));
    float band = step(0.045, d) * step(d, 0.115);
    float along = (e.x < e.y) ? p.y : p.x;
    float gui = 0.5 + 0.5 * sin(along * 60.0 * max(P.f.x, 1.0) / 6.2831853 + sin(d * 220.0) * 2.2);
    gui *= 0.5 + 0.5 * sin(along * 38.0 + d * 140.0);
    ink += frame * 0.9 + band * smoothstep(0.55, 0.9, gui) * 0.7;
    // fine background micro-lines inside the border
    float inner = step(0.12, d);
    float ml = smoothstep(0.55, 0.9, 0.5 + 0.5 * sin(p.y * 520.0 + sin(p.x * 21.0) * 3.0));
    ink += inner * ml * 0.14;
    // oval portrait with radial hatching
    float2 po = (p - float2(1.1818, 0.5)) / float2(0.34, 0.36);
    float ro = length(po);
    float ring = smoothstep(0.03, 0.01, abs(ro - 1.0)) + smoothstep(0.03, 0.01, abs(ro - 1.12)) * 0.6;
    float hatch = smoothstep(0.35, 0.8, 0.5 + 0.5 * sin((po.x * 0.8 + po.y) * 240.0 + fbm(uv, int2(10, 10), 3, sd + 3u) * 10.0));
    float shade = (1.0 - smoothstep(0.0, 1.0, ro)) * (0.35 + 0.65 * fbm(uv, int2(5, 7), 4, sd + 4u) + 0.5);
    float portrait = step(ro, 0.98) * hatch * sat(shade);
    ink += ring + portrait * 0.75;
    // corner denomination blocks
    float2 c0 = float2(min(p.x, 2.3636 - p.x), min(p.y, 1.0 - p.y));
    float cornerBox = step(0.16, c0.x) * step(c0.x, 0.42) * step(0.16, c0.y) * step(c0.y, 0.34);
    float digits = step(0.5, h01(int2(int(c0.x * 70.0), int(c0.y * 70.0)), sd + 5u)) * step(0.35, fract(c0.x * 70.0)) * step(0.35, fract(c0.y * 70.0));
    ink += cornerBox * (0.25 + 0.65 * digits);
    // serial numbers, upper right and lower left
    float2 sr = float2(p.x - 1.7, p.y - 0.2);
    float sn = step(0.0, sr.x) * step(sr.x, 0.5) * step(0.0, sr.y) * step(sr.y, 0.06);
    float sdg = step(0.4, h01(int2(int(sr.x * 90.0), 0), sd + 6u)) * step(0.2, fract(sr.x * 90.0)) * step(fract(sr.x * 90.0), 0.8);
    float2 sl = float2(p.x - 0.46, p.y - 0.78);
    float sn2 = step(0.0, sl.x) * step(sl.x, 0.5) * step(0.0, sl.y) * step(sl.y, 0.06);
    float sdg2 = step(0.4, h01(int2(int(sl.x * 90.0), 1), sd + 7u)) * step(0.2, fract(sl.x * 90.0)) * step(fract(sl.x * 90.0), 0.8);
    float serials = sn * sdg + sn2 * sdg2;
    // seals, left and right of the portrait
    float2 sp = float2(min(abs(p.x - 0.62), abs(p.x - 1.74)), p.y - 0.5);
    float sealR = length(float2(sp.x, sp.y)) / 0.1;
    float sealMask = step(abs(p.x - 0.62), 0.12) + step(abs(p.x - 1.74), 0.12);
    float seal = sat(sealMask) * (smoothstep(0.1, 0.0, abs(sealR - 1.0)) + step(sealR, 0.75) * smoothstep(0.4, 0.9, 0.5 + 0.5 * sin(atan2(sp.y, sp.x) * 18.0)));
    float3 c = paper;
    c = mix(c, P.colorB.rgb, sat(ink) * 0.88);
    c = mix(c, P.colorC.rgb, sat(serials + seal * 0.8) * 0.9);
    // wear: creases and handling grime
    float crease = smoothstep(0.012, 0.0, abs(fbm(uv, int2(3, 2), 3, sd + 8u))) * 0.35 * P.f.y;
    c *= 1.0 - crease - 0.08 * P.f.y * fbm(uv, int2(4, 4), 4, sd + 9u);
    s.albedo = mix(P.colorA.rgb * 0.8, c, inNote);
    s.height = 0.5 + sat(ink) * 0.15;
    s.rough = 0.84 - sat(ink) * 0.12;
    s.ao = 1.0 - crease * 0.3;
    return s;
}
"""#
