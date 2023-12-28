Shader "RSLib/Debug/Normal"
{
    Properties
    {
        [MaterialToggle] Normalize ("Normalize 01", Float) = 0
    }
    
    SubShader
    {
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local _ NORMALIZE_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                #if defined(NORMALIZE_ON)
                return fixed4(i.normal * 0.5 + 0.5, 1);
                #else
                return fixed4(i.normal, 1);
                #endif
            }
            
            ENDCG
        }
    }
}
