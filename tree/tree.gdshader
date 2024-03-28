shader_type canvas_item;

uniform sampler2D noise: filter_nearest, repeat_enable;
uniform float border_width : hint_range(0.0, 0.5) = 0.1;
uniform sampler2D color: filter_nearest, repeat_enable;

void vertex() {
	VERTEX.x = VERTEX.x + 0.01 * VERTEX.y * sin(TIME);
}

void fragment() {
	// Calculate distance from UV to the borders
    vec2 dist_to_border = min(vec2(1.0) - abs(fract(UV) - 0.5) * 2.0, 1.0);

    // Calculate alpha based on distance to the borders
    float alpha = 0.2 + min(dist_to_border.y, 1.0 - border_width);

    // Output final color with adjusted alpha
	COLOR = vec4(texture(color, UV));
	COLOR.a = step(texture(noise, UV).r, alpha);
}
