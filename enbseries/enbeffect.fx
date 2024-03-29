//========================================================//
//                                                        //
//      _/_/_/_/  _/                                      //
//     _/        _/_/_/      _/_/    _/_/_/    _/    _/   //
//    _/_/_/    _/    _/  _/    _/  _/    _/  _/    _/    //
//   _/        _/    _/  _/    _/  _/    _/  _/    _/     //
//  _/_/_/_/  _/_/_/      _/_/    _/    _/    _/_/_/      //
//                                               _/       //
//                                          _/_/          //
//========================================================//
//     An ENB Preset by MechanicalPanda and Adyss         //
//========================================================// 

// Uncommend to get some debug features
//#define DEBUG_MODE

//========================================================//
// Textures                                               //
//========================================================//

// Main Buffers
Texture2D TextureColor;         // HDR color
Texture2D TextureOriginal;      // color R16B16G16A16 64 bit hdr format
Texture2D TextureBloom;         // ENB bloom
Texture2D TextureLens;          // ENB lens fx
Texture2D TextureAdaptation;    // ENB adaptation
Texture2D TextureDepth;         // Scene depth
Texture2D TextureAperture;      // This frame aperture 1*1 R32F hdr red channel only . computed in depth of field shader file
Texture2D TexturePalette;       // enbpalette texture, if loaded and enabled in [colorcorrection].

//temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D RenderTargetRGBA32;   //R8G8B8A8 32 bit ldr format
Texture2D RenderTargetRGBA64;   //R16B16G16A16 64 bit ldr format
Texture2D RenderTargetRGBA64F;  //R16B16G16A16F 64 bit hdr format
Texture2D RenderTargetR16F;     //R16F 16 bit hdr format with red channel only
Texture2D RenderTargetR32F;     //R32F 32 bit hdr format with red channel only
Texture2D RenderTargetRGB32F;   //32 bit hdr format without alpha

//========================================================//
// Internals                                              //
//========================================================//
#include "Include/Shared/Globals.fxh"
#include "Include/Shared/ReforgedUI.fxh"
#include "Include/Shared/Conversions.fxh"
#include "Include/Shared/BlendingModes.fxh"

//========================================================//
// UI                                                     //
//========================================================//
UI_MESSAGE(1,                       " \x95 Ebony ENB \x95 ")
UI_WHITESPACE(1)
UI_MESSAGE(3,                   	"|----- Filmic VDR Tonemap -----")
UI_FLOAT_TODID(uiHdrMax,      	    "| VDR Max White",		    1.0, 50.0, 16.0)
UI_FLOAT_TODID(uiContrast,      	"| VDR Contrast",		    0.1, 2.0, 1.0)
UI_FLOAT_TODID(uiShoulder,      	"| VDR Shoulder",		    0.0, 2.0, 1.0)
UI_FLOAT_TODID(uiMidIn,      	    "| VDR Mid In",		        0.0, 1.0, 0.18)
UI_FLOAT_TODID(uiMidOut,      	    "| VDR Mid Out",		    0.0, 1.0, 0.18)
UI_FLOAT_TODID(uiCrosstalk,      	"| VDR Crosstalk",		    0.0, 20.0, 4.0)
UI_WHITESPACE(2)
UI_MESSAGE(4,                       "|----- Color -----")
UI_FLOAT_TODID(exposure,            "| Exposure",              -10.0, 10.0, 0.0)
UI_FLOAT_TODID(adapationImpact,     "| Adaptation Impact",      0.0, 10.0, 1.0)
UI_FLOAT_TODID(gamma,               "| Gamma",                  0.1, 3.0, 1.0)
UI_FLOAT3_TODID(rgbGamma,           "| RGB Gamma",              0.5, 0.5, 0.5)
UI_FLOAT_FINE_TODID(colorTempK,     "| Color Temperature",      1000.0, 30000.0, 7000.0, 20.0)
UI_FLOAT_TODID(desaturation,        "| Desaturation",           0.0, 1.0, 0.1)
UI_FLOAT_TODID(resaturation,        "| Resaturation",           0.0, 1.0, 0.1)
UI_FLOAT_TODID(saturation,          "| Saturation",             0.1, 5.0, 1.0)
UI_FLOAT_TODID(contrast,            "| Contrast",               0.0, 1.0, 0.5)
UI_FLOAT_TODID(maxWhite,            "| Max White",              0.0, 12.0, 1.0)
UI_FLOAT_TODID(blackPoint,          "| Black Point",           -1.0, 1.0, 0.0)
UI_FLOAT_TODID(whitePoint,          "| White Point",            0.0, 100.0, 1.0)
UI_WHITESPACE(3)
UI_FLOAT_DNI(h_BlueShift,           "| Highlights Blueshift",   -1.0, 1.0, 0.0)
UI_FLOAT_DNI(h_GreenShift,          "| Highlights Greenshift",  -1.0, 1.0, 0.0)
UI_FLOAT_DNI(h_RedShift,            "| Highlights Redshift",    -1.0, 1.0, 0.0)
UI_FLOAT_DNI(m_BlueShift,           "| Midtones Blueshift",     -1.0, 1.0, 0.0)
UI_FLOAT_DNI(m_GreenShift,          "| Midtones Greenshift",    -1.0, 1.0, 0.0)
UI_FLOAT_DNI(m_RedShift,            "| Midtones Redshift",      -1.0, 1.0, 0.0)
UI_FLOAT_DNI(s_BlueShift,           "| Shadows Blueshift",      -1.0, 1.0, 0.0)
UI_FLOAT_DNI(s_GreenShift,          "| Shadows Greenshift",     -1.0, 1.0, 0.0)
UI_FLOAT_DNI(s_RedShift,            "| Shadows Redshift",       -1.0, 1.0, 0.0)
UI_WHITESPACE(4)
UI_MESSAGE(5,                       "|----- Nighteye -----")
UI_FLOAT(neBrightness,              "| Nighteye Brightness",    0.0, 8.0, 1.0)
UI_FLOAT(neGamma,                   "| Nighteye Gamma",         0.0, 3.0, 1.0)
UI_FLOAT(neContrast,                "| Nighteye Contrast",      0.0, 2.5, 1.0)
#ifdef DEBUG_MODE
UI_WHITESPACE(5)
UI_MESSAGE(6,                       "|----- Debug -----")
UI_BOOL(showBloom,                  "| Show Bloom",             false)
UI_BOOL(showLens,                   "| Show Lens",              false)
#endif

