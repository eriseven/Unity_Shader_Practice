// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/HLJ"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_EdgeColor("Edge Color",Color) = (1,1,1,1)
		_LineWidth("Line Width",Range(0,1)) = 1
		_Rim("Rim Value",Range(0,1)) = 1
		_RimColor("Rim Color",Color) = (1,1,1,1)
		_AmbColor("Amb Color",Color) = (1,1,1,1)
		_ShadowTex("Shadow Texture",2D) = "white" {}
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
//				o.vertex.z -= 0.01;
//				float3 n = normalize(v.normal);
//				o.vertex = UnityObjectToClipPos(v.vertex + (n * 0.008 * _LineWidth));
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
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 tmp : TEXCOORD1;
				float4 color : COLOR;
			};

			sampler2D _MainTex,_ShadowTex;
			float4 _MainTex_ST;
			half _Rim;
			float4 _RimColor,_AmbColor;

			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				float3 worldNormal = mul(unity_WorldToObject,v.normal);
				o.tmp.x = (1 - dot(normalize(worldNormal),_WorldSpaceLightPos0)) * 0.5;
				o.tmp.y = (1 - clamp(dot(worldNormal,normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld , v.vertex).xyz)),0,1));
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				float2 BUV = float2(i.tmp.x,0.5);
				float shadow = tex2D(_ShadowTex,BUV).r;


				col.rgb = ((i.tmp.y*_RimColor) * _Rim) + lerp((col.rgb * ((_AmbColor * (1-shadow)) + shadow).xyz),col.rgb,1-i.color.g);
//				col.rgb = float3(i.tmp.y,i.tmp.y,i.tmp.y);
				return col;
			}
			ENDCG
		}

	}
}
