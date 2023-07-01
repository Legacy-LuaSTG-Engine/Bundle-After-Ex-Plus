//======================================
//code by Xiliusha(ETC)
//powered by OLC
//======================================

texture2D ScreenTexture:POSTEFFECTTEXTURE;
sampler2D ScreenTextureSampler = sampler_state {
    texture = <ScreenTexture>;
    AddressU  = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

float4 screen : SCREENSIZE;

//这个shader通过传入一个灰度图作为alpha通道，原图的透明度根据这个灰度图从白到黑从不透明到透明
texture2D Texture2 < string binding = "tex"; >;
sampler2D ScreenTextureSampler2 = sampler_state {
    texture = <Texture2>;
    AddressU = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{
    float4 texColor = tex2D(ScreenTextureSampler, uv);
    float4 texColor2 = tex2D(ScreenTextureSampler2, uv);
    
    float mix = (texColor2.r + texColor2.g + texColor2.b) / 3.0;
    
    texColor.a = mix;
    
    return texColor;
}

technique Main
{
    pass MainPass
    {
        PixelShader = compile ps_3_0 PS_MainPass();
    }
}
