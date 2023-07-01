//======================================
//code by Xiliusha(ETC)
//======================================

texture2D ScreenTexture:POSTEFFECTTEXTURE;
sampler2D ScreenTextureSampler = sampler_state
{
    texture = <ScreenTexture>;
    AddressU  = BORDER;
    AddressV = BORDER;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
};

//自动设置的参数
float4 screen : SCREENSIZE;

//色相
float DH < string binding = "dh"; > = 0.0f;//色调（0~360）
float DS < string binding = "ds"; > = 0.0f;//饱和度（0~1）
float DV < string binding = "dv"; > = 0.0f;//明度（0~1）

float4 PS_MainPass(float4 position:POSITION, float2 uv:TEXCOORD0):COLOR
{
    float4 texColor = tex2D(ScreenTextureSampler, uv);
    
    float r=texColor.r;
    float g=texColor.g;
    float b=texColor.b;
    float a=texColor.a;
    float h;
    float s;
    float l;

    {   //rgb to hsl
        float bmax=max(max(r,g),b);
        float bmin=min(min(r,g),b);
        //h
        if(bmax==bmin){
            h=0.0;
        }
        else if(bmax==r && g>=b){
            h=60.0*(g-b)/(bmax-bmin)+0.0;
        }
        else if(bmax==r && g<b){
            h=60.0*(g-b)/(bmax-bmin)+360.0;
        }
        else if(bmax==g){
            h=60.0*(b-r)/(bmax-bmin)+120.0;
        }
        else if(bmax==b){
            h=60.0*(r-g)/(bmax-bmin)+240.0;
        }
        //l
        l=0.5*(bmax+bmin);
        //s
        if(l==0.0 || bmax==bmin){
            s=0.0;
        }
        else if(0.0<=l && l<=0.5){
            s=(bmax-bmin)/(2.0*l);
        }
        else if(l>0.5){
            s=(bmax-bmin)/(2.0-2.0*l);
        }
    }

    //change hue
    h=h+DH;
    s=min(1.0,max(0.0,s+DS));
    l=min(1.0,max(0.0,l+DV));

    float4 finalColor;
    {   //hsl to rgb
        float q;
        if(l<0.5){
            q=l*(1.0+s);
        }
        else if(l>=0.5){
            q=l+s-l*s;
        }
        float p=2.0*l-q;
        float hk=h/360.0;
        float3 t;
        t[0]=hk+1.0/3.0;
        t[1]=hk;
        t[2]=hk-1.0/3.0;
        for(int i=0;i<3;i=i+1){
            if(t[i]<0.0){
                t[i]=t[i]+1.0;
            }
            if(t[i]>1.0){
                t[i]=t[i]-1.0;
            }
        }//got t[i]
        float3 c;
        for(int i=0;i<3;i=i+1){
            if(t[i]<1.0/6.0){
                c[i]=p+((q-p)*6.0*t[i]);
            }else if(1.0/6.0<=t[i] && t[i]<0.5){
                c[i]=q;
            }else if(0.5<=t[i] && t[i]<2.0/3.0){
                c[i]=p+((q-p)*6.0*(2.0/3.0-t[i]));
            }else{
                c[i]=p;
            }
        }
        finalColor=float4(c[0],c[1],c[2],a);
    }

    return finalColor;
}

technique Main
{
    pass MainPass
    {
        PixelShader = compile ps_3_0 PS_MainPass();
    }
}
