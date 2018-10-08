// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// https://forum.unity.com/threads/guilty-gear-xrd-shader-test.448557/

Shader "EriSeven/Cartoon/GearXStage" {
	Properties {
		//_Color("Color", Color) = (1,1,1,1)
		// http://wiki.unity3d.com/index.php?title=Outlined_Diffuse_3

		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_SSSTex("SSS (RGB)", 2D) = "white" {}
		_ILMTex("ILM (RGB)", 2D) = "white" {}

		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_Outline("Outline width", Range(.0, 2)) = 0.005
		_ShadowContrast("Vertex Shadow contrast", Range(0, 20)) = 1
		_DarkenInnerLineColor("Darken Inner Line Color", Range(0, 1)) = 0.2

		_LightDirection("Light Direction", Vector) = (0,0,1)
	}

CGINCLUDE
    #include "UnityCG.cginc"

    sampler2D _MainTex;
    sampler2D _SSSTex;

    struct appdata {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float4 texCoord : TEXCOORD0;
        float4 vertexColor : COLOR;
    };

    uniform float _Outline;
    uniform float4 _OutlineColor;
    uniform float _ShadowContrast;
    uniform float _DarkenInnerLineColor;
    uniform half3 _LightDirection;

ENDCG


    SubShader {

        Pass {
            Name "OUTLINE"
            Cull Front
            ZWrite On


            CGPROGRAM

            struct v2f {
                float4 pos : POSITION;
                float4 color : COLOR;
                float4 tex : TEXCOORD0;
            };

            v2f vert(appdata v) {
                // just make a copy of incoming vertex data but scaled according to normal direction
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                float2 offset = TransformViewToProjection(norm.xy);
                o.pos.xy += offset * _Outline;
                o.tex = v.texCoord;
                
                o.color = _OutlineColor;
                return o;
            }

            half4 frag(v2f i) : COLOR { 
                //fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
                fixed4 cLight = tex2D(_MainTex, i.tex.xy);
                fixed4 cSSS = tex2D(_SSSTex, i.tex.xy);
                fixed4 cDark = cLight * cSSS;

                cDark = cDark *0.5f;// *cDark * cDark;
                cDark.a = 1; // weapon had alpha?

                return cDark;
            }

			#pragma vertex vert
			#pragma fragment frag

            ENDCG
        }

        Pass {
            Name "CEL_SHADING"
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            sampler2D _ILMTex;

            struct v2f {
                float4 pos : POSITION;
                float4 color : COLOR;
                float4 tex : TEXCOORD0;
                float3 norm : NORMAL;
            };

            v2f vert(appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // o.norm = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
                o.norm = UnityObjectToWorldNormal(v.normal);
                o.color = v.vertexColor;
                o.tex = v.texCoord;
                return o;
            }

            half4 frag(v2f i) : COLOR { 

                fixed4 c = tex2D(_MainTex, i.tex.xy);
                fixed4 cSSS = tex2D(_SSSTex, i.tex.xy);
                fixed4 cILM = tex2D(_ILMTex, i.tex.xy);

                fixed3 BrightColor = c.rgb;
                fixed3 ShadowColor = c.rgb * cSSS.rgb;

                fixed clampedLineColor = cILM.a;
                if (clampedLineColor < _DarkenInnerLineColor)
                    clampedLineColor = _DarkenInnerLineColor; 

                half3 InnerLineColor = half3(clampedLineColor, clampedLineColor, clampedLineColor);

                float vertColor = i.color.r;// (IN.vertexColor.r - 0.5) * _ShadowContrast + 0.5; //IN.vertexColor.r;
                // easier to combine black dark areas 
                float ShadowThreshold = cILM.g;
                ShadowThreshold *= vertColor;
                ShadowThreshold = 1 - ShadowThreshold; // flip black / white

                float SpecularIntensity = cILM.r;// 1 + (1 - cILM.r);// +cILM.r;// *2; // make whiter
                float SpecularSize =  1-cILM.b;// *0.25f);

                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                half NdotL = dot(lightDir, i.norm);

                half testDot = (NdotL + 1) / 2.0; // color 0 to 1. black = shadow, white = light

                // c = fixed4(testDot, 1, 1, 1);
                // c = fixed4(i.norm, 1);
                // c = fixed4(ShadowThreshold, 1, 1, 1);

                half4 specColor = half4(SpecularIntensity, SpecularIntensity, SpecularIntensity, 1);
                half blendArea = 0.04;


                NdotL -= ShadowThreshold;

                half specStrength = SpecularIntensity;// = 0.1f + s.SpecularIntensity;// > 1 = brighter, < 1 = darker
                if (NdotL < 0) // <= s.ShadowThreshold)
                {
                    if ( NdotL < - SpecularSize -0.5f && specStrength <= 0.5f) // -0.5f)
                    {
                        c.rgb = ShadowColor *(0.5f + specStrength);// (specStrength + 0.5f);// 0.5f; //  *s.ShadowColor;
                    }
                    else
                    {
                        c.rgb = ShadowColor;
                    }
                }
                else
                {
                    if (SpecularSize < 1 && NdotL * 1.8f > SpecularSize && specStrength >= 0.5f) //  0.5f) // 1.0f)
                    {
                        c.rgb = BrightColor * (0.5f + specStrength);// 1.5f;//  *(specStrength * 2);// 2; // lighter
                    }
                    else
                    {
                        c.rgb = BrightColor;
                    }

                }


                c.rgb = c.rgb * InnerLineColor;

                return c;
            }

			#pragma vertex vert
			#pragma fragment frag

            ENDCG
        }
    }


	FallBack "Diffuse"
}
