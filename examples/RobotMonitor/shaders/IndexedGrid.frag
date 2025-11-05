VARYING vec2 vTexCoord;

void MAIN()
{
    float index = texture(indexMap, vTexCoord).r;
    vec4 color = texture(paletteMap, vec2(index, 0.5));
    FRAGCOLOR = color;
    FRAGCOLOR.a *= opacity;
}
