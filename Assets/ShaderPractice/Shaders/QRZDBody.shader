Shader "EriSeven/Cartoon/QRZDBody"
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


		_EmmsiveColor("Emmsive Color", Color) = ( 0.5, 0.5, 0.5, 0.5 )
		_EmmsiveIntensity("Emmsive Intensity", Range(0, 1)) = 0


		_Matcap3("Matcap 3", 2D) = "white" {}
		_ReflectionIntensity("Reflection Intensity", Range(0, 1)) = 1


		_Matcap5("Matcap 5", 2D) = "white" {}
		_ReflectionIntensityHair("Reflection Intensity Hair", Range(0, 1)) = 1




		// _SkinMasks6("Skin Mask", 2D) = "white" {}
		skin_color_switch("Skin Color Switch", Range(0, 1)) = 0

		skin_color1("Skin Color 1", Color) = ( 0.3765, 0.1765, 0.1686, 0 )
		skin_color2("Skin Color 2", Color) = ( 0.9451, 0.9255, 0.9373, 0 )
		skin_color3("Skin Color 3", Color) = ( 0.4941, 0.8902, 0.898, 0 )

		skin_orgin_hsv1("Skin Orgin HSV1", Color) = ( 0, 0, 0, 1 )
		skin_orgin_hsv2("Skin Orgin HSV2", Color) = ( 0, 0, 0, 1 )
		skin_orgin_hsv3("Skin Orgin HSV3", Color) = ( 0, 0, 0, 1 )

		skin_hsv1("Skin HSV1", Color) = ( 0, 0, 0, 1 )
		skin_hsv2("Skin HSV2", Color) = ( 0, 0, 0, 1 )
		skin_hsv3("Skin HSV3", Color) = ( 0, 0, 0, 1 )
		skinhold0("Skin Hold0", Range(0, 1)) = 0.1
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "AutoLight.cginc"

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

		float4 _EmmsiveColor;
		float _EmmsiveIntensity;



		sampler2D _Matcap3;
		float _ReflectionIntensity;

		sampler2D _Matcap5;
		float _ReflectionIntensityHair;




		sampler2D _SkinMasks6;
		float skin_color_switch;

		float4 skin_color1;
		float4 skin_color2;
		float4 skin_color3;

		float4 skin_orgin_hsv1;
		float4 skin_orgin_hsv2;
		float4 skin_orgin_hsv3;

		float4 skin_hsv1;
		float4 skin_hsv2;
		float4 skin_hsv3;
		float skinhold0;
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
				// SHADOW_COORDS(5)
				LIGHTING_COORDS(5, 6)
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
				// TRANSFER_SHADOW(o)
				TRANSFER_VERTEX_TO_FRAGMENT(o);

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

			half4 rgb2hsvl(half3 rgb )
			{
				half4 K = float4(0.0, -0.3333, 0.6666, -1.0);
				half4 p = lerp(float4(rgb.bg, K.wz), float4(rgb.gb, K.xy), step(rgb.b, rgb.g));
				half4 q = lerp(float4(p.xyw, rgb.r), float4(rgb.r, p.yzx), step(p.x, rgb.r));

				float c = min(q.w, q.y);
				float d = q.x-c;
				return float4(abs(q.z+(q.w-q.y)/(6.0*d+0.000001)), d/(q.x+0.000001), q.x, (q.x+c)/2.0);
			}

			half3 hsv2rgb(half3 hsv )
			{
				half4 K = float4(1.0, 0.6666, 0.3333, 3.0);
				half3 p = abs(6.0*frac(hsv.xxx+K.xyz)-K.www);
				return hsv.z * lerp(K.xxx, clamp(p-K.xxx, 0.0, 1.0), hsv.y);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				FragmentCommonData cdata = SetupFragCommomData(i);

				fixed shadow = LIGHT_ATTENUATION(i);

				float3 masks = tex2D(_Masks7, i.uv).rgb;
				float diffuseAlpha =  1.0;
				float matcap_mask01 = 0.0;
				float matcap_mask02 = 0.0;
				matcap_mask01 = masks.b; //

				float _hero_switch = 0.0;
				diffuseAlpha = masks.r;
				matcap_mask02 = masks.g;





				// float4 mask_color = tex2D(_SkinMasks6, i.uv);
				// float4 hsv = rgb2hsvl(cdata.diffColor.rgb);
				// float4 do1 = skin_orgin_hsv1;
				// float4 do2 = skin_orgin_hsv2;
				// float4 do3 = skin_orgin_hsv3;
				// float4 dhsv1 = skin_hsv1-do1;
				// float4 dhsv2 = skin_hsv2-do2;
				// float4 dhsv3 = skin_hsv3-do3;
				// float d1 =  clamp((mask_color.r*mask_color.r-0.1)*1.1111, 0.0, 1.0);
				// float d2 =  clamp((mask_color.g*mask_color.g-0.1)*1.1111, 0.0, 1.0);
				// float d3 =  clamp((mask_color.b*mask_color.b-0.1)*1.1111, 0.0, 1.0);
				// float3 a1 = lerp(cdata.diffColor.rgb, skin_color1.rgb, mask_color.r*skin_color_switch);

				// cdata.diffColor.rgb = lerp(a1, hsv2rgb(float3(do1.r, d1, hsv.b) + dhsv1.rgb), step(skinhold0, mask_color.r)*skin_color_switch);
				// float3 a2 = lerp(cdata.diffColor.rgb, skin_color2.rgb, mask_color.g*skin_color_switch);
				// cdata.diffColor.rgb = lerp(a2, hsv2rgb(float3(do2.r, d2, hsv.b) + dhsv2.rgb), step(skinhold0, mask_color.g)*skin_color_switch);
				// float3 a3 = lerp(cdata.diffColor.rgb, skin_color3.rgb, mask_color.b*skin_color_switch);
				// cdata.diffColor.rgb = lerp(a3, hsv2rgb(float3(do3.r, d3, hsv.b) + dhsv3.rgb), step(skinhold0, mask_color.b)*skin_color_switch);






				float3 dark_color =   _ShadowColor.xyz;
				// float shadow_factor = 1.0;
				float shadow_factor = shadow;

				float3 dir_light =  cdata.lightDir;
				float3 sha_color = float3(0.6706, 0.4588, 0.4275); //(171.0/255.0, 117.0/255.0, 109.0/255.0);
				float3 dirLightResult = 
					0.5 * _LightColor0.rgb * lerp(sha_color, float3(1.0, 1.0, 1.0), shadow_factor);

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

				// return fixed4(NdotshadowFactor, 0, 0, 1);
				// return fixed4(RimlightDotValue, 0, 0, 1);
				// return fixed4(NdotshadowFactor * NdotView, 0, 0, 1);

				float Ndotshadow = smoothstep(shadownol1, shadownol2, NdotshadowFactor * NdotView);

				// return fixed4(Ndotshadow, 0, 0, 1);				

				float dif_illum = dot(diffuse, half3(0.299, 0.587, 0.114));
				float shadowshift = smoothstep(0.25, 0.74, dif_illum);

				// return fixed4(shadowshift, 0, 0, 1);				


				float3 shadowColor = lerp(_DarkShadow.rgb, _BrightShadow.rgb, shadowshift);
				falloff_c =  lerp( shadowColor * diffuse.rgb, diffuse.rgb, Ndotshadow );

				// return fixed4(falloff_c.rgb, 1);

				//--------------------rim---------------------------
				float3 rim = float3(0.0, 0.0, 0.0);

				float rimdot = clamp(RimlightDotValue * (1.0 - NdotView), 0.0, 1.0);
				float rimffcal = smoothstep(0.35, 0.58, rimdot);
				float3 lightColor = rimffcal * diffuse.rgb * fo_rim_color.rgb * 1.0;
				rim = lightColor.xyz ;




				//--------------------matcap---------------------------

				float3 matcap_lit = float3(0, 0, 0);
				float3x3 ViewMatrix33 = (float3x3)UNITY_MATRIX_V;
				float3 normalView = normalize(mul(ViewMatrix33, cdata.normalWorld));
				normalView.y = -normalView.y;
				float2 matcapUV = normalView.xy * 0.5 + 0.5;	




				float3 matcap_map_color = tex2D(_Matcap3, matcapUV.xy).xyz;
				matcap_map_color = matcap_map_color * _ReflectionIntensity * matcap_mask01;
				matcap_lit += matcap_map_color;

				matcap_lit += tex2D(_Matcap5, matcapUV).rgb*matcap_mask02*_ReflectionIntensityHair;
				falloff_c += matcap_lit.rgb;






				//--------------------emiss---------------------------
				float3 emissive = float3(0.0, 0.0, 0.0);

				float emissive_mask = 0.0;
				emissive_mask = tex2D(_BumpMap, i.uv).b;

				float4 color_emmsive = _EmmsiveColor;
				float4 color_emmsive2 = float4(0, 0, 0, 0);





				falloff_c = lerp(falloff_c, diffuse, emissive_mask);
				emissive = color_emmsive2.xyz+color_emmsive.rgb*_EmmsiveIntensity * emissive_mask;







				// return fixed4(emissive, 1);


				
				float3 finalColor = emissive + rim + falloff_c;
				float alpha = 1.0;
				alpha = diffuseAlpha*AlphaMtl;





				float4 result = float4(finalColor.rgb, alpha);
				// return result;

				float4 FlashedColor = ChangeColor;
				float flash_factor =  GetFresnel(cdata, fresnel_intensity);
				FlashedColor.xyz = ChangeColor.xyz * flash_factor;
				// return FlashedColor;

				result.rgb = result.rgb + (FlashedColor.rgb*ColorFactor); //ColorFactor  ;

				// return fixed4(FlashedColor.rgb, 1);
				// return cdata.diffColor;
				return result;
				// return fixed4(1,1,1,1);
			}

			ENDCG
		}

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
