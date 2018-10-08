Shader "EriSeven/PBR/PBRShader"
{
	// Properties
	Properties
	{
        _Color("Base Color", Color) = (1,1,1,1)
		_MainTex ("Albedo", 2D) = "white" {}

		_NormalMap ("Normal Map", 2D) = "bump" {}

		_MetalMap ("Metal Map", 2D) = "white" {}
		_Metal("Metal", Range(0, 1)) = 1

		_RoughMap ("Rough Map", 2D) = "white" {}
		_Rough ("Rough", Range(0, 1)) = 1

		_OcclusionMap ("Occlusion Map", 2D) = "white" {}

		// _IrradianceMap("Irrandiance Map", Cube) = "_Skybox" {}
		// _RadianceMap("Randiance Map", Cube) = "_Skybox" {}
		// _BDRF_Map("BDRF LUT Map", 2D) = "white" {}

		[KeywordEnum(DistributionGGX, Blinn_Phong, Benckmann)] 
		_NDF("Normal Distribution Function (NDF)", Float) = 0

		[KeywordEnum(Smith, Implicit, Neumann)] 
		_Geometry("Geometric Shadowing (G)", Float) = 0


		[KeywordEnum(None, Color, Normal, Metal, Rough, AO, Direct, Indirect)] 
		_Debug("Debug mode", Float) = 0

		[Toggle] _Force_Colorspace_Linear("Force Linear Colorspace", Float) = 0
	}


	// Common CG
	CGINCLUDE
		#pragma multi_compile_fwdbase

		#pragma multi_compile _DEBUG_NONE _DEBUG_COLOR _DEBUG_NORMAL _DEBUG_METAL _DEBUG_ROUGH _DEBUG_AO _DEBUG_DIRECT _DEBUG_INDIRECT
		#pragma multi_compile _NDF_DISTRIBUTIONGGX _NDF_BLINN_PHONG _NDF_BENCKMANN
		#pragma multi_compile _GEOMETRY_SMITH _GEOMETRY_IMPLICIT _GEOMETRY_NEUMANN

		#pragma shader_feature _FORCE_COLORSPACE_LINEAR_ON

		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		#include "EriSevenCG.cginc"

		fixed4 _Color;

		sampler2D _MainTex;
		float4 _MainTex_ST;

		sampler2D _NormalMap;

		sampler2D _MetalMap;
		half _Metal;

		sampler2D _RoughMap;
		half _Rough;

		sampler2D _OcclusionMap;


		UNITY_DECLARE_TEXCUBE(_IrradianceMap);
		UNITY_DECLARE_TEXCUBE(_RadianceMap);
		sampler2D _BDRF_Map;


	ENDCG



	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

		
			#pragma multi_compile_fwdbase
			struct v2f
			{
				float4 pos: SV_POSITION;

				float2 uv : TEXCOORD0;

				half3 tspace0 : TEXCOORD1; // tangent.x, bitangent.x, normal.x
				half3 tspace1 : TEXCOORD2; // tangent.y, bitangent.y, normal.y
				half3 tspace2 : TEXCOORD3; // tangent.z, bitangent.z, normal.z

				half4 worldPos : TEXCOORD4;

				// SHADOW_COORDS(5)
				LIGHTING_COORDS(5, 6)
	
			};

			

			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos  = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);


				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);

				half3 wNormal = UnityObjectToWorldNormal(v.normal);
				half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
				// compute bitangent from cross product of normal and tangent
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(wNormal, wTangent) * tangentSign;

				// output the tangent space matrix
				// o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
				// o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
				// o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);

				o.tspace0 = wTangent;
				o.tspace1 = wBitangent;
				o.tspace2 = wNormal;

				TRANSFER_VERTEX_TO_FRAGMENT(o);
				// TRANSFER_SHADOW(o)
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// Sample base color
				#ifdef _FORCE_COLORSPACE_LINEAR_ON
				fixed4 baseColor = tex2DL(_MainTex, i.uv);
				#else
				fixed4 baseColor = tex2D(_MainTex, i.uv);
				#endif //_FORCE_COLORSPACE_LINEAR_ON

				baseColor *= _Color;



				// Calculate normal
				fixed3 tnormal = UnpackNormal(tex2D(_NormalMap, i.uv));
				half3 worldNormal;

				half3 tangent = i.tspace0.xyz;
				half3 binormal = i.tspace1.xyz;
				half3 normal = normalize(i.tspace2.xyz);

				// tangent = normalize (tangent - normal * dot(tangent, normal));
				// // recalculate Binormal
				// half3 newB = cross(normal, tangent);
				// binormal = newB * sign (dot (newB, binormal));

				worldNormal = normalize(tangent * tnormal.x + binormal * tnormal.y + normal * tnormal.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
				

				// worldNormal.x = dot(i.tspace0, tnormal);
				// worldNormal.y = dot(i.tspace1, tnormal);
				// worldNormal.z = dot(i.tspace2, tnormal);

				// Metalness
				half metal = tex2D(_MetalMap, i.uv).r * _Metal;

				// Roughness
				half rough = tex2D(_RoughMap, i.uv).r * _Rough;
				rough = clamp(rough, 0.01, 0.9);


				#ifdef _FORCE_COLORSPACE_LINEAR_ON
				half3 ao = tex2DL(_OcclusionMap, i.uv).rgb;
				#else
				half3 ao = tex2D(_OcclusionMap, i.uv).rgb;
				#endif //_FORCE_COLORSPACE_LINEAR_ON

				// fixed shadow = SHADOW_ATTENUATION(i);
				fixed shadow = LIGHT_ATTENUATION(i);

				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				half3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos.xyz));

				half3 reflDir = normalize(reflect(-viewDir, worldNormal));
				half3 halfDir = normalize(viewDir + lightDir);

				half HdotL = DotClamp01(lightDir, halfDir);
				half NdotV = DotClamp01(worldNormal, viewDir);
				half NdotL = DotClamp01(worldNormal, lightDir);


				//-----------------------BRDF Start----------------------------
				#ifdef _FORCE_COLORSPACE_LINEAR_ON
				half3 F0 = HALF3_ONE * 0.04;
				#else
				// half3 F0 = HALF3_ONE * 0.04;
				half3 F0 = unity_ColorSpaceDielectricSpec.xyz;
				#endif
				F0 = lerp(F0, baseColor, metal);
				F0 = clamp(F0, 0.02, 0.99);

				// Direct lighting
				half3 Lo = HALF3_ZERO;

				half3 radiance = _LightColor0.rgb * UNITY_PI;
				// half3 radiance = _LightColor0.rgb;

				#if defined(_NDF_DISTRIBUTIONGGX)
				float NDF = DistributionGGX(worldNormal, halfDir, rough);
				#elif defined(_NDF_BENCKMANN)
				float NDF = Benckmann(worldNormal, halfDir, rough.r);
				#else
				float NDF = Blinn_Phong(worldNormal, halfDir, rough.r);
				#endif

				#if defined(_GEOMETRY_IMPLICIT)
				float G = GeometryImplicit(NdotL, NdotV);
				#elif defined(_GEOMETRY_NEUMANN)
				float G = GeometryNeumann(NdotL, NdotV);
				#else
				float G = GeometrySmith(worldNormal, viewDir, lightDir, rough);
				#endif

				float3 F = FresnelSchlick(HdotL, F0);

				float3 nominator = NDF*G*F;
				float denominator = 4*NdotV*NdotL + 0.00001;

				float3 brdf = nominator/denominator;


				half3 kS = F;
				half3 kD = HALF3_ONE - kS;

				kD *= 1.0 - metal.r;
				Lo += (kD * baseColor * UNITY_INV_PI + brdf) * radiance * NdotL * shadow;
				// return fixed4(shadow, shadow, shadow, 1);


				// Indirect lighting
				half3 ambient = HALF3(1);
				{

				F = FresnelSchlickRoughness(NdotV, F0, rough);
				kS = F;
				kD = HALF3_ONE - kS;
				kD *= 1.0 - metal;

				half4 irrData = UNITY_SAMPLE_TEXCUBE(_IrradianceMap, worldNormal);

				#ifdef _FORCE_COLORSPACE_LINEAR_ON
				half3 irradiance = DecodeHDR_L(irrData, unity_SpecCube0_HDR);
				#else
				half3 irradiance = DecodeHDR(irrData, unity_SpecCube0_HDR);
				#endif //_FORCE_COLORSPACE_LINEAR_ON

				half3 diffuse = baseColor.rgb * irradiance;

				half4 prefilterData = UNITY_SAMPLE_TEXCUBE_LOD(_RadianceMap, reflDir, rough * 9);

				#ifdef _FORCE_COLORSPACE_LINEAR_ON
				half3 prefilterColor = DecodeHDR_L(prefilterData, unity_SpecCube0_HDR);
				#else
				half3 prefilterColor = DecodeHDR(prefilterData, unity_SpecCube0_HDR);
				#endif // _FORCE_COLORSPACE_LINEAR_ON

				#ifdef _FORCE_COLORSPACE_LINEAR_ON
				brdf.xy = tex2DL(_BDRF_Map, half2(NdotV, rough)).rg;
				#else
				brdf.xy = tex2D(_BDRF_Map, half2(NdotV, rough)).rg;
				#endif //_FORCE_COLORSPACE_LINEAR_ON


				half3 reflection = prefilterColor*(F*brdf.x + brdf.y);

				ambient = (kD * diffuse + reflection)*ao;

				}





				fixed4 fragColor = fixed4(Lo + ambient, 1);

				//-------------- For Shader Debug --------------
				#if _DEBUG_COLOR
				fragColor = baseColor;
				#endif //_DEBUG_COLOR

				#if _DEBUG_NORMAL
				fragColor = fixed4(worldNormal, 1);
				#endif //_DEBUG_NORMAL

				#ifdef _DEBUG_METAL
				fragColor = fixed4(HALF3(metal),1);
				#endif //_DEBUG_METAL

				#ifdef _DEBUG_ROUGH
				fragColor = fixed4(HALF3(rough),1);
				#endif //_DEBUG_ROUGH

				#ifdef _DEBUG_AO
				fragColor = fixed4(ao, 1);
				#endif //_DEBUG_AO

				#ifdef _DEBUG_DIRECT
				fragColor = fixed4(Lo, 1);
				#endif //_DEBUG_DIRECT

				#ifdef _DEBUG_INDIRECT
				fragColor = fixed4(ambient, 1);
				#endif //_DEBUG_INDIRECT


				// HDR tonemapping
				fragColor.rgb = fragColor.rgb / (fragColor.rgb + half3(1.0, 1.0, 1.0));

				#ifdef _FORCE_COLORSPACE_LINEAR_ON
				fragColor.rgb = LinearToGammaSpace(fragColor.rgb);
				#endif //_FORCE_COLORSPACE_LINEAR_ON

				return fragColor;
			}
			ENDCG
		}

		// pull in shadow caster from VertexLit built-in shader
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
