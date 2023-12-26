Shader "Interior Mapping"
{
    Properties
    {
        _WindowTex ("Window Texture", 2D) = "black" {}
        _CeilingTex ("Ceiling Texture", 2D) = "white" {}
        _WallTex ("Wall Texture", 2D) = "white" {}
        _CeilingsCount ("Ceiling Count", Float) = 1
        _WallsCount ("Walls Count", Float) = 1
        _Depth ("Depth", Float) = 1
        
        [Header(COLORS)]
        _CeilingColor ("Ceiling Color", Color) = (1,1,1,1)
        _FloorColor ("Floor Color", Color) = (1,1,1,1)
        _WallRightColor ("Wall Right Color", Color) = (1,1,1,1)
        _WallLeftColor ("Wall Left Color", Color) = (1,1,1,1)
        _WallBackColor ("Wall Back Color", Color) = (1,1,1,1)
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
                float2 uv     : TEXCOORD0;
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float2 uv       : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 vertex   : SV_POSITION;
            };

            sampler2D _WindowTex;
            sampler2D _CeilingTex;
            sampler2D _WallTex;
            float _CeilingsCount;
            float _WallsCount;
            float _Depth;

            float4 _CeilingColor;
            float4 _FloorColor;
            float4 _WallRightColor;
            float4 _WallLeftColor;
            float4 _WallBackColor;
            
            float3 rayToPlaneIntersection(float3 planeNormal, float3 planePosition, float3 rayStart, float3 rayDirection)
            {
                // https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection.html
                float distance = dot(planePosition - rayStart, planeNormal) / dot(rayDirection, planeNormal);
                return rayStart + rayDirection * distance;
            }

            float2 random(float2 s)
            {
	            return frac(sin(dot(s, float2(12.9898, 78.233))) * 43758.5453);
            }
            
            v2f vert(appdata v)
            {
                v2f o;
                o.uv = v.uv;
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
                float3 wallIntersection = cameraDirection.x < 0
                    ? rayToPlaneIntersection(RIGHT, float3(wallRightPos, 0, 0), cameraWorldPos, cameraDirection)
                    : rayToPlaneIntersection(RIGHT, float3(wallLeftPos, 0, 0), cameraWorldPos, cameraDirection);

                float wallBackPos = ceil(i.worldPos.z + 1e-3);
                float3 backWallIntersection = rayToPlaneIntersection(FORWARD, float3(0, 0, wallBackPos * _Depth), cameraWorldPos, cameraDirection);

                float4 interiorColor;

                if (length(ceilingIntersection - i.worldPos) < length(wallIntersection - i.worldPos))
                {
                    if (length(ceilingIntersection - i.worldPos) < length(backWallIntersection - i.worldPos))
                    {
                        float4 ceilingColor = cameraDirection.y < 0 ? _CeilingColor : _FloorColor;
                        interiorColor = tex2D(_CeilingTex, ceilingIntersection.xz / float2(1, _Depth) * float2(_WallsCount, 1)) * ceilingColor;
                    }
                    else
                    {
                        interiorColor = tex2D(_WallTex, backWallIntersection.xy * float2(_WallsCount, _CeilingsCount)) * _WallBackColor;
                    }
                }
                else
                {
                    if (length(wallIntersection - i.worldPos) < length(backWallIntersection - i.worldPos))
                    {
                        float4 wallColor = cameraDirection.x < 0 ? _WallRightColor : _WallLeftColor;
                        interiorColor = tex2D(_WallTex, wallIntersection.yz / float2(1, _Depth) * float2(_CeilingsCount, 1)) * wallColor;
                    }
                    else
                    {
                        interiorColor = tex2D(_WallTex, backWallIntersection.xy * float2(_WallsCount, _CeilingsCount)) * _WallBackColor;
                    }
                }

                float4 windowColor = tex2D(_WindowTex, i.uv * float2(_WallsCount, _CeilingsCount));
                float4 color = lerp(interiorColor, windowColor, windowColor.a);

                return color;
            }
            
            ENDCG
        }
    }
}
