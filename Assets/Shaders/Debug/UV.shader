Shader "RSLib/Debug/UV"
{
    Properties
    {
        _MainTex ("Checker Texture", 2D) = "black" {}
    }
    
    SubShader
    {
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            fixed4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 checker = tex2D(_MainTex, i.uv);
                fixed4 uvColor = fixed4(i.uv, 0, 1);
                
                return lerp(uvColor, checker, checker.a);
            }
            
            ENDCG
        }
    }
}
