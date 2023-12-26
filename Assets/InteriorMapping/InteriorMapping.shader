Shader "Interior Mapping"
{
    Properties
    {
        _CeilingTex ("Ceiling Texture", 2D) = "white" {}
        _CeilingsCount ("Ceiling Count", Float) = 1
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
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 vertex   : SV_POSITION;
            };

            sampler2D _CeilingTex;
            float _CeilingsCount;
                
            float3 rayToPlaneIntersection(float3 planeNormal, float3 planePosition, float3 rayStart, float3 rayDirection)
            {
                // https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection.html
                float distance = dot((planePosition - rayStart), planeNormal) / dot(rayDirection, planeNormal);
                return rayStart + rayDirection * distance;
            }
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 cameraWorldPos = _WorldSpaceCameraPos;
                float3 cameraDirection = normalize(cameraWorldPos - i.worldPos);

                // float3 debugIntersection = rayToPlaneIntersection(_DebugPlaneNormal, _DebugPlanePosition, _DebugRayStart, normalize(_DebugRayDirection));
                // return fixed4(length(debugIntersection - i.worldPos).xxx, 1);

                // https://www.proun-game.com/Oogst3D/CODING/InteriorMapping/InteriorMapping.pdf
                float d = 1.0 / _CeilingsCount;
                float y = i.worldPos.y;
                float ceilingHeight = ceil(y / d) * d;
                float floorHeight = (ceil(y / d) - 1) * d;

                float3 intersection;
                if (cameraDirection.y < 0)
                    intersection = rayToPlaneIntersection(float3(0, -1, 0), float3(0, ceilingHeight, 0), cameraWorldPos, cameraDirection);
                else
                    intersection = rayToPlaneIntersection(float3(0, 1, 0), float3(0, floorHeight, 0), cameraWorldPos, cameraDirection);
                
                return tex2D(_CeilingTex, intersection.xz);
            }
            
            ENDCG
        }
    }
}
