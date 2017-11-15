Shader "EriSeven/PBR/SimplePBR"
{
	Properties
	{
        _Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}

		_BumpMap ("Normal Map", 2D) = "bump" {}

		_MetalMap ("Metal Map", 2D) = "white" {}
		_Metal("Metal", Range(0, 10)) = 1

		_RoughMap ("Rough Map", 2D) = "white" {}
		_Rough ("Rough", Range(0, 10)) = 1

		_OcclusionMap ("Occlusion Map", 2D) = "white" {}


        _F0("Fresnel 0", Color) = (0.04,0.04,0.04,0.04)


		_IrradianceMap("Irrandiance Map", Cube) = "_Skybox" {}

		_RadianceMap("Randiance Map", Cube) = "_Skybox" {}

		_BDRF_Map("BDRF LUT Map", 2D) = "white" {}

        _DebugMode ("Debug Mode", Int) = 0
	}

	CGINCLUDE

	#include "EriSevenCG.cginc"
	#include "UnityCG.cginc"
	// #include "Lighting.cginc"
	#include "AutoLight.cginc"

	sampler2D _MainTex;
	float4 _MainTex_ST;

	sampler2D _BumpMap;

	sampler2D _MetalMap;
	half _Metal;

	sampler2D _RoughMap;
	half _Rough;

	sampler2D _OcclusionMap;


	UNITY_DECLARE_TEXCUBE(_IrradianceMap);
	// samplerCUBE _IrradianceMap;

	UNITY_DECLARE_TEXCUBE(_RadianceMap);
	// samplerCUBE _RadianceMap;

	sampler2D _BDRF_Map;

	fixed4 _Color;

	float4 _F0;

	int _DebugMode;
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
			// make fog work
			// #pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			

			struct v2f
			{
				half4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;

				half3 tspace0 : TEXCOORD1; // tangent.x, bitangent.x, normal.x
				half3 tspace1 : TEXCOORD2; // tangent.y, bitangent.y, normal.y
				half3 tspace2 : TEXCOORD3; // tangent.z, bitangent.z, normal.z

				half4 worldPos : TEXCOORD4;
				SHADOW_COORDS(5)

				// UNITY_FOG_COORDS(5)
			};

			
			v2f vert (appdata_full v)
			{
				v2f o;

				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);

				half3 wNormal = UnityObjectToWorldNormal(v.normal);
				half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
				// compute bitangent from cross product of normal and tangent
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
				// output the tangent space matrix
				o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
				o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
				o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				// UNITY_TRANSFER_FOG(o,o.vertex);
				TRANSFER_SHADOW(o)
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 color = tex2D(_MainTex, i.uv) * _Color;

				fixed3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));

				fixed3 metal = tex2D(_MetalMap, i.uv);
				// metal.r = 1 - metal.r;
				metal.r *= _Metal;

				fixed3 rough = tex2D(_RoughMap, i.uv);
				rough.r *= _Rough;

				fixed3 ao = tex2D(_OcclusionMap, i.uv);

				fixed shadow = SHADOW_ATTENUATION(i);

				half3 worldNormal;
				worldNormal.x = dot(i.tspace0, tnormal);
				worldNormal.y = dot(i.tspace1, tnormal);
				worldNormal.z = dot(i.tspace2, tnormal);


				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				half3 refl = normalize(reflect(-viewDir, worldNormal));

				half3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos.xyz));

				half3 halfDir = normalize(viewDir + lightDir);

				half HdotL = DotClamp01(halfDir, viewDir);
				half NdotV = DotClamp01(worldNormal, viewDir);
				half NdotL = DotClamp01(worldNormal, lightDir);

				//-----------------------BRDF Start----------------------------
				// half3 F0 = HALF3_ONE * 0.04;
				half3 F0 = _F0;
				F0 = F0 * (1 - metal.r) + color * metal.r;
				half3 Lo = HALF3_ZERO;

				half3 radiance = _LightColor0.rgb;

				float NDF = DistributionGGX(worldNormal, halfDir, rough.r);
				// float NDF = Blinn_Phong(worldNormal, halfDir, rough.r);
				// float NDF = Benckmann(worldNormal, halfDir, rough.r);



				// float G = GeometrySmith(worldNormal, viewDir, lightDir, rough.r);
				// float G = GeometryImplicit(NdotL, NdotV);
				float G = GeometryNeumann(NdotL, NdotV);

				float3 F = FresnelSchlick(HdotL, F0);

				float3 nominator = NDF*G*F;
				float denominator = 4*NdotV*NdotL + 0.00001;

				float3 brdf = nominator/denominator;

				half3 kS = F;
				half3 kD = HALF3_ONE - kS;
				kD *= 1.0 - metal.r;
				kD *= shadow;

				Lo += (kD*color/UNITY_PI + brdf)*radiance*NdotL;
				//------------------------BRDF End-----------------------------

				F = FresnelSchlickRoughness(NdotV, F0, rough.r);
				kS = F;
				kD = HALF3_ONE - kS;
				kD *= 1.0 - metal.r;


				half4 irrData = UNITY_SAMPLE_TEXCUBE(_IrradianceMap, worldNormal);
				half3 irradiance = DecodeHDR(irrData, unity_SpecCube0_HDR);
				half3 diffuse = color.rgb * irradiance;



				half4 prefilterData = UNITY_SAMPLE_TEXCUBE_LOD(_RadianceMap, refl, rough.r * 8);
				half3 prefilterColor = DecodeHDR(prefilterData, unity_SpecCube0_HDR);
				// skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR) * UNITY_INV_PI;
				brdf.xy = tex2D(_BDRF_Map, half2(NdotV, rough.r)).rg;
				half3 reflection = prefilterColor*(F*brdf.x + brdf.y);

				half3 ambient = (kD * diffuse + reflection)*ao;


				fixed4 fragColor = fixed4(1,1,1,1);

				// fragColor

				if (_DebugMode == 0)
					fragColor.rgb = Lo + ambient;
				else if (_DebugMode == 1)
					fragColor.rgb = worldNormal.rgb;
				else if(_DebugMode == 2)
					fragColor.rgb = metal.rgb;
				else if(_DebugMode == 3)
					fragColor.rgb = rough.rgb;
				else if(_DebugMode == 4)
					fragColor.rgb = ao.rgb;
				else if(_DebugMode == 5)
					fragColor.rgb = brdf;
				else if(_DebugMode == 6)
					fragColor.rgb = kD;
				else if(_DebugMode == 7)
					fragColor.rgb = half3(NDF, 0, 0);

				// Apply HDR tonemapping
				// fragColor = fragColor/(fragColor + half4(1,1,1,1));

				// Apply gamma correction
				// fragColor = pow(fragColor, half4(1,1,1,1) * (1.0/2.2));
				fragColor.a = 1;



				// apply fog
				// UNITY_APPLY_FOG(i.fogCoord, fragColor);
				return fragColor;
			}
			ENDCG
		}
		// pull in shadow caster from VertexLit built-in shader
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
