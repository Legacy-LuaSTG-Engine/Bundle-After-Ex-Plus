// 引擎设置的参数，不可修改

SamplerState screen_texture_sampler : register(s4); // RenderTarget 纹理的采样器
Texture2D screen_texture            : register(t4); // RenderTarget 纹理
cbuffer engine_data : register(b1)
{
    float4 screen_texture_size; // 纹理大小
    float4 viewport;            // 视口
};

// 用户传递的浮点参数
// 由多个 float4 组成，且 float4 是最小单元，最多可传递 8 个 float4

cbuffer user_data : register(b0)
{
    float hue_shift;        // 色相改变量
    float saturation_shift; // 饱和度改变量
    float lightness_shift;  // 亮度改变量
};

// 主函数

struct PS_Input
{
    float4 sxy : SV_Position;
    float2 uv  : TEXCOORD0;
    float4 col : COLOR0;
};
struct PS_Output
{
    float4 col : SV_Target;
};

float f(float n, float H, float S, float L) {
    float k = fmod(n + H / 30.0f, 12.0f);
    float a = S * min(L, 1.0f - L);
    return L - a * max(-1.0f, min(min(k - 3.0f, 9.0f - k), 1.0f));
}

PS_Output main(PS_Input input)
{
    float4 texture_color = screen_texture.Sample(screen_texture_sampler, input.uv);

    // See: https://en.wikipedia.org/wiki/HSL_and_HSV

    // Step 1

    float max_component = max(max(texture_color.r, texture_color.g), texture_color.b); // maximum component, Xmax, V, Value
    float min_component = min(min(texture_color.r, texture_color.g), texture_color.b); // minimum component, Xmin, V - C
    float chroma = max_component - min_component; // range, chroma, Xmax - Xmin, 2(V - L)
    float lightness = (max_component + min_component) * 0.5f; // mid-range, lightness, mid(R, G, B), (Xmax + Xmin) / 2, V - C / 2
    float saturation;
    if (lightness <= 0.0f || lightness >= 1.0f) {
        saturation = 0.0f;
    }
    else {
        saturation = (max_component - lightness) / min(lightness, 1.0f - lightness);
    }
    float hue;
    if (chroma <= 0.0f) {
        hue = 0.0f;
    }
    else if (max_component == texture_color.r) {
        hue = 60.0f * fmod((texture_color.g - texture_color.b) / chroma, 6.0f);
    }
    else if (max_component == texture_color.g) {
        hue = 60.0f * ((texture_color.b - texture_color.r) / chroma + 2.0f);
    }
    else if (max_component == texture_color.b) {
        hue = 60.0f * ((texture_color.r - texture_color.g) / chroma + 4.0f);
    }

    // Step 2

    hue = fmod(hue + hue_shift, 360.0f);
    saturation = clamp(saturation + saturation_shift, 0.0f, 1.0f);
    lightness = clamp(lightness + lightness_shift, 0.0f, 1.0f);

    // Step 3

    texture_color.r = f(0.0f, hue, saturation, lightness);
    texture_color.g = f(8.0f, hue, saturation, lightness);
    texture_color.b = f(4.0f, hue, saturation, lightness);

    PS_Output output;
    output.col = texture_color;
    return output;
}
