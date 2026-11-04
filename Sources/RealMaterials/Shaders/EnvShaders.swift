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
"""#
