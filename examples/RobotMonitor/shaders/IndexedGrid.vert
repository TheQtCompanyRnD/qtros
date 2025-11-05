VARYING vec2 vTexCoord;

void MAIN()
{
    vTexCoord = vec2(UV0.x,1-UV0.y);
    POSITION = MODELVIEWPROJECTION_MATRIX * vec4(VERTEX, 1.0);
}
