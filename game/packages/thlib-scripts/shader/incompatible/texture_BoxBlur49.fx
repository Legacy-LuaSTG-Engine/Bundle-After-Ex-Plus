//==============================================================================
//模糊 code by Xiliusha(ETC)
//49点模式：中心和四周8个点加上外围16个再加上最外围24点平均
//推荐参数：半径x，迭代(最少~推荐)次(最多别超过4次！)
//          半径1，迭代1~1次(可用于一些符卡的特效)
//          半径2，迭代1~1次(可用于一些符卡的特效)
//          半径3，迭代1~2次(推荐的级别，可用于暂停菜单模糊)
//          半径4，迭代2~2次(一般到这个级别就够用了)
//          半径5，迭代2~3次(已经很模糊了)
//          半径6，迭代3~3次(模糊程度非常高)
//==============================================================================

texture2D ScreenTexture:POSTEFFECTTEXTURE;
sampler2D ScreenTextureSampler = sampler_state {
    texture = <ScreenTexture>;
    AddressU  = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

float inner = 1.0f;//边沿缩进

float4 screen : SCREENSIZE;
float4 viewport : VIEWPORT;

float radiu < string binding = "radiu"; > = 0.0f;//采样半径(单位：游戏内单位长度，即和游戏坐标系相关)

//根据采样半径对纹理周围8个点进行采样，然后和中心的点进行混合，49点模式
float4 GaussianSampler49(float2 uv, float r)
{
    float2 screenSize = float2(screen.z - screen.x, screen.w - screen.y);
    float2 xy = uv * screenSize;
    
    float ratble[8]={9961.0f,-1.0f,-0.65f,-0.35f,0.0f,0.35f,0.65f,1.0f};
    float4 TexColor=float4(0.0f,0.0f,0.0f,0.0f);
    float2 SamplerPointx[22];
    float2 SamplerPointy[22];
    float2 SamplerPointz[8];
    float2 Lxy;
    float2 Luv;
    float num;
    
    //获得采样点偏移
    for (int sa = 1; sa <= 7; sa = sa + 1)
    {
        num = ratble[sa];
        SamplerPointx[sa] = float2(-1.0f * r, num * r);
        SamplerPointx[7+sa] = float2(-0.65f * r, num * r);
        SamplerPointx[14+sa] = float2(-0.35f * r, num * r);
        SamplerPointy[sa] = float2(0.0f * r, num * r);
        SamplerPointy[7+sa] = float2(0.35f * r, num * r);
        SamplerPointy[14+sa] = float2(0.65f * r, num * r);
        SamplerPointz[sa] = float2(1.0f * r, num * r);
    }
    
    for (int se = 1; se <= 21; se = se + 1)
    {
        Lxy = xy + SamplerPointx[se]; //获得采样点坐标
        Lxy.x = clamp(Lxy.x, viewport.x + inner, viewport.z - inner); //限制采样点x坐标
        Lxy.y = clamp(Lxy.y, viewport.y + inner, viewport.w - inner); //限制采样点y坐标
        Luv = Lxy / screenSize; //获得采样点uv坐标
        TexColor = TexColor + tex2D(ScreenTextureSampler, Luv); //得到采样颜色并相加
    }
    for (int se = 1; se <= 21; se = se + 1)
    {
        Lxy = xy + SamplerPointy[se]; //获得采样点坐标
        Lxy.x = clamp(Lxy.x, viewport.x + inner, viewport.z - inner); //限制采样点x坐标
        Lxy.y = clamp(Lxy.y, viewport.y + inner, viewport.w - inner); //限制采样点y坐标
        Luv = Lxy / screenSize; //获得采样点uv坐标
        TexColor = TexColor + tex2D(ScreenTextureSampler, Luv); //得到采样颜色并相加
    }
    for (int se = 1; se <= 7; se = se + 1)
    {
        Lxy = xy + SamplerPointz[se]; //获得采样点坐标
        Lxy.x = clamp(Lxy.x, viewport.x + inner, viewport.z - inner); //限制采样点x坐标
        Lxy.y = clamp(Lxy.y, viewport.y + inner, viewport.w - inner); //限制采样点y坐标
        Luv = Lxy / screenSize; //获得采样点uv坐标
        TexColor = TexColor + tex2D(ScreenTextureSampler, Luv); //得到采样颜色并相加
    }
    
    return TexColor / 49.0f; //取平均值
}

float4 PS_MainPass(float4 position : POSITION, float2 uv : TEXCOORD0):COLOR
{
    float scale=(screen.w-screen.y)/480.0f;//保证画面效果在不同分辨率下相同，除以的数为游戏基础坐标系的y(小海鸽建议改为960)
    float4 texColor = GaussianSampler49(uv,radiu*scale);//获得均值颜色，49点
    texColor.a = 1.0f;
    return texColor;
}

technique Main
{
    pass MainPass
    {
        PixelShader = compile ps_3_0 PS_MainPass();
    }
}