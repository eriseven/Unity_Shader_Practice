#ifndef ERI_SEVEN_CG_INCLUD
#define ERI_SEVEN_CG_INCLUD

#include "UnityCG.cginc"
#include "Lighting.cginc"

#define HALF3_ONE   half3(1,1,1)
#define HALF3_ZERO  half3(0,0,0)

//------------------Utilities---------------------
float DotClamp01(float3 v1, float3 v2)
{
    return saturate(dot(v1, v2));
}



//------------------PBR Functions---------------------
// Cook-torrance BRDF
// float Cook_Torrance_BRDF(float3 l, float3 v)
// {

// }


inline half _Pow5 (half x)
{
    return x*x * x*x * x;
}

half _DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
{
    half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
    // Two schlick fresnel term
    half lightScatter   = (1 + (fd90 - 1) * _Pow5(1 - NdotL));
    half viewScatter    = (1 + (fd90 - 1) * _Pow5(1 - NdotV));

    return lightScatter * viewScatter;
}


//Normal Distribution Function (NDF)
half DistributionGGX(half3 N, half3 H, half roughness)
{
    half a = roughness*roughness;
    // half a = roughness;
    half a2 = a*a;
    half NdotH = max(dot(N, H), 0.0);
    half NdotH2 = NdotH*NdotH;

    half nom = a2;
    half denom = (NdotH2*(a2 - 1.0) + 1.0);
    denom = UNITY_PI*denom*denom;

    return nom/denom;
}

half Blinn_Phong(half3 N, half3 H, half roughness)
{
    half a = roughness*roughness;
    half a2 = a*a;

    half denom = UNITY_PI * a2;

    half NdotH = DotClamp01(N,H);

    half nom = pow(NdotH, (2/a2 - 2));

    return nom/denom;
}

half Benckmann(half3 N, half3 H, half roughness)
{
    half a = roughness*roughness;
    half a2 = a*a;

    half NdotH = DotClamp01(N,H);
    half NdotH2 = NdotH * NdotH;
    half NdotH4 = NdotH2 * NdotH2;

    half denom = UNITY_PI * a2 * NdotH4 + 0.0000001;

    half nom = exp((NdotH2-1)/(a2 * NdotH2));

    return nom/denom;
}




//Geometric Shadowing

half GeometryImplicit(half NdotL, half NdotV)
{
    return NdotL * NdotV + 0.0000001;
}

half GeometryNeumann(half NdotL, half NdotV)
{
    return (NdotL * NdotV) / (max(NdotL, NdotV) + 0.0000001);
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = r*r/8.0;

    // float k = roughness/2.0;
    float nom = NdotV;
    float denom = NdotV*(1.0 - k) + k;

    return nom/denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1*ggx2;
}

//Fresnel
float3 FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0)*pow(1.0 - cosTheta, 5.0);
}

float3 FresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(HALF3_ONE * (1.0 - roughness), F0) - F0)*pow(1.0 - cosTheta, 5.0);
}

#endif //ERI_SEVEN_CG_INCLUD