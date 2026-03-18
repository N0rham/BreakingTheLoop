// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Knife/Particle Channel Packed"
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
		_AlphaSoftness("AlphaSoftness", Range( 0 , 1)) = 0
		_DepthSoftness("DepthSoftness", Float) = 1
		[Toggle(_ALPHADISSOLVE_ON)] _AlphaDissolve("AlphaDissolve", Float) = 0
		[HDR]_Emission("Emission", Color) = (0,0,0,0)
		[Toggle(_EMISSIONDISSOLVE_ON)] _EmissionDissolve("EmissionDissolve", Float) = 0
		_EmissionTex("EmissionTex", 2D) = "white" {}
		_EmissionSoftness1("EmissionSoftness1", Range( 0 , 1)) = 0
		_EmissionSoftness2("EmissionSoftness2", Range( 0 , 1)) = 0
		[Toggle(_FINALALPHASMOOTHSTEP_ON)] _FinalAlphaSmoothstep("FinalAlphaSmoothstep", Float) = 0
		_FinalAlphaSmoothstepMin("FinalAlphaSmoothstepMin", Range( 0 , 1)) = 0
		_FinalAlphaSmoothstepMax("FinalAlphaSmoothstepMax", Range( 0 , 1)) = 1
		[Toggle(_EMISSIONALPHA_ON)] _EmissionAlpha("EmissionAlpha", Float) = 0
		[Toggle(_FINALEMISSIONSMOOTHSTEP_ON)] _FinalEmissionSmoothstep("FinalEmissionSmoothstep", Float) = 0
		_FinalEmissionSmoothstepMin("FinalEmissionSmoothstepMin", Range( 0 , 1)) = 0
		_FinalEmissionSmoothstepMax("FinalEmissionSmoothstepMax", Range( 0 , 1)) = 1
		[Toggle(_NORMALMAPENABLED_ON)] _NormalMapEnabled("Normal Map Enabled", Float) = 0
		_NormalMap("NormalMap", 2D) = "bump" {}
		_NormalScale("NormalScale", Float) = 0
		_EmissionSubValue("EmissionSubValue", Range( 0 , 1)) = 0
		[Toggle(_ALPHAEMISSIONDISSOLVESUB_ON)] _AlphaEmissionDissolveSub("Alpha Emission Dissolve Sub", Float) = 0
		_EmissionSpeed("EmissionSpeed", Vector) = (0,0,0,0)
		[Toggle(_ELIMINATEEMISSIONROTATION_ON)] _EliminateEmissionRotation("EliminateEmissionRotation", Float) = 0
		[ASEEnd][Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Float) = 2


		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector][ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[HideInInspector][ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Lit" }

		Cull [_CullMode]
		ZWrite Off
		ZTest LEqual
		Offset 0 , 0
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
			Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _CLUSTERED_RENDERING
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_FRAG_COLOR
			#define ASE_NEEDS_FRAG_SCREEN_POSITION
			#pragma shader_feature _NORMALMAPENABLED_ON
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ELIMINATEEMISSIONROTATION_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					float4 screenPos : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_color : COLOR;
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_texcoord9 : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;
			sampler2D _EmissionTex;
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_color = v.ase_color;
				o.ase_texcoord8 = v.texcoord;
				o.ase_texcoord9.xy = v.texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord9.zw = 0;

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
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord;
					o.lightmapUVOrVertexSH.xy = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );

				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif

				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;

				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(positionCS);
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

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
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
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
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
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

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag ( VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					float4 ScreenPos = IN.screenPos;
				#endif

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 texCoord232 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float4 texCoord3 = IN.ase_texcoord8;
				texCoord3.xy = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float AnimFrame4 = round( texCoord3.z );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles223 = ( columns135 * 2.0 ) * ( rows136 * 2.0 );
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset223 = 1.0f / ( columns135 * 2.0 );
				float fbrowsoffset223 = 1.0f / ( rows136 * 2.0 );
				// Speed of animation
				float fbspeed223 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling223 = float2(fbcolsoffset223, fbrowsoffset223);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex223 = round( fmod( fbspeed223 + AnimFrame4, fbtotaltiles223) );
				fbcurrenttileindex223 += ( fbcurrenttileindex223 < 0) ? fbtotaltiles223 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox223 = round ( fmod ( fbcurrenttileindex223, ( columns135 * 2.0 ) ) );
				// Multiply Offset X by coloffset
				float fboffsetx223 = fblinearindextox223 * fbcolsoffset223;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy223 = round( fmod( ( fbcurrenttileindex223 - fblinearindextox223 ) / ( columns135 * 2.0 ), ( rows136 * 2.0 ) ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy223 = (int)(( rows136 * 2.0 )-1) - fblinearindextoy223;
				// Multiply Offset Y by rowoffset
				float fboffsety223 = fblinearindextoy223 * fbrowsoffset223;
				// UV Offset
				float2 fboffset223 = float2(fboffsetx223, fboffsety223);
				// Flipbook UV
				half2 fbuv223 = texCoord232 * fbtiling223 + fboffset223;
				// *** END Flipbook UV Animation vars ***
				float3 unpack222 = UnpackNormalScale( tex2D( _NormalMap, fbuv223 ), _NormalScale );
				unpack222.z = lerp( 1, unpack222.z, saturate(_NormalScale) );
				#ifdef _NORMALMAPENABLED_ON
				float3 staticSwitch221 = unpack222;
				#else
				float3 staticSwitch221 = float3(0,0,1);
				#endif
				float3 normals206 = staticSwitch221;
				
				float4 texCoord170 = IN.ase_texcoord8;
				texCoord170.xy = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_0 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_1 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord8.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 texCoord278 = IN.ase_texcoord9.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult283 = (float2(texCoord278.y , texCoord278.y));
				float cos277 = cos( texCoord278.x );
				float sin277 = sin( texCoord278.x );
				float2 rotator277 = mul( ( uv_EmissionTex + appendResult283 ) - float2( 0.5,0.5 ) , float2x2( cos277 , -sin277 , sin277 , cos277 )) + float2( 0.5,0.5 );
				#ifdef _ELIMINATEEMISSIONROTATION_ON
				float2 staticSwitch279 = rotator277;
				#else
				float2 staticSwitch279 = uv_EmissionTex;
				#endif
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + staticSwitch279);
				float4 smoothstepResult193 = smoothstep( temp_cast_0 , temp_cast_1 , tex2D( _EmissionTex, panner238 ));
				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				float fbtotaltiles98 = columns135 * rows136;
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				float fbspeed98 = _Time[ 1 ] * 0.0;
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_2 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_3 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_2 , temp_cast_3 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_4 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_4 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch276 = smoothstepResult258;
				#else
				float staticSwitch276 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch276 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				float3 BaseColor = (( (_Color).rgb * (IN.ase_color).rgb )).xyz;
				float3 Normal = normals206;
				float3 Emission = staticSwitch240.rgb;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = 0.5;
				float Occlusion = 1;
				float Alpha = staticSwitch275;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif

				#ifdef _CLEARCOAT
					float CoatMask = 0;
					float CoatSmoothness = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;

				#ifdef _NORMALMAP
						#if _NORMAL_DROPOFF_TS
							inputData.normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, WorldNormal));
						#elif _NORMAL_DROPOFF_OS
							inputData.normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							inputData.normalWS = Normal;
						#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					inputData.shadowCoord = ShadowCoords;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
				#else
					inputData.shadowCoord = float4(0, 0, 0, 0);
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif
					inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
				#else
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
					#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				SurfaceData surfaceData;
				surfaceData.albedo              = BaseColor;
				surfaceData.metallic            = saturate(Metallic);
				surfaceData.specular            = Specular;
				surfaceData.smoothness          = saturate(Smoothness),
				surfaceData.occlusion           = Occlusion,
				surfaceData.emission            = Emission,
				surfaceData.alpha               = saturate(Alpha);
				surfaceData.normalTS            = Normal;
				surfaceData.clearCoatMask       = 0;
				surfaceData.clearCoatSmoothness = 1;

				#ifdef _CLEARCOAT
					surfaceData.clearCoatMask       = saturate(CoatMask);
					surfaceData.clearCoatSmoothness = saturate(CoatSmoothness);
				#endif

				#ifdef _DBUFFER
					ApplyDecalToSurfaceData(IN.clipPos, surfaceData, inputData);
				#endif

				half4 color = UniversalFragmentPBR( inputData, surfaceData);

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
					half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
					color.rgb += BaseColor * mainTransmission;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
							color.rgb += BaseColor * transmission;
						}
					#endif
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );

					half3 mainLightDir = mainLight.direction + inputData.normalWS * normal;
					half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), scattering );
					half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
					color.rgb += BaseColor * mainTranslucency * strength;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 lightDir = light.direction + inputData.normalWS * normal;
							half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );
							half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
							color.rgb += BaseColor * translucency * strength;
						}
					#endif
				}
				#endif

				#ifdef ASE_REFRACTION
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal,0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON


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
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
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

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = clipPos;

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

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
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

				float4 screenPos = IN.ase_texcoord2;
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
				float4 temp_cast_0 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_1 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_0 , temp_cast_1 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				float Alpha = staticSwitch275;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
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

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON


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
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
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

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
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

				float4 screenPos = IN.ase_texcoord2;
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
				float4 temp_cast_0 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_1 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_0 , temp_cast_1 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				float Alpha = staticSwitch275;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature EDITOR_VISUALIZATION

			#define SHADERPASS SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ELIMINATEEMISSIONROTATION_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
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
				#ifdef EDITOR_VISUALIZATION
					float4 VizUV : TEXCOORD2;
					float4 LightCoord : TEXCOORD3;
				#endif
				float4 ase_color : COLOR;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _EmissionTex;
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord6 = screenPos;
				
				o.ase_color = v.ase_color;
				o.ase_texcoord4 = v.texcoord0;
				o.ase_texcoord5.xy = v.texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.zw = 0;

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

				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );

				#ifdef EDITOR_VISUALIZATION
					float2 VizUV = 0;
					float4 LightCoord = 0;
					UnityEditorVizData(v.vertex.xyz, v.texcoord0.xy, v.texcoord1.xy, v.texcoord2.xy, VizUV, LightCoord);
					o.VizUV = float4(VizUV, 0, 0);
					o.LightCoord = LightCoord;
				#endif

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
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

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
				o.texcoord0 = v.texcoord0;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
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
				o.texcoord0 = patch[0].texcoord0 * bary.x + patch[1].texcoord0 * bary.y + patch[2].texcoord0 * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
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

				float4 texCoord170 = IN.ase_texcoord4;
				texCoord170.xy = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_0 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_1 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord4.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 texCoord278 = IN.ase_texcoord5.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult283 = (float2(texCoord278.y , texCoord278.y));
				float cos277 = cos( texCoord278.x );
				float sin277 = sin( texCoord278.x );
				float2 rotator277 = mul( ( uv_EmissionTex + appendResult283 ) - float2( 0.5,0.5 ) , float2x2( cos277 , -sin277 , sin277 , cos277 )) + float2( 0.5,0.5 );
				#ifdef _ELIMINATEEMISSIONROTATION_ON
				float2 staticSwitch279 = rotator277;
				#else
				float2 staticSwitch279 = uv_EmissionTex;
				#endif
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + staticSwitch279);
				float4 smoothstepResult193 = smoothstep( temp_cast_0 , temp_cast_1 , tex2D( _EmissionTex, panner238 ));
				float4 screenPos = IN.ase_texcoord6;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float4 texCoord3 = IN.ase_texcoord4;
				texCoord3.xy = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
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
				float4 temp_cast_2 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_3 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_2 , temp_cast_3 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_4 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_4 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch276 = smoothstepResult258;
				#else
				float staticSwitch276 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch276 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				float3 BaseColor = (( (_Color).rgb * (IN.ase_color).rgb )).xyz;
				float3 Emission = staticSwitch240.rgb;
				float Alpha = staticSwitch275;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = BaseColor;
				metaInput.Emission = Emission;
				#ifdef EDITOR_VISUALIZATION
					metaInput.VizUV = IN.VizUV.xy;
					metaInput.LightCoord = IN.LightCoord;
				#endif

				return UnityMetaFragment(metaInput);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON


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
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
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

			half4 frag(VertexOutput IN  ) : SV_TARGET
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

				float4 screenPos = IN.ase_texcoord2;
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
				float4 temp_cast_0 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_1 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_0 , temp_cast_1 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				float3 BaseColor = (( (_Color).rgb * (IN.ase_color).rgb )).xyz;
				float Alpha = staticSwitch275;
				float AlphaClipThreshold = 0.5;

				half4 color = half4(BaseColor, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			Blend One Zero
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _NORMALMAPENABLED_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
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
				float3 worldNormal : TEXCOORD2;
				float4 worldTangent : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord5 = screenPos;
				
				o.ase_texcoord4 = v.ase_texcoord;
				o.ase_color = v.ase_color;
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
				float3 normalWS = TransformObjectToWorldNormal( v.ase_normal );
				float4 tangentWS = float4(TransformObjectToWorldDir( v.ase_tangent.xyz), v.ase_tangent.w);
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.worldNormal = normalWS;
				o.worldTangent = tangentWS;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

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
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
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
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
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

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float3 WorldNormal = IN.worldNormal;
				float4 WorldTangent = IN.worldTangent;

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 texCoord232 = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float4 texCoord3 = IN.ase_texcoord4;
				texCoord3.xy = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float AnimFrame4 = round( texCoord3.z );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles223 = ( columns135 * 2.0 ) * ( rows136 * 2.0 );
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset223 = 1.0f / ( columns135 * 2.0 );
				float fbrowsoffset223 = 1.0f / ( rows136 * 2.0 );
				// Speed of animation
				float fbspeed223 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling223 = float2(fbcolsoffset223, fbrowsoffset223);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex223 = round( fmod( fbspeed223 + AnimFrame4, fbtotaltiles223) );
				fbcurrenttileindex223 += ( fbcurrenttileindex223 < 0) ? fbtotaltiles223 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox223 = round ( fmod ( fbcurrenttileindex223, ( columns135 * 2.0 ) ) );
				// Multiply Offset X by coloffset
				float fboffsetx223 = fblinearindextox223 * fbcolsoffset223;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy223 = round( fmod( ( fbcurrenttileindex223 - fblinearindextox223 ) / ( columns135 * 2.0 ), ( rows136 * 2.0 ) ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy223 = (int)(( rows136 * 2.0 )-1) - fblinearindextoy223;
				// Multiply Offset Y by rowoffset
				float fboffsety223 = fblinearindextoy223 * fbrowsoffset223;
				// UV Offset
				float2 fboffset223 = float2(fboffsetx223, fboffsety223);
				// Flipbook UV
				half2 fbuv223 = texCoord232 * fbtiling223 + fboffset223;
				// *** END Flipbook UV Animation vars ***
				float3 unpack222 = UnpackNormalScale( tex2D( _NormalMap, fbuv223 ), _NormalScale );
				unpack222.z = lerp( 1, unpack222.z, saturate(_NormalScale) );
				#ifdef _NORMALMAPENABLED_ON
				float3 staticSwitch221 = unpack222;
				#else
				float3 staticSwitch221 = float3(0,0,1);
				#endif
				float3 normals206 = staticSwitch221;
				
				float4 screenPos = IN.ase_texcoord5;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				float fbtotaltiles98 = columns135 * rows136;
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				float fbspeed98 = _Time[ 1 ] * 0.0;
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_0 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_1 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_0 , temp_cast_1 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				float3 Normal = normals206;
				float Alpha = staticSwitch275;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(WorldNormal);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					return half4(packedNormalWS, 0.0);
				#else
					#if defined(_NORMALMAP)
						#if _NORMAL_DROPOFF_TS
							float crossSign = (WorldTangent.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
							float3 bitangent = crossSign * cross(WorldNormal.xyz, WorldTangent.xyz);
							float3 normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent.xyz, bitangent, WorldNormal.xyz));
						#elif _NORMAL_DROPOFF_OS
							float3 normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							float3 normalWS = Normal;
						#endif
					#else
						float3 normalWS = WorldNormal;
					#endif
					return half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "GBuffer"
			Tags { "LightMode"="UniversalGBuffer" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_GBUFFER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_FRAG_COLOR
			#define ASE_NEEDS_FRAG_SCREEN_POSITION
			#pragma shader_feature _NORMALMAPENABLED_ON
			#pragma shader_feature _EMISSIONALPHA_ON
			#pragma shader_feature _EMISSIONDISSOLVE_ON
			#pragma shader_feature _ELIMINATEEMISSIONROTATION_ON
			#pragma shader_feature _ALPHAEMISSIONDISSOLVESUB_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON
			#pragma shader_feature _FINALEMISSIONSMOOTHSTEP_ON
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
				float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_color : COLOR;
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_texcoord9 : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;
			sampler2D _EmissionTex;
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GBufferOutput.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_color = v.ase_color;
				o.ase_texcoord8 = v.texcoord;
				o.ase_texcoord9.xy = v.texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord9.zw = 0;
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
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV(v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy);
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH(normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz);
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord;
					o.lightmapUVOrVertexSH.xy = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );

				o.fogFactorAndVertexLight = half4(0, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

					o.clipPos = positionCS;

				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(positionCS);
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

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
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
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
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
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

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			FragmentOutput frag ( VertexOutput IN
								#ifdef ASE_DEPTH_WRITE_ON
								,out float outputDepth : ASE_SV_DEPTH
								#endif
								 )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					float4 ScreenPos = IN.screenPos;
				#endif

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#else
					ShadowCoords = float4(0, 0, 0, 0);
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 texCoord232 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float columns135 = _Columns;
				float rows136 = _Rows;
				float4 texCoord3 = IN.ase_texcoord8;
				texCoord3.xy = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float AnimFrame4 = round( texCoord3.z );
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles223 = ( columns135 * 2.0 ) * ( rows136 * 2.0 );
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset223 = 1.0f / ( columns135 * 2.0 );
				float fbrowsoffset223 = 1.0f / ( rows136 * 2.0 );
				// Speed of animation
				float fbspeed223 = _Time[ 1 ] * 0.0;
				// UV Tiling (col and row offset)
				float2 fbtiling223 = float2(fbcolsoffset223, fbrowsoffset223);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex223 = round( fmod( fbspeed223 + AnimFrame4, fbtotaltiles223) );
				fbcurrenttileindex223 += ( fbcurrenttileindex223 < 0) ? fbtotaltiles223 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox223 = round ( fmod ( fbcurrenttileindex223, ( columns135 * 2.0 ) ) );
				// Multiply Offset X by coloffset
				float fboffsetx223 = fblinearindextox223 * fbcolsoffset223;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy223 = round( fmod( ( fbcurrenttileindex223 - fblinearindextox223 ) / ( columns135 * 2.0 ), ( rows136 * 2.0 ) ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy223 = (int)(( rows136 * 2.0 )-1) - fblinearindextoy223;
				// Multiply Offset Y by rowoffset
				float fboffsety223 = fblinearindextoy223 * fbrowsoffset223;
				// UV Offset
				float2 fboffset223 = float2(fboffsetx223, fboffsety223);
				// Flipbook UV
				half2 fbuv223 = texCoord232 * fbtiling223 + fboffset223;
				// *** END Flipbook UV Animation vars ***
				float3 unpack222 = UnpackNormalScale( tex2D( _NormalMap, fbuv223 ), _NormalScale );
				unpack222.z = lerp( 1, unpack222.z, saturate(_NormalScale) );
				#ifdef _NORMALMAPENABLED_ON
				float3 staticSwitch221 = unpack222;
				#else
				float3 staticSwitch221 = float3(0,0,1);
				#endif
				float3 normals206 = staticSwitch221;
				
				float4 texCoord170 = IN.ase_texcoord8;
				texCoord170.xy = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_cast_0 = (_EmissionSoftness1).xxxx;
				float4 temp_cast_1 = (_EmissionSoftness2).xxxx;
				float2 uv_EmissionTex = IN.ase_texcoord8.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw;
				float2 texCoord278 = IN.ase_texcoord9.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult283 = (float2(texCoord278.y , texCoord278.y));
				float cos277 = cos( texCoord278.x );
				float sin277 = sin( texCoord278.x );
				float2 rotator277 = mul( ( uv_EmissionTex + appendResult283 ) - float2( 0.5,0.5 ) , float2x2( cos277 , -sin277 , sin277 , cos277 )) + float2( 0.5,0.5 );
				#ifdef _ELIMINATEEMISSIONROTATION_ON
				float2 staticSwitch279 = rotator277;
				#else
				float2 staticSwitch279 = uv_EmissionTex;
				#endif
				float2 panner238 = ( 1.0 * _Time.y * _EmissionSpeed + staticSwitch279);
				float4 smoothstepResult193 = smoothstep( temp_cast_0 , temp_cast_1 , tex2D( _EmissionTex, panner238 ));
				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth142 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth142 = abs( ( screenDepth142 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _DepthSoftness ) );
				float clampResult146 = clamp( distanceDepth142 , 0.0 , 1.0 );
				float depthFadeAlpha163 = clampResult146;
				float temp_output_18_0 = ( columns135 * rows136 );
				float ChannelFramesCount103 = temp_output_18_0;
				float fbtotaltiles98 = columns135 * rows136;
				float fbcolsoffset98 = 1.0f / columns135;
				float fbrowsoffset98 = 1.0f / rows136;
				float fbspeed98 = _Time[ 1 ] * 0.0;
				float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
				float fbcurrenttileindex98 = round( fmod( fbspeed98 + ( frac( ( AnimFrame4 / ChannelFramesCount103 ) ) * ChannelFramesCount103 ), fbtotaltiles98) );
				fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
				float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, columns135 ) );
				float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
				float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / columns135, rows136 ) );
				fblinearindextoy98 = (int)(rows136-1) - fblinearindextoy98;
				float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
				float2 fboffset98 = float2(fboffsetx98, fboffsety98);
				half2 fbuv98 = (texCoord3).xy * fbtiling98 + fboffset98;
				float4 tex2DNode1 = tex2D( _MainTex, fbuv98 );
				float4 temp_cast_2 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_3 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_2 , temp_cast_3 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				#ifdef _ALPHAEMISSIONDISSOLVESUB_ON
				float staticSwitch246 = ( texCoord170.w - ( finalAlpha248 * _EmissionSubValue ) );
				#else
				float staticSwitch246 = texCoord170.w;
				#endif
				float4 temp_cast_4 = (staticSwitch246).xxxx;
				float4 clampResult197 = clamp( ( smoothstepResult193 - temp_cast_4 ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
				#ifdef _EMISSIONDISSOLVE_ON
				float4 staticSwitch177 = ( _Emission * clampResult197 );
				#else
				float4 staticSwitch177 = ( _Emission * texCoord170.w );
				#endif
				float smoothstepResult258 = smoothstep( _FinalEmissionSmoothstepMin , _FinalEmissionSmoothstepMax , staticSwitch159);
				#ifdef _FINALEMISSIONSMOOTHSTEP_ON
				float staticSwitch276 = smoothstepResult258;
				#else
				float staticSwitch276 = staticSwitch159;
				#endif
				#ifdef _EMISSIONALPHA_ON
				float4 staticSwitch240 = ( staticSwitch276 * staticSwitch177 );
				#else
				float4 staticSwitch240 = staticSwitch177;
				#endif
				
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				float3 BaseColor = (( (_Color).rgb * (IN.ase_color).rgb )).xyz;
				float3 Normal = normals206;
				float3 Emission = staticSwitch240.rgb;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = 0.5;
				float Occlusion = 1;
				float Alpha = staticSwitch275;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.positionCS = IN.clipPos;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
						inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
						inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
						inputData.normalWS = Normal;
					#endif
				#else
					inputData.normalWS = WorldNormal;
				#endif

				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				inputData.viewDirectionWS = SafeNormalize( WorldViewDirection );

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#else
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
					#else
						inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
					#endif
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
						#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				#ifdef _DBUFFER
					ApplyDecal(IN.clipPos,
						BaseColor,
						Specular,
						inputData.normalWS,
						Metallic,
						Occlusion,
						Smoothness);
				#endif

				BRDFData brdfData;
				InitializeBRDFData
				(BaseColor, Metallic, Specular, Smoothness, Alpha, brdfData);

				Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
				half4 color;
				MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
				color.rgb = GlobalIllumination(brdfData, inputData.bakedGI, Occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
				color.a = Alpha;

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return BRDFDataToGbuffer(brdfData, inputData, Smoothness, Emission + color.rgb, Occlusion);
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#define SCENESELECTIONPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON


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
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
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
				o.ase_texcoord = screenPos;
				
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

				float4 screenPos = IN.ase_texcoord;
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
				float4 temp_cast_0 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_1 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_0 , temp_cast_1 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				surfaceDescription.Alpha = staticSwitch275;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _EMISSION
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 120108
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

		    #define SCENEPICKINGPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature _FINALALPHASMOOTHSTEP_ON
			#pragma shader_feature _ALPHADISSOLVE_ON
			#pragma shader_feature _MAINTEXSMOOTHSTEP_ON


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
			float4 _EmissionTex_ST;
			float4 _Color;
			float4 _Emission;
			float2 _EmissionSpeed;
			float _FinalEmissionSmoothstepMax;
			float _FinalEmissionSmoothstepMin;
			float _EmissionSubValue;
			float _MainSoftnessMax;
			float _MainSoftnessMin;
			float _AlphaSoftness;
			float _CullMode;
			float _FinalAlphaSmoothstepMin;
			float _EmissionSoftness2;
			float _EmissionSoftness1;
			float _NormalScale;
			float _Rows;
			float _Columns;
			float _DepthSoftness;
			float _FinalAlphaSmoothstepMax;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif
			sampler2D _MainTex;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
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
				o.ase_texcoord = screenPos;
				
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

				float4 screenPos = IN.ase_texcoord;
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
				float4 temp_cast_0 = (_MainSoftnessMin).xxxx;
				float4 temp_cast_1 = (_MainSoftnessMax).xxxx;
				float4 smoothstepResult233 = smoothstep( temp_cast_0 , temp_cast_1 , tex2DNode1);
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
				float smoothstepResult173 = smoothstep( 0.0 , _AlphaSoftness , lerpResult22);
				float clampResult166 = clamp( ( ( depthFadeAlpha163 * smoothstepResult173 ) - ( 1.0 - IN.ase_color.a ) ) , 0.0 , 1.0 );
				#ifdef _ALPHADISSOLVE_ON
				float staticSwitch159 = ( _Color.a * clampResult166 );
				#else
				float staticSwitch159 = ( ( _Color.a * IN.ase_color.a ) * depthFadeAlpha163 * smoothstepResult173 );
				#endif
				float finalAlpha248 = staticSwitch159;
				float smoothstepResult252 = smoothstep( _FinalAlphaSmoothstepMin , _FinalAlphaSmoothstepMax , staticSwitch159);
				#ifdef _FINALALPHASMOOTHSTEP_ON
				float staticSwitch275 = smoothstepResult252;
				#else
				float staticSwitch275 = finalAlpha248;
				#endif
				

				surfaceDescription.Alpha = staticSwitch275;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
						clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}
		
	}
	
	CustomEditor "UnityEditor.ShaderGraphLitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.RangedFloatNode;134;-4202.213,708.7427;Inherit;False;Property;_Rows;Rows;0;0;Create;True;0;0;0;False;0;False;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-4219.035,567.627;Inherit;False;Property;_Columns;Columns;1;0;Create;True;0;0;0;False;0;False;4;8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;135;-4024.213,606.7427;Inherit;False;columns;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;136;-3999.213,728.7427;Inherit;False;rows;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-3960.801,-110.4;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;138;-3742.213,663.7427;Inherit;False;136;rows;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;137;-3715.213,570.7427;Inherit;False;135;columns;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;-3476.581,586.8773;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;122;-3697.72,3.856701;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;4;-3480.801,-33.39998;Inherit;False;AnimFrame;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;103;-3232.833,548.3247;Inherit;False;ChannelFramesCount;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;121;-3037.313,135.0355;Inherit;False;103;ChannelFramesCount;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;104;-3090.28,-45.1772;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;112;-2755.486,-146.6782;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;16;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;113;-2556.085,-48.1782;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;26;-3001.968,777.5865;Inherit;False;Frames1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;114;-2383.785,-75.5782;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;-2675.5,-272.1573;Inherit;False;136;rows;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;139;-2704.5,-358.1573;Inherit;False;135;columns;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;144;-3648.429,-169.1767;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-2673.201,806.7868;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;204;-2117.219,77.18805;Inherit;True;Property;_MainTex;MainTex;3;0;Create;True;0;0;0;False;0;False;None;57aa161cd62747745b87629675b16137;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.GetLocalVarNode;27;-3835.442,1586.618;Inherit;False;26;Frames1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCFlipBookUVAnimation;98;-2101.218,-238.2752;Inherit;False;0;0;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-2651.201,940.7868;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;43;-2517.201,815.7868;Inherit;False;Frames2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-1843.427,-297.8819;Inherit;True;Property;_Tex;Tex;0;0;Create;True;0;0;0;False;0;False;-1;None;f5a3e0d69c865b5439c9bd0e50d9141a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;234;-1540.528,8.183472;Inherit;False;Property;_MainSoftnessMin;MainSoftnessMin;5;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;-3864.675,1877.818;Inherit;False;43;Frames2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;133;-3603.111,1565.098;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;44;-2423.201,945.7868;Inherit;False;Frames3;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;235;-1476.528,82.18347;Inherit;False;Property;_MainSoftnessMax;MainSoftnessMax;6;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;52;-3798.73,1416.279;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;23;-3449.742,1440.318;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;123;-3597.268,1868.176;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;53;-3806.73,1721.279;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;49;-3848.175,2168.319;Inherit;False;44;Frames3;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;233;-1323.528,-153.8165;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;54;-3742.73,2011.279;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;124;-3598.558,2111.958;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;24;-3394.442,1727.618;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;236;-1274.528,-246.8165;Inherit;False;Property;_MainTexSmoothstep;MainTexSmoothstep;4;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;56;-3234.93,1501.176;Inherit;False;lerp1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;152;-1063.649,-19.47003;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RegisterLocalVarNode;57;-3172.53,1765.076;Inherit;False;lerp2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-1491.582,968.5979;Inherit;False;Property;_DepthSoftness;DepthSoftness;8;0;Create;True;0;0;0;False;0;False;1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;25;-3408.442,2000.618;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;60;-953.7399,194.5367;Inherit;False;56;lerp1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;20;-738.5215,4.716976;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;58;-3093.23,2039.376;Inherit;False;lerp3;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;61;-781.7399,300.5367;Inherit;False;57;lerp2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DepthFade;142;-1253.282,905.098;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;146;-1005.782,832.337;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;21;-519.5215,134.717;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;62;-667.7399,397.5367;Inherit;False;58;lerp3;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;174;-475.1115,542.3913;Inherit;False;Property;_AlphaSoftness;AlphaSoftness;7;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;22;-365.0283,290.8066;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;163;-795.183,903.2671;Inherit;False;depthFadeAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;164;-393.2097,14.70349;Inherit;False;163;depthFadeAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;173;-167.1115,354.3913;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;127;-1056.864,-476.2369;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;167;-324.7333,-161.2263;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;162;-60.55688,113.2626;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;165;78.87601,24.77582;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;125;-1041.864,-701.2369;Inherit;False;Property;_Color;Color;2;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;158;-470.7218,-322.6705;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;166;257.876,23.77582;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;278;-2461.589,1584.963;Inherit;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;172;388.4871,-86.409;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;131;55.12355,-269.4049;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;283;-2045.836,1514.259;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;237;-2277.438,1271.754;Inherit;False;0;192;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;281;-1878.836,1405.259;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;159;484.6583,-221.2462;Inherit;False;Property;_AlphaDissolve;AlphaDissolve;9;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;248;775.607,-53.26995;Inherit;False;finalAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;277;-1604.589,1582.963;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;279;-1448.589,1399.963;Inherit;False;Property;_EliminateEmissionRotation;EliminateEmissionRotation;28;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;250;-672.8932,1136.73;Inherit;False;Property;_EmissionSubValue;EmissionSubValue;25;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;249;-690.8932,1056.73;Inherit;False;248;finalAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;271;-1254.033,1573.312;Inherit;False;Property;_EmissionSpeed;EmissionSpeed;27;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;238;-948.0377,1401.354;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;251;-368.8932,1057.73;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;170;-481.7773,864.3997;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;247;-134.3784,1051.624;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;194;-445.8678,1503.202;Inherit;False;Property;_EmissionSoftness2;EmissionSoftness2;14;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;192;-485.8678,1182.202;Inherit;True;Property;_EmissionTex;EmissionTex;12;0;Create;True;0;0;0;False;0;False;-1;None;2140d5caeca76404cadd35cc48f45f10;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;195;-485.8678,1399.202;Inherit;False;Property;_EmissionSoftness1;EmissionSoftness1;13;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;224;-2453.211,1961.536;Inherit;False;135;columns;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;246;45.62158,934.624;Inherit;False;Property;_AlphaEmissionDissolveSub;Alpha Emission Dissolve Sub;26;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;193;-87.8678,1201.202;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;225;-2447.702,2119.007;Inherit;False;136;rows;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;226;-2163.839,1965.316;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;228;-2080.336,2303.065;Inherit;False;4;AnimFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;196;379.1322,1038.202;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;227;-2156.839,2122.316;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;232;-2247.079,1790.732;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;168;-248.219,627.3657;Inherit;False;Property;_Emission;Emission;10;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;170.1817,63.80706,13.64665,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;257;156.8456,465.3385;Inherit;False;Property;_FinalEmissionSmoothstepMax;FinalEmissionSmoothstepMax;21;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;197;526.1322,1016.202;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;230;-1519.603,2324.986;Inherit;False;Property;_NormalScale;NormalScale;24;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;256;179.8456,361.3385;Inherit;False;Property;_FinalEmissionSmoothstepMin;FinalEmissionSmoothstepMin;20;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCFlipBookUVAnimation;223;-1626.185,2094.693;Inherit;False;0;0;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SmoothstepOpNode;258;526.8457,368.3385;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;274;-1006.884,1899.545;Inherit;False;Constant;_Vector0;Vector 0;26;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;222;-1314.529,2101.159;Inherit;True;Property;_NormalMap;NormalMap;23;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;171;229.2227,626.3997;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;190;385.2937,786.7416;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;253;186.5071,163.13;Inherit;False;Property;_FinalAlphaSmoothstepMin;FinalAlphaSmoothstepMin;16;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;177;473.4174,561.438;Inherit;False;Property;_EmissionDissolve;EmissionDissolve;11;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;255;163.5071,267.13;Inherit;False;Property;_FinalAlphaSmoothstepMax;FinalAlphaSmoothstepMax;17;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;276;805.6426,295.1938;Inherit;False;Property;_FinalEmissionSmoothstep;FinalEmissionSmoothstep;19;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;154;-459.6545,-651.055;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;221;-834.5293,1966.159;Inherit;False;Property;_NormalMapEnabled;Normal Map Enabled;22;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;155;-409.6545,-467.055;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;252;533.5071,170.13;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;206;-544.756,1888.111;Inherit;False;normals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;126;-99.86377,-485.2369;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;241;1123.483,539.1605;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;129;157.1362,-411.2369;Inherit;False;True;True;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;207;1229.142,-49.15683;Inherit;False;206;normals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;284;1486.953,685.3458;Inherit;False;Property;_CullMode;Cull Mode;29;1;[Enum];Create;True;0;0;1;UnityEngine.Rendering.CullMode;True;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;240;1225.512,360.524;Inherit;False;Property;_EmissionAlpha;EmissionAlpha;18;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;273;-1204.884,1869.545;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;209;-1417.255,1893.461;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StaticSwitch;275;1180.943,71.19385;Inherit;False;Property;_FinalAlphaSmoothstep;FinalAlphaSmoothstep;15;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;285;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;286;1610.346,-77.11003;Float;False;True;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;Knife/Particle Channel Packed;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;19;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;True;True;0;True;_CullMode;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;True;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;;0;0;Standard;41;Workflow;1;638177630478134345;Surface;1;638177630487167698;  Refraction Model;0;0;  Blend;0;0;Two Sided;1;0;Fragment Normal Space,InvertActionOnDeselection;0;0;Forward Only;0;0;Transmission;0;0;  Transmission Shadow;0.5,False,;0;Translucency;0;0;  Translucency Strength;1,False,;0;  Normal Distortion;0.5,False,;0;  Scattering;2,False,;0;  Direct;0.9,False,;0;  Ambient;0.1,False,;0;  Shadow;0.5,False,;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;1;0;Built-in Fog;1;0;_FinalColorxAlpha;0;0;Meta Pass;1;0;Override Baked GI;0;0;Extra Pre Pass;0;0;DOTS Instancing;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Write Depth;0;0;  Early Z;0;0;Vertex Position,InvertActionOnDeselection;1;0;Debug Display;0;0;Clear Coat;0;0;0;10;False;True;True;True;True;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;287;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;288;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;289;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;290;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;False;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;291;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthNormals;0;6;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormals;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;292;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;GBuffer;0;7;GBuffer;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalGBuffer;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;293;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;SceneSelectionPass;0;8;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;294;1610.346,-77.11003;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ScenePickingPass;0;9;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
WireConnection;135;0;12;0
WireConnection;136;0;134;0
WireConnection;18;0;137;0
WireConnection;18;1;138;0
WireConnection;122;0;3;3
WireConnection;4;0;122;0
WireConnection;103;0;18;0
WireConnection;112;0;104;0
WireConnection;112;1;121;0
WireConnection;113;0;112;0
WireConnection;26;0;18;0
WireConnection;114;0;113;0
WireConnection;114;1;121;0
WireConnection;144;0;3;0
WireConnection;40;0;26;0
WireConnection;98;0;144;0
WireConnection;98;1;139;0
WireConnection;98;2;140;0
WireConnection;98;4;114;0
WireConnection;41;0;26;0
WireConnection;43;0;40;0
WireConnection;1;0;204;0
WireConnection;1;1;98;0
WireConnection;133;0;27;0
WireConnection;44;0;41;0
WireConnection;23;0;52;0
WireConnection;23;1;133;0
WireConnection;23;2;133;0
WireConnection;123;0;47;0
WireConnection;233;0;1;0
WireConnection;233;1;234;0
WireConnection;233;2;235;0
WireConnection;124;0;49;0
WireConnection;24;0;53;0
WireConnection;24;1;123;0
WireConnection;24;2;123;0
WireConnection;236;1;1;0
WireConnection;236;0;233;0
WireConnection;56;0;23;0
WireConnection;152;0;236;0
WireConnection;57;0;24;0
WireConnection;25;0;54;0
WireConnection;25;1;124;0
WireConnection;25;2;124;0
WireConnection;20;0;152;0
WireConnection;20;1;152;1
WireConnection;20;2;60;0
WireConnection;58;0;25;0
WireConnection;142;0;143;0
WireConnection;146;0;142;0
WireConnection;21;0;20;0
WireConnection;21;1;152;2
WireConnection;21;2;61;0
WireConnection;22;0;21;0
WireConnection;22;1;152;3
WireConnection;22;2;62;0
WireConnection;163;0;146;0
WireConnection;173;0;22;0
WireConnection;173;2;174;0
WireConnection;167;0;127;4
WireConnection;162;0;164;0
WireConnection;162;1;173;0
WireConnection;165;0;162;0
WireConnection;165;1;167;0
WireConnection;158;0;125;4
WireConnection;158;1;127;4
WireConnection;166;0;165;0
WireConnection;172;0;125;4
WireConnection;172;1;166;0
WireConnection;131;0;158;0
WireConnection;131;1;164;0
WireConnection;131;2;173;0
WireConnection;283;0;278;2
WireConnection;283;1;278;2
WireConnection;281;0;237;0
WireConnection;281;1;283;0
WireConnection;159;1;131;0
WireConnection;159;0;172;0
WireConnection;248;0;159;0
WireConnection;277;0;281;0
WireConnection;277;2;278;1
WireConnection;279;1;237;0
WireConnection;279;0;277;0
WireConnection;238;0;279;0
WireConnection;238;2;271;0
WireConnection;251;0;249;0
WireConnection;251;1;250;0
WireConnection;247;0;170;4
WireConnection;247;1;251;0
WireConnection;192;1;238;0
WireConnection;246;1;170;4
WireConnection;246;0;247;0
WireConnection;193;0;192;0
WireConnection;193;1;195;0
WireConnection;193;2;194;0
WireConnection;226;0;224;0
WireConnection;196;0;193;0
WireConnection;196;1;246;0
WireConnection;227;0;225;0
WireConnection;197;0;196;0
WireConnection;223;0;232;0
WireConnection;223;1;226;0
WireConnection;223;2;227;0
WireConnection;223;4;228;0
WireConnection;258;0;159;0
WireConnection;258;1;256;0
WireConnection;258;2;257;0
WireConnection;222;1;223;0
WireConnection;222;5;230;0
WireConnection;171;0;168;0
WireConnection;171;1;170;4
WireConnection;190;0;168;0
WireConnection;190;1;197;0
WireConnection;177;1;171;0
WireConnection;177;0;190;0
WireConnection;276;1;159;0
WireConnection;276;0;258;0
WireConnection;154;0;125;0
WireConnection;221;1;274;0
WireConnection;221;0;222;0
WireConnection;155;0;127;0
WireConnection;252;0;159;0
WireConnection;252;1;253;0
WireConnection;252;2;255;0
WireConnection;206;0;221;0
WireConnection;126;0;154;0
WireConnection;126;1;155;0
WireConnection;241;0;276;0
WireConnection;241;1;177;0
WireConnection;129;0;126;0
WireConnection;240;1;177;0
WireConnection;240;0;241;0
WireConnection;275;1;248;0
WireConnection;275;0;252;0
WireConnection;286;0;129;0
WireConnection;286;1;207;0
WireConnection;286;2;240;0
WireConnection;286;6;275;0
ASEEND*/
//CHKSM=1A29A4F03BACFD94D98CB87AEC010234CA093722