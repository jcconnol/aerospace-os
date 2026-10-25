shader_type spatial;
render_mode cull_disabled;

uniform vec4 ring_color : source_color = vec4(0.7, 0.55, 0.4, 1.0);
varying vec3 object_position;

void vertex() {
    object_position = VERTEX;
}

void fragment() {
    float r = length(object_position.xz);
    float bands = sin(r * 9.0) * 0.25 + sin(r * 24.0) * 0.15 + sin(r * 2.0) * 0.2;
    ALBEDO = ring_color.rgb * (0.55 + bands);
    ROUGHNESS = 1.0;
    ALPHA = smoothstep(-0.5, -0.25, bands) * 0.85;
}
