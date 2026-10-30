// A Rift tear in the arena floor where the creatures crawl out: a jagged, flattened ellipse
// (a hole seen in 3/4 view) with a dark rim and a swirling violet core. Runs in the world
// SubViewport, so each fragment is one world pixel; colours are quantised to read as pixel art.
shader_type canvas_item;

uniform vec4 col_rim : source_color = vec4(0.05, 0.02, 0.10, 1.0);
uniform vec4 col_dark : source_color = vec4(0.20, 0.08, 0.45, 1.0);
uniform vec4 col_mid : source_color = vec4(0.48, 0.30, 0.95, 1.0);
uniform vec4 col_hi : source_color = vec4(0.86, 0.76, 1.0, 1.0);
uniform float speed = 1.6;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float a = atan(uv.y, uv.x);
	// Jagged edge: a few fixed sine "cracks" around the rim.
	float edge = 1.0 - 0.10 * sin(a * 7.0) - 0.07 * sin(a * 13.0 + 1.3) - 0.05 * sin(a * 23.0 + 0.4);
	float r = length(uv) / edge;
	if (r > 1.0) {
		COLOR = vec4(0.0);
	} else if (r > 0.82) {
		COLOR = col_rim;
	} else {
		float swirl = sin(a * 2.0 + r * 8.0 - TIME * speed) * 0.5 + 0.5;
		float v = (1.0 - r) * 0.85 + swirl * 0.3;
		float q = floor(clamp(v, 0.0, 1.0) * 4.0) / 4.0;
		vec3 c = mix(col_dark.rgb, col_mid.rgb, smoothstep(0.0, 0.6, q));
		c = mix(c, col_hi.rgb, step(0.74, q) * 0.8);
		COLOR = vec4(c, 1.0);
	}
}