//========================================================//
// Functions                                              //
//========================================================//

#include "Include/Shaders/colorBalance.fxh"
#include "Include/Shared/Graphing.fxh"

// VDR Tonemap by Timothy Lottes
// Added parts of Frostbyte Style Tonemap since they are kinda similar

// General tonemapping operator, build 'b' term.
float ColToneB(float hdrMax, float contrast, float shoulder, float midIn, float midOut) 
{
    return
        -((-pow(midIn, contrast) + (midOut*(pow(hdrMax, contrast * shoulder) * pow(midIn, contrast) -
            pow(hdrMax, contrast) * pow(midIn, contrast * shoulder) * midOut)) /
           (pow(hdrMax, contrast * shoulder) * midOut - pow(midIn, contrast * shoulder)*midOut)) /
           (pow(midIn, contrast * shoulder) * midOut));
}

// General tonemapping operator, build 'c' term.
float ColToneC(float hdrMax, float contrast, float shoulder, float midIn, float midOut) 
{
    return (pow(hdrMax, contrast * shoulder) * pow(midIn, contrast) - pow(hdrMax, contrast) * pow(midIn, contrast * shoulder) * midOut) /
           (pow(hdrMax, contrast * shoulder) * midOut - pow(midIn, contrast * shoulder) * midOut);
}

// General tonemapping operator, p := {contrast,shoulder,b,c}.
float ColTone(float x, float4 p)
{ 
    float  z = pow(x, p.r); 
    return z / (pow(z, p.g)*p.b + p.a); 
}

float3 TimothyTonemapper(float3 color)
{
    // Hue-preserving range compression requires desaturation in order to achieve a natural look
    float3 ictcp    = rgb2ictcp(color);
    float  presat   = pow(smoothstep(1.0, 1.0 - desaturation, ictcp.x), 1.3);
           color    = ictcp2rgb(ictcp * float3(1.0, presat.xx));

    // Tonemap
    float  b        = ColToneB(uiHdrMax, uiContrast, uiShoulder, uiMidIn, uiMidOut);
    float  c        = ColToneC(uiHdrMax, uiContrast, uiShoulder, uiMidIn, uiMidOut);

    float  peak     = max3(color);
    float3 ratio    = color / peak;
           peak     = ColTone(peak, float4(uiContrast, uiShoulder, b, c));

    // Channel Crosstalk
    float  crossSat = uiContrast * 16.0;
    float  white    = 1.0;

           ratio    = pow(abs(ratio), saturation / crossSat);
           ratio    = lerp(ratio, white, pow(peak, uiCrosstalk));
           ratio    = pow(abs(ratio), crossSat);

    // Resaturation
           color   = peak * ratio;
    float3 final   = rgb2ictcp(color);
    float  postsat = resaturation * smoothstep(1.0, 0.0, ictcp.x);
           final.yz = lerp(final.yz, ictcp.yz * final.x / max(1e-3, ictcp.x), postsat);

    return ictcp2rgb(final);
}

