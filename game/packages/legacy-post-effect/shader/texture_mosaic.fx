//======================================
//shader原作者：欧艾露汐(OLC)
//shader改进（和阉割）：Xiliusha(ETC)
//======================================

texture2D ScreenTexture:POSTEFFECTTEXTURE;
sampler2D ScreenTextureSampler = sampler_state {
    texture = <ScreenTexture>;
    AddressU  = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

float4 screen : SCREENSIZE;

//效果中心参数，可选，默认为窗口左上角
float CX < string binding = "CX"; > = 0.0f;
float CY < string binding = "CY"; > = 0.0f;
//矩形马赛克单体，默认值为0.01
float SizeX < string binding = "SizeX"; > = 0.01f;
float SizeY < string binding = "SizeY"; > = 0.01f;

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{
    float2 mosaicSize = float2(abs(SizeX), abs(SizeY));
    mosaicSize = max(mosaicSize, float2(0.01f, 0.01f));
    float2 screenSize = float2(screen.z - screen.x, screen.w - screen.y);
    float2 xy = uv * screenSize;
    
    xy.x = (CX + mosaicSize[0] / 2) + floor((xy.x - (CX + mosaicSize[0] / 2)) / mosaicSize[0]) * mosaicSize[0];
    xy.y = (CY - mosaicSize[1] / 2) + floor((xy.y - (CY - mosaicSize[1] / 2)) / mosaicSize[1]) * mosaicSize[1];
    xy = xy + mosaicSize * float2(0.5, 0.5);
    
    uv = xy / screenSize;
    
    float4 texColor = tex2D(ScreenTextureSampler, uv);
    
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
