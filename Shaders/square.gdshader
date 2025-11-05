shader_type spatial;

uniform sampler2D grid_albedo_tex : source_color;
uniform sampler2D grid_normal_tex;
uniform sampler2D grid_orm_tex;
uniform sampler2D square_albedo_tex : source_color;
uniform sampler2D square_normal_tex;
uniform vec3 square_modulate: source_color = vec3(0.7, 0.6, 0.6);

varying vec2 uv_offset;
varying float brightness;

void vertex() {
	vec2 seed2d = fract(sin(NODE_POSITION_WORLD.xz) * 1000.0);
	float seed = seed2d.x + seed2d.y * 5.0;
	uv_offset = vec2(fract(sin(seed * 5.0) * 100.0), fract(sin(seed * 9.0) * 273.0));
	brightness = fract(sin(seed * 13.0) * 175.0) * 0.5 + 0.5;
}

void fragment() {
	vec4 grid_albedo = texture(grid_albedo_tex, UV);
	vec3 grid_normal = texture(grid_normal_tex, UV).xyz;
	vec3 grid_orm = texture(grid_orm_tex, UV).xyz;
	
	float albedo_alpha = max(0.0, grid_albedo.a - 0.75) * 4.0;
	float normal_alpha = min(1.0, grid_albedo.a * 4.0);
	
	vec3 square_albedo = texture(square_albedo_tex, UV * 0.5 + uv_offset).xyz * square_modulate * brightness;
	vec3 square_normal = texture(square_normal_tex, UV * 0.5 + uv_offset).xyz;
	
	ALBEDO = mix(square_albedo, grid_albedo.xyz, albedo_alpha);
	NORMAL_MAP = mix(square_normal, grid_normal, normal_alpha);
	NORMAL_MAP.xy = 1.0 - NORMAL_MAP.xy;
	ROUGHNESS = mix(0.7, grid_orm.y, albedo_alpha);
}
