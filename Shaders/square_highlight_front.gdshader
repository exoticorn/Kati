shader_type spatial;

render_mode unshaded;

uniform sampler2D mask;
uniform vec3 color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = color;
	ALPHA = texture(mask, UV).a;
}
