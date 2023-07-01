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
float4 viewport : VIEWPORT;  // 视口

// 外部参数
float centerX < string binding = "centerX"; > = 100.0f;  // 指定效果的中心坐标X
float centerY < string binding = "centerY"; > = 100.0f;  // 指定效果的中心坐标Y
float effectSize < string binding = "size"; > = 50.0f;  // 指定效果的影响大小
float effectArg < string binding = "arg"; > = 25.f;  // 变形系数
float4 effectColor < string binding = "color"; > = float4(163/255.f, 73/255.f, 164/255.f, 1.f);  // 指定效果的中心颜色,着色时使用colorburn算法
float effectColorSize < string binding = "colorsize"; > = 80.0f;  // 指定颜色的扩散大小
float timer < string binding = "timer"; > = 0.f;  // 外部计时器
//
float inner = 5.f; //边沿缩进

float2 Distortion(float2 xy, float2 delta, float deltaLen)
{
	static const float PI = 3.14159265f;
	float inner = 1.f;
	float k = deltaLen / effectSize;
	float p = pow((k-1),0.75);
	float arg = effectArg * p;
	float2 delta1 = float2(sin(1.75f * 2 * PI * delta.x + 0.05f*deltaLen + timer/20),sin(1.75f * 2 * PI * delta.y + 0.05f*deltaLen + timer/24)); //1.75f 此项越高，波纹越“破碎”
	float delta2 = arg * sin(0.005f * 2 * PI * deltaLen+ timer/40); //0.005f 此项越高，波纹越密
	return delta1 * delta2; //delta1：方向向量，delta2：向量长度，即返回像素移动的方向和距离
}

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{	 	
		float2 uv2 = uv;
		float2 screenSize = float2(screen.z - screen.x, screen.w - screen.y);
		float2 center = float2(centerX, centerY);
		float2 xy = uv * screenSize;  // 屏幕上真实位置
		float2 delta = xy - center;  // 计算效果中心到纹理采样点的向量
		float deltaLen = length(delta);
		delta = normalize(delta);
    
		if (deltaLen <= effectSize) {
			float2 distDelta = Distortion(xy, delta, deltaLen);
			float2 resultxy = xy + distDelta;
			if (resultxy.x>viewport.x+inner && resultxy.x<viewport.z-inner && resultxy.y>viewport.y+inner && resultxy.y<viewport.w-inner) {
			uv2 += distDelta / screenSize;
			}
			else {
			uv2=uv;
			}
		}
	// 对纹理进行采样
	float4 texColor = tex2D(ScreenTextureSampler, uv2); //使用uv2采样
	
	// 扭曲着色
	if (deltaLen <= effectColorSize) {
		float k = deltaLen / effectColorSize;
		float ak = effectColor.a * pow((1-k),1.2);
		float4 processedcolor=float4(max(64/255.f,effectColor.r),max(64/255.f,effectColor.g),max(64/255.f,effectColor.b),effectColor.a);
		float4 resultColor = texColor - ((1-texColor)*(1-processedcolor))/processedcolor;
		texColor.r = ak * resultColor.r + (1 - ak) * texColor.r;
		texColor.g = ak * resultColor.g + (1 - ak) * texColor.g;
		texColor.b = ak * resultColor.b + (1 - ak) * texColor.b;
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
