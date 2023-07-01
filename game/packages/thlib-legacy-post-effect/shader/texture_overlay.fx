//========================================
//叠加混合模式
//code by ETC(Xiliusha)
//========================================

//外部传入的纹理，作为顶层传入
texture2D ScreenTexture:POSTEFFECTTEXTURE;
sampler2D ScreenTextureSampler = sampler_state {
    texture = <ScreenTexture>;
    AddressU  = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

//外部传入的纹理，作为底层传入
texture2D Texture2 < string binding = "tex"; >;
sampler2D ScreenTextureSampler2 = sampler_state {
    texture = <Texture2>;
    AddressU = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

//叠加混合模式处理过程
float overlay(float base,float blend)
{
    if (base<0.5)
    {
        return 2.0*base*blend;
    }
    else
    {
        return 1.0-2.0*(1.0-base)*(1.0-blend);
    }
}

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{
    float4 TexColorB = tex2D(ScreenTextureSampler, uv);//作为顶层
    float4 TexColorA = tex2D(ScreenTextureSampler2, uv);//作为底层
    float4 TexColor;

    TexColor.r=overlay(TexColorA.r,TexColorB.r);
    TexColor.g=overlay(TexColorA.g,TexColorB.g);
    TexColor.b=overlay(TexColorA.b,TexColorB.b);

    TexColor=lerp(TexColorA,TexColor,TexColorB.a);

    TexColor.a=1.0-(1.0-TexColorA.a)*(1.0-TexColorB.a);

    return TexColor;
}

technique Main
{
    pass MainPass
    {
        PixelShader = compile ps_3_0 PS_MainPass();
    }
}
