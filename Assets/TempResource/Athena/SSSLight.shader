Shader "SSS/SSSLight"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NormalTex ("Normal Texture", 2D) = "white" {}
    }
 
    SubShader
    {
        Tags { "RenderType" = "SSS" }
		Stencil
		{
			Ref 1
			Comp Always
			Pass Replace
			ReadMask 1
			WriteMask 1
		}
        pass
        {      
            Tags { "LightMode"="ForwardBase"}
 
            CGPROGRAM
 
            #pragma target 3.0
 
            #pragma vertex vertShadow
            #pragma fragment fragShadow
 
            #include "UnityCG.cginc"
 
            sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NormalTex;
 
            struct v2f
            {
                float4 pos : SV_POSITION;
                half3 lightDir : TEXCOORD0;
                half2 uv : TEXCOORD1;
                half3 TtoW0 : TEXCOORD2;  
                half3 TtoW1 : TEXCOORD3;  
                half3 TtoW2 : TEXCOORD4; 
				half viewZ : TEXCOORD5;
            };
 
            v2f vertShadow(appdata_tan v)
            {
                v2f o;
 
                o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
				float3x3 m = unity_ObjectToWorld;
				//float3x3 m = UNITY_MATRIX_MV; 
				
				TANGENT_SPACE_ROTATION;  
                o.lightDir = normalize(mul(m, ObjSpaceLightDir(v.vertex)));  

                half3 worldNormal = normalize(mul(m, v.normal));
                half3 worldTangent =  normalize(mul(m, v.tangent.xyz));
                half3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;  
                o.TtoW0 = half3(worldTangent.x, worldBinormal.x, worldNormal.x);  
                o.TtoW1 = half3(worldTangent.y, worldBinormal.y, worldNormal.y);  
                o.TtoW2 = half3(worldTangent.z, worldBinormal.z, worldNormal.z); 
                return o;
            }
 
            fixed4 fragShadow(v2f i) : COLOR
            {              
				fixed3 norm = UnpackNormal(tex2D(_NormalTex, i.uv));  
				half3 worldNormal = normalize(half3(dot(i.TtoW0.xyz, norm), dot(i.TtoW1.xyz, norm), dot(i.TtoW2.xyz, norm)));
				
				fixed light = saturate(dot(worldNormal, i.lightDir)); 

				half3 viewNormal = normalize(mul(unity_MatrixV,worldNormal));//不知道为啥直接转换到View空间法线纹理会不对,只能在这里乘了
                fixed4 finalColor = fixed4(1 - abs(viewNormal.rg) - fixed2(ddx(i.pos.z),ddy(i.pos.z) * 100),light,1);
                return finalColor;
            }
            ENDCG
        }
    }
}