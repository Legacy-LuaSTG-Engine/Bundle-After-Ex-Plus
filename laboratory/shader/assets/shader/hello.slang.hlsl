#pragma pack_matrix(column_major)
#ifdef SLANG_HLSL_ENABLE_NVAPI
#include "nvHLSLExtns.h"
#endif

#ifndef __DXC_VERSION_MAJOR
// warning X3557: loop doesn't seem to do anything, forcing loop to unroll
#pragma warning(disable : 3557)
#endif


#line 11 "hello.slang"
Texture2D<float4 > render_target_0 : register(t0);


#line 12
SamplerState render_target_sampler_0 : register(s0);


#line 5
struct EffectParameters_0
{
    float4 background_color_0;
};

cbuffer effect_0 : register(b0)
{
    EffectParameters_0 effect_0;
}

#line 21
struct ShaderOutput_0
{
    float4 color_0 : SV_Target;
};


#line 14
struct ShaderInput_0
{
    float4 sxy_0 : SV_Position;
    float2 uv_0 : TEXCOORD0;
    float4 color_1 : COLOR0;
};


#line 27
ShaderOutput_0 main(ShaderInput_0 input_0)
{

    ShaderOutput_0 output_0;
    output_0.color_0 = render_target_0.Sample(render_target_sampler_0, input_0.uv_0) + effect_0.background_color_0;
    return output_0;
}

