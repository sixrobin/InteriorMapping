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
		
		void Raycast(float3 rayDirection, float3 rayStart, float3 planePosition, float3 planeNormal, float4 color, inout FragmentRayData currentRayData)
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
			float3 rayDirection = normalize(i.objectViewDir);
			float3 rayStart = i.localPosition + rayDirection * 0.0001;

			FragmentRayData rayData;
			rayData.color = float3(1, 1, 1);
			rayData.distance = 1e+10;

			// Ceiling/Floor.
			float dc = 1.0 / _CeilingsCount;
			float ceilingPos = ceil(rayStart.y / dc) * dc;
			float floorPos = (ceil(rayStart.y / dc) - 1) * dc;
			if (dot(UP, rayDirection) > 0)
				Raycast(rayDirection, rayStart, float3(0, ceilingPos, 0), UP, fixed4(ceilingPos + dc, 0, 0, 1), rayData);
			else
				Raycast(rayDirection, rayStart, float3(0, floorPos, 0), -UP, fixed4(0, 0, ceilingPos + dc, 1), rayData);

			// Left/Right.
			float dw = 1.0 / _WallsCount;
            float wallRightPos = ceil(rayStart.x / dw) * dw;
            float wallLeftPos = (ceil(rayStart.x / dw) - 1) * dw;
			if (dot(RIGHT, rayDirection) > 0)
				Raycast(rayDirection, rayStart, float3(wallRightPos, 0, 0), RIGHT, fixed4(0, wallRightPos + dw, 0, 1), rayData);
			else
				Raycast(rayDirection, rayStart, float3(wallLeftPos, 0, 0), -RIGHT, fixed4(wallRightPos + dw, wallRightPos + dw, 0, 1), rayData);

        	// Back.
        	float backPos = ceil(rayStart.z / dw) * dw;
        	Raycast(rayDirection, rayStart, float3(0, 0, backPos), -FORWARD, fixed4(1, 0, 1, 1), rayData);

			o.Albedo = saturate(rayData.color);
		}
		
		ENDCG
	}
}
