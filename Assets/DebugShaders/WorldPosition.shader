Shader "RSLib/Debug/World Position"
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(unity_ObjectToWorld, o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                #if defined(NORMALIZE_ON)
                return fixed4(i.worldPosition * 0.5 + 0.5, 1);
                #else
                return fixed4(i.worldPosition, 1);
                #endif
            }
            
            ENDCG
        }
    }
}
