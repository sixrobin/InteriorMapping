Shader "Interior Mapping (Object Space)"
{
    Properties 
	{
		[Header(DIMENSIONS)]
		_CeilingsCount ("Ceiling Count", Float) = 1
		_WallsCount ("Walls Count", Float) = 1
		
		[Header(TEXTURES)]
		_CeilingTex ("Ceiling Texture", 2DArray) = "" {}
		_FloorTex ("Floor Textures", 2DArray) = "" {}
        _WallTex ("Wall Texture", 2DArray) = "" {}
		_WindowTex ("Window Texture", 2D) = "black" {}
		_ShuttersTex ("Shutters Texture", 2D) = "black" {}

		[Header(ROOMS LIGHTING)]
		_LitRooms ("Lit Rooms", Range(0, 1)) = 0.5
		_RoomLightColor ("Room Light Color", Color) = (1, 1, 0.25, 1)
		
		[Header(SHUTTERS)]
		_Shutters ("Shutters", Range(0, 1)) = 0.5
		_ClosedShutters ("Closed Shutters", Range(0, 1)) = 0

        [Header(COLORS)]
        _CeilingColor ("Ceiling Color", Color) = (1,1,1,1)
        _FloorColor ("Floor Color", Color) = (1,1,1,1)
        _WallRightColor ("Wall Right Color", Color) = (1,1,1,1)
        _WallLeftColor ("Wall Left Color", Color) = (1,1,1,1)
        _WallBackColor ("Wall Back Color", Color) = (1,1,1,1)
        _WindowColor ("Window Color", Color) = (1,1,1,0)
	}
	
	SubShader 
	{
		Tags
		{
			"RenderType"="Opaque"
		}
		
		CGPROGRAM

		#pragma surface surf Standard vertex:vert
		#pragma require 2darray
		#pragma target 3.5

		#include "Assets/CGInc/Easing.cginc"
		#include "Assets/CGInc/Maths.cginc"

		#define RIGHT   float3(1, 0, 0)
		#define UP      float3(0, 1, 0)
		#define FORWARD float3(0, 0, 1)

		struct Input 
		{
			float2 uv_WindowTex;
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
		
        UNITY_DECLARE_TEX2DARRAY(_CeilingTex);
        UNITY_DECLARE_TEX2DARRAY(_FloorTex);
        UNITY_DECLARE_TEX2DARRAY(_WallTex);
		sampler2D _WindowTex;
		sampler2D _ShuttersTex;

		float _Shutters;
		float _ClosedShutters;

		float _LitRooms;
		float4 _RoomLightColor;

		float4 _CeilingColor;
		float4 _FloorColor;
		float4 _WallRightColor;
		float4 _WallLeftColor;
		float4 _WallBackColor;
		float4 _WindowColor;

		float2 random(float2 s)
		{
			return frac(sin(dot(s, float2(12.9898, 78.233))) * 43758.5453);
		}
		
        RayPlaneIntersection rayToPlaneIntersection(float3 rayStart, float3 rayDirection, float3 planeNormal, float3 planePosition)
        {
        	RayPlaneIntersection result;

        	// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection.html
        	result.distance = dot(planePosition - rayStart, planeNormal) / dot(rayDirection, planeNormal);
        	result.position = rayStart + rayDirection * result.distance;

        	return result;
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

        	float wallsOffset = 0.5 / _WallsCount * (_WallsCount % 2);
        	float ceilingsOffset = 0.5 / _CeilingsCount * (_CeilingsCount % 2);
        	float3 offset = float3(wallsOffset, ceilingsOffset, wallsOffset);
        	
			float3 rayDirection = normalize(i.objectViewDir);
			float3 rayStart = i.localPosition + offset + rayDirection * 0.0001;

			FragmentRayData rayData;
			rayData.color = float3(1, 1, 1);
			rayData.distance = 1e+64;

        	float roomUID = random(ceil(i.uv_WindowTex.xy * float2(_WallsCount, _CeilingsCount)));
			float ceilingTextureIndex = floor(roomUID * 2); // TODO: Find a way to get ceiling textures count dynamically.
			float floorTextureIndex = floor(roomUID * 3); // TODO: Find a way to get floor textures count dynamically.
			float wallTextureIndex = floor(roomUID * 2); // TODO: Find a way to get wall textures count dynamically.

        	float dc = 1.0 / _CeilingsCount;
			float dw = 1.0 / _WallsCount;
			// TODO: Disable interior mapping for 1st floor (or n first floor, based on a slider/int value).

			// Ceiling/Floor.
			if (rayDirection.y > 0)
			{
				float ceilingPos = ceil(rayStart.y / dc) * dc;
				RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, UP, float3(0, ceilingPos, 0));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_CeilingTex, float3(hit.position.xz * _WallsCount, ceilingTextureIndex)) * _CeilingColor;
				}
			}
			else
			{
				float floorPos = (ceil(rayStart.y / dc) - 1) * dc;
				RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, -UP, float3(0, floorPos, 0));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_FloorTex, float3(hit.position.xz * _WallsCount, floorTextureIndex)).rgb * _FloorColor;
				}
			}

			// Left/Right.
			if (rayDirection.x > 0)
			{
		        float wallRightPos = ceil(rayStart.x / dw) * dw;
				RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, RIGHT, float3(wallRightPos, 0, 0));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(hit.position.zy * _CeilingsCount * float2(1, _WallsCount / _CeilingsCount), wallTextureIndex)).rgb * _WallRightColor;
				}
			}
			else
			{
	            float wallLeftPos = (ceil(rayStart.x / dw) - 1) * dw;
				RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, RIGHT, float3(wallLeftPos, 0, 0));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(hit.position.zy * _CeilingsCount * float2(1, _WallsCount / _CeilingsCount), wallTextureIndex)).rgb * _WallLeftColor;;
				}
			}

        	// Back.
        	if (rayDirection.z > 0)
        	{
        		float backPos = ceil(rayStart.z / dw) * dw;
        		RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, FORWARD, float3(0, 0, backPos));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(hit.position.xy * float2(_WallsCount, _CeilingsCount), wallTextureIndex)).rgb * _WallBackColor;
				}
        	}
        	else
        	{
        		float backPos = ceil(rayStart.z / dw - 1) * dw;
        		RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, -FORWARD, float3(0, 0, backPos));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(hit.position.xy * float2(_WallsCount, _CeilingsCount), wallTextureIndex)).rgb * _WallBackColor;
				}
        	}

			// Room lighting.
			_LitRooms = 1 - _LitRooms;
			float lit = step(_LitRooms, 1 - roomUID); // (1 - UID) to avoid using same random for both lighting and shutters.
			rayData.color.rgb = saturate(rayData.color.rgb + _RoomLightColor * lit * _RoomLightColor.a);

			// Shutters.
			_Shutters = (1 - _Shutters) * step(_ClosedShutters, roomUID);
			float shutterPercentage01 = _Shutters + _Shutters * roomUID;
			float shutterPercentageRemapped = Remap(shutterPercentage01, 0, 1, 0.15, 0.85); // Remap from cell bounds to window bounds.
			float2 shuttersGradient = frac(i.uv_WindowTex * float2(_WallsCount, _CeilingsCount)).xy;
			float4 shuttersColor = tex2D(_ShuttersTex, shuttersGradient - float2(0, shutterPercentageRemapped));
			shuttersColor = lerp(shuttersColor, 0, step(shuttersGradient.y, shutterPercentageRemapped));
			if (lit == 0)
				rayData.color.rgb *= OutQuad(saturate(shutterPercentage01 + _Shutters * roomUID)); // Reduce unlit room light based on shutter opening.
			
			// Final color computation.
            float4 windowColor = tex2D(_WindowTex, i.uv_WindowTex * float2(_WallsCount, _CeilingsCount));
            float3 color = lerp(rayData.color, windowColor.rgb, windowColor.a);
			color = lerp(color, shuttersColor, (1 - windowColor.a) * shuttersColor.a);
			color = lerp(color, _WindowColor, (1 - windowColor.a) * (1 - shuttersColor.a) * _WindowColor.a);

			o.Albedo = color;
		}
		
		ENDCG
	}
}
