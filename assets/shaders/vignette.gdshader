// Dark edges for the arena, dithered with a 4x4 Bayer matrix so the falloff stays pixel art
// (no smooth banded gradient, no bloom). Runs in the world SubViewport: FRAGCOORD = world pixels.
shader_type canvas_item;

uniform float strength = 0.5;
uniform vec4 tint : source_color = vec4(0.03, 0.02, 0.08, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= 0.85;
	float d = length(uv) * 1.7;
	float v = smoothstep(0.72, 1.15, d) * strength;
	ivec2 p = ivec2(mod(FRAGCOORD.xy, 4.0));
	float bayer[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	float th = (bayer[p.y * 4 + p.x] + 0.5) / 16.0;
	float q = floor(v * 4.0 + th) / 4.0;
	COLOR = vec4(tint.rgb, q);
}
