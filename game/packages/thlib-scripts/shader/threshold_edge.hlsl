// --------------------------------------------------------------------------------
// 阈值边缘功能
// 根据灰度、等值线、范围生成渐变边缘
// 璀境石
// --------------------------------------------------------------------------------

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
    float4 color_down; // 往低值
    float4 color_up;   // 往高值
    float range_down;  // 往低值范围
    float range_up;    // 往高值范围
    float threshold;
};

// 用户传递的纹理和采样器参数，可用槽位 0 到 3

SamplerState mask_texture_sampler : register(s0);
Texture2D    mask_texture         : register(t0);

// 常量

static const float _1_3 = 1.0f / 3.0f;

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

PS_Output main(PS_Input input)
{
    float2 xy = input.uv * screen_texture_size.xy;  // 屏幕上真实位置
    if (xy.x < viewport.x || xy.x > viewport.z || xy.y < viewport.y || xy.y > viewport.w)
    {
        discard; // 抛弃不需要的像素，防止意外覆盖画面
    }

    float4 mask_color = mask_texture.Sample(mask_texture_sampler, input.uv);
    float mask_value = (mask_color.r + mask_color.g + mask_color.b) * _1_3;
    if (mask_value < (threshold - range_down) || mask_value > (threshold + range_up)) {
        discard; // 抛弃不需要的像素
    }
    float4 texture_color = screen_texture.Sample(screen_texture_sampler, input.uv);
    if (mask_value < threshold)
    {
        // 低于阈值的“外”边缘部分，逐渐变透明
        if (range_down < 0.00001) {
            discard; // 太小了
        }
        float k = min((threshold - mask_value) / range_down, 1.0f);
        float4 target_color1 = color_up;
        target_color1.a *= texture_color.a;
        float4 target_color2 = color_down;
        target_color2.a *= texture_color.a * (1.0f - k);
        texture_color = lerp(target_color1, target_color2, k);
    }
    else {
        // 高于阈值的内边缘部分，逐渐变为图片颜色
        if (range_up < 0.00001) {
            discard; // 太小了
        }
        float k = min((mask_value - threshold) / range_up, 1.0f);
        float4 target_color = color_up;
        target_color.a *= texture_color.a;
        texture_color = lerp(target_color, texture_color, k);
    }
    texture_color.rgb = texture_color.rgb * texture_color.a;

    PS_Output output;
    output.col = texture_color;
    return output;
}
