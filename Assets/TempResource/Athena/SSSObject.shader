Shader "SSS/SSSObject"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NormalTex ("Normal Texture", 2D) = "white" {}
    }
 
    SubShader
    {
        Tags { "RenderType"="SSS" }
 
        pass
        {      
            Tags { "LightMode"="ForwardBase"}
 
            CGPROGRAM
 
            #pragma target 3.0
            #pragma fragmentoption ARB_precision_hint_fastest
 
            #pragma vertex vertShadow
            #pragma fragment fragShadow
            #pragma multi_compile_fwdbase
			#pragma multi_compile_fog
 
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
 
            sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _SSSLightTexture;
            float4 _LightColor0;
			SamplerState my_linear_clamp_sampler;
				
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
				UNITY_FOG_COORDS(1)
                LIGHTING_COORDS(4, 5)
				#if defined(SHADOWS_SCREEN) && defined(UNITY_NO_SCREENSPACE_SHADOWS)
					float4 shadowPos : TEXCOORD6;
					half photopermeabilityPow : TEXCOORD7;
				#endif
            };
 
            v2f vertShadow(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.screenPos = ComputeScreenPos(o.pos);

				#if defined(SHADOWS_SCREEN) && defined(UNITY_NO_SCREENSPACE_SHADOWS)
					float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
					o.shadowPos = mul(unity_WorldToShadow[0], worldPos);
					float3 viewLight = normalize(mul(UNITY_MATRIX_V,_WorldSpaceLightPos0.xyz));
					o.photopermeabilityPow = pow(saturate(-viewLight.z),5) * 0.1;
				#endif
				
				UNITY_TRANSFER_FOG(o,v.vertex);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
 
                return o;
            }
 
            half4 fragShadow(v2f i) : COLOR
            {                  
				half4 ambient = UNITY_LIGHTMODEL_AMBIENT;//环境光
                half attenuation = LIGHT_ATTENUATION(i);//投影

                half4 diffuse = tex2D(_MainTex, i.uv);
				half light = tex2Dproj(_SSSLightTexture,i.screenPos).b;
                
				#if defined(SHADOWS_SCREEN) && defined(UNITY_NO_SCREENSPACE_SHADOWS)
					half photopermeability = UNITY_SAMPLE_DEPTH(_ShadowMapTexture.Sample(my_linear_clamp_sampler, i.shadowPos.xy)) - i.shadowPos.z;
					ambient += saturate(exp(-photopermeability * 3000)) * i.photopermeabilityPow;
				#endif
                
				half4 finalColor = (ambient + light * attenuation * _LightColor0) * diffuse;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalColor);
				//finalColor.xyz = light;
				
				return finalColor;
            }
            ENDCG
        }

		Pass
		{
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f {
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert( appdata_base v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag( v2f i ) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
    }
}