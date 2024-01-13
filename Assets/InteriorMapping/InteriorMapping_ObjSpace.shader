Shader "Interior Mapping (Object Space)"
{
    Properties 
	{
		_CeilingsCount ("Ceiling Count", Float) = 1
		_WallsCount ("Walls Count", Float) = 1
	}
	
	SubShader 
	{
		Tags
		{
			"RenderType"="Opaque"
		}
		
		CGPROGRAM

		#pragma surface surf Standard vertex:vert
		
		#define RIGHT   float3(1, 0, 0)
		#define UP      float3(0, 1, 0)
		#define FORWARD float3(0, 0, 1)

		struct Input 
		{
			float3 objectViewDir;
			float3 localPosition;
		};

		struct FragmentRayData
		{
			float3 color;
			float distance;
		};

		struct RayPlaneIntersection
		{
			float3 position;
			float distance;
		};

		float _CeilingsCount;
		float _WallsCount;

        RayPlaneIntersection rayToPlaneIntersection(float3 rayStart, float3 rayDirection, float3 planeNormal, float3 planePosition)
        {
        	RayPlaneIntersection result;

        	// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection.html
        	result.distance = dot(planePosition - rayStart, planeNormal) / dot(rayDirection, planeNormal);
        	result.position = rayStart + rayDirection * result.distance;

        	return result;
        }
		
		void raycast(float3 rayDirection, float3 rayStart, float3 planePosition, float3 planeNormal, float4 color, inout FragmentRayData currentRayData)
		{
			RayPlaneIntersection intersection = rayToPlaneIntersection(rayStart, rayDirection, planeNormal, planePosition);
			if (intersection.distance < currentRayData.distance)
			{
				currentRayData.distance = intersection.distance;
				currentRayData.color = color;
			}
		}
		
		void vert(inout appdata_full i, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float3 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;
			o.objectViewDir = i.vertex - objectSpaceCameraPos;
			o.localPosition = i.vertex;
		}

		void surf(Input i, inout SurfaceOutputStandard o) 
		{
        	// https://www.proun-game.com/Oogst3D/CODING/InteriorMapping/InteriorMapping.pdf

			float3 rayDirection = normalize(i.objectViewDir);
			float3 rayStart = i.localPosition + rayDirection * 0.0001;

			FragmentRayData rayData;
			rayData.color = float3(1, 1, 1);
			rayData.distance = 1e+64;

        	float dc = 1.0 / _CeilingsCount;
			float dw = 1.0 / _WallsCount;

			// Ceiling/Floor.
			if (rayDirection.y > 0)
			{
				float ceilingPos = ceil(rayStart.y / dc) * dc;
				raycast(rayDirection, rayStart, float3(0, ceilingPos, 0), UP, fixed4(ceilingPos + dc, 0, 0, 1), rayData);
			}
			else
			{
				float floorPos = (ceil(rayStart.y / dc) - 1) * dc;
				raycast(rayDirection, rayStart, float3(0, floorPos, 0), -UP, fixed4(0, 0, floorPos + dc * 2, 1), rayData);
			}

			// Left/Right.
			if (rayDirection.x > 0)
			{
		        float wallRightPos = ceil(rayStart.x / dw) * dw;
				raycast(rayDirection, rayStart, float3(wallRightPos, 0, 0), RIGHT, fixed4(0, wallRightPos + dw, 0, 1), rayData);
			}
			else
			{
	            float wallLeftPos = (ceil(rayStart.x / dw) - 1) * dw;
				raycast(rayDirection, rayStart, float3(wallLeftPos, 0, 0), -RIGHT, fixed4(wallLeftPos + dw * 2, wallLeftPos + dw * 2, 0, 1), rayData);
			}

        	// Back.
        	if (rayDirection.z > 0)
        	{
        		float backPos = ceil(rayStart.z / dw) * dw;
	        	raycast(rayDirection, rayStart, float3(0, 0, backPos), -FORWARD, fixed4(1, 0, 1, 1), rayData);
        	}
        	else
        	{
        		float backPos = ceil(rayStart.z / dw - 1) * dw;
	        	raycast(rayDirection, rayStart, float3(0, 0, backPos), -FORWARD, fixed4(1, 0, 1, 1), rayData);
        	}

			o.Albedo = rayData.color;
		}
		
		ENDCG
	}
}
