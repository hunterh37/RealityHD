// Terawatt data center programs: perforatedSheet (staggered round-hole sheet steel, cutout).

let metalTerawattDC = #"""
// ---------------------------------------------------------------- terawatt data center
// Perforated sheet: round holes on a staggered grid (rows offset half a pitch), powder-coated face.
// colorA coat, colorB bare-edge tint inside the hole rim, colorC scuff.
// f.x holes per tile along U (integer), f.y hole radius (pitch fraction), f.z roughness, f.w scuffing.
S perforatedSheet(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    float N = max(4.0, floor(P.f.x + 0.5));
    float rows = floor(N * 0.85) * 2.0;
    float py = N / rows;
    float ry = uv.y * rows;
    float row0 = floor(ry);
    float d = 9.0;
    for (int k = -1; k <= 1; k++) {
        float rr = row0 + float(k);
        float cx = floor(uv.x * N + (fmod(rr + 1000.0, 2.0) > 0.5 ? 0.5 : 0.0)) + 0.5 - (fmod(rr + 1000.0, 2.0) > 0.5 ? 0.5 : 0.0);
        float2 c = float2(cx / N, (rr + 0.5) / rows);
        float2 dv = float2((uv.x - c.x) * N, (uv.y - c.y) * N);
        d = min(d, length(dv));
    }
    float r = P.f.y;
    float hole = d < r ? 1.0 : 0.0;
    s.alpha = 1.0 - hole;
    float rim = smoothstep(r, r + 0.06, d);
    float n = fbm(uv, int2(10, 10), 3, sd + 1u);
    float scuff = smoothstep(0.55, 0.8, gnoise(uv * 40.0, int2(40, 40), sd + 2u)) * P.f.w;
    float3 c = mix(P.colorB.rgb, P.colorA.rgb, rim);
    c = mix(c, P.colorC.rgb, scuff * 0.7) * (0.92 + 0.12 * n);
    s.albedo = c;
    s.height = mix(0.25, 0.5, rim);
    s.rough = sat(P.f.z + scuff * 0.2 + (1.0 - rim) * 0.1);
    s.ao = mix(0.55, 1.0, rim);
    s.metal = 0.0;
    return s;
}
"""#
