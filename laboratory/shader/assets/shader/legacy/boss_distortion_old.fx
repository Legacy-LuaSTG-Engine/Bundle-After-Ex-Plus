/*
 * BOSS背景扭曲特效
 *
 * code by CHU for DFLYT
 *
 */

// 由PostEffect过程捕获到的纹理
texture2D ScreenTexture:POSTEFFECTTEXTURE;  // 纹理
sampler2D ScreenTextureSampler = sampler_state {  // 采样器
    texture = <ScreenTexture>;
    AddressU  = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

// 自动设置的参数
float4 screen : SCREENSIZE;  // 屏幕缓冲区大小

// 外部参数
float centerX < string binding = "centerX"; > = 100.0f;  // 指定效果的中心坐标X
float centerY < string binding = "centerY"; > = 100.0f;  // 指定效果的中心坐标Y
float effectSize < string binding = "size"; > = 50.0f;  // 指定效果的影响大小
float effectArg < string binding = "arg"; > = 25.f;  // 变形系数
float4 effectColor < string binding = "color"; > = float4(163/255.f, 73/255.f, 164/255.f, 1.f);  // 指定效果的中心颜色
float effectColorSize < string binding = "colorsize"; > = 80.0f;  // 指定颜色的扩散大小
float timer < string binding = "timer"; > = 0.f;  // 外部计时器

float2 Distortion(float2 xy, float2 delta, float deltaLen)
{
    float k = deltaLen / effectSize;
    float p = (k - 1) * (k - 1);
    float2 delta1 = float2(effectArg * 0.8 * sin((xy.x * 0.5 + xy.y) / 18 + timer / 5), 0);
    float arg = lerp(effectArg * 1.2f, effectArg * 0.8f, sin(timer / 10) * 0.5f + 1.f);
    float2 delta2 = deltaLen * (1 - lerp(pow(k, (1 + arg)), k, k));
    return delta1 * p + delta2 * p * 0.8f;
}

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{
    float2 screenSize = float2(screen.z - screen.x, screen.w - screen.y);
    float2 center = float2(centerX, centerY);
    float2 xy = uv * screenSize;  // 屏幕上真实位置
    float2 delta = xy - center;  // 计算效果中心到纹理采样点的向量
    float deltaLen = length(delta);
    delta = normalize(delta);
    
    if (deltaLen <= effectSize) {
        float2 distDelta = Distortion(xy, delta, deltaLen);
        uv += distDelta / screenSize;
    }
    
    // 对纹理进行采样
    float4 texColor = tex2D(ScreenTextureSampler, uv);
    
    // 着色
    if (deltaLen <= effectColorSize) {
        float k = deltaLen / effectColorSize;
        float4 addColor = lerp(effectColor, float4(0, 0, 0, 0), k * k);
        texColor += addColor * addColor.a;
    }
 
    texColor.a = 1;
    return texColor;
}

technique Main
{
    pass MainPass
    {
        PixelShader = compile ps_3_0 PS_MainPass();
    }
}
