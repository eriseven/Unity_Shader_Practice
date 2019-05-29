// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/BH3"
{
	Properties
	{
		_Color("Color",Color) = (0.9314, 0.9314, 0.9314, 0.9500)
		_MainTex ("Texture", 2D) = "white" {}
		_LightMapTex("LightMap",2D) = "white"{}
		_FirstShadowMultColor("FirstShadowMultColor",Color) = (0.7294, 0.6000, 0.6510,1)
		_SecondShadowMultColor("SecondShadowMultColor",Color) = (0.6510, 0.4510, 0.5490,1)
		_LightArea("LightArea",Float) = 0.5
		_SecondShadow("Second Shadow",Float) = 0.51
		_Shininess("Shininess",Float) = 10
		_SpecMulti("SpecMulti",Range(0,1)) = 0.2
		_BloomFactor("BloomFactor",Float) = 1
		_EdgeColor("Edge Color",Color) = (1,1,1,1)
		_LineWidth("Line Width",Range(0,1)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			fixed4 _EdgeColor;
			fixed _LineWidth;
			
			v2f vert (appdata v)
			{
				v2f o;
				float4 pos = mul(UNITY_MATRIX_MV,v.vertex);
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);
				normal.z = -0.4;
				pos = pos + float4(normalize(normal),0) * _LineWidth * 0.008 * v.color.r;
				o.vertex = mul(UNITY_MATRIX_P,pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _EdgeColor;
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"

			#define inversesqrt(fv) 1/sqrt(fv)
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD1;
				float3 worldpos : TEXCOORD2;
				float ldotn : TEXCOORD3;
			};

			sampler2D _MainTex,_LightMapTex;
			float4 _Color,_MainTex_ST,_FirstShadowMultColor,_SecondShadowMultColor;
			float _LightArea,_SecondShadow,_Shininess,_SpecMulti,_BloomFactor;
			uniform float4 _LightColor0;

			float DotInversesqrt(float3 v)
			{
				return inversesqrt(dot(v,v));
			}

			float3 NormalizeVector(float3 v)
			{
				return DotInversesqrt(v) * v;
			}

			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				float3 worldNomal = mul((float3x3)unity_WorldToObject,v.normal);
//				o.normal = inversesqrt(dot(worldNomal,worldNomal)) * worldNomal;
				o.normal = NormalizeVector(worldNomal);
				float NdotL = -dot(_WorldSpaceLightPos0.xyz,o.normal);
				o.ldotn = NdotL * 0.5 + 0.5;
				float4 wp = mul(unity_ObjectToWorld,v.vertex);
				o.worldpos = wp.xyz/wp.w;
				return o;
			}


			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 mask = tex2D(_LightMapTex, i.uv);
				float colorR_Minus_MaskG = int(max(0,floor(1.5-(i.color.r * mask.g))));
				float colorR_Mul_MaskG = i.color.r * mask.g;
				float2 C_Mul_M = float2(colorR_Mul_MaskG,colorR_Mul_MaskG) * float2(1.2,1.25) + float2(-0.1,-0.125);
//				colorR_Mul_MaskG = (colorR_Minus_MaskG != 0) ? C_Mul_M.g : C_Mul_M.r;
				colorR_Mul_MaskG += i.ldotn;
				colorR_Mul_MaskG = (colorR_Mul_MaskG*0.5 + (-_LightArea)) + 1;
				colorR_Mul_MaskG =  floor(colorR_Mul_MaskG);
				colorR_Mul_MaskG = int(max(colorR_Mul_MaskG,0));

				fixed3 col = tex2D(_MainTex, i.uv).rgb;
				fixed3 col_Mul_FS = col * _FirstShadowMultColor.rgb;
				fixed3 shadow_col = (colorR_Mul_MaskG != 0) ? col : col_Mul_FS;
				fixed3 col_Mul_SS = col * _SecondShadowMultColor.rgb;

				float mask_idotn = i.color.r * mask.g + i.ldotn;
				mask_idotn = (mask_idotn * 0.5 - _SecondShadow) + 1;
				mask_idotn = max(0,floor(mask_idotn));
				int mask_idotn_int = int(mask_idotn);

				float3 col_shadow_combine = (mask_idotn_int != 0) ? col_Mul_FS : col_Mul_SS;

				float colorR_Mul_MaskG_91 = max(0,floor(i.color.r * mask.g + 0.91));
				float int_91_mask = int(colorR_Mul_MaskG_91);

				float3 col_combine_01 = (int_91_mask != 0) ? shadow_col : col_shadow_combine;

				float3 viewDir = _WorldSpaceCameraPos.xyz - i.worldpos;
				float3 halfDir = -_WorldSpaceLightPos0.xyz + DotInversesqrt(viewDir) * viewDir;

				float spec = saturate(dot(NormalizeVector(halfDir),NormalizeVector(i.normal)));
//				hdotn = exp2(log2(hdotn)*_Shininess);
				spec = pow(spec,_Shininess);
				spec = floor((-spec + (-mask.b + 1)) + 1);
				spec = max(spec,0);
				int spec_int = int(spec);
				float3 final = mask.r*_SpecMulti*_LightColor0.rgb;
				final = (spec_int != 0) ? float3(0,0,0) : final;
				final = (final + col_combine_01)*_Color.rgb;
				return fixed4(final,_BloomFactor);
//				return fixed4(colorR_Mul_MaskG_91,colorR_Mul_MaskG_91,colorR_Mul_MaskG_91,1);
//				return fixed4(shadow_col.rgb,1);
//				return fixed4(halfDir,1);
//				return fixed4(col_shadow_combine.rgb,1);
			}
			ENDCG
		}
	}
}
