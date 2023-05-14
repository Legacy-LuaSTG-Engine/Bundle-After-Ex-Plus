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
    float4   my_color4;
    float4   user_data_2;
    float4   my_rect;
    float4x4 my_matrix; // 相当于4 个 float4
};

// 用户传递的纹理和采样器参数，可用槽位 0 到 3

SamplerState my_sampler0 : register(s0);
Texture2D    my_texture0 : register(t0);

SamplerState my_sampler1 : register(s1);
Texture2D    my_texture1 : register(t1);

SamplerState my_sampler2 : register(s2);
Texture2D    my_texture2 : register(t2);

SamplerState my_sampler3 : register(s3);
Texture2D    my_texture3 : register(t3);

// 为了方便使用，可以定义一些宏

#define my_color3 user_data_0.xyz
#define my_timer  user_data_0.w
#define my_pos2_1 user_data_2.xy
#define my_pos2_2 user_data_2.zw

// 不变量

static const float my_PI = 3.14159265f;

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
    float4 tex_col = screen_texture.Sample(screen_texture_sampler, input.uv);
    tex_col.xyz = lerp(my_color3, tex_col.xyz, 0.5f + 0.5f * sin(my_timer));
    
    PS_Output output;
    output.col = tex_col;
    return output;
}

// lua 侧调用（仅用于说明参数如何传递，并非可正常运行的代码）
/*

lstg.LoadTexture("texture0", "xxx.png")
lstg.LoadTexture("texture1", "yyy.png")
lstg.CreateRenderTarget("rendertarget2")
lstg.CreateRenderTarget("rendertarget3")

lstg.CreateRenderTarget("screen")
lstg.LoadFX("template", "template.hlsl")

lstg.PushRenderTarget("screen")
lstg.RenderClear(lstg.Color(255, 0, 0, 0))
lstg.PopRenderTarget()
lstg.PostEffect("template", "screen", 6, "mul+alpha", -- 着色器名称，屏幕渲染目标，采样器类型，（最终绘制出来的）混合模式
    -- 浮点参数
    {
        { 1.0, 1.0, 1.0, 0.0 },         -- my_color3(r, g, b), timer
        { 0.0, 0.0, 0.0, 1.0 },         -- my_color4(r, g, b, a)
        { 100.0, 100.0, -50.0, -50.0 }, -- my_pos2_1(x, y), my_pos2_2(x, y)
        { 0.0, 1280.0, 0.0, 960.0 },    -- my_rect(l, r, b, t)
        
        -- my_matrix
        { 1.0, 0.0, 0.0, 0.0 },
        { 0.0, 1.0, 0.0, 0.0 },
        { 0.0, 0.0, 1.0, 0.0 },
        { 0.0, 0.0, 0.0, 1.0 },
    },
    -- 纹理与采样器类型参数
    {
        { "texture0", 6 },
        { "texture1", 6 },
        { "rendertarget2", 6 },
        { "rendertarget3", 6 },
    }
)

*/
