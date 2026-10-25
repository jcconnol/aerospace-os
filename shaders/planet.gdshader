shader_type spatial;

uniform vec4 surface_color : source_color = vec4(0.04, 0.15, 0.3, 1.0);
uniform vec4 land_color : source_color = vec4(0.2, 0.35, 0.15, 1.0);
uniform float world_seed = 0.0;
varying vec3 object_position;

float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

float terrain(vec3 p) {
    return noise(p) * 0.6 + noise(p * 2.1) * 0.28 + noise(p * 4.3) * 0.12;
}

void vertex() {
    object_position = VERTEX;
}

void fragment() {
    vec3 sphere = normalize(object_position);
    vec3 p = sphere * 3.0 + vec3(world_seed);
    float elevation = terrain(p);
    float land = smoothstep(0.46, 0.51, elevation);
    float clouds = smoothstep(0.56, 0.76, terrain(p * 2.0 + vec3(15.0)));
    float ice = smoothstep(0.82, 0.97, abs(sphere.y));
    ALBEDO = mix(surface_color.rgb, land_color.rgb * (0.6 + elevation), land);
    ALBEDO = mix(ALBEDO, vec3(0.7, 0.8, 0.85), max(clouds * 0.85, ice));
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.0);
    EMISSION = vec3(0.08, 0.25, 0.5) * rim * 0.45;
    ROUGHNESS = mix(0.4, 0.95, land);
}
