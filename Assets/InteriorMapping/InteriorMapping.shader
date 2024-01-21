Shader "Interior Mapping"
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
		_CeilingTexCount ("Ceiling Textures Count", Float) = 1
		_FloorTex ("Floor", 2DArray) = "" {}
		_FloorTexCount ("Floor Textures Count", Float) = 1
        _WallTex ("Wall", 2DArray) = "" {}
		_WallTexCount ("Wall Textures Count", Float) = 1
		_LitRooms ("Lit Rooms", Range(0, 1)) = 0.5
		_RoomLightColor ("Room Light Color", Color) = (1, 1, 0.25, 1)

		[Space(30)]
		
		[Header(OUTSIDE WALL)]
		[Space(5)]
		_OutsideWallTex ("Outside Wall", 2D) = "white" {}
		[Normal] [NoScaleOffset] _OutsideWallNormal ("Outside Wall Normal", 2D) = "bump" {}

		[Space(30)]

		[Header(WINDOWS)]
		[Space(5)]
		[NoScaleOffset] _WindowTex ("Window", 2D) = "white" {}
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
		_ShuttersHeightRemapMin ("Shutters Height Remap Min", Range(0, 1)) = 0
		_ShuttersHeightRemapMax ("Shutters Height Remap Max", Range(0, 1)) = 1
	}
	
	SubShader 
	{
		Tags
		{
			"RenderType"="Opaque"
		}
		
		CGPROGRAM

		#pragma surface surf Standard vertex:vert fullforwardshadows addshadow
		#pragma require 2darray
		#pragma target 3.5

		#include "Assets/CGInc/Easing.cginc"
		#include "Assets/CGInc/Maths.cginc"
		#include "Assets/CGInc/Random.cginc"
		#include "Assets/CGInc/UV.cginc"

		#define RIGHT         float3(1, 0, 0)
		#define UP            float3(0, 1, 0)
		#define FORWARD       float3(0, 0, 1)
		#define SMOOTHSTEP_AA 0.01

		struct Input 
		{
			float2 uv_WindowTex;
			float3 objectViewDir;
			float3 localPosition;
			float3 normal : NORMAL;
		};

		// Represents the interior mapping ray for each pixel.
		// Contains the pixel color to use and the hit distance.
		struct FragmentRayData
		{
			float3 color;
			float distance;
		};

		// Represents the intersection between a ray and a plane.
		// Contains the intersection position and distance from ray start position.
		struct RayPlaneIntersection
		{
			float3 position;
			float distance;
		};

		#define DECLARE_TEX2DARRAY_ST(tex) UNITY_DECLARE_TEX2DARRAY(tex); float4 tex##_ST;
		#define DECLARE_TEX_ST(tex)        sampler2D tex; float4 tex##_ST;

		// Dimensions.
		float _CeilingsCount;
		float _WallsCount;
		float _IgnoredFloorsCount;
		
		// Interior.
        DECLARE_TEX2DARRAY_ST(_CeilingTex)
		float _CeilingTexCount;
        DECLARE_TEX2DARRAY_ST(_FloorTex)
		float _FloorTexCount;
        DECLARE_TEX2DARRAY_ST(_WallTex)
		float _WallTexCount;
		float _LitRooms;
		float4 _RoomLightColor;
		
		// Outside wall.
		DECLARE_TEX_ST(_OutsideWallTex)
		sampler2D _OutsideWallNormal;

		// Windows.
		sampler2D _WindowTex;
		sampler2D _WindowNormal;
		float4 _WindowTex_TexelSize;
		float _WindowRefraction;
		float _RefractionStep;
		float4 _WindowGlassColor;

		// Shutters.
		sampler2D _ShuttersTex;
		sampler2D _ShuttersNormal;
		float _Shutters;
		float _ClosedShutters;
		float _ShuttersHeightRemapMin;
		float _ShuttersHeightRemapMax;
		
        RayPlaneIntersection rayToPlaneIntersection(float3 rayStart, float3 rayDirection, float3 planeNormal, float3 planePosition)
        {
			// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection.html

        	RayPlaneIntersection result;
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
			float dimensionsRatio = _WallsCount / _CeilingsCount;

        	// Compute an offset to handle odd dimensions correctly.
        	float wallsOffset = 0.5 / _WallsCount * (_WallsCount % 2);
        	float ceilingsOffset = 0; // 0.5 / _CeilingsCount * (_CeilingsCount % 2); // Use commented part if objet's pivot is at the center.
        	float3 offset = float3(wallsOffset, ceilingsOffset, wallsOffset);

			float3 transformScale = float3
			(
			    length(unity_ObjectToWorld._m00_m10_m20),
			    length(unity_ObjectToWorld._m01_m11_m21),
			    length(unity_ObjectToWorld._m02_m12_m22)
			);
			
			float3 rayDirection = normalize(i.objectViewDir);
			float3 refractionDirection = hash23(floor(i.uv_WindowTex.xy * float2(1, transformScale.y) * _RefractionStep) / _RefractionStep);
			rayDirection += refractionDirection * _WindowRefraction;
			float3 rayStart = i.localPosition + offset + rayDirection * 1e-6; // Move the ray a little forward to ensure it starts inside the room.

        	// Ray initialization.
			FragmentRayData rayData;
			rayData.color = float3(1, 1, 1);
			rayData.distance = 1e+64;

			float roof = dot(i.normal, UP);
			float floorIndex = floor(i.uv_WindowTex.y * _CeilingsCount);
			float discardInterior = floorIndex < _IgnoredFloorsCount || (roof && _WindowTex_TexelSize.z > 1); // Discard interior mapping on roof, only if there are windows.
			
        	float roomUID = random(ceil(i.uv_WindowTex.xy * float2(_WallsCount, _CeilingsCount)));
			float ceilingTextureIndex = floor(roomUID * _CeilingTexCount);
			float floorTextureIndex = floor(roomUID * _FloorTexCount);
			float wallTextureIndex = floor(roomUID * _WallTexCount);

        	// Actual interior mapping code, using the explanations from this document.
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
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(uv_ST(hit.position.zy, _WallTex_ST) * float2(_CeilingsCount * dimensionsRatio, _CeilingsCount), wallTextureIndex)).rgb;
				}
			}
			else
			{
	            float wallLeftPos = (ceil(rayStart.x / dw) - 1) * dw;
				RayPlaneIntersection hit = rayToPlaneIntersection(rayStart, rayDirection, RIGHT, float3(wallLeftPos, 0, 0));
				if (hit.distance < rayData.distance)
				{
					rayData.distance = hit.distance;
					rayData.color = UNITY_SAMPLE_TEX2DARRAY(_WallTex, float3(uv_ST(hit.position.zy, _WallTex_ST) * float2(_CeilingsCount * dimensionsRatio, _CeilingsCount), wallTextureIndex)).rgb;
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
			float shutterPercentageRemapped = Remap(shutterPercentage01, 0, 1, _ShuttersHeightRemapMin, _ShuttersHeightRemapMax); // Remap from cell bounds to window bounds.
			float2 shuttersGradient = frac(i.uv_WindowTex * float2(_WallsCount, _CeilingsCount));
			float shuttersMask = smoothstep(shutterPercentageRemapped - SMOOTHSTEP_AA, shutterPercentageRemapped + SMOOTHSTEP_AA, shuttersGradient.y);
        	float2 shuttersUV = shuttersGradient - float2(0, shutterPercentageRemapped);
			float4 shuttersColor = tex2D(_ShuttersTex, shuttersUV) * shuttersMask;
			if (lit == 0)
				rayData.color.rgb *= OutQuad(saturate(shutterPercentage01 + _Shutters * roomUID)); // Reduce unlit room lighting based on shutter opening.
			
			// Outside wall color.
			float2 outsideWallUVScale = lerp(float2(_WallsCount, _CeilingsCount), float2(min(_WallsCount, _CeilingsCount).xx), roof);
        	float2 outsideWallUV = uv_ST(i.uv_WindowTex, _OutsideWallTex_ST) * outsideWallUVScale;
			float3 outsideWallColor = tex2D(_OutsideWallTex, outsideWallUV);

			// Albedo computation.
			float3 color = outsideWallColor;
        	float2 windowUV = i.uv_WindowTex * float2(_WallsCount, _CeilingsCount);
            float4 windowColor = tex2D(_WindowTex, windowUV);
			float windowGlassMask = saturate(windowColor.a - smoothstep(0, 0.5, 1 - Luminance(windowColor.rgb)));
        	if (discardInterior == 0)
        	{
				color = lerp(color, windowColor.rgb, windowColor.a - windowGlassMask);
	            color = lerp(color, rayData.color * _WindowGlassColor, windowGlassMask);
				color = lerp(color, _WindowGlassColor, windowGlassMask * _WindowGlassColor.a);
				color = lerp(color, shuttersColor, windowGlassMask * shuttersMask);
        	}

			// Normals computation.
			float3 outsideWallNormal = UnpackNormal(tex2D(_OutsideWallNormal, outsideWallUV));
			float3 windowNormal = UnpackNormal(tex2D(_WindowNormal, windowUV));
        	float3 shuttersNormal = UnpackNormal(tex2D(_ShuttersNormal, shuttersUV));
			outsideWallNormal.xy *= 1 - windowColor.a;
        	windowNormal.xy *= _WindowTex_TexelSize.x == 1 ? 0 : windowColor.a * windowGlassMask * (1 - discardInterior);
			shuttersNormal.xy *= shuttersMask * (windowGlassMask * shuttersColor.a) * (1 - discardInterior);
        	float3 normal = saturate(outsideWallNormal + windowNormal + shuttersNormal);

        	// Emission computation.
        	float3 emission = 0;
        	if (discardInterior == 0)
        		emission = _RoomLightColor * _RoomLightColor.a * lit * windowGlassMask * (1 - shuttersColor.a);
        	
			// Smoothness computation.
			float smoothness = windowGlassMask * step(shuttersGradient.y, shutterPercentageRemapped);
			if (discardInterior)
				smoothness = 0;
			else if (_WindowTex_TexelSize.x == 1) // No texture set in material.
				smoothness *= 1 - windowColor.a;
			
			o.Albedo = color;
			o.Emission = emission;
			o.Normal = normal;
			o.Smoothness = smoothness;
		}
		
		ENDCG
	}
}
