shader_type spatial;

uniform sampler2D mask;
instance uniform vec3 color: source_color;
instance uniform float alpha;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = color;
	ALPHA = texture(mask, UV).a * alpha;
}
