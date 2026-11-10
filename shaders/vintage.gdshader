shader_type canvas_item;
// Light vintage film overlay: grain, flicker, vignette and the odd scratch.

uniform float grain : hint_range(0.0, 0.3) = 0.07;
uniform float vignette : hint_range(0.0, 1.0) = 0.42;
uniform vec4 tint : source_color = vec4(0.55, 0.38, 0.18, 0.05);

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float frame = floor(TIME * 14.0);
	float n = rand(floor(FRAGCOORD.xy / 2.0) + vec2(frame * 7.13, frame * 3.71)) - 0.5;
	float d = distance(UV, vec2(0.5));
	float v = smoothstep(0.38, 0.85, d) * vignette;

	// Occasional thin vertical film scratch.
	float sx = rand(vec2(frame, 1.0));
	float scratch = step(0.93, rand(vec2(frame, 9.0))) * (1.0 - smoothstep(0.0, 0.0015, abs(UV.x - sx))) * 0.35;

	vec3 col = tint.rgb;
	float a = tint.a;
	// Vignette darkens towards a warm ink tone.
	col = mix(col, vec3(0.08, 0.04, 0.06), v / max(a + v, 0.001));
	a = max(a, v);
	// Grain: light and dark speckles.
	float g = n * grain * 2.0;
	vec3 gcol = g > 0.0 ? vec3(1.0, 0.96, 0.86) : vec3(0.1, 0.06, 0.04);
	col = mix(col, gcol, clamp(abs(g) * 3.0, 0.0, 1.0));
	a = clamp(a + abs(g), 0.0, 1.0);
	col = mix(col, vec3(1.0, 0.97, 0.9), scratch);
	a = max(a, scratch);
	COLOR = vec4(col, a);
}
