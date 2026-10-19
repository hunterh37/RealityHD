// Off-world site programs: solarCell (aligned space solar cell grid with fingers, busbar and interconnect gaps).

let metalSite = #"""
// ---------------------------------------------------------------- site
// Triple-junction space solar cells in an aligned grid on a Kapton substrate: AR-coated blue-violet cell
// with chamfered corners, fine collector fingers, one busbar, amber interconnect gap.
// colorA cell, colorB metal grid, colorC gap/substrate. f.x cells along u per tile, f.y along v,
// f.z gap width (cell fraction), f.w per-cell tone variation.
S solarCell(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    float2 n = float2(max(1.0, floor(P.f.x + 0.5)), max(1.0, floor(P.f.y + 0.5)));
    float2 g = uv * n;
    float2 gi = floor(g); float2 gf = g - gi;
    int2 id = wrapc(int2(gi), int2(n));
    float2 e = min(gf, 1.0 - gf);
    float gw = P.f.z;
    float inCell = step(gw, e.x) * step(gw * 0.6, e.y) * step(0.16, e.x + e.y);
    float tone = h01(id, sd + 3u);
    float fing = 1.0 - smoothstep(0.0, 0.06, abs(fract(gf.x * 14.0) - 0.5) - 0.42 + 0.06);
    float bus = 1.0 - smoothstep(0.012, 0.03, abs(gf.y - 0.5));
    float ar = fbm(uv, int2(int(n.x) * 2, int(n.y) * 2), 2, sd + 5u);
    float3 cell = P.colorA.rgb * (1.0 + (tone - 0.5) * P.f.w);
    cell = mix(cell, cell * float3(1.25, 0.9, 1.5), sat(0.5 + ar) * 0.35);
    float3 gap = P.colorC.rgb * (0.85 + 0.3 * fbm(uv, int2(24, 24), 2, sd + 7u));
    float metalMask = sat(fing * 0.3 + bus) * inCell;
    s.albedo = mix(gap, mix(cell, P.colorB.rgb, metalMask), inCell);
    s.height = inCell * 0.55 + metalMask * 0.04 + ar * 0.01;
    s.rough = mix(0.7, 0.16 + metalMask * 0.1, inCell);
    s.ao = 1.0 - (1.0 - inCell) * 0.45;
    s.metal = inCell * 0.3 + metalMask * 0.6;
    s.alpha = 1.0;
    return s;
}
"""#
