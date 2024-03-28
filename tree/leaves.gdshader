shader_type canvas_item;

uniform sampler2D leaves_texture;
uniform float height = 0.0;

void vertex() {
	VERTEX.x = VERTEX.x + 0.01 * (VERTEX.y + height) * sin(TIME);
}

void fragment() {
	COLOR = texture(leaves_texture, UV) * 2.0;
	COLOR.a = 1.0 - step(texture(TEXTURE, UV).r * step(length(UV - 0.5), 0.5), sqrt(length(UV - 0.5)));
}