
Shader "Custom/pbr_test"
{

Properties
{
// @block Properties
    _MainTex("Texture", 2D) = "white" {}
    _BumpMap ("Normal Map", 2D) = "bump" {}
    _MetalMap ("Metal Map", 2D) = "white" {}
    _Metal("Metal", Range(0, 10)) = 1

    _RoughMap ("Rough Map", 2D) = "white" {}
    _Rough ("Rough", Range(0, 10)) = 1

    _OcclusionMap ("Occlusion Map", 2D) = "white" {}

    _Specular ("Specular", Color) = (1, 1, 1, 1)
    _Gloss ("Gloss", Range(0.01, 1)) = 0.5 

// @endblock
}

SubShader
{

// Tags { "Queue"="Geometry" "RenderType"="Opaque" }
// LOD 100


Pass
{
    Tags { "LightMode"="ForwardBase" }

    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    #pragma multi_compile_fog

#include "UnityCG.cginc"
#include "Lighting.cginc"

struct v2f
{
    float4 vertex : SV_POSITION;

    float2 uv : TEXCOORD0;

    float3 tspace0 : TEXCOORD1; // tangent.x, bitangent.x, normal.x
    float3 tspace1 : TEXCOORD2; // tangent.y, bitangent.y, normal.y
    float3 tspace2 : TEXCOORD3; // tangent.z, bitangent.z, normal.z


    float4 worldPos : TEXCOORD4;

    float3 normal : NORMAL;
};

// @block VertexShader
sampler2D _MainTex;
float4 _MainTex_ST;

sampler2D _BumpMap;
float4 _BumpMap_ST;

sampler2D _MetalMap;
float4 _MetalMap_ST;

sampler2D _RoughMap;
float4 _RoughMap_ST;

sampler2D _OcclusionMap;
float4 _OcclusionMap_ST;

fixed4 _Specular;
float _Gloss;

float _Rough;
float _Metal;

#define PI 3.14159265359


v2f vert(appdata_full v)
{
    v2f o;

    o.worldPos = mul(UNITY_MATRIX_M, v.vertex);

    float3 wNormal = UnityObjectToWorldNormal(v.normal);
    float3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
    // compute bitangent from cross product of normal and tangent
    float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    float3 wBitangent = cross(wNormal, wTangent) * tangentSign;
    // output the tangent space matrix
    o.tspace0 = float3(wTangent.x, wBitangent.x, wNormal.x);
    o.tspace1 = float3(wTangent.y, wBitangent.y, wNormal.y);
    o.tspace2 = float3(wTangent.z, wBitangent.z, wNormal.z);


    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

    o.normal = wNormal;
    return o;
}
// @endblock

// @block FragmentShader

float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom = a2;
    float denom = (NdotH2*(a2 - 1.0) + 1.0);
    denom = PI*denom*denom;

    return nom/denom;
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

float3 fresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0)*pow(1.0 - cosTheta, 5.0);
}

float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1,1,1)*(1.0 - roughness), F0) - F0)*pow(1.0 - cosTheta, 5.0);
}


// float GGX_D(half3 wm, float alpha) // alpha为粗糙度
// {
//     float tanTheta2 = TanTheta2(wm),
//     cosTheta2 = CosTheta2(wm);

// 	float root = alpha / (cosTheta2 * (alpha * alpha + tanTheta2));

// 	return INV_PI * (root * root);
// }

