shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

// Rolling doorway mist with feathered edges: alpha falls off toward
// the quad's sides (no hard cut on wonky doorways) and thins toward
// the top. Wide curtains tile the texture and shrink the feather
// fraction so density and edge softness stay constant at any span.

uniform sampler2D mist_tex: source_color;
uniform vec4 tint: source_color = vec4(0.72, 0.85, 1.0, 0.55);
uniform vec2 scroll = vec2(0.03, 0.05);
uniform float tiles = 1.2;
uniform float feather = 0.18;

void fragment() {
	vec2 uv = vec2(UV.x * tiles, UV.y) + scroll * TIME;
	vec4 tex = texture(mist_tex, uv);
	float edge_x = smoothstep(0.0, feather, UV.x) * smoothstep(1.0, 1.0 - feather, UV.x);
	float top_fade = smoothstep(0.0, 0.3, UV.y);
	ALBEDO = tex.rgb * tint.rgb;
	ALPHA = tex.a * tint.a * edge_x * top_fade;
}
