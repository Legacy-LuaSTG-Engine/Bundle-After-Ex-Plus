// slangc hello.slang -lang slang -profile sm_4_0 -capability sm_4_0_version -entry main -target hlsl -o hello.slang.hlsl -reflection-json hello.slang.hlsl.json

#language slang 2026

struct EffectParameters
{
    float4 background_color;
};

ConstantBuffer<EffectParameters> effect;
Texture2D render_target;
SamplerState render_target_sampler;

struct ShaderInput
{
    float4 sxy : SV_Position;
    float2 uv : TEXCOORD0;
    float4 color : COLOR0;
};

struct ShaderOutput
{
    float4 color : SV_Target;
};

[shader("fragment")]
ShaderOutput main(ShaderInput input)
{
    float4 add_color = render_target.Sample(render_target_sampler, input.uv);
    ShaderOutput output;
    output.color = add_color + effect.background_color;
    return output;
}
