Shader "SSS/SSSBlur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	
	CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		uniform half4 _MainTex_TexelSize;
		half4 _MainTex_ST;
		
		uniform half _Size;
	
		// weight curves
		static const half curve4[4] = {0.324, 0.232, 0.0855, 0.0205};

		struct v2f_withBlurCoords8 
		{
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
			half2 offs : TEXCOORD1;
		};	

		v2f_withBlurCoords8 vertBlurHorizontal (appdata_img v)
		{
			v2f_withBlurCoords8 o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);
			o.offs = _MainTex_TexelSize.xy * half2(1.0, 0.0) * _Size;

			return o; 
		}
		
		v2f_withBlurCoords8 vertBlurVertical (appdata_img v)
		{
			v2f_withBlurCoords8 o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = half4(v.texcoord.xy,1,1);
			o.offs = _MainTex_TexelSize.xy * half2(0.0, 1.0) * _Size;
			 
			return o; 
		}	

		half4 fragBlur8 ( v2f_withBlurCoords8 i ) : SV_Target
		{
			half2 uv = i.uv.xy; 
			half4 baseColor = tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(uv, _MainTex_ST));
			half light = baseColor.b * curve4[0];

			half4 frontColor = baseColor;
			half4 backColor = baseColor;
			half2 frontCord = uv;
			half2 backCord = uv;
  			for (int l = 1; l <= 3; l++ )
  			{
				frontCord += i.offs * frontColor.rg;
				frontColor = tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(frontCord, _MainTex_ST));
				backCord -= i.offs * backColor.rg;
				backColor = tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(backCord, _MainTex_ST));
				light += (frontColor.b + backColor.b) * curve4[l];
			}
			return half4(baseColor.rg,light,1);
		}
					
	ENDCG
	
	SubShader {
	ZTest Off Cull Off ZWrite Off Blend Off
	Stencil
	{
		Ref 1
		Comp Equal
		Pass Keep
		ReadMask 1
		WriteMask 1
	}
	Pass {
		CGPROGRAM 
		
		#pragma vertex vertBlurVertical
		#pragma fragment fragBlur8
		
		ENDCG 
		}
		
	Pass {
		CGPROGRAM
		
		#pragma vertex vertBlurHorizontal
		#pragma fragment fragBlur8
		
		ENDCG
		}	
	}	

	FallBack Off
}
