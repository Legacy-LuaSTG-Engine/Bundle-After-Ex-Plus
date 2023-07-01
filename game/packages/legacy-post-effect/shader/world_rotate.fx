//======================================
//code by Xiliusha(ETC)
//powered by OLC
//做正邪的卡可以用上
//======================================

// 由PostEffect过程捕获到的纹理
texture2D ScreenTexture:POSTEFFECTTEXTURE;//纹理
sampler2D ScreenTextureSampler = sampler_state//采样器
{
    texture = <ScreenTexture>;
    AddressU  = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

// 自动设置的参数
float4 screen : SCREENSIZE;  // 屏幕缓冲区大小

// 外部参数
float centerX < string binding = "centerX"; > = 0.0f;//指定效果的中心坐标X
float centerY < string binding = "centerY"; > = 0.0f;//指定效果的中心坐标Y
float vscale < string binding = "vscale"; > = 1.0f;//水平缩放
float hscale < string binding = "hscale"; > = 1.0f;//垂直缩放
float angle < string binding = "angle"; > = 0.0f;//旋转

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{
    float2 screenSize = float2(screen.z - screen.x, screen.w - screen.y);
    float2 xy = uv * screenSize;//屏幕上真实位置
    float2 center = float2(centerX, centerY);
    float2 delta = xy - center;//计算效果中心到坐标的向量
    
    float tx;
    float ty;
    
    if (vscale == 0)
    {
        tx = centerX;
    }
    else
    {
        tx = center[0] + delta[0] * 1/vscale;//缩放水平坐标
    }
    if (hscale == 0)
    {
        ty = centerY;
    }
    else
    {
        ty = center[1] + delta[1] * 1/hscale;//缩放垂直坐标
    }
    
    float2 xy2 = float2(tx, ty);
    
    float2 delta2 = xy2 - center;//效果中心到坐标的向量
    float rot = radians(angle);//角度化弧度
    float2 trans = float2(cos(rot), sin(rot));//转为向量？形式
    float2 xy3= float2(delta2.x * trans[0] - delta2.y * trans[1], delta2.x * trans[1] + delta2.y * trans[0]) + center;//坐标旋转
    
    uv=xy3/screenSize;//转换为uv坐标
    
    float4 texColor = tex2D(ScreenTextureSampler, uv);//对纹理进行采样
    
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
