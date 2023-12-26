Shader "Interior Mapping"
{
    Properties
    {
        _CeilingTex ("Ceiling Texture", 2D) = "white" {}
        _WallTex ("Wall Texture", 2D) = "white" {}
        _CeilingsCount ("Ceiling Count", Float) = 1
        _WallsCount ("Walls Count", Float) = 1
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

            #define RIGHT   float3(1, 0, 0)
            #define UP      float3(0, 1, 0)
            #define FORWARD float3(0, 0, 1)

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
            sampler2D _WallTex;
            float _CeilingsCount;
            float _WallsCount;
                
            float3 rayToPlaneIntersection(float3 planeNormal, float3 planePosition, float3 rayStart, float3 rayDirection)
            {
                // https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection.html
                float distance = dot(planePosition - rayStart, planeNormal) / dot(rayDirection, planeNormal);
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
                // https://www.proun-game.com/Oogst3D/CODING/InteriorMapping/InteriorMapping.pdf

                float3 cameraWorldPos = _WorldSpaceCameraPos;
                float3 cameraDirection = normalize(cameraWorldPos - i.worldPos);
                
                float dc = 1.0 / _CeilingsCount;
                float ceilingPos = ceil(i.worldPos.y / dc) * dc;
                float floorPos = (ceil(i.worldPos.y / dc) - 1) * dc;
                
                float3 ceilingIntersection = cameraDirection.y < 0
                    ? rayToPlaneIntersection(UP, float3(0, ceilingPos, 0), cameraWorldPos, cameraDirection)
                    : rayToPlaneIntersection(UP, float3(0, floorPos, 0), cameraWorldPos, cameraDirection);

                float dw = 1.0 / _WallsCount;
                float wallRightPos = ceil(i.worldPos.x / dw) * dw;
                float wallLeftPos = (ceil(i.worldPos.x / dw) - 1) * dw;
                float wallBackPos = ceil(i.worldPos.z + 1);
                
                float3 wallIntersection = cameraDirection.x < 0
                    ? rayToPlaneIntersection(RIGHT, float3(wallRightPos, 0, 0), cameraWorldPos, cameraDirection)
                    : rayToPlaneIntersection(RIGHT, float3(wallLeftPos, 0, 0), cameraWorldPos, cameraDirection);

                float3 backWallIntersection = rayToPlaneIntersection(FORWARD, float3(0, 0, wallBackPos), cameraWorldPos, cameraDirection);

                if (length(ceilingIntersection - i.worldPos) < length(wallIntersection - i.worldPos))
                {
                    if (length(ceilingIntersection - i.worldPos) < length(backWallIntersection - i.worldPos))
                        return tex2D(_CeilingTex, ceilingIntersection.xz);
                    return tex2D(_WallTex, backWallIntersection.xy);
                }
                else
                {
                    if (length(wallIntersection - i.worldPos) < length(backWallIntersection - i.worldPos))
                        return tex2D(_WallTex, wallIntersection.yz);
                    return tex2D(_WallTex, backWallIntersection.xy);
                }
            }
            
            ENDCG
        }
    }
}
