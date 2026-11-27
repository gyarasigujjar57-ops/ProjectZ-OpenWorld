shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float noise21(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
void fragment() {
    vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 p = wp.xz;
    float broad = noise21(p * 0.34);
    float grain = noise21(p * 8.5);
    float fine = hash21(floor(p * 95.0));
    float value = broad * 0.09 + grain * 0.055 + fine * 0.035;
    vec3 asphalt = vec3(0.105, 0.112, 0.118) + vec3(value);
    float worn = smoothstep(0.60, 0.88, noise21(p * 1.15));
    asphalt = mix(asphalt, vec3(0.16, 0.158, 0.145), worn * 0.20);
    ALBEDO = asphalt;
    ROUGHNESS = 0.94;
    METALLIC = 0.0;
}
