// 引擎参数

SamplerState screen_texture_sampler : register(s4); // RenderTarget 纹理的采样器
Texture2D screen_texture            : register(t4); // RenderTarget 纹理
cbuffer engine_data : register(b1)
{
    float4 screen_texture_size; // 纹理大小
    float4 viewport;            // 视口
};

// 用户传递的参数

cbuffer user_data : register(b0)
{
    float4 center_pos;   // 指定效果的中心坐标
    float4 effect_color; // 指定效果的中心颜色,着色时使用colorburn算法
    float4 effect_param; // 多个参数：effect_size 指定效果的影响大小、effect_arg 变形系数、effect_color_size 颜色的扩散大小、timer 外部计时器
};

#define effect_size       effect_param.x
#define effect_arg        effect_param.y
#define effect_color_size effect_param.z
#define timer             effect_param.w

// 不变量

static const float PI    = 3.14159265f;
static const float inner = 1.0f;
static const float cb_64 = (64.0f / 255.0f);

// 方法

float2 Distortion(float2 xy, float2 delta, float delta_len)
{
	float k = delta_len / effect_size;
	float p = pow(1.0f - k, 0.75f);//pow((k - 1.0f), 0.75f);
	float arg = effect_arg * p;
	float2 delta1 = float2(sin(1.75f * 2.0f * PI * delta.x + 0.05f * delta_len + timer / 20.0f), sin(1.75f * 2.0f * PI * delta.y + 0.05f * delta_len + timer / 24.0f)); // 1.75f 此项越高，波纹越“破碎”
	float delta2 = arg * sin(0.005f * 2.0f * PI * delta_len+ timer / 40.0f); // 0.005f 此项越高，波纹越密
	return delta1 * delta2; // delta1：方向向量，delta2：向量长度，即返回像素移动的方向和距离
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
    float2 uv2 = input.uv;
    float2 delta = xy - center_pos.xy;  // 计算效果中心到纹理采样点的向量
    float delta_len = length(delta);
    delta = normalize(delta);
    if (delta_len <= effect_size)
    {
        float2 distDelta = Distortion(xy, delta, delta_len);
        float2 resultxy = xy + distDelta;
        if (resultxy.x > (viewport.x + inner) && resultxy.x < (viewport.z - inner) && resultxy.y > (viewport.y + inner) && resultxy.y < (viewport.w - inner))
        {
            uv2 += distDelta / screen_texture_size.xy;
        }
        else
        {
            uv2 = input.uv;
        }
    }
    
    float4 tex_color = screen_texture.Sample(screen_texture_sampler, uv2); // 对纹理进行采样
    if (delta_len <= effect_color_size)
    {
        // 扭曲着色
        float k = delta_len / effect_color_size;
        float ak = effect_color.a * pow((1.0f - k), 1.2f);
        float4 processed_color = float4(max(cb_64, effect_color.r), max(cb_64, effect_color.g), max(cb_64, effect_color.b), effect_color.a);
        float4 result_color = tex_color - ((1.0f - tex_color) * (1.0f - processed_color)) / processed_color;
        tex_color.r = ak * result_color.r + (1.0f - ak) * tex_color.r;
        tex_color.g = ak * result_color.g + (1.0f - ak) * tex_color.g;
        tex_color.b = ak * result_color.b + (1.0f - ak) * tex_color.b;
    }
    tex_color.a = 1.0f;
    
    PS_Output output;
    output.col = tex_color;
    return output;
}
