Shader "EriSeven/Cartoon/QRZDFace"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_Masks7 ("Mask", 2D) = "white" {}
		_OutlineWidth("Outline Width", Range(0.001, 5.0)) = 0.1
		_OutlineColor("Outline Color", Color) = ( 0.196, 0.118, 0.078, 1 )
		_Outlinefix("Outline Fix", Range(0, 1)) = 0.33
		AlphaMtl("AlphaMtl", Range(0, 1)) = 1

		_ShadowColor("Shadow Color", Color) = ( 0, 0, 0, 0 )
		_AmbientColor("Ambient Color", Color) = ( 1, 1, 1, 1 )

		shadow_pos_x("Shadow Pos X", Float) = -0.01
		shadow_pos_y("Shadow Pos Y", Float) = 0.06
		shadow_pos_z("Shadow Pos Z", Float) = -1.0
		
		shadownol1("shadownol1", Float) = 0
		shadownol2("shadownol2", Float) = 0.09

		_BrightShadow("Bright Shadow", Color) = ( 0.9137, 0.8588, 0.8157, 0 )
		_DarkShadow("Dark Shadow", Color) = ( 0.7333, 0.6078, 0.898, 0 )

		fo_rim_color("Rim Color", Color) = ( 0.4157, 0.4157, 0.4157, 1 )

		ChangeColor("ChangeColor", Color) = ( 0, 0, 0, 0 )
		fresnel_intensity("Fresnel Intensity", Range(0, 1)) = 1

		ColorFactor("Color Factor", Range(0, 1)) = 0
	}

	CGINCLUDE
	#include "UnityCG.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;

		sampler2D _Masks7;
		sampler2D _BumpMap;

		half _OutlineWidth;
		fixed4 _OutlineColor;
		half _Outlinefix;
		half AlphaMtl;

		fixed4 _ShadowColor;
		fixed4 _AmbientColor;

		float shadow_pos_x;
		float shadow_pos_y;
		float shadow_pos_z;

		float shadownol1;
		float shadownol2;

		float4 _BrightShadow;
		float4 _DarkShadow;

		float4 fo_rim_color;
		float4 ChangeColor;

		float fresnel_intensity;

		float ColorFactor;
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Name "Outline"
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half2 uv : TEXCOORD0;
				half3 diffuse : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				half3 color : COLOR;
			};


			v2f vert (appdata v)
			{
				half view_z = _OutlineWidth;
				view_z = view_z * v.diffuse.r;

				half3 nor = normalize(v.normal);
				half4 pos = v.vertex + half4(nor.xyz * view_z, 0.0);

				v2f o;
				o.vertex = UnityObjectToClipPos(pos);
				o.vertex.z += 0.00001;


				float2 uv = float2(v.uv.x, 1 - v.uv.y);
				o.uv = TRANSFORM_TEX(uv, _MainTex);
				o.color = v.diffuse;
				UNITY_TRANSFER_FOG(o,o.vertex);


				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 diffuse = tex2D(_MainTex, i.uv);
				fixed4 masks = tex2D(_Masks7, i.uv);

				float _hero_switch = 0.0;

				diffuse.a = masks.r;
				_hero_switch = 0.0;


				fixed4 c = diffuse;
				fixed maxChan = max(c.g, c.b);
				fixed3 newMapColor = 
					lerp(float3( maxChan, maxChan, maxChan ), float3(0.0,0.6,1.0), float3(1, 1, 1) * _Outlinefix * 0.5);

				fixed3 outline_color = c.rgb - max(newMapColor - half3(_Outlinefix, _Outlinefix, _Outlinefix), 0.1);
				fixed4 result = fixed4(0, 0, 0, 0);

				result.xyz =  lerp(outline_color.rgb, _OutlineColor.xyz, _hero_switch);
				result.a = diffuse.a*AlphaMtl;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, result);
				return result;
			}
			ENDCG
		}

		Pass
		{
            Tags { "LightMode"="ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
				half2 uv : TEXCOORD0;
				// half3 diffuse : COLOR;

			};

			struct v2f
			{
				float4 pos : SV_POSITION;

				float2 uv : TEXCOORD0;
				half3 tspace0 : TEXCOORD1; // tangent.x, bitangent.x, normal.x
				half3 tspace1 : TEXCOORD2; // tangent.y, bitangent.y, normal.y
				half3 tspace2 : TEXCOORD3; // tangent.z, bitangent.z, normal.z

				half4 worldPos : TEXCOORD4;

				// half3 color : COLOR;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);

				half3 wNormal = UnityObjectToWorldNormal(normalize(v.normal));
				half3 wTangent = UnityObjectToWorldDir(normalize(v.tangent.xyz));

				// compute bitangent from cross product of normal and tangent
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(wNormal, wTangent) * tangentSign;

				// output the tangent space matrix
				o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
				o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
				o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);


				float2 uv = float2(v.uv.x, 1 - v.uv.y);
				o.uv = TRANSFORM_TEX(uv, _MainTex);

				return o;
			}

			struct FragmentCommonData
			{
				float4 diffColor;
				float4 specColor;
				float3 normalWorld;
				float3 eyeDir;
				float3 posWorld;
				float3 lightDir;
			};

			FragmentCommonData SetupFragCommomData(v2f i)
			{
				FragmentCommonData result;

				fixed3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				half3 worldNormal;
				worldNormal.x = dot(i.tspace0, tnormal);
				worldNormal.y = dot(i.tspace1, tnormal);
				worldNormal.z = dot(i.tspace2, tnormal);

				result.normalWorld = normalize(worldNormal);
				result.eyeDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				result.lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos.xyz));
				result.posWorld = i.worldPos;


				result.diffColor = tex2D(_MainTex, i.uv);
				return result;
			}

			float GetFresnel( FragmentCommonData frag_data, float factor )
			{
				float3 view_dir = frag_data.eyeDir;//normalize(CameraPos.xyz - oPosWorld.xyz);    //浠庣偣鍒伴暅澶寸殑鍏夌嚎  
				float3 norm_world = frag_data.normalWorld;//normalize(oNormal.xyz);
				float view_fac = dot( view_dir, norm_world); //[-1,1]
				view_fac = 1.0 - abs(view_fac);
				view_fac = pow(view_fac, factor);
				return view_fac;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				FragmentCommonData cdata = SetupFragCommomData(i);

				float3 masks = tex2D(_Masks7, i.uv).rgb;
				float diffuseAlpha =  1.0;
				float matcap_mask01 = 0.0;
				float matcap_mask02 = 0.0;
				matcap_mask01 = masks.b; //

				float _hero_switch = 0.0;
				diffuseAlpha = masks.r;
				matcap_mask02 = masks.g;

				float3 dark_color =   _ShadowColor.xyz;
				float shadow_factor = 1.0;

				float3 dir_light =  cdata.lightDir;
				float3 sha_color = float3(0.6706, 0.4588, 0.4275); //(171.0/255.0, 117.0/255.0, 109.0/255.0);
				float3 dirLightResult = 
					_LightColor0.rgb * lerp(sha_color, float3(1.0, 1.0, 1.0), shadow_factor);

				// return fixed4(dirLightResult.rgb, 1);

				float3 indirect_diffuse = _AmbientColor.xyz;

				float3 diffuse_fac = dirLightResult + indirect_diffuse;

				// return fixed4(diffuse_fac.rgb, 1);

				float3 diffuse =  cdata.diffColor.xyz * 0.5 * 1.2784 * diffuse_fac;
				// return fixed4(diffuse.rgb, 1);

				float3 falloff_c = diffuse;
				float NdotView = clamp(dot(cdata.normalWorld, cdata.eyeDir), 0.0, 1.0);//灏嗗嚱鏁扮殑鍊奸檺瀹氬湪0.02鍒?.98

				float3 dir_light1 = float3(-1.00,0.23,0.26);
				float3 dir_shadow1 = normalize(float3(shadow_pos_x,  shadow_pos_y, shadow_pos_z));

				float3x3 _InverseView33 = (float3x3)UNITY_MATRIX_I_V;
				float3 dir_rimlight = mul(_InverseView33, dir_light1);//_InverseView33*dir_light1;
				float3 dir_shadow = mul(_InverseView33, dir_shadow1);

				float NdotshadowFactor = clamp(dot(dir_shadow, cdata.normalWorld.xyz), 0.0, 1.0);
				float RimlightDotValue = clamp(dot(dir_rimlight, cdata.normalWorld.xyz), 0.0, 1.0);

				float Ndotshadow = smoothstep(shadownol1, shadownol2, NdotshadowFactor * NdotView);

				float dif_illum = dot(diffuse, half3(0.299, 0.587, 0.114));
				float shadowshift = smoothstep(0.25, 0.74, dif_illum);
				float3 shadowColor = lerp(_DarkShadow.rgb, _BrightShadow.rgb, shadowshift);
				falloff_c =  lerp( shadowColor * diffuse.rgb, diffuse.rgb, Ndotshadow );

				// return fixed4(falloff_c.rgb, 1);


				float3 rim = float3(0.0, 0.0, 0.0);

				float rimdot = clamp(RimlightDotValue * (1.0 - NdotView), 0.0, 1.0);
				float rimffcal = smoothstep(0.35, 0.58, rimdot);
				float3 lightColor = rimffcal * diffuse.rgb * fo_rim_color.rgb * 1.0;
				rim = lightColor.xyz ;


				float3 finalColor = rim + falloff_c;
				float alpha = 1.0;
				alpha = diffuseAlpha*AlphaMtl;

				float4 result = float4(finalColor.rgb, alpha);
				// return result;

				float4 FlashedColor = ChangeColor;
				float flash_factor =  GetFresnel(cdata, fresnel_intensity);
				FlashedColor.xyz = ChangeColor.xyz * flash_factor;

				// result.rgb = result.rgb + (FlashedColor.rgb*ColorFactor); //ColorFactor  ;
				// return fixed4(FlashedColor.rgb, 1);
				// return cdata.diffColor;
				return result;
				// return fixed4(1,1,1,1);
			}

			ENDCG
		}
	}
}
