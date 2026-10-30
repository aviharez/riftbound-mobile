// Rift portal vortex. Runs inside the low-res world SubViewport, so every fragment is one world pixel:
// the swirl is quantised to four colour steps to read as pixel art (art-spec §5.7 "Rift portal distortion").
shader_type canvas_item;

uniform vec4 col_dark : source_color = vec4(0.09, 0.04, 0.22, 1.0);
uniform vec4 col_mid : source_color = vec4(0.43, 0.29, 0.90, 1.0);
uniform vec4 col_hi : source_color = vec4(0.82, 0.72, 1.0, 1.0);
uniform float speed = 2.2;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float swirl = sin(a * 3.0 + r * 9.0 - TIME * speed) * 0.5 + 0.5;
	float v = (1.0 - r) * 0.9 + swirl * 0.35 * (1.0 - r);
	float q = floor(clamp(v, 0.0, 1.0) * 5.0) / 5.0;
	vec3 c = mix(col_dark.rgb, col_mid.rgb, smoothstep(0.0, 0.6, q));
	c = mix(c, col_hi.rgb, step(0.79, q) * 0.7);
	float alpha = step(r, 1.0) * clamp(q * 1.6, 0.0, 0.85);
	COLOR = vec4(c, alpha);
}
