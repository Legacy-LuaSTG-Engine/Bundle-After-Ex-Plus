// ----------------------------------------
// 3x3 均值模糊 code by Xiliusha
// 代码移植 by 璀境石
// ----------------------------------------

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
    float4 user_data_0;
};

// 用户传递的纹理和采样器参数，可用槽位 0 到 3

// 为了方便使用，可以定义一些宏

#define screenSize screen_texture_size.xy
// 采样半径（单位：游戏内单位长度，即和游戏坐标系相关）
#define radiu user_data_0.x

// 不变量

static const float border_inner = 1.0f;

// 方法

float2 ClampSamplePoint(float2 pos)
{
    pos.x = clamp(pos.x, viewport.x + border_inner, viewport.z - border_inner);
    pos.y = clamp(pos.y, viewport.y + border_inner, viewport.w - border_inner);
    return pos;
}

float4 BoxBlur3x3(float2 uv, float r)
{
    float2 xy = uv * screen_texture_size.xy;
    // 生成采样点
    float2 sample_point_1 = ClampSamplePoint(xy + float2(-1.0f * r,  1.0f * r));
    float2 sample_point_2 = ClampSamplePoint(xy + float2( 0.0f * r,  1.0f * r));
    float2 sample_point_3 = ClampSamplePoint(xy + float2( 1.0f * r,  1.0f * r));
    float2 sample_point_4 = ClampSamplePoint(xy + float2(-1.0f * r,  0.0f * r));
    float2 sample_point_5 = ClampSamplePoint(xy + float2( 0.0f * r,  0.0f * r));
    float2 sample_point_6 = ClampSamplePoint(xy + float2( 1.0f * r,  0.0f * r));
    float2 sample_point_7 = ClampSamplePoint(xy + float2(-1.0f * r, -1.0f * r));
    float2 sample_point_8 = ClampSamplePoint(xy + float2( 0.0f * r, -1.0f * r));
    float2 sample_point_9 = ClampSamplePoint(xy + float2( 1.0f * r, -1.0f * r));
    // 对纹理采样
    float2 uv_scale = float2(1.0f, 1.0f) / screen_texture_size.xy;
    float4 sample_color_1 = screen_texture.Sample(screen_texture_sampler, sample_point_1 * uv_scale);
    float4 sample_color_2 = screen_texture.Sample(screen_texture_sampler, sample_point_2 * uv_scale);
    float4 sample_color_3 = screen_texture.Sample(screen_texture_sampler, sample_point_3 * uv_scale);
    float4 sample_color_4 = screen_texture.Sample(screen_texture_sampler, sample_point_4 * uv_scale);
    float4 sample_color_5 = screen_texture.Sample(screen_texture_sampler, sample_point_5 * uv_scale);
    float4 sample_color_6 = screen_texture.Sample(screen_texture_sampler, sample_point_6 * uv_scale);
    float4 sample_color_7 = screen_texture.Sample(screen_texture_sampler, sample_point_7 * uv_scale);
    float4 sample_color_8 = screen_texture.Sample(screen_texture_sampler, sample_point_8 * uv_scale);
    float4 sample_color_9 = screen_texture.Sample(screen_texture_sampler, sample_point_9 * uv_scale);
    // 计算总和
    float4 total_color
        = sample_color_1
        + sample_color_2
        + sample_color_3
        + sample_color_4
        + sample_color_5
        + sample_color_6
        + sample_color_7
        + sample_color_8
        + sample_color_9;
    return total_color / 9.0f; // 取平均值
}

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

    PS_Output output;
    output.col = BoxBlur3x3(input.uv, radiu);
    return output;
}
