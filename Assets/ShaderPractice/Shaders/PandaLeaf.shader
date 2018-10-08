Shader "EriSeven/PandaLeaf"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AlphaTex ("Alpha", 2D) = "white" {}
		_LightMap ("Light Map", 2D) = "white" {}

		c_FogColor("Fog Color", Color) = ( 0.02441406, 0.3297272, 0.5335846, 1 )
		// c_FogParam("Fog Param", Float)

		// c_vLightMapColorScale ("Light Map Color Scale", Color) = ( 4.54701, 4, 4.675663, 1 )
		c_fAlphaRefValue("Alpha Ref Value", Range(0, 1)) = 0.3921569
		c_MaterialAmbientEx("Material Ambient Ex", Color) = (0,0,0,1)
		c_fInvLumScale("Inv Lum Scale", Range(0, 1))= 0.25
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Cull off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 fog : TEXCOORD1; 
				// UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _AlphaTex;
			sampler2D _LightMap;
			float4 _LightMap_ST;
			
			// float3 c_vLightMapColorScale;
			float c_fAlphaRefValue;
			float4 c_MaterialAmbientEx;
			float c_fInvLumScale;

			float4 c_FogColor;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(UNITY_MATRIX_M, v.vertex);
				float4 viewToVertex;
				viewToVertex.xyz = worldPos - _WorldSpaceCameraPos;
				viewToVertex.w = sqrt(dot (viewToVertex.xyz, viewToVertex.xyz));

				float2 uv = float2(v.uv.x, 1 - v.uv.y);
				// o.uv.xy = TRANSFORM_TEX(uv, _MainTex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);


				float2 uv2 = float2(v.uv2.x, 1 - v.uv2.y);
				// o.uv.zw = TRANSFORM_TEX(uv2, _LightMap);
				o.uv.zw = TRANSFORM_TEX(v.uv2, _LightMap);

				float4 fogColor_1;
				float4 c_FogParam = float4( 50, 0.0025, 315, 0 );
				float4 c_FogExpParam = float4( 0.1495514, 0.1495514, 0.7385254, 0.0023 );

				float tmpvar_9;
				tmpvar_9 = (1.0/(exp((viewToVertex.w * c_FogExpParam.w))));
				fogColor_1.xyz = (c_FogExpParam.xyz * (1.0 - tmpvar_9));

				float tmpvar_10;
				tmpvar_10 = clamp (((viewToVertex.w - c_FogParam.x) * c_FogParam.y), 0.0, 1.0);
				fogColor_1.w = (tmpvar_9 * (1.0 - tmpvar_10));
				fogColor_1.xyz = ((fogColor_1.xyz * (1.0 - tmpvar_10)) + (c_FogColor.xyz * tmpvar_10));
				o.fog = fogColor_1;
				// UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv.xy);

				// fixed4 light_col = tex2D(_LightMap, i.uv.zw);
				fixed4 light_col = fixed4(DecodeLightmap(tex2D(_LightMap, i.uv.zw)), 1);
				// return light_col;
				float4 c_vLightMapColorScale = float4( 4.54701, 4, 4.675663, 1 );

				// light_col.xyz = light_col.xyz * light_col.xyz;
				light_col.xyz = light_col.xyz * c_vLightMapColorScale;
				light_col.w = (1.0 - light_col.w) * 0.5;

				col.xyz = col.xyz * col.xyz;
				col.w = tex2D(_AlphaTex, i.uv.xy).x;

				fixed4 diff_col = fixed4(light_col.xyz, 1) * col;
				// fixed4 diff_col = col;
				if (((diff_col.w - c_fAlphaRefValue) < 0.0)) {
					discard;
				};

				// return col;

				diff_col.xyz = ((diff_col.xyz * i.fog.w) + i.fog.xyz);
				diff_col.xyz = (diff_col.xyz + c_MaterialAmbientEx.xyz);
				diff_col.xyz = (diff_col.xyz * c_fInvLumScale);

				// apply fog
				// UNITY_APPLY_FOG(i.fogCoord, diff_col);
				return diff_col;
			}
			ENDCG
		}
	}
}
