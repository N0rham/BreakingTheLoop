// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Knife/Particle Channel Packed Unlit"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_Rows("Rows", Float) = 4
		_Columns("Columns", Float) = 4
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white" {}
		[Toggle(_MAINTEXSMOOTHSTEP_ON)] _MainTexSmoothstep("MainTexSmoothstep", Float) = 0
		_MainSoftnessMin("MainSoftnessMin", Range( 0 , 1)) = 0
		_MainSoftnessMax("MainSoftnessMax", Range( 0 , 1)) = 1
		_DepthSoftness("DepthSoftness", Float) = 1
		[Toggle(_ALPHADISSOLVE_ON)] _AlphaDissolve("AlphaDissolve", Float) = 0
		[HDR]_Emission("Emission", Color) = (0,0,0,0)
		[Toggle(_EMISSIONDISSOLVE_ON)] _EmissionDissolve("EmissionDissolve", Float) = 0
		_EmissionTex("EmissionTex", 2D) = "white" {}
		_EmissionSpeed("EmissionSpeed", Vector) = (0,0,0,0)
		_EmissionSoftness1("EmissionSoftness1", Range( 0 , 1)) = 0
		_EmissionSoftness2("EmissionSoftness2", Range( 0 , 1)) = 0
		[Toggle(_FINALALPHASMOOTHSTEP_ON)] _FinalAlphaSmoothstep("FinalAlphaSmoothstep", Float) = 0
		_FinalAlphaSmoothstepMin("FinalAlphaSmoothstepMin", Range( 0 , 1)) = 0
		_FinalAlphaSmoothstepMax("FinalAlphaSmoothstepMax", Range( 0 , 1)) = 1
		[Toggle(_EMISSIONALPHA_ON)] _EmissionAlpha("EmissionAlpha", Float) = 0
		[Toggle(_FINALEMISSIONSMOOTHSTEP_ON)] _FinalEmissionSmoothstep("FinalEmissionSmoothstep", Float) = 0
		_FinalEmissionSmoothstepMin("FinalEmissionSmoothstepMin", Range( 0 , 1)) = 0
		_FinalEmissionSmoothstepMax("FinalEmissionSmoothstepMax", Range( 0 , 1)) = 1
		_EmissionSubValue("EmissionSubValue", Range( 0 , 1)) = 0
		[ASEEnd][Toggle(_ALPHAEMISSIONDISSOLVESUB_ON)] _AlphaEmissionDissolveSub("Alpha Emission Dissolve Sub", Float) = 0


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Unlit" }

		Cull Back
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 3.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma multi_compile _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma shader_feature _ _SAMPLE_GI
			#pragma multi_compile _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _Emission;
			float4 _EmissionTex_ST;
			float2 _EmissionSpeed;
			float _EmissionSoftness1;
			float _EmissionSoftness2;
			float _DepthSoftness;
			float _Columns;
			float _Rows;
			float _MainSoftnessMin;
			float _MainSoftnessMax;
			float _EmissionSubValue;
			float _FinalEmissionSmoothstepMin;
			float _FinalEmissionSmoothstepMax;
			float _FinalAlphaSmoothstepMin;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _EmissionTex;
			sampler2D _MainTex;


			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord4 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord3 = v.ase_texcoord;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 texCoord170 = IN.ase_texcoord3;
				texCoord170.xy = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_1 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_2 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord3.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + uv_EmissionTex);
				float4 smoothstepResult193 = smoothstep( temp_cast_1 , temp_cast_2 , tex2D( _EmissionTex, panner238 ));
				float4 screenPos = IN.ase_texcoord4;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float4 texCoord3 = IN.ase_texcoord3;
				texCoord3.xy = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float AnimFrame4 = round( texCoord3.z );
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles98 = columns135 * rows136;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				// Speed of animation
				float fbspeed98 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				// Multiply Offset X by coloffset
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				// Multiply Offset Y by rowoffset
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				// UV Offset
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				// Flipbook UV
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				// *** END Flipbook UV Animation vars ***
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_3 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_4 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_3 , temp_cast_4 , tex2DNode1);
				#ifdef _MAINTEXSMOOTHSTEP_ON
				float4 staticSwitch236 = smoothstepResult233;
				#else
				float4 staticSwitch236 = tex2DNode1;
				#endif
				float4 break152 = staticSwitch236;
				float Frames126 = temp_output_18_0;
				float temp_output_133_0 = ( Frames126 - 1.0 );
				float smoothstepResult23 = smoothstep( temp_output_133_0 , temp_output_133_0 , AnimFrame4);
				float lerp156 = smoothstepResult23;
				float lerpResult20 = lerp( break152.r , break152.g , lerp156);
				float Frames243 = ( Frames126 * 2.0 );
				float temp_output_123_0 = ( Frames243 - 1.0 );
				float smoothstepResult24 = smoothstep( temp_output_123_0 , temp_output_123_0 , AnimFrame4);
				float lerp257 = smoothstepResult24;
				float lerpResult21 = lerp( lerpResult20 , break152.b , lerp257);
				float Frames344 = ( Frames126 * 3.0 );
				float temp_output_124_0 = ( Frames344 - 1.0 );
				float smoothstepResult25 = smoothstep( temp_output_124_0 , temp_output_124_0 , AnimFrame4);
				float lerp358 = smoothstepResult25;
				float lerpResult22 = lerp( lerpResult21 , break152.a , lerp358);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * lerpResult22 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * lerpResult22 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_5 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_5 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch278 = smoothstepResult258;
				#else
				float staticSwitch278 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch278 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch277 = smoothstepResult252;
				#else
				float staticSwitch277 = finalAlpha248;
				#endif
				float4 appendResult273 = (float4((staticSwitch240).rgb , staticSwitch277));
				float4 temp_output_275_0 = ( float4( (( (_Color).rgb * (IN.ase_color).rgb )).xyz , 0.0 ) + appendResult273 );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = temp_output_275_0.xyz;
				float Alpha = (temp_output_275_0).w;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.clipPos, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_color : COLOR;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _Emission;
			float4 _EmissionTex_ST;
			float2 _EmissionSpeed;
			float _EmissionSoftness1;
			float _EmissionSoftness2;
			float _DepthSoftness;
			float _Columns;
			float _Rows;
			float _MainSoftnessMin;
			float _MainSoftnessMax;
			float _EmissionSubValue;
			float _FinalEmissionSmoothstepMin;
			float _FinalEmissionSmoothstepMax;
			float _FinalAlphaSmoothstepMin;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _EmissionTex;
			sampler2D _MainTex;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord2 = v.ase_texcoord;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 texCoord170 = IN.ase_texcoord2;
				texCoord170.xy = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_1 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_2 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord2.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + uv_EmissionTex);
				float4 smoothstepResult193 = smoothstep( temp_cast_1 , temp_cast_2 , tex2D( _EmissionTex, panner238 ));
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float4 texCoord3 = IN.ase_texcoord2;
				texCoord3.xy = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float AnimFrame4 = round( texCoord3.z );
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles98 = columns135 * rows136;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				// Speed of animation
				float fbspeed98 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				// Multiply Offset X by coloffset
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				// Multiply Offset Y by rowoffset
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				// UV Offset
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				// Flipbook UV
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				// *** END Flipbook UV Animation vars ***
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_3 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_4 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_3 , temp_cast_4 , tex2DNode1);
				#ifdef _MAINTEXSMOOTHSTEP_ON
				float4 staticSwitch236 = smoothstepResult233;
				#else
				float4 staticSwitch236 = tex2DNode1;
				#endif
				float4 break152 = staticSwitch236;
				float Frames126 = temp_output_18_0;
				float temp_output_133_0 = ( Frames126 - 1.0 );
				float smoothstepResult23 = smoothstep( temp_output_133_0 , temp_output_133_0 , AnimFrame4);
				float lerp156 = smoothstepResult23;
				float lerpResult20 = lerp( break152.r , break152.g , lerp156);
				float Frames243 = ( Frames126 * 2.0 );
				float temp_output_123_0 = ( Frames243 - 1.0 );
				float smoothstepResult24 = smoothstep( temp_output_123_0 , temp_output_123_0 , AnimFrame4);
				float lerp257 = smoothstepResult24;
				float lerpResult21 = lerp( lerpResult20 , break152.b , lerp257);
				float Frames344 = ( Frames126 * 3.0 );
				float temp_output_124_0 = ( Frames344 - 1.0 );
				float smoothstepResult25 = smoothstep( temp_output_124_0 , temp_output_124_0 , AnimFrame4);
				float lerp358 = smoothstepResult25;
				float lerpResult22 = lerp( lerpResult21 , break152.a , lerp358);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * lerpResult22 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * lerpResult22 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_5 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_5 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch278 = smoothstepResult258;
				#else
				float staticSwitch278 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch278 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch277 = smoothstepResult252;
				#else
				float staticSwitch277 = finalAlpha248;
				#endif
				float4 appendResult273 = (float4((staticSwitch240).rgb , staticSwitch277));
				float4 temp_output_275_0 = ( float4( (( (_Color).rgb * (IN.ase_color).rgb )).xyz , 0.0 ) + appendResult273 );
				

				float Alpha = (temp_output_275_0).w;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
            Name "SceneSelectionPass"
            Tags { "LightMode"="SceneSelectionPass" }

			Cull Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _Emission;
			float4 _EmissionTex_ST;
			float2 _EmissionSpeed;
			float _EmissionSoftness1;
			float _EmissionSoftness2;
			float _DepthSoftness;
			float _Columns;
			float _Rows;
			float _MainSoftnessMin;
			float _MainSoftnessMax;
			float _EmissionSubValue;
			float _FinalEmissionSmoothstepMin;
			float _FinalEmissionSmoothstepMax;
			float _FinalAlphaSmoothstepMin;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _EmissionTex;
			sampler2D _MainTex;


			
			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord1 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float4 texCoord170 = IN.ase_texcoord;
				texCoord170.xy = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_1 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_2 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + uv_EmissionTex);
				float4 smoothstepResult193 = smoothstep( temp_cast_1 , temp_cast_2 , tex2D( _EmissionTex, panner238 ));
				float4 screenPos = IN.ase_texcoord1;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float4 texCoord3 = IN.ase_texcoord;
				texCoord3.xy = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float AnimFrame4 = round( texCoord3.z );
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles98 = columns135 * rows136;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				// Speed of animation
				float fbspeed98 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				// Multiply Offset X by coloffset
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				// Multiply Offset Y by rowoffset
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				// UV Offset
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				// Flipbook UV
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				// *** END Flipbook UV Animation vars ***
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_3 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_4 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_3 , temp_cast_4 , tex2DNode1);
				#ifdef _MAINTEXSMOOTHSTEP_ON
				float4 staticSwitch236 = smoothstepResult233;
				#else
				float4 staticSwitch236 = tex2DNode1;
				#endif
				float4 break152 = staticSwitch236;
				float Frames126 = temp_output_18_0;
				float temp_output_133_0 = ( Frames126 - 1.0 );
				float smoothstepResult23 = smoothstep( temp_output_133_0 , temp_output_133_0 , AnimFrame4);
				float lerp156 = smoothstepResult23;
				float lerpResult20 = lerp( break152.r , break152.g , lerp156);
				float Frames243 = ( Frames126 * 2.0 );
				float temp_output_123_0 = ( Frames243 - 1.0 );
				float smoothstepResult24 = smoothstep( temp_output_123_0 , temp_output_123_0 , AnimFrame4);
				float lerp257 = smoothstepResult24;
				float lerpResult21 = lerp( lerpResult20 , break152.b , lerp257);
				float Frames344 = ( Frames126 * 3.0 );
				float temp_output_124_0 = ( Frames344 - 1.0 );
				float smoothstepResult25 = smoothstep( temp_output_124_0 , temp_output_124_0 , AnimFrame4);
				float lerp358 = smoothstepResult25;
				float lerpResult22 = lerp( lerpResult21 , break152.a , lerp358);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * lerpResult22 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * lerpResult22 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_5 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_5 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch278 = smoothstepResult258;
				#else
				float staticSwitch278 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch278 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch277 = smoothstepResult252;
				#else
				float staticSwitch277 = finalAlpha248;
				#endif
				float4 appendResult273 = (float4((staticSwitch240).rgb , staticSwitch277));
				float4 temp_output_275_0 = ( float4( (( (_Color).rgb * (IN.ase_color).rgb )).xyz , 0.0 ) + appendResult273 );
				

				surfaceDescription.Alpha = (temp_output_275_0).w;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
            Name "ScenePickingPass"
            Tags { "LightMode"="Picking" }

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _Emission;
			float4 _EmissionTex_ST;
			float2 _EmissionSpeed;
			float _EmissionSoftness1;
			float _EmissionSoftness2;
			float _DepthSoftness;
			float _Columns;
			float _Rows;
			float _MainSoftnessMin;
			float _MainSoftnessMax;
			float _EmissionSubValue;
			float _FinalEmissionSmoothstepMin;
			float _FinalEmissionSmoothstepMax;
			float _FinalAlphaSmoothstepMin;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _EmissionTex;
			sampler2D _MainTex;


			
			float4 _SelectionID;


			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord1 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float4 texCoord170 = IN.ase_texcoord;
				texCoord170.xy = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_1 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_2 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + uv_EmissionTex);
				float4 smoothstepResult193 = smoothstep( temp_cast_1 , temp_cast_2 , tex2D( _EmissionTex, panner238 ));
				float4 screenPos = IN.ase_texcoord1;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float4 texCoord3 = IN.ase_texcoord;
				texCoord3.xy = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float AnimFrame4 = round( texCoord3.z );
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles98 = columns135 * rows136;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				// Speed of animation
				float fbspeed98 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				// Multiply Offset X by coloffset
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				// Multiply Offset Y by rowoffset
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				// UV Offset
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				// Flipbook UV
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				// *** END Flipbook UV Animation vars ***
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_3 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_4 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_3 , temp_cast_4 , tex2DNode1);
				#ifdef _MAINTEXSMOOTHSTEP_ON
				float4 staticSwitch236 = smoothstepResult233;
				#else
				float4 staticSwitch236 = tex2DNode1;
				#endif
				float4 break152 = staticSwitch236;
				float Frames126 = temp_output_18_0;
				float temp_output_133_0 = ( Frames126 - 1.0 );
				float smoothstepResult23 = smoothstep( temp_output_133_0 , temp_output_133_0 , AnimFrame4);
				float lerp156 = smoothstepResult23;
				float lerpResult20 = lerp( break152.r , break152.g , lerp156);
				float Frames243 = ( Frames126 * 2.0 );
				float temp_output_123_0 = ( Frames243 - 1.0 );
				float smoothstepResult24 = smoothstep( temp_output_123_0 , temp_output_123_0 , AnimFrame4);
				float lerp257 = smoothstepResult24;
				float lerpResult21 = lerp( lerpResult20 , break152.b , lerp257);
				float Frames344 = ( Frames126 * 3.0 );
				float temp_output_124_0 = ( Frames344 - 1.0 );
				float smoothstepResult25 = smoothstep( temp_output_124_0 , temp_output_124_0 , AnimFrame4);
				float lerp358 = smoothstepResult25;
				float lerpResult22 = lerp( lerpResult21 , break152.a , lerp358);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * lerpResult22 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * lerpResult22 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_5 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_5 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch278 = smoothstepResult258;
				#else
				float staticSwitch278 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch278 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch277 = smoothstepResult252;
				#else
				float staticSwitch277 = finalAlpha248;
				#endif
				float4 appendResult273 = (float4((staticSwitch240).rgb , staticSwitch277));
				float4 temp_output_275_0 = ( float4( (( (_Color).rgb * (IN.ase_color).rgb )).xyz , 0.0 ) + appendResult273 );
				

				surfaceDescription.Alpha = (temp_output_275_0).w;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On


			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _Emission;
			float4 _EmissionTex_ST;
			float2 _EmissionSpeed;
			float _EmissionSoftness1;
			float _EmissionSoftness2;
			float _DepthSoftness;
			float _Columns;
			float _Rows;
			float _MainSoftnessMin;
			float _MainSoftnessMax;
			float _EmissionSubValue;
			float _FinalEmissionSmoothstepMin;
			float _FinalEmissionSmoothstepMax;
			float _FinalAlphaSmoothstepMin;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _EmissionTex;
			sampler2D _MainTex;


			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

				o.clipPos = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float4 texCoord170 = IN.ase_texcoord1;
				texCoord170.xy = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_1 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_2 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord1.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + uv_EmissionTex);
				float4 smoothstepResult193 = smoothstep( temp_cast_1 , temp_cast_2 , tex2D( _EmissionTex, panner238 ));
				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float4 texCoord3 = IN.ase_texcoord1;
				texCoord3.xy = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float AnimFrame4 = round( texCoord3.z );
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles98 = columns135 * rows136;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				// Speed of animation
				float fbspeed98 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				// Multiply Offset X by coloffset
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				// Multiply Offset Y by rowoffset
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				// UV Offset
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				// Flipbook UV
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				// *** END Flipbook UV Animation vars ***
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_3 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_4 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_3 , temp_cast_4 , tex2DNode1);
				#ifdef _MAINTEXSMOOTHSTEP_ON
				float4 staticSwitch236 = smoothstepResult233;
				#else
				float4 staticSwitch236 = tex2DNode1;
				#endif
				float4 break152 = staticSwitch236;
				float Frames126 = temp_output_18_0;
				float temp_output_133_0 = ( Frames126 - 1.0 );
				float smoothstepResult23 = smoothstep( temp_output_133_0 , temp_output_133_0 , AnimFrame4);
				float lerp156 = smoothstepResult23;
				float lerpResult20 = lerp( break152.r , break152.g , lerp156);
				float Frames243 = ( Frames126 * 2.0 );
				float temp_output_123_0 = ( Frames243 - 1.0 );
				float smoothstepResult24 = smoothstep( temp_output_123_0 , temp_output_123_0 , AnimFrame4);
				float lerp257 = smoothstepResult24;
				float lerpResult21 = lerp( lerpResult20 , break152.b , lerp257);
				float Frames344 = ( Frames126 * 3.0 );
				float temp_output_124_0 = ( Frames344 - 1.0 );
				float smoothstepResult25 = smoothstep( temp_output_124_0 , temp_output_124_0 , AnimFrame4);
				float lerp358 = smoothstepResult25;
				float lerpResult22 = lerp( lerpResult21 , break152.a , lerp358);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * lerpResult22 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * lerpResult22 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_5 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_5 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch278 = smoothstepResult258;
				#else
				float staticSwitch278 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch278 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch277 = smoothstepResult252;
				#else
				float staticSwitch277 = finalAlpha248;
				#endif
				float4 appendResult273 = (float4((staticSwitch240).rgb , staticSwitch277));
				float4 temp_output_275_0 = ( float4( (( (_Color).rgb * (IN.ase_color).rgb )).xyz , 0.0 ) + appendResult273 );
				

				surfaceDescription.Alpha = (temp_output_275_0).w;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				float3 normalWS = IN.normalWS;

				return half4(NormalizeNormalPerPixel(normalWS), 0.0);
			}

			ENDHLSL
		}

		
		Pass
		{
			
            Name "DepthNormalsOnly"
            Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma exclude_renderers glcore gles gles3 
			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define ATTRIBUTES_NEED_TEXCOORD1
			#define VARYINGS_NEED_NORMAL_WS
			#define VARYINGS_NEED_TANGENT_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _Emission;
			float4 _EmissionTex_ST;
			float2 _EmissionSpeed;
			float _EmissionSoftness1;
			float _EmissionSoftness2;
			float _DepthSoftness;
			float _Columns;
			float _Rows;
			float _MainSoftnessMin;
			float _MainSoftnessMax;
			float _EmissionSubValue;
			float _FinalEmissionSmoothstepMin;
			float _FinalEmissionSmoothstepMax;
			float _FinalAlphaSmoothstepMin;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _EmissionTex;
			sampler2D _MainTex;


			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

				o.clipPos = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.ase_color;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float4 texCoord170 = IN.ase_texcoord1;
				texCoord170.xy = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_1 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_2 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord1.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + uv_EmissionTex);
				float4 smoothstepResult193 = smoothstep( temp_cast_1 , temp_cast_2 , tex2D( _EmissionTex, panner238 ));
				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float4 texCoord3 = IN.ase_texcoord1;
				texCoord3.xy = IN.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float AnimFrame4 = round( texCoord3.z );
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles98 = columns135 * rows136;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				// Speed of animation
				float fbspeed98 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				// Multiply Offset X by coloffset
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				// Multiply Offset Y by rowoffset
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				// UV Offset
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				// Flipbook UV
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				// *** END Flipbook UV Animation vars ***
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_3 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_4 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_3 , temp_cast_4 , tex2DNode1);
				#ifdef _MAINTEXSMOOTHSTEP_ON
				float4 staticSwitch236 = smoothstepResult233;
				#else
				float4 staticSwitch236 = tex2DNode1;
				#endif
				float4 break152 = staticSwitch236;
				float Frames126 = temp_output_18_0;
				float temp_output_133_0 = ( Frames126 - 1.0 );
				float smoothstepResult23 = smoothstep( temp_output_133_0 , temp_output_133_0 , AnimFrame4);
				float lerp156 = smoothstepResult23;
				float lerpResult20 = lerp( break152.r , break152.g , lerp156);
				float Frames243 = ( Frames126 * 2.0 );
				float temp_output_123_0 = ( Frames243 - 1.0 );
				float smoothstepResult24 = smoothstep( temp_output_123_0 , temp_output_123_0 , AnimFrame4);
				float lerp257 = smoothstepResult24;
				float lerpResult21 = lerp( lerpResult20 , break152.b , lerp257);
				float Frames344 = ( Frames126 * 3.0 );
				float temp_output_124_0 = ( Frames344 - 1.0 );
				float smoothstepResult25 = smoothstep( temp_output_124_0 , temp_output_124_0 , AnimFrame4);
				float lerp358 = smoothstepResult25;
				float lerpResult22 = lerp( lerpResult21 , break152.a , lerp358);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * lerpResult22 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * lerpResult22 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_5 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_5 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch278 = smoothstepResult258;
				#else
				float staticSwitch278 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch278 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch277 = smoothstepResult252;
				#else
				float staticSwitch277 = finalAlpha248;
				#endif
				float4 appendResult273 = (float4((staticSwitch240).rgb , staticSwitch277));
				float4 temp_output_275_0 = ( float4( (( (_Color).rgb * (IN.ase_color).rgb )).xyz , 0.0 ) + appendResult273 );
				

				surfaceDescription.Alpha = (temp_output_275_0).w;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				float3 normalWS = IN.normalWS;

				return half4(NormalizeNormalPerPixel(normalWS), 0.0);
			}

			ENDHLSL
		}
		
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.RangedFloatNode;12;-4219.035,567.627;Inherit;False;Property;_Columns;Columns;1;0;Create;True;0;0;0;False;0;False;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;134;-4202.213,708.7427;Inherit;False;Property;_Rows;Rows;0;0;Create;True;0;0;0;False;0;False;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;136;-3999.213,728.7427;Inherit;False;rows;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;135;-4024.213,606.7427;Inherit;False;columns;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;137;-3715.213,570.7427;Inherit;False;135;columns;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;138;-3742.213,663.7427;Inherit;False;136;rows;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-3960.801,-110.4;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RoundOpNode;122;-3697.72,3.856701;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;-3476.581,586.8773;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;103;-3232.833,548.3247;Inherit;False;ChannelFramesCount;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;4;-3480.801,-33.39998;Inherit;False;AnimFrame;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;104;-3090.28,-45.1772;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;121;-3037.313,135.0355;Inherit;False;103;ChannelFramesCount;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;112;-2755.486,-146.6782;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;16;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;113;-2556.085,-48.1782;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;26;-3001.968,777.5865;Inherit;False;Frames1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;144;-3648.429,-169.1767;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;114;-2383.785,-75.5782;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;-2675.5,-272.1573;Inherit;False;136;rows;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;139;-2704.5,-358.1573;Inherit;False;135;columns;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-2673.201,806.7868;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;204;-2117.219,77.18805;Inherit;True;Property;_MainTex;MainTex;3;0;Create;True;0;0;0;False;0;False;None;32584e99bcab64341b15558b66246c02;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;43;-2517.201,815.7868;Inherit;False;Frames2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCFlipBookUVAnimation;98;-2101.218,-238.2752;Inherit;False;0;0;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;27;-3835.442,1586.618;Inherit;False;26;Frames1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-2651.201,940.7868;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;52;-3798.73,1416.279;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;133;-3603.111,1565.098;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-1843.427,-297.8819;Inherit;True;Property;_Tex;Tex;0;0;Create;True;0;0;0;False;0;False;-1;None;f5a3e0d69c865b5439c9bd0e50d9141a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;234;-1768.528,8.183472;Inherit;False;Property;_MainSoftnessMin;MainSoftnessMin;5;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;-3864.675,1877.818;Inherit;False;43;Frames2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;44;-2423.201,945.7868;Inherit;False;Frames3;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;235;-1773.528,119.1835;Inherit;False;Property;_MainSoftnessMax;MainSoftnessMax;6;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;49;-3848.175,2168.319;Inherit;False;44;Frames3;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;53;-3806.73,1721.279;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;233;-1412.528,-148.8165;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;23;-3449.742,1440.318;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;123;-3597.268,1868.176;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;24;-3394.442,1727.618;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;56;-3234.93,1501.176;Inherit;False;lerp1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-1491.582,968.5979;Inherit;False;Property;_DepthSoftness;DepthSoftness;8;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;124;-3598.558,2111.958;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;54;-3742.73,2011.279;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;236;-1231.147,-248.5517;Inherit;False;Property;_MainTexSmoothstep;MainTexSmoothstep;4;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DepthFade;142;-1253.282,905.098;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;152;-1063.649,-19.47003;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;60;-953.7399,194.5367;Inherit;False;56;lerp1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;57;-3172.53,1765.076;Inherit;False;lerp2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;25;-3408.442,2000.618;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;20;-738.5215,4.716976;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;146;-1005.782,832.337;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;61;-781.7399,300.5367;Inherit;False;57;lerp2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;58;-3093.23,2039.376;Inherit;False;lerp3;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;21;-519.5215,134.717;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;163;-795.183,903.2671;Inherit;False;depthFadeAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;62;-667.7399,397.5367;Inherit;False;58;lerp3;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;164;-393.2097,14.70349;Inherit;False;163;depthFadeAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;127;-1056.864,-476.2369;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;22;-365.0283,290.8066;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;162;-60.55688,113.2626;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;167;-324.7333,-161.2263;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;165;78.87601,24.77582;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;125;-1041.864,-701.2369;Inherit;False;Property;_Color;Color;2;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;166;257.876,23.77582;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;158;-470.7218,-322.6705;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;131;55.12355,-269.4049;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;172;388.4871,-86.409;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;159;458.6583,-204.2462;Inherit;False;Property;_AlphaDissolve;AlphaDissolve;9;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;248;747.5269,-106.4725;Inherit;False;finalAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;237;-1384.438,1345.754;Inherit;False;0;192;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;250;-672.8932,1136.73;Inherit;False;Property;_EmissionSubValue;EmissionSubValue;23;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;249;-690.8932,1056.73;Inherit;False;248;finalAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;271;-1254.033,1573.312;Inherit;False;Property;_EmissionSpeed;EmissionSpeed;13;0;Create;True;0;0;0;False;0;False;0,0;0,-0.45;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;170;-481.7773,864.3997;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;238;-948.0377,1401.354;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;251;-368.8932,1057.73;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;194;-445.8678,1503.202;Inherit;False;Property;_EmissionSoftness2;EmissionSoftness2;15;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;192;-485.8678,1182.202;Inherit;True;Property;_EmissionTex;EmissionTex;12;0;Create;True;0;0;0;False;0;False;-1;None;2140d5caeca76404cadd35cc48f45f10;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;195;-485.8678,1399.202;Inherit;False;Property;_EmissionSoftness1;EmissionSoftness1;14;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;247;-134.3784,1051.624;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;246;45.62158,934.624;Inherit;False;Property;_AlphaEmissionDissolveSub;Alpha Emission Dissolve Sub;24;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;193;-87.8678,1201.202;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;196;379.1322,1038.202;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;197;526.1322,1016.202;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;256;349.4456,327.7385;Inherit;False;Property;_FinalEmissionSmoothstepMin;FinalEmissionSmoothstepMin;21;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;168;-248.219,627.3657;Inherit;False;Property;_Emission;Emission;10;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;7.377211,2.858186,0.6952345,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;257;326.4456,431.7385;Inherit;False;Property;_FinalEmissionSmoothstepMax;FinalEmissionSmoothstepMax;22;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;190;385.2937,786.7416;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;258;696.4457,334.7385;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;171;229.2227,626.3997;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;177;473.4174,561.438;Inherit;False;Property;_EmissionDissolve;EmissionDissolve;11;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;278;855.9118,241.1099;Inherit;False;Property;_FinalEmissionSmoothstep;FinalEmissionSmoothstep;20;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;253;522.1071,72.73;Inherit;False;Property;_FinalAlphaSmoothstepMin;FinalAlphaSmoothstepMin;17;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;255;499.1071,176.73;Inherit;False;Property;_FinalAlphaSmoothstepMax;FinalAlphaSmoothstepMax;18;0;Create;True;0;0;0;False;0;False;1;0.11;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;241;791.9829,579.4604;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;240;891.412,403.424;Inherit;False;Property;_EmissionAlpha;EmissionAlpha;19;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;252;815.1071,83.73;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;154;-459.6545,-651.055;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;155;-409.6545,-467.055;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;274;1144.743,347.8459;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;277;945.9118,-18.89011;Inherit;False;Property;_FinalAlphaSmoothstep;FinalAlphaSmoothstep;16;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;126;-99.86377,-485.2369;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;273;1250.477,68.60117;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;129;157.1362,-411.2369;Inherit;False;True;True;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;199;-656.2374,1252.588;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;173;-167.1115,354.3913;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;174;-475.1115,542.3913;Inherit;False;Property;_AlphaSoftness;AlphaSoftness;7;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;275;1343.683,-40.13361;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;276;752.0867,-498.3344;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PosVertexDataNode;198;-908.2374,1207.588;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;279;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;281;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;282;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;283;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;284;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;285;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;286;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;287;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;288;1681.946,-63.81003;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;280;1861.946,-71.81003;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;Knife/Particle Channel Packed Unlit;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;;0;0;Standard;23;Surface;1;638177632631563352;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Cast Shadows;0;638177632637779110;  Use Shadow Threshold;0;0;Receive Shadows;0;638177632648455010;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;False;True;False;False;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.ComponentMaskNode;289;1523.185,48.01352;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
WireConnection;136;0;134;0
WireConnection;135;0;12;0
WireConnection;122;0;3;3
WireConnection;18;0;137;0
WireConnection;18;1;138;0
WireConnection;103;0;18;0
WireConnection;4;0;122;0
WireConnection;112;0;104;0
WireConnection;112;1;121;0
WireConnection;113;0;112;0
WireConnection;26;0;18;0
WireConnection;144;0;3;0
WireConnection;114;0;113;0
WireConnection;114;1;121;0
WireConnection;40;0;26;0
WireConnection;43;0;40;0
WireConnection;98;0;144;0
WireConnection;98;1;139;0
WireConnection;98;2;140;0
WireConnection;98;4;114;0
WireConnection;41;0;26;0
WireConnection;133;0;27;0
WireConnection;1;0;204;0
WireConnection;1;1;98;0
WireConnection;44;0;41;0
WireConnection;233;0;1;0
WireConnection;233;1;234;0
WireConnection;233;2;235;0
WireConnection;23;0;52;0
WireConnection;23;1;133;0
WireConnection;23;2;133;0
WireConnection;123;0;47;0
WireConnection;24;0;53;0
WireConnection;24;1;123;0
WireConnection;24;2;123;0
WireConnection;56;0;23;0
WireConnection;124;0;49;0
WireConnection;236;1;1;0
WireConnection;236;0;233;0
WireConnection;142;0;143;0
WireConnection;152;0;236;0
WireConnection;57;0;24;0
WireConnection;25;0;54;0
WireConnection;25;1;124;0
WireConnection;25;2;124;0
WireConnection;20;0;152;0
WireConnection;20;1;152;1
WireConnection;20;2;60;0
WireConnection;146;0;142;0
WireConnection;58;0;25;0
WireConnection;21;0;20;0
WireConnection;21;1;152;2
WireConnection;21;2;61;0
WireConnection;163;0;146;0
WireConnection;22;0;21;0
WireConnection;22;1;152;3
WireConnection;22;2;62;0
WireConnection;162;0;164;0
WireConnection;162;1;22;0
WireConnection;167;0;127;4
WireConnection;165;0;162;0
WireConnection;165;1;167;0
WireConnection;166;0;165;0
WireConnection;158;0;125;4
WireConnection;158;1;127;4
WireConnection;131;0;158;0
WireConnection;131;1;164;0
WireConnection;131;2;22;0
WireConnection;172;0;125;4
WireConnection;172;1;166;0
WireConnection;159;1;131;0
WireConnection;159;0;172;0
WireConnection;248;0;159;0
WireConnection;238;0;237;0
WireConnection;238;2;271;0
WireConnection;251;0;249;0
WireConnection;251;1;250;0
WireConnection;192;1;238;0
WireConnection;247;0;170;4
WireConnection;247;1;251;0
WireConnection;246;1;170;4
WireConnection;246;0;247;0
WireConnection;193;0;192;0
WireConnection;193;1;195;0
WireConnection;193;2;194;0
WireConnection;196;0;193;0
WireConnection;196;1;246;0
WireConnection;197;0;196;0
WireConnection;190;0;168;0
WireConnection;190;1;197;0
WireConnection;258;0;159;0
WireConnection;258;1;256;0
WireConnection;258;2;257;0
WireConnection;171;0;168;0
WireConnection;171;1;170;4
WireConnection;177;1;171;0
WireConnection;177;0;190;0
WireConnection;278;1;159;0
WireConnection;278;0;258;0
WireConnection;241;0;278;0
WireConnection;241;1;177;0
WireConnection;240;1;177;0
WireConnection;240;0;241;0
WireConnection;252;0;159;0
WireConnection;252;1;253;0
WireConnection;252;2;255;0
WireConnection;154;0;125;0
WireConnection;155;0;127;0
WireConnection;274;0;240;0
WireConnection;277;1;248;0
WireConnection;277;0;252;0
WireConnection;126;0;154;0
WireConnection;126;1;155;0
WireConnection;273;0;274;0
WireConnection;273;3;277;0
WireConnection;129;0;126;0
WireConnection;199;0;198;1
WireConnection;199;1;198;3
WireConnection;173;0;22;0
WireConnection;173;2;174;0
WireConnection;275;0;129;0
WireConnection;275;1;273;0
WireConnection;276;0;168;0
WireConnection;276;1;22;0
WireConnection;280;2;275;0
WireConnection;280;3;289;0
WireConnection;289;0;275;0
ASEEND*/
//CHKSM=91A4F0C740FD5F7DF699E870D3B5FF196FAE6694
