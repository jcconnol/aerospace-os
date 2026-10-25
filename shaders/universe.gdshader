shader_type sky;

uniform sampler2D nebula_photo : source_color, filter_linear_mipmap, repeat_disable;

uniform float world_seed = 0.0;
uniform int region = 0;
uniform vec3 tint : source_color = vec3(0.1, 0.5, 0.8);
uniform vec3 accent : source_color = vec3(1.0, 0.3, 0.12);

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

float clouds(vec3 p) {
    float n = 0.0;
    float strength = 0.55;
    for (int i = 0; i < 5; i++) {
        n += noise(p) * strength;
        p = p * 2.03 + vec3(4.3, 8.1, 1.7);
        strength *= 0.48;
    }
    return n;
}

vec3 stars(vec3 direction, float density) {
    vec3 cell = floor(direction * density);
    vec3 local = fract(direction * density) - 0.5;
    float random = hash(cell + world_seed);
    vec3 center = vec3(hash(cell + 7.0), hash(cell + 13.0), hash(cell + 29.0)) * 0.6 - 0.3;
    float d = length(local - center);
    float core = exp(-d * d * 190.0);
    float halo = exp(-d * d * 24.0) * 0.14;
    float visible = step(0.972, random);
    vec3 color = mix(vec3(0.48, 0.7, 1.0), vec3(1.0, 0.84, 0.6), hash(cell + 51.0));
    return color * (core + halo) * visible * (0.65 + hash(cell + 65.0) * 1.7);
}

vec3 universe(vec3 direction) {
    vec3 shifted = direction * 3.0 + vec3(world_seed * 0.07);
    float cloud = clouds(shifted);
    float dust = clouds(shifted * 3.8 + 12.0);
    vec3 color = vec3(0.0015, 0.003, 0.009);
    float band = exp(-pow((direction.y + direction.x * 0.32) * 3.2, 2.0));
    color += tint * pow(cloud, 3.0) * band * 0.25;
    // A sky-space basis keeps each region's main feature visible from spawn.
    vec3 forward = normalize(vec3(0.45 + sin(world_seed) * 0.12, 0.25, -1.0));
    vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, forward);
    float front = dot(direction, forward);
    vec2 p = vec2(dot(direction, right), dot(direction, up)) / max(front, 0.01);
    if (front > 0.0) {
        if (region == 0 || region == 3) {
            // Telescope imagery is projected onto a distant sky patch, not a flat screen.
            vec2 aspect = region == 0 ? vec2(2.0, 2.0) : vec2(1.6, 2.0);
            float angle = sin(world_seed * 0.13) * 0.35;
            vec2 rotated = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle))) * p;
            vec2 uv = rotated / aspect + 0.5;
            float border = max(abs(uv.x - 0.5), abs(uv.y - 0.5));
            float mask = 1.0 - smoothstep(0.37, 0.5, border);
            color += texture(nebula_photo, clamp(uv, vec2(0.0), vec2(1.0))).rgb * mask * 0.85;
        } else if (region == 1) {
            // Stylized gravitational lens and luminous accretion disk.
            float r = length(p);
            float ring = exp(-pow((r - 0.22) * 95.0, 2.0));
            float disk_r = length(p / vec2(1.0, 0.18));
            float disk = exp(-pow((disk_r - 0.38) * 13.0, 2.0));
            float disk_detail = 0.6 + 0.4 * sin(disk_r * 150.0 + dust * 8.0);
            float behind = smoothstep(0.195, 0.23, r);
            color *= behind;
            color += accent * (ring * 1.3 + disk * disk_detail * behind);
            color += vec3(1.0, 0.82, 0.5) * ring * 0.6;
            color += accent * exp(-r * 4.0) * behind * 0.1;
        } else {
            // Spiral galaxy with a bright core, dust lanes and two arms.
            vec2 q = p / vec2(1.1, 0.56);
            float r = length(q);
            float a = atan(q.y, q.x);
            float arms = pow(0.5 + 0.5 * cos(a * 2.0 - r * 15.0 + cloud * 3.0), 5.0);
            float envelope = exp(-r * 3.8);
            color += tint * arms * envelope * (0.4 + dust) * 1.5;
            color += accent * exp(-r * 17.0) * 1.6;
            color += vec3(0.6, 0.7, 1.0) * arms * envelope * pow(dust, 4.0);
        }
    }
    return color;
}

void sky() {
    // Bake the expensive nebula once per folder; draw crisp all-direction stars live.
    if (AT_CUBEMAP_PASS) {
        COLOR = universe(EYEDIR);
    } else {
        COLOR = texture(RADIANCE, EYEDIR).rgb;
        float occultation = 1.0;
        if (region == 1) {
            vec3 forward = normalize(vec3(0.45 + sin(world_seed) * 0.12, 0.25, -1.0));
            // The event horizon hides stars inside its angular radius.
            occultation = 1.0 - smoothstep(0.974, 0.982, dot(EYEDIR, forward));
        }
        COLOR += (stars(EYEDIR, 155.0) + stars(EYEDIR.yzx, 265.0) * 0.6) * occultation;
    }
}