// S Curve by Sevence
float3 S_Curve(float3 x)
{
    float  a = saturate(1.0 - contrast);  //  0.0 - 1.0
    float  w = maxWhite;     //  1.0 - 11.2
    float  l = blackPoint;   // -1.0 - 1.0
    float  h = whitePoint;   //  1.0 - 100.0

    float3 A = 0.5 * ((2 * x - 1) / (a + (1 - a) * abs(2 * x - 1))) + 0.5;
    float3 B = 0.5 * ((2 * w - 1) / (a + (1 - a) * abs(2 * w - 1))) + 0.5;

    return max(l + (h - l) * (A / B), 0.001);
}

float3 colorTemperatureToRGB(float temperatureInKelvins)
{
	float3 retColor;

    temperatureInKelvins = clamp(temperatureInKelvins, 1000.0, 40000.0) / 100.0;

    if (temperatureInKelvins <= 66.0)
    {
        retColor.r = 1.0;
        retColor.g = saturate(0.39008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098);
    }
    else
    {
    	float t = temperatureInKelvins - 60.0;
        retColor.r = saturate(1.29293618606274509804 * pow(t, -0.1332047592));
        retColor.g = saturate(1.12989086089529411765 * pow(t, -0.0755148492));
    }

    if (temperatureInKelvins >= 66.0)
        retColor.b = 1.0;
    else if(temperatureInKelvins <= 19.0)
        retColor.b = 0.0;
    else
        retColor.b = saturate(0.54320678911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914);

    return retColor;
}

// Apply wb lumapreserving
float3 whiteBalance(float3 color, float luma)
{
    color /= luma;
    color *= colorTemperatureToRGB(colorTempK);
    return color * luma;
}

//========================================================//
// Pixel Shaders                                          //
//========================================================//
float3	PS_Color(VS_OUTPUT IN, float4 v0 : SV_Position0) : SV_Target
{
    float2  coord   = IN.txcoord.xy;
    float3  color   = TextureColor.Sample(PointSampler,  coord);
    float3  bloom   = TextureBloom.SampleLevel(LinearSampler, coord, 0) * ENBParams01.x;
    float3  lens    = TextureLens.Sample(LinearSampler, coord);
    float   adapt   = TextureAdaptation.Load(int3(0, 0, 0));

            //Debug
    #ifdef DEBUG_MODE
            if(showBloom)
            return bloom;

            if(showLens)
            return lens;
     #endif

            color  += bloom / (1 + color);                          // Blend Bloom
            color  *= exp(exposure - (adapt * adapationImpact));    // Exposure
            color   = TimothyTonemapper(color);                     // Tonemap
            color   = pow(color, gamma - rgbGamma + 0.5);           // Gamma
            color   = whiteBalance(color, GetLuma(color, Rec709));  // Whitebalane
            color   = S_Curve(color);                               // Contrast
            color   = ColorBalance(color, float3(s_RedShift, s_GreenShift, s_BlueShift), 
                                          float3(m_RedShift, m_GreenShift, m_BlueShift),
                                          float3(h_RedShift, h_GreenShift, h_BlueShift));

            // Fade effects
            color   = lerp(color, Params01[5].xyz, Params01[5].w);  

    	    // Nighteye
            if((Params01[5].r > 0.46 && Params01[5].r < 0.47) && (Params01[5].b > 0.74 && Params01[5].b < 0.75) && (Params01[5].g > 0.56 && Params01[5].g < 0.57))
            {
                float3 neColor  = color * neBrightness;
                       neColor  = pow(neColor, neGamma);
                       neColor  = (neColor - 0.5) * neContrast + 0.5;
                       color    = lerp(color, neColor, Params01[5].w * 2.0); // ne intensity sucks... so 2x
            }

    return saturate(color + triDither(color, coord, Timer.x, 8));
}

//========================================================//
// Techniques                                             //
//========================================================//
technique11 Draw <string UIName="Ebony ENB";>
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
        SetPixelShader (CompileShader(ps_5_0, PS_Color()));
    }
}