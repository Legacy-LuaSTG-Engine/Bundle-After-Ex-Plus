// --------------------------------------------------------------------------------
// 遮罩功能
// 根据灰度图生成 alpha 通道
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
    float4   user_data_0;
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

    float4 texture_color = screen_texture.Sample(screen_texture_sampler, input.uv);
    float4 mask_color = mask_texture.Sample(mask_texture_sampler, input.uv);
    texture_color *= ((mask_color.r + mask_color.g + mask_color.b) * _1_3);

    PS_Output output;
    output.col = texture_color;
    return output;
}

// lua 侧调用（仅用于说明参数如何传递，并非可正常运行的代码）
/*

lstg.CreateRenderTarget("RenderTarget")
lstg.CreateRenderTarget("Mask")

lstg.PushRenderTarget("RenderTarget")
...
lstg.PopRenderTarget()

lstg.PushRenderTarget("Mask")
...
lstg.PopRenderTarget()

lstg.PostEffect(
    -- 着色器资源名称
    "texture_mask",
    -- 屏幕渲染目标，采样器类型
    "RenderTarget", 6,
    -- 混合模式
    "mul+alpha",
    -- 浮点参数
    {},
    -- 纹理与采样器类型参数
    {
        { "Mask", 6 },
    }
)

*/
