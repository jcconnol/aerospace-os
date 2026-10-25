shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 portal_color : source_color = vec4(0.15, 0.8, 1.0, 1.0);
uniform float world_seed = 0.0;

void fragment() {
    vec2 p = (UV - 0.5) * 2.0;
    float r = length(p);
    float a = atan(p.y, p.x);
    float spiral = pow(0.5 + 0.5 * sin(a * 5.0 - r * 19.0 + TIME * 1.6 + world_seed), 4.0);
    float rim = exp(-pow((r - 0.89) * 33.0, 2.0));
    float interior = (0.08 + spiral * 0.3) * smoothstep(1.0, 0.6, r);
    float core = exp(-r * 9.0) * 0.7;
    ALBEDO = portal_color.rgb * (interior + rim * 1.6) + vec3(0.7, 0.85, 1.0) * core;
    ALPHA = smoothstep(1.0, 0.94, r);
}