float4 frag(v2f i) : SV_Target
{
    fixed4 albedo = tex2D(_MainTex, i.uv);

    fixed3 metal = tex2D(_MetalMap, i.uv);
    metal.r *= _Metal;

    fixed3 rough = tex2D(_RoughMap, i.uv);
    rough.r *= _Rough;

    fixed3 ao = tex2D(_OcclusionMap, i.uv);

    float3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));

    float3 worldNormal;
    worldNormal.x = dot(i.tspace0, tnormal);
    worldNormal.y = dot(i.tspace1, tnormal);
    worldNormal.z = dot(i.tspace2, tnormal);

    float3 view = normalize(UnityWorldSpaceViewDir(i.worldPos));

    float3 refl = normalize(reflect(-view, worldNormal));

    float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos.xyz));
    // half3 lightDir = _WorldSpaceLightPos0;


    fixed3 diffuse =  _LightColor0.rgb * albedo.rgb * max(0, dot(worldNormal, lightDir));



    float3 halfDir = normalize(lightDir + view);

    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);


    //---------PBR---------

    // Calculate reflectance at normal incidence
    float3 F0 = half3(1,1,1) * 0.04;
    // F0 = lerp(F0, half3(albedo.rgb), metal.r);
    F0 = F0 * (1 - metal.r) + albedo.rgb * metal.r;


    // Calculate lighting for all lights
    float3 Lo = float3(0.0, 0.0, 0.0);
    float3 lightDot = float3(0.0, 0.0, 0.0);
    float3 normal = worldNormal;

    {

        // Cook-torrance BRDF
        float3 light = lightDir;
        float3 radiance = _LightColor0.rgb;

        float3 high = normalize(view + light);

        float NDF = DistributionGGX(normal, high, rough.r);
        float G = GeometrySmith(normal, view, light, rough.r);
        float3 F = fresnelSchlick(max(dot(high, view), 0.0), F0);
        float3 nominator = NDF*G*F;
        float denominator = 4*max(dot(normal, view), 0.0)*max(dot(normal, light), 0.0) + 0.001;
        float3 brdf = nominator/denominator;

        // Store to kS the fresnel value and calculate energy conservation
        float3 kS = F;
        float3 kD = float3(1.0, 1.0, 1.0) - kS;

        // Multiply kD by the inverse metalness such that only non-metals have diffuse lighting
        kD *= 1.0 - metal.r;

        // Scale light by dot product between normal and light direction
        float NdotL = max(dot(normal, light), 0.0);

        // Add to outgoing radiance Lo
        // Note: BRDF is already multiplied by the Fresnel so it doesn't need to be multiplied again
        Lo += (kD*albedo/PI + brdf)*radiance*NdotL*_LightColor0.a;
        lightDot += radiance*NdotL + brdf*_LightColor0.a;

        // return fixed4(saturate(dot(high, view)), 0, 0, 1);
        // return float4(denom, 0, 0, 1);
        // return fixed4(high,1);
        // return fixed4(Lo, 1);
        // return fixed4(brdf, 1);
    }

    // Calculate ambient lighting using IBL
    float3 F = fresnelSchlickRoughness(max(dot(normal, view), 0.0), F0, rough.r);
    float3 kS = F;
    float3 kD = 1.0 - kS;
    kD *= 1.0 - metal.r;

    // // Calculate indirect diffuse
    // vec3 irradiance = texture(irradianceMap, fragNormal).rgb;
    // vec3 diffuse = color*irradiance;

    // Sample both the prefilter map and the BRDF lut and combine them together as per the Split-Sum approximation
    // vec3 prefilterColor = textureLod(prefilterMap, refl, rough.r*MAX_REFLECTION_LOD).rgb;
    // half3 prefilterColor = half3(1,1,1);
    // half2 brdf = texture(brdfLUT, vec2(max(dot(normal, view), 0.0), rough.r)).rg;
    // vec3 reflection = prefilterColor*(F*brdf.x + brdf.y);

    // Calculate final lighting
    float3 ambient = (kD*diffuse + 0)*ao;

    float3 fragmentColor = ambient + Lo;                              // Physically Based Rendering
    // Apply HDR tonemapping
    // fragmentColor = fragmentColor/(fragmentColor + half3(1.0, 1.0, 1.0));

    // Apply gamma correction
    // fragmentColor = pow(fragmentColor, half3(1,1,1)*(1.0/2.2));


    fixed4 col = fixed4(fragmentColor.rgb, 1);
    // fixed4 col = fixed4(kS.rgb, 1);
    // fixed4 col = fixed4(lightDot.rgb, 1);
    // fixed4 col = fixed4(metal.rgb, 1);
    // fixed4 col = fixed4(kD.rgb, 1);
    // fixed4 col = fixed4(ao.rgb, 1);
    // fixed4 col = fixed4(diffuse + specular, 1);
    // fixed4 col = fixed4(lightDir.rgb, 1);
    // fixed4 col = albedo;

    // col = fixed4(worldNormal.xyz, 1);

    return col;
}
    ENDCG
}

}

// CustomEditor "uShaderTemplate.MaterialEditor"

}
