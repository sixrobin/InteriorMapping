Shader "Interior Mapping"
{
    Properties
    {
        _Cube ("Cubemap", Cube) = "white" {}
    }
    
    SubShader
    {
        Tags 
        {
            "RenderType"="Opaque"
        }

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex  : POSITION;
                float2 uv      : TEXCOORD0;
                float3 normal  : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv      : TEXCOORD0;
                float4 vertex  : SV_POSITION;
                float3 viewDir : TEXCOORD1;
            };

            samplerCUBE _Cube;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                half3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                half3 viewDir = WorldSpaceViewDir(float4(worldPos, 1));

                float3 worldSpaceNormal = mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz;
                float3 worldSpaceTangent = normalize(float3(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0)).xyz));
                float3 worldSpaceBinormal = normalize(cross(worldSpaceNormal, worldSpaceTangent) * v.tangent.w);
                
                float3x3 tangentTransform_World = float3x3(worldSpaceTangent, worldSpaceBinormal, worldSpaceNormal);
                
                o.viewDir = mul(tangentTransform_World, viewDir);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 expandedUV = frac(i.uv) * 2 - 1;
                float3 uv = float3(expandedUV, -1);

                float4 color = texCUBE(_Cube, i.viewDir);
                
                return color;
            }
            
            ENDCG
        }
    }
}
