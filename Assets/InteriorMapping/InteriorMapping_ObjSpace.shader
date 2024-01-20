Shader "Interior Mapping (Object Space)"
{
    Properties 
	{
		[Header(DIMENSIONS)]
		[Space(5)]
		_CeilingsCount ("Ceiling Count", Float) = 4
		_WallsCount ("Walls Count", Float) = 4
		_IgnoredFloorsCount ("Ignored Floors Count", Float) = 1
		
		[Space(30)]

		[Header(INTERIOR)]
		[Space(5)]
		_CeilingTex ("Ceiling", 2DArray) = "" {}
		_FloorTex ("Floor", 2DArray) = "" {}
        _WallTex ("Wall", 2DArray) = "" {}
		_LitRooms ("Lit Rooms", Range(0, 1)) = 0.5
		_RoomLightColor ("Room Light Color", Color) = (1, 1, 0.25, 1)

		[Space(30)]
		
		[Header(OUTSIDE WALL)]
		[Space(5)]
		_OutsideWallTex ("Outside Wall", 2D) = "white" {}
		[Normal] [NoScaleOffset] _OutsideWallNormal ("Outside Wall Normal", 2D) = "bump" {}
		_BottomBricksTex ("Bottom Bricks", 2D) = "black" {}
		[Normal] [NoScaleOffset] _BottomBricksNormal ("Bottom Bricks Normal", 2D) = "bump" {}
		_BottomBricksHeight ("Bottom Bricks Height", Range(0, 1)) = 0.1

		[Space(30)]

		[Header(WINDOWS)]
		[Space(5)]
		[NoScaleOffset] _WindowTex ("Window", 2D) = "black" {}
		[NoScaleOffset] [Normal] _WindowNormal ("Window Normal", 2D) = "bump" {}
		_WindowRefraction ("Window Refraction", Range(0, 0.1)) = 0
		_RefractionStep ("Refraction Step", Float) = 1024
		_WindowGlassColor ("Window Color", Color) = (1,1,1,0)

		[Space(30)]

		[Header(SHUTTERS)]
		[Space(5)]
		_ShuttersTex ("Shutters", 2D) = "black" {}
		[NoScaleOffset] [Normal] _ShuttersNormal ("Shutters Normal", 2D) = "bump" {}
		_Shutters ("Shutters", Range(0, 1)) = 0.5
		_ClosedShutters ("Closed Shutters", Range(0, 1)) = 0
	}
	
	SubShader 
	{
		Tags
		{
			"RenderType"="Opaque"
		}
		
		CGPROGRAM

		#pragma surface surf Standard vertex:vert addshadow
		#pragma require 2darray
		#pragma target 3.5

		#include "Assets/CGInc/Easing.cginc"
		#include "Assets/CGInc/Maths.cginc"
		#include "Assets/CGInc/UV.cginc"

		#define RIGHT         float3(1, 0, 0)
		#define UP            float3(0, 1, 0)
		#define FORWARD       float3(0, 0, 1)
		#define SMOOTHSTEP_AA 0.002

		struct Input 
		{
			float2 uv_WindowTex;
			float3 objectViewDir;
			float3 localPosition;
			float3 normal : NORMAL;
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

		#define DECLARE_TEX2DARRAY_ST(tex) UNITY_DECLARE_TEX2DARRAY(tex); float4 tex##_ST;
		#define DECLARE_TEX_ST(tex)        sampler2D tex; float4 tex##_ST;

		float _CeilingsCount;
		float _WallsCount;
		float _IgnoredFloorsCount;
		
        DECLARE_TEX2DARRAY_ST(_CeilingTex)
        DECLARE_TEX2DARRAY_ST(_FloorTex)
        DECLARE_TEX2DARRAY_ST(_WallTex)
		DECLARE_TEX_ST(_OutsideWallTex)
		sampler2D _OutsideWallNormal;
		DECLARE_TEX_ST(_BottomBricksTex)
		sampler2D _BottomBricksNormal;
		sampler2D _WindowTex;
		sampler2D _WindowNormal;
		sampler2D _ShuttersTex;
		sampler2D _ShuttersNormal;

		float _WindowRefraction;
		float _RefractionStep;
		float _BottomBricksHeight;
		float _Shutters;
		float _ClosedShutters;
		float _LitRooms;
		float4 _RoomLightColor;
		float4 _WindowGlassColor;

		float2 random(float2 s)
		{
			return frac(sin(dot(s, float2(12.9898, 78.233))) * 43758.5453);
		}

		float3 hash23(float2 input)
        {
            float a = dot(input.xyx, float3(127.1, 311.7, 74.7));
            float b = dot(input.yxx, float3(269.5, 183.3, 246.1));
            float c = dot(input.xyy, float3(113.5, 271.9, 124.6));
            return frac(sin(float3(a, b, c)) * 43758.5453123);
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

			o.localPosition = i.vertex;
			o.normal = i.normal;

			float3 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;
			o.objectViewDir = i.vertex - objectSpaceCameraPos;
		}

		void surf(Input i, inout SurfaceOutputStandard o)
		{
        	float wallsOffset = 0.5 / _WallsCount * (_WallsCount % 2);
        	float ceilingsOffset = 0; // 0.5 / _CeilingsCount * (_CeilingsCount % 2); // Only if objet's pivot is at the center.
        	float3 offset = float3(wallsOffset, ceilingsOffset, wallsOffset);
        	
			float3 rayDirection = normalize(i.objectViewDir);
			float3 refractionDirection = hash23(floor((i.uv_WindowTex.xy * float2(1, 3)) * _RefractionStep) / _RefractionStep); // TODO: 1,3 is object scale.
			rayDirection += refractionDirection * _WindowRefraction;
			float3 rayStart = i.localPosition + offset + rayDirection * 1e-6;

			FragmentRayData rayData;
			rayData.color = float3(1, 1, 1);
			rayData.distance = 1e+64;

			float floorIndex = floor(i.uv_WindowTex.y * _CeilingsCount);
			float roof = dot(i.normal, UP);
			float discardInterior = floorIndex < _IgnoredFloorsCount || roof;
			
        	float roomUID = random(ceil(i.uv_WindowTex.xy * float2(_WallsCount, _CeilingsCount)));
			float ceilingTextureIndex = floor(roomUID * 2); // TODO: Find a way to get ceiling textures count dynamically.
			float floorTextureIndex = floor(roomUID * 3); // TODO: Find a way to get floor textures count dynamically.
			float wallTextureIndex = floor(roomUID * 2); // TODO: Find a way to get wall textures count dynamically.

			// https://www.proun-game.com/Oogst3D/CODING/InteriorMapping/InteriorMapping.pdf
        	float dc = 1.0 / _CeilingsCount;
			float dw = 1.0 / _WallsCount;

			// Ceiling/Floor.
			if (rayDirection.y > 0)
			{
				float ceilingPos = ceil(rayStart.y / dc) * dc;
				RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, UP, float3(0, ceilingPos, 0));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_CeilingTex, float3(uv_ST(hit.position.xz, _CeilingTex_ST) * _WallsCount, ceilingTextureIndex));
				}
			}
			else
			{
				float floorPos = (ceil(rayStart.y / dc) - 1) * dc;
				RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, -UP, float3(0, floorPos, 0));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_FloorTex, float3(uv_ST(hit.position.xz, _FloorTex_ST) * _WallsCount, floorTextureIndex)).rgb;
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
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(uv_ST(hit.position.zy, _WallTex_ST) * _CeilingsCount, wallTextureIndex)).rgb;
				}
			}
			else
			{
	            float wallLeftPos = (ceil(rayStart.x / dw) - 1) * dw;
				RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, RIGHT, float3(wallLeftPos, 0, 0));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(uv_ST(hit.position.zy, _WallTex_ST) * _CeilingsCount, wallTextureIndex)).rgb;
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
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(uv_ST(hit.position.xy, _WallTex_ST) * float2(_WallsCount, _CeilingsCount), wallTextureIndex)).rgb;
				}
        	}
        	else
        	{
        		float backPos = ceil(rayStart.z / dw - 1) * dw;
        		RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, -FORWARD, float3(0, 0, backPos));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(uv_ST(hit.position.xy, _WallTex_ST) * float2(_WallsCount, _CeilingsCount), wallTextureIndex)).rgb;
				}
        	}

			// Room lighting.
			float lit = step(1 - _LitRooms, 1 - roomUID); // (1 - UID) to avoid using same random for both lighting and shutters.
			
			// Shutters.
			_Shutters = (1 - _Shutters) * step(_ClosedShutters, roomUID);
			float shutterPercentage01 = _Shutters + _Shutters * roomUID;
			float shutterPercentageRemapped = Remap(shutterPercentage01, 0, 1, 0.15, 0.85); // Remap from cell bounds to window bounds.
			float2 shuttersGradient = frac(i.uv_WindowTex * float2(_WallsCount, _CeilingsCount)).xy;
			float4 shuttersColor = tex2D(_ShuttersTex, shuttersGradient - float2(0, shutterPercentageRemapped));
			float shuttersMask = smoothstep(shutterPercentageRemapped - SMOOTHSTEP_AA, shutterPercentageRemapped + SMOOTHSTEP_AA, shuttersGradient.y);
			shuttersColor = lerp(0, shuttersColor, shuttersMask);
			if (lit == 0)
				rayData.color.rgb *= OutQuad(saturate(shutterPercentage01 + _Shutters * roomUID)); // Reduce unlit room light based on shutter opening.
			
			// Outside wall color.
			float2 uvScale = lerp(float2(_WallsCount, _CeilingsCount), float2(min(_WallsCount, _CeilingsCount).xx), roof);
			float3 outsideWallColor = tex2D(_OutsideWallTex, uv_ST(i.uv_WindowTex, _OutsideWallTex_ST) * uvScale);
			float3 bottomBricksColor = tex2D(_BottomBricksTex, uv_ST(i.uv_WindowTex, _BottomBricksTex_ST));
			float bottomBricksMask = step(i.uv_WindowTex.y, _BottomBricksHeight) * (1 - roof);
			outsideWallColor = lerp(outsideWallColor, bottomBricksColor, bottomBricksMask);

			// Final color computation.
			float3 color = outsideWallColor;
            float4 windowColor = tex2D(_WindowTex, i.uv_WindowTex * float2(_WallsCount, _CeilingsCount));
			float windowGlassMask = saturate(windowColor.a - smoothstep(0, 0.5, 1 - Luminance(windowColor.rgb)));
			color = lerp(color, windowColor.rgb, windowColor.a - windowGlassMask);
            color = lerp(color, rayData.color, windowGlassMask);
			color = lerp(color, shuttersColor, windowGlassMask * shuttersColor.a);
			color = lerp(color, _WindowGlassColor, windowGlassMask * (1 - shuttersColor.a) * _WindowGlassColor.a);

			// Normal computation.
			float3 outsideWallNormal = UnpackNormal(tex2D(_OutsideWallNormal, uv_ST(i.uv_WindowTex, _OutsideWallTex_ST) * float2(_WallsCount, _CeilingsCount)));
			float3 bottomBricksNormal = UnpackNormal(tex2D(_BottomBricksNormal, uv_ST(i.uv_WindowTex, _BottomBricksTex_ST)));
			float3 windowNormal = UnpackNormal(tex2D(_WindowNormal, i.uv_WindowTex * float2(_WallsCount, _CeilingsCount)));
			float3 shuttersNormal = UnpackNormal(tex2D(_ShuttersNormal, shuttersGradient - float2(0, shutterPercentageRemapped)));
			outsideWallNormal.xy *= (1 - windowColor.a) * (1 - bottomBricksMask);
			bottomBricksNormal.xy *= bottomBricksNormal * bottomBricksMask;
			windowNormal.xy *= windowColor.a * windowGlassMask * (1 - bottomBricksMask) * (1 - discardInterior);
			shuttersNormal.xy *= shuttersMask * (windowGlassMask * shuttersColor.a) * (1 - discardInterior);
			float3 normal = saturate(outsideWallNormal + bottomBricksNormal + windowNormal + shuttersNormal);
			
			o.Albedo = discardInterior ? outsideWallColor : color;
			o.Normal = saturate(normal);
			o.Emission = discardInterior ? 0 : _RoomLightColor * _RoomLightColor.a * lit * windowGlassMask * (1 - shuttersColor.a);
			o.Smoothness = discardInterior ? 0 : windowGlassMask * step(shuttersGradient.y, shutterPercentageRemapped);
		}
		
		ENDCG
	}
}
