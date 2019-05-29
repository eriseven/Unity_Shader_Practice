Shader "Unlit/qrzd"
{
	Properties
	{
		_MainTex ("Diffuse", 2D) = "white" {}
		_NormalTex("Normal", 2D) = "bump" {}
		_Mask1Tex ("Mask 1", 2D) = "white" {}
		_Mask2Tex ("Mask 2", 2D) = "white" {}
		_MatCap1Tex ("MatCap 1", 2D) = "white" {}
		_MatCap2Tex ("MatCap 2", 2D) = "white" {}
		_AmbientColor("Ambient Color",Color) = (1,1,1,1)
		_UpColor("Up Color",Color) = (1,1,1,1)
		_DownColor("Down Color",Color) = (1,1,1,1)
		_shadow_pos("shadow pos",Vector) = (0,0.5,0,1)
		_shadownol1("shadownol 1",Float) = 0.09
		_shadownol2("shadownol 2",Float) = 0.16
		_DarkShadow("Dark Shadow",Color) = (1,1,1,1)
		_BrightShadow("Bright Shadow",Color) = (1,1,1,1)
		_fo_rim_color("fo rim color",Color) = (1,1,1,1)
		_ReflectionIntensity("Reflection Intensity",Range(0,2)) = 1
		_ReflectionIntensityHair("Reflection Intensity Hair",Range(0,2)) = 1
		_EmmsiveColor("Emmsive Color",Color) = (1,1,1,1)
		_EmmsiveIntensity("Emmsive Intensity",Range(0,5)) = 1
		_ChangeColor("Change Color",Color) = (1,1,1,1)
		_FresnelIntensity("Fresnel Intensity",Range(0,32)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float4 posLocal : TEXCOORD2;
				float3 tangent : TEXCOORD3;
				float3 binormal : TEXCOORD4;
				float3 normal : TEXCOORD5;
				SHADOW_COORDS(6)
			};

			sampler2D _MainTex,_NormalTex,_Mask1Tex,_Mask2Tex,_MatCap1Tex,_MatCap2Tex;
			float4 _MainTex_ST;
			float4 _AmbientColor,_UpColor,_DownColor,_shadow_pos,_DarkShadow,_BrightShadow,_fo_rim_color,_EmmsiveColor,_ChangeColor;
			uniform float4 _LightColor0;
			float _shadownol1,_shadownol2,_ReflectionIntensity,_ReflectionIntensityHair,_EmmsiveIntensity,_FresnelIntensity;
			
			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.posLocal = v.vertex;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normal = UnityObjectToWorldDir(v.normal);
				o.tangent = UnityObjectToWorldDir(v.tangent);
				o.binormal = normalize(cross(o.normal,o.tangent));
				if(length(v.tangent) > 1.5)
				{
					o.binormal *= -1.0;
				}

				TRANSFER_SHADOW(o)

				return o;
			}

			inline float4 _rgb2hsvl(in float3 _rgb)
			{
				float4 _K = {0.0, -0.33329999, 0.66659999, -1.0};
				float4 _p = lerp(float4(_rgb.zy, _K.wz), float4(_rgb.yz, _K.xy), step(_rgb.z, _rgb.y));
				float4 _q = lerp(float4(_p.xyw, _rgb.x), float4(_rgb.x, _p.yzx), step(_p.x, _rgb.x));
				float _c = min(_q.w, _q.y);
				float _d = (_q.x - _c);
				return float4(abs((_q.z + ((_q.w - _q.y) / ((6.0 * _d) + 1e-06)))), (_d / (_q.x + 1e-06)), _q.x, ((_q.x + _c) / 2.0));
			}

			float4 frag (v2f i) : SV_Target
			{
//				fixed4 col = tex2D(_MainTex, i.uv);
				

				float4 rawNormal = tex2D(_NormalTex, i.uv);
				float2 localNormal = ((rawNormal.xy * 2.0) - 1.0);
				float3 normalWorld = normalize((i.normal + (localNormal.x * i.tangent)) + (localNormal.y * i.binormal));
				float3 eyeDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
				float3 posWorld = i.posWorld;
				float4 diffColor = tex2D(_MainTex, i.uv);

				float3 masks = tex2D(_Mask1Tex,i.uv).rgb;
				float  diffuseAlpha =  masks.r;
				float  matcap_mask01 = masks.b;
				float  matcap_mask02 = masks.g;

				float4 mask_color = tex2D(_Mask2Tex, i.uv);

				float4 hsv = _rgb2hsvl(diffColor.xyz);

				float3 dir_light =  normalize(-_WorldSpaceLightPos0.xyz);
				float3 sha_color = float3(0.6706, 0.45879999, 0.42750001);


				float shadow_factor = SHADOW_ATTENUATION(i);
				shadow_factor = pow(shadow_factor,0.5);
				float3 dirLightResult = (_LightColor0.rgb * lerp(sha_color, float3(1.0, 1.0, 1.0), shadow_factor));
				float3 indirect_diffuse = _AmbientColor.xyz;
				float _CharacterHeight = 2;
				float3 finalAO = lerp(_DownColor.xyz, _UpColor.xyz, (i.posLocal.y / _CharacterHeight));
				indirect_diffuse *= finalAO;
				float3 diffuse_fac = dirLightResult + indirect_diffuse;
				float3 diffuse = ((diffColor * 0.5) * 1.2783999) * diffuse_fac;

				float NdotView = clamp(dot(normalWorld,eyeDir), 0.0, 1.0);
				float3 dir_light1 = float3(-1.0, 0.23, 0.25999999);
				float3 dir_shadow1 = normalize(_shadow_pos.xyz);

				float3 dir_rimlight = mul(transpose((float3x3)UNITY_MATRIX_IT_MV), dir_light1);
				float3 dir_shadow = mul(transpose((float3x3)UNITY_MATRIX_IT_MV), dir_shadow1);
				float NdotshadowFactor = clamp(dot(dir_shadow, normalWorld), 0.0, 1.0);
				float RimlightDotValue = clamp(dot(dir_rimlight, normalWorld), 0.0, 1.0);
				float Ndotshadow = smoothstep(_shadownol1, _shadownol2, (NdotshadowFactor * NdotView));
				float dif_illum = dot(diffuse, float3(0.29899999, 0.58700001, 0.114));
				float shadowshift = smoothstep(0.25, 0.74000001, dif_illum);
				float3 shadowColor = lerp(_DarkShadow.xyz, _BrightShadow.xyz, shadowshift);
				float3 falloff_c = lerp((shadowColor * diffuse.xyz), diffuse.xyz, Ndotshadow);

				float rimdot = clamp((RimlightDotValue * (1.0 - NdotView)), 0.0, 1.0);
				float rimffcal = smoothstep(0.34999999, 0.57999998, rimdot);
				float3 lightColor = rimffcal * diffuse.xyz * _fo_rim_color.xyz;

				//mat cap
				float3 normalView = normalize(mul((float3x3)UNITY_MATRIX_V, normalWorld));
				float2 matcapUV = ((normalView.xy * 0.5) + 0.5);
				float3 matcap_map_color = tex2D(_MatCap1Tex, matcapUV).xyz;
				matcap_map_color = ((matcap_map_color * _ReflectionIntensity) * matcap_mask01);
				float3 matcap_lit = matcap_map_color;
				matcap_lit += tex2D(_MatCap2Tex, matcapUV).xyz * matcap_mask02 * _ReflectionIntensityHair;
				falloff_c += matcap_lit;

				float emissive_mask = rawNormal.z;
				//_EmmsiveColor
				falloff_c = lerp(falloff_c, diffuse, emissive_mask);
				float3 emissive = float3(0,0,0) + (_EmmsiveColor.xyz * _EmmsiveIntensity * emissive_mask);

				float3 finalColor = emissive + lightColor + falloff_c;

				//GetFresnel
				float view_fac = dot(eyeDir, normalWorld);
				view_fac = 1.0 - abs(view_fac);
				view_fac = pow(view_fac, _FresnelIntensity);
				finalColor += _ChangeColor * view_fac;

				diffColor.rgb = finalColor.rgb;
				return diffColor;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
