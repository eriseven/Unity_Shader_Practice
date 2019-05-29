Shader "Unlit/frxy"
{
	Properties
	{
		_MainTex ("Diffuse Texture", 2D) = "white" {}
		_DarkTex ("Dark Texture", 2D) = "white" {}
		_MaskTex ("Mask Texture", 2D) = "white" {}
		_RampTex ("Ramp Texture", 2D) = "white" {}

		[KeywordEnum(Off, On)] _USE_NORMAL_MAP("USE NORMAL MAP", Float) = 0
		_NormalTex ("Normal Texture", 2D) = "bump" {}

		[KeywordEnum(Off, On)] _USE_MATCAP_MAP("USE MATCAP MAP", Float) = 0
		_MatTex("Aniso Texture",2D) = "white" {}

		_OutlineWidth("Outline Width",Float) = 0
		_OutlineColor("Outline Color",Color) = (0,0,0,0)
//		_aniso_uv_tilling("aniso_uv_tilling",Float) = 1
//		_anisoControl("aniso Control",Vector) = (1,1,1,1)
		_sidelight_color("Sidelight Color",Color) = (1,1,1,1)
		_sidelight_offset("Sidelight Offset",Float) = 0
		_uplight_color("Up Color",Color) = (1,1,1,1)
		[KeywordEnum(Off, On)] _USE_VIEW_LIGHT("USE VIEW LIGHT", Float) = 0
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
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			float _OutlineWidth;
			fixed4 _OutlineColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				float4 wpos = mul(unity_ObjectToWorld, v.vertex); 
				float camDis = length(_WorldSpaceCameraPos.xyz - wpos.xyz);
				camDis *= 0.01;
				float disIndex = 1 + min(5.0,camDis);
				float4 pos_offest = float4(normalize(v.normal.xyz) * _OutlineWidth*0.001 * disIndex,0.0);
				float4 pos = float4(( v.vertex + pos_offest).xyz,1.0);
				o.vertex = UnityObjectToClipPos(pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(_OutlineColor.rgb,1);
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ _USE_NORMAL_MAP_ON
			#pragma multi_compile __ _USE_VIEW_LIGHT_ON
			#pragma multi_compile __ _USE_MATCAP_MAP_ON
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD1;
				float3 worldTangent : TEXCOORD2;
				float3 worldBinormal : TEXCOORD3;
				float3 view : TEXCOORD4;
				float4 p_color : TEXCOORD5;
				float3 pos_local : TEXCOORD6;
				float3 camera_dir : TEXCOORD7;
			};

			sampler2D _MainTex,_DarkTex,_MaskTex,_NormalTex,_RampTex,_MatTex;
			float4 _MainTex_ST,_sidelight_color,_uplight_color;//_anisoControl
			float _sidelight_offset;
			uniform float4 _LightColor0;
			
			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				float4 wpos = mul(unity_ObjectToWorld, v.vertex); 
				o.worldNormal = UnityObjectToWorldDir(v.normal);

			#if _USE_NORMAL_MAP_ON
				o.worldTangent = UnityObjectToWorldDir(v.tangent);
				o.worldBinormal = normalize(cross(o.worldNormal,o.worldTangent));
				if(length(v.tangent) > 1.0)
					o.worldBinormal = o.worldBinormal * -1.0;
			#endif

				o.view = normalize(UnityWorldSpaceViewDir(wpos));
				o.p_color = v.color;
				o.pos_local = v.vertex.xyz;
				float4 model_center = mul(unity_ObjectToWorld,float4(0,0,0,1));
				o.camera_dir = UnityWorldSpaceViewDir(model_center);

				return o;
			}

			//Anisotropic GGX
			// [Burley 2012, "Physically-Based Shading at Disney"]
			inline float3 D_GGXaniso(float RoughnessX, float RoughnessY, float NoH, float3 H, float3 X, float3 Y )
			{
				float mx = RoughnessX * RoughnessX;
				float my = RoughnessY * RoughnessY;
				float XoH = dot( X, H );
				float YoH = dot( Y, H );
				float d = XoH*XoH / (mx*mx) + YoH*YoH / (my*my) + NoH*NoH;
				float ggx = 1.0 / ( 3.1415926 * mx*my * d*d ); 
				return float3(ggx.rrr);
			}

			float4 frag (v2f i) : SV_Target
			{
				float4 finalColor = float4(0,0,0,1);
				float3 diffuse = tex2D(_MainTex, i.uv).rgb;
				float3 shadow = tex2D(_DarkTex, i.uv).rgb;
				float3 mask = tex2D(_MaskTex, i.uv).rgb;
				float mentalness = mask.b;

			#if _USE_VIEW_LIGHT_ON
				float3 light_dir =  normalize(i.view);
			#else
				//lighting color
				float3 light_dir =  normalize(_WorldSpaceLightPos0.xyz);
			#endif

				float3 normal_dir = normalize(i.worldNormal);
			#if _USE_NORMAL_MAP_ON
//				normal_dir = UnpackNormal(tex2D(_NormalTex, i.uv));
				normal_dir = tex2D(_NormalTex, i.uv).rgb;
				normal_dir.xy = normal_dir.xy * 2.0 - 1.0;
				normal_dir = normal_dir.x * i.worldTangent + normal_dir.y * i.worldBinormal + normal_dir.z * i.worldNormal;
				normal_dir = normalize(normal_dir);
			#endif

				float shadowFactor = 1.0;
				float ndotl = clamp(dot(normal_dir,light_dir),0,1);
				ndotl *= shadowFactor;
				float ndl_ramp = ndotl * 0.9 + 0.1;
				ndl_ramp *= mask.r;
				float ramp = tex2D(_RampTex, float2(ndl_ramp, 0.5)).r;
				float3 lightColor = _LightColor0.rgb;
				float3 lighting = lerp(shadow,diffuse*lightColor,ramp);
				float3 diffuse_lighting = lighting * (1.0 - mentalness);

				float glossness = mask.g;
				float3 specular = float3(0,0,0);

//			#if NEOX_ANIS_SPECULAR
//				float3 t = i.worldTangent;
//				float3 b = i.worldBinormal;
//				// ShaderX: Per-Pixel Strand Based Anisotropic Lighting
//				float3 aniso_map = tex2D(_AnisoTex,i.uv *_aniso_uv_tilling).rgb;
//				float aniso_disturbe = tex2D(_AnisoTex,i.uv).z;
//				normal_dir.xy += (aniso_map.xy  * 0.5 - 0.5) * _anisoControl.z;
//				t = normalize(t - dot(t, normal_dir) * normal_dir); // Graham-Schmidt Orthonormalization
//				b = normalize(cross(t, normal_dir));
//				float3 half_dir = normalize(light_dir + i.view);
//				float ndoth = clamp(dot(normal_dir,half_dir), 0.0, 1.0);
//				float roughness = 1.0 - glossness;
//				float3 aniso_ctrl = float3(_anisoControl.x * roughness, _anisoControl.y * roughness, _anisoControl.z);
//				specular = D_GGXaniso(aniso_ctrl.x, aniso_ctrl.y, ndoth, half_dir, t, b) * _anisoControl.w ;
//				specular = min(specular,1);
//				specular *= _anisoColor.xyz;
//				specular *= float3(aniso_disturbe.rrr);
//				specular *= ramp;
			//#else
			#if _USE_MATCAP_MAP_ON
				specular = float3(mentalness.rrr);
				float3 matcap_dir = normalize(mul((float3x3)UNITY_MATRIX_VP , normal_dir));
				matcap_dir.xy = float2(matcap_dir.x, -matcap_dir.y) * 0.5 + 0.5;
				float3 matcap = tex2D(_MatTex, matcap_dir.xy).rgb;
				matcap *= matcap; 
				matcap *= 4.0 * mask.g;

			#else
				float3 matcap = float3(0,0,0);
			#endif
			//#endif

				//side normal
				float offset_radians = radians(_sidelight_offset);
				float side_x = i.camera_dir.x * cos(offset_radians) - i.camera_dir.z * sin(offset_radians);
				float side_z = i.camera_dir.z * cos(offset_radians) + i.camera_dir.x * sin(offset_radians);
				float3 real_side_dir = float3(side_x, 0.0, side_z);
				float3 side_light_dir = normalize(real_side_dir);
				float ndsl = clamp(dot(side_light_dir, normal_dir), 0.0, 1.0)+ 0.01;
				float side_ramp = tex2D(_RampTex, float2(ndsl, 0.0)).g;
				float3 side_light_color = _sidelight_color.rgb;

			#if _USE_VIEW_LIGHT_ON
				float3 up_color = float3(1,1,1);
			#else
				//up_color
				float up_ramp_v = min(1.0, max(0.0, i.pos_local.y) * 0.4);
				float up_ramp = tex2D(_RampTex, float2(0.5, 1.0 - up_ramp_v)).b;
				float3 up_color = lerp(_uplight_color.rgb, float3(1,1,1), up_ramp);
			#endif

//			#if NEOX_ANIS_SPECULAR
//				finalColor.rgb = (diffuse_lighting + specular) * up_color;
//			#else
			#if _USE_MATCAP_MAP_ON
				finalColor.rgb = (diffuse_lighting + matcap * diffuse) * up_color;
			#else
				finalColor.rgb = diffuse_lighting * up_color;
			#endif
//			#endif
				finalColor.rgb += side_ramp  * side_light_color * diffuse_lighting;


				return float4(finalColor.rgb,1);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
