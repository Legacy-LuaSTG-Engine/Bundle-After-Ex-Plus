//==============================================================================
//模糊 code by Xiliusha(ETC)
//9点模式：中心和四周8个点平均
//推荐参数：半径x，迭代(最少~推荐)次(最多别超过64次！)
//          半径1，迭代1~2次(可用于一些符卡的特效)
//          半径2，迭代4~8次(推荐的级别，可用于暂停菜单模糊)
//          半径3，迭代8~16次(一般到这个级别就够用了)
//          半径4，迭代16~32次(已经很模糊了)
//          半径5，迭代32~64次(模糊程度非常高，烧显卡警告，2080土豪随意)
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

//根据采样半径对纹理周围8个点进行采样，然后和中心的点进行混合，9点模式
float4 GaussianSampler9(float2 uv, float r)
{
    float2 screenSize = float2(screen.z - screen.x, screen.w - screen.y);
    float2 xy = uv * screenSize;
    
    float4 TexColor=float4(0.0f,0.0f,0.0f,0.0f);
    float2 SamplerPoint[10];
    float2 Lxy;
    float2 Luv;
    
    //获得采样点偏移
    SamplerPoint[1] = float2(-1.0f * r, 1.0f * r);
    SamplerPoint[2] = float2(0.0f * r, 1.0f * r);
    SamplerPoint[3] = float2(1.0f * r, 1.0f * r);
    SamplerPoint[4] = float2(-1.0f * r, 0.0f * r);
    SamplerPoint[5] = float2(0.0f * r, 0.0f * r);
    SamplerPoint[6] = float2(1.0f * r, 0.0f * r);
    SamplerPoint[7] = float2(-1.0f * r, -1.0f * r);
    SamplerPoint[8] = float2(0.0f * r, -1.0f * r);
    SamplerPoint[9] = float2(1.0f * r, -1.0f * r);
    
    for (int se = 1; se <= 9; se = se + 1)
    {
        Lxy = xy + SamplerPoint[se]; //获得采样点坐标
        Lxy.x = clamp(Lxy.x, viewport.x + inner, viewport.z - inner); //限制采样点x坐标
        Lxy.y = clamp(Lxy.y, viewport.y + inner, viewport.w - inner); //限制采样点y坐标
        Luv = Lxy / screenSize; //获得采样点uv坐标
        TexColor = TexColor + tex2D(ScreenTextureSampler, Luv); //得到采样颜色并相加
    }
    
    return TexColor / 9.0f; //取平均值
}

float4 PS_MainPass(float4 position : POSITION, float2 uv : TEXCOORD0):COLOR
{
    float scale=(screen.w-screen.y)/480.0f;//保证画面效果在不同分辨率下相同，除以的数为游戏基础坐标系的y(小海鸽建议改为960)
    float4 texColor = GaussianSampler9(uv,radiu*scale);//获得均值颜色，9点
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