shader_type canvas_item;
uniform float lod: hint_range(0.0, 5.0) = 2.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment(){
    COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, lod);
    COLOR.rgb *= 0.5; // Escurece um pouco
}