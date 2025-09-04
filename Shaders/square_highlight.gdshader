shader_type spatial;

render_mode unshaded, depth_test_disabled;

uniform sampler2D mask;
uniform vec3 color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = color;
	ALPHA = texture(mask, UV).a * 0.1;
}
