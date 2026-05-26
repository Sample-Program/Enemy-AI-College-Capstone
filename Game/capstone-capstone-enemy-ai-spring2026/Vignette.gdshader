shader_type canvas_item;

uniform float strength = 0.75;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    vec2 uv = SCREEN_UV - vec2(0.5);
    float dist = length(uv);

    float vignette = smoothstep(0.8, 0.2, dist * strength);

    vec4 color = texture(screen_texture, SCREEN_UV);
    color.rgb *= vignette;

    COLOR = color;
}