Shader "Azerilo/URP 2D Water with Refraction"
    {
        Properties
        {
            Color_234C1B0B("Water Top Color", Color) = (1, 1, 1, 0)
            Vector1_8DA20226("Water Top Width", Float) = 5
            Color_D12BF231("Water Color", Color) = (0.8156863, 0.9568627, 1, 0)
            Vector1_56BE0FD1("Water Level", Range(0, 1)) = 0.8
            Vector1_745B9376("Wave Speed", Float) = 3
            Vector1_5CB84537("Wave Frequency", Float) = 18
            Vector1_AF318A03("Wave Depth", Range(0, 20)) = 1.4
            Vector1_63384718("Refraction Speed", Range(0, 20)) = 10
            Vector1_73BD9798("Refraction Noise", Float) = 70
            Vector1_D775EAAC("Refraction Strength", Range(-2, 2)) = 0.7
            [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
            [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
            [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
        }
        SubShader
        {
            Tags
            {
                "RenderPipeline"="UniversalPipeline"
                "RenderType"="Transparent"
                "UniversalMaterialType" = "Unlit"
                "Queue"="Transparent"
            }
            Pass
            {
                Name "Pass"
                Tags
                {
                    // LightMode: <None>
                }
    
                // Render State
                Cull Back
                Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
                ZTest LEqual
                ZWrite Off
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile_fog
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma shader_feature _ _SAMPLE_GI
                // GraphKeywords: <None>
    
                // Defines
                #define _SURFACE_TYPE_TRANSPARENT 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define VARYINGS_NEED_POSITION_WS
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_UNLIT
                #define REQUIRE_DEPTH_TEXTURE
                #define REQUIRE_OPAQUE_TEXTURE
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS;
                    float4 texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 WorldSpacePosition;
                    float4 ScreenPosition;
                    float4 uv0;
                    float3 TimeParameters;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float4 interp1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.positionWS;
                    output.interp1.xyzw =  input.texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.positionWS = input.interp0.xyz;
                    output.texCoord0 = input.interp1.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float4 Color_234C1B0B;
                float Vector1_8DA20226;
                float4 Color_D12BF231;
                float Vector1_56BE0FD1;
                float Vector1_745B9376;
                float Vector1_5CB84537;
                float Vector1_AF318A03;
                float Vector1_63384718;
                float Vector1_73BD9798;
                float Vector1_D775EAAC;
                CBUFFER_END
                
                // Object and Global properties
                float4 Color_20C936C9;
    
                // Graph Functions
                
                void Unity_Divide_float(float A, float B, out float Out)
                {
                    Out = A / B;
                }
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
                {
                    Out = UV * Tiling + Offset;
                }
                
                
                inline float Unity_SimpleNoise_RandomValue_float (float2 uv)
                {
                    return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
                }
                
                inline float Unity_SimpleNnoise_Interpolate_float (float a, float b, float t)
                {
                    return (1.0-t)*a + (t*b);
                }
                
                
                inline float Unity_SimpleNoise_ValueNoise_float (float2 uv)
                {
                    float2 i = floor(uv);
                    float2 f = frac(uv);
                    f = f * f * (3.0 - 2.0 * f);
                
                    uv = abs(frac(uv) - 0.5);
                    float2 c0 = i + float2(0.0, 0.0);
                    float2 c1 = i + float2(1.0, 0.0);
                    float2 c2 = i + float2(0.0, 1.0);
                    float2 c3 = i + float2(1.0, 1.0);
                    float r0 = Unity_SimpleNoise_RandomValue_float(c0);
                    float r1 = Unity_SimpleNoise_RandomValue_float(c1);
                    float r2 = Unity_SimpleNoise_RandomValue_float(c2);
                    float r3 = Unity_SimpleNoise_RandomValue_float(c3);
                
                    float bottomOfGrid = Unity_SimpleNnoise_Interpolate_float(r0, r1, f.x);
                    float topOfGrid = Unity_SimpleNnoise_Interpolate_float(r2, r3, f.x);
                    float t = Unity_SimpleNnoise_Interpolate_float(bottomOfGrid, topOfGrid, f.y);
                    return t;
                }
                void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
                {
                    float t = 0.0;
                
                    float freq = pow(2.0, float(0));
                    float amp = pow(0.5, float(3-0));
                    t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
                
                    freq = pow(2.0, float(1));
                    amp = pow(0.5, float(3-1));
                    t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
                
                    freq = pow(2.0, float(2));
                    amp = pow(0.5, float(3-2));
                    t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
                
                    Out = t;
                }
                
                void Unity_Add_float4(float4 A, float4 B, out float4 Out)
                {
                    Out = A + B;
                }
                
                void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
                {
                    Out = A * B;
                }
                
                void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
                {
                    Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
                }
                
                void Unity_Subtract_float(float A, float B, out float Out)
                {
                    Out = A - B;
                }
                
                void Unity_Comparison_Less_float(float A, float B, out float Out)
                {
                    Out = A < B ? 1 : 0;
                }
                
                void Unity_Branch_float2(float Predicate, float2 True, float2 False, out float2 Out)
                {
                    Out = Predicate ? True : False;
                }
                
                void Unity_SceneColor_float(float4 UV, out float3 Out)
                {
                    Out = SHADERGRAPH_SAMPLE_SCENE_COLOR(UV.xy);
                }
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Sine_float(float In, out float Out)
                {
                    Out = sin(In);
                }
                
                void Unity_Comparison_Greater_float(float A, float B, out float Out)
                {
                    Out = A > B ? 1 : 0;
                }
                
                void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                {
                    Out = Predicate ? True : False;
                }
                
                void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
                {
                    Out = A * B;
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                    float Alpha;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _ScreenPosition_8ed4b323f4f106849eda05f041314f2c_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0);
                    float _Property_373d7310208ff486bbf8a3259833d1b8_Out_0 = Vector1_63384718;
                    float _Divide_593e951e650bbd80996dccbbe89f53ac_Out_2;
                    Unity_Divide_float(_Property_373d7310208ff486bbf8a3259833d1b8_Out_0, 100, _Divide_593e951e650bbd80996dccbbe89f53ac_Out_2);
                    float _Multiply_2e179bde7dfd688e85aaae302149f8c2_Out_2;
                    Unity_Multiply_float(_Divide_593e951e650bbd80996dccbbe89f53ac_Out_2, IN.TimeParameters.x, _Multiply_2e179bde7dfd688e85aaae302149f8c2_Out_2);
                    float2 _TilingAndOffset_f90ee46f27f3d081b4ddb84578c783f6_Out_3;
                    Unity_TilingAndOffset_float(IN.uv0.xy, float2 (1, 1), (_Multiply_2e179bde7dfd688e85aaae302149f8c2_Out_2.xx), _TilingAndOffset_f90ee46f27f3d081b4ddb84578c783f6_Out_3);
                    float _Property_ff0baa56ee3d568eb312f3a6f2b2d3af_Out_0 = Vector1_73BD9798;
                    float _SimpleNoise_badb01badbf2298ca74526e8b17673ab_Out_2;
                    Unity_SimpleNoise_float(_TilingAndOffset_f90ee46f27f3d081b4ddb84578c783f6_Out_3, _Property_ff0baa56ee3d568eb312f3a6f2b2d3af_Out_0, _SimpleNoise_badb01badbf2298ca74526e8b17673ab_Out_2);
                    float4 _Property_8cc4660029ca4884a11e0a85b0581a29_Out_0 = Color_20C936C9;
                    float _Property_1de02d5f49a08b8eab610a90e1911cb1_Out_0 = Vector1_D775EAAC;
                    float _Divide_58924c2a5e735c81b2309aa2eb82458b_Out_2;
                    Unity_Divide_float(_Property_1de02d5f49a08b8eab610a90e1911cb1_Out_0, 100, _Divide_58924c2a5e735c81b2309aa2eb82458b_Out_2);
                    float4 _Add_9ded394883e31188b2d77d852ecb6540_Out_2;
                    Unity_Add_float4(_Property_8cc4660029ca4884a11e0a85b0581a29_Out_0, (_Divide_58924c2a5e735c81b2309aa2eb82458b_Out_2.xxxx), _Add_9ded394883e31188b2d77d852ecb6540_Out_2);
                    float4 _Multiply_2d5921574ba3db8e96a47f3ed5a79378_Out_2;
                    Unity_Multiply_float((_SimpleNoise_badb01badbf2298ca74526e8b17673ab_Out_2.xxxx), _Add_9ded394883e31188b2d77d852ecb6540_Out_2, _Multiply_2d5921574ba3db8e96a47f3ed5a79378_Out_2);
                    float2 _TilingAndOffset_8e76997513c4ad858cdf0148ebee6db8_Out_3;
                    Unity_TilingAndOffset_float((_ScreenPosition_8ed4b323f4f106849eda05f041314f2c_Out_0.xy), float2 (1, 1), (_Multiply_2d5921574ba3db8e96a47f3ed5a79378_Out_2.xy), _TilingAndOffset_8e76997513c4ad858cdf0148ebee6db8_Out_3);
                    float _SceneDepth_cb726e53e537878f8dded5b13dbb196b_Out_1;
                    Unity_SceneDepth_Eye_float((float4(_TilingAndOffset_8e76997513c4ad858cdf0148ebee6db8_Out_3, 0.0, 1.0)), _SceneDepth_cb726e53e537878f8dded5b13dbb196b_Out_1);
                    float4 _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0);
                    float _Split_de4ec4e893dff3848faba8eddc2c33b8_R_1 = _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0[0];
                    float _Split_de4ec4e893dff3848faba8eddc2c33b8_G_2 = _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0[1];
                    float _Split_de4ec4e893dff3848faba8eddc2c33b8_B_3 = _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0[2];
                    float _Split_de4ec4e893dff3848faba8eddc2c33b8_A_4 = _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0[3];
                    float _Subtract_e04a11cdf02ef4809bcac78822696f74_Out_2;
                    Unity_Subtract_float(_SceneDepth_cb726e53e537878f8dded5b13dbb196b_Out_1, _Split_de4ec4e893dff3848faba8eddc2c33b8_A_4, _Subtract_e04a11cdf02ef4809bcac78822696f74_Out_2);
                    float _Comparison_739ba6765d539c82bd0510fa86047a34_Out_2;
                    Unity_Comparison_Less_float(_Subtract_e04a11cdf02ef4809bcac78822696f74_Out_2, 0, _Comparison_739ba6765d539c82bd0510fa86047a34_Out_2);
                    float2 _Branch_8ec74c3ea8cc4689a1cf8811f1410039_Out_3;
                    Unity_Branch_float2(_Comparison_739ba6765d539c82bd0510fa86047a34_Out_2, (_ScreenPosition_8ed4b323f4f106849eda05f041314f2c_Out_0.xy), _TilingAndOffset_8e76997513c4ad858cdf0148ebee6db8_Out_3, _Branch_8ec74c3ea8cc4689a1cf8811f1410039_Out_3);
                    float3 _SceneColor_423c37856a8dff81aeff37fff8764a9c_Out_1;
                    Unity_SceneColor_float((float4(_Branch_8ec74c3ea8cc4689a1cf8811f1410039_Out_3, 0.0, 1.0)), _SceneColor_423c37856a8dff81aeff37fff8764a9c_Out_1);
                    float4 _Property_2431f4c9d874f78ebe1bc2867afaa2ec_Out_0 = Color_234C1B0B;
                    float4 _UV_cae19cd50907c986bfac8000fcc55360_Out_0 = IN.uv0;
                    float4 _Add_4b77fda1a266e5868c852226324046d5_Out_2;
                    Unity_Add_float4(_Property_2431f4c9d874f78ebe1bc2867afaa2ec_Out_0, _UV_cae19cd50907c986bfac8000fcc55360_Out_0, _Add_4b77fda1a266e5868c852226324046d5_Out_2);
                    float4 _Property_7e27e38310ef2784a384c60888aa7849_Out_0 = Color_D12BF231;
                    float4 _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0 = IN.uv0;
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_R_1 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[0];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_G_2 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[1];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_B_3 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[2];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_A_4 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[3];
                    float _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0 = Vector1_5CB84537;
                    float _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2;
                    Unity_Multiply_float(_Split_b7f6798c5c3baf81a04496f4af428a21_R_1, _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0, _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2);
                    float _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0 = Vector1_745B9376;
                    float _Multiply_a07084ffbf220388b55751a6362f056b_Out_2;
                    Unity_Multiply_float(IN.TimeParameters.x, _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2);
                    float _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2;
                    Unity_Add_float(_Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2, _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2);
                    float _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1;
                    Unity_Sine_float(_Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2, _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1);
                    float _Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0 = Vector1_AF318A03;
                    float _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2;
                    Unity_Divide_float(_Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0, 100, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2);
                    float _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2;
                    Unity_Multiply_float(_Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2, _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2);
                    float _Property_02aa838086edbc889d6afefebe6be70d_Out_0 = Vector1_56BE0FD1;
                    float _Property_ed5ff1176af7ba83b365b4b2dc2e779f_Out_0 = Vector1_8DA20226;
                    float _Divide_9cbdbc2bc747e38a9cae5fec062cc368_Out_2;
                    Unity_Divide_float(_Property_ed5ff1176af7ba83b365b4b2dc2e779f_Out_0, 1000, _Divide_9cbdbc2bc747e38a9cae5fec062cc368_Out_2);
                    float _Subtract_98378fe44c51a08a88c0dd33d0fcdee2_Out_2;
                    Unity_Subtract_float(_Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Divide_9cbdbc2bc747e38a9cae5fec062cc368_Out_2, _Subtract_98378fe44c51a08a88c0dd33d0fcdee2_Out_2);
                    float _Add_7df99c4416d7c68e8b3a6fff849116c8_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Subtract_98378fe44c51a08a88c0dd33d0fcdee2_Out_2, _Add_7df99c4416d7c68e8b3a6fff849116c8_Out_2);
                    float _Comparison_40e1062705411a84b8476f128b40d741_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_7df99c4416d7c68e8b3a6fff849116c8_Out_2, _Comparison_40e1062705411a84b8476f128b40d741_Out_2);
                    float _Branch_453a802f56019e8ba166f6e33820a826_Out_3;
                    Unity_Branch_float(_Comparison_40e1062705411a84b8476f128b40d741_Out_2, 0, 1, _Branch_453a802f56019e8ba166f6e33820a826_Out_3);
                    float4 _Lerp_f44b73cbec88f78c828ce3d15cb88ed1_Out_3;
                    Unity_Lerp_float4(_Add_4b77fda1a266e5868c852226324046d5_Out_2, _Property_7e27e38310ef2784a384c60888aa7849_Out_0, (_Branch_453a802f56019e8ba166f6e33820a826_Out_3.xxxx), _Lerp_f44b73cbec88f78c828ce3d15cb88ed1_Out_3);
                    float3 _Multiply_5f9efc17e50ea18d9d5c055b9adabd8a_Out_2;
                    Unity_Multiply_float(_SceneColor_423c37856a8dff81aeff37fff8764a9c_Out_1, (_Lerp_f44b73cbec88f78c828ce3d15cb88ed1_Out_3.xyz), _Multiply_5f9efc17e50ea18d9d5c055b9adabd8a_Out_2);
                    float _Add_1113249fecc4d28da19af79ba352056d_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Add_1113249fecc4d28da19af79ba352056d_Out_2);
                    float _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_1113249fecc4d28da19af79ba352056d_Out_2, _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2);
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, 1, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
                    surface.BaseColor = _Multiply_5f9efc17e50ea18d9d5c055b9adabd8a_Out_2;
                    surface.Alpha = _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                    output.WorldSpacePosition =          input.positionWS;
                    output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
                    output.uv0 =                         input.texCoord0;
                    output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "ShadowCaster"
                Tags
                {
                    "LightMode" = "ShadowCaster"
                }
    
                // Render State
                Cull Back
                Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
                ZTest LEqual
                ZWrite On
                ColorMask 0
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _SURFACE_TYPE_TRANSPARENT 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_SHADOWCASTER
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float4 texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float4 uv0;
                    float3 TimeParameters;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float4 interp0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyzw =  input.texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.texCoord0 = input.interp0.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float4 Color_234C1B0B;
                float Vector1_8DA20226;
                float4 Color_D12BF231;
                float Vector1_56BE0FD1;
                float Vector1_745B9376;
                float Vector1_5CB84537;
                float Vector1_AF318A03;
                float Vector1_63384718;
                float Vector1_73BD9798;
                float Vector1_D775EAAC;
                CBUFFER_END
                
                // Object and Global properties
                float4 Color_20C936C9;
    
                // Graph Functions
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Sine_float(float In, out float Out)
                {
                    Out = sin(In);
                }
                
                void Unity_Divide_float(float A, float B, out float Out)
                {
                    Out = A / B;
                }
                
                void Unity_Comparison_Greater_float(float A, float B, out float Out)
                {
                    Out = A > B ? 1 : 0;
                }
                
                void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                {
                    Out = Predicate ? True : False;
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float Alpha;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0 = IN.uv0;
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_R_1 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[0];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_G_2 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[1];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_B_3 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[2];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_A_4 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[3];
                    float _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0 = Vector1_5CB84537;
                    float _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2;
                    Unity_Multiply_float(_Split_b7f6798c5c3baf81a04496f4af428a21_R_1, _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0, _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2);
                    float _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0 = Vector1_745B9376;
                    float _Multiply_a07084ffbf220388b55751a6362f056b_Out_2;
                    Unity_Multiply_float(IN.TimeParameters.x, _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2);
                    float _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2;
                    Unity_Add_float(_Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2, _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2);
                    float _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1;
                    Unity_Sine_float(_Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2, _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1);
                    float _Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0 = Vector1_AF318A03;
                    float _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2;
                    Unity_Divide_float(_Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0, 100, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2);
                    float _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2;
                    Unity_Multiply_float(_Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2, _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2);
                    float _Property_02aa838086edbc889d6afefebe6be70d_Out_0 = Vector1_56BE0FD1;
                    float _Add_1113249fecc4d28da19af79ba352056d_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Add_1113249fecc4d28da19af79ba352056d_Out_2);
                    float _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_1113249fecc4d28da19af79ba352056d_Out_2, _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2);
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, 1, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
                    surface.Alpha = _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                    output.uv0 =                         input.texCoord0;
                    output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "DepthOnly"
                Tags
                {
                    "LightMode" = "DepthOnly"
                }
    
                // Render State
                Cull Back
                Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
                ZTest LEqual
                ZWrite On
                ColorMask 0
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _SURFACE_TYPE_TRANSPARENT 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_DEPTHONLY
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float4 texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float4 uv0;
                    float3 TimeParameters;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float4 interp0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyzw =  input.texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.texCoord0 = input.interp0.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float4 Color_234C1B0B;
                float Vector1_8DA20226;
                float4 Color_D12BF231;
                float Vector1_56BE0FD1;
                float Vector1_745B9376;
                float Vector1_5CB84537;
                float Vector1_AF318A03;
                float Vector1_63384718;
                float Vector1_73BD9798;
                float Vector1_D775EAAC;
                CBUFFER_END
                
                // Object and Global properties
                float4 Color_20C936C9;
    
                // Graph Functions
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Sine_float(float In, out float Out)
                {
                    Out = sin(In);
                }
                
                void Unity_Divide_float(float A, float B, out float Out)
                {
                    Out = A / B;
                }
                
                void Unity_Comparison_Greater_float(float A, float B, out float Out)
                {
                    Out = A > B ? 1 : 0;
                }
                
                void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                {
                    Out = Predicate ? True : False;
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float Alpha;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0 = IN.uv0;
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_R_1 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[0];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_G_2 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[1];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_B_3 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[2];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_A_4 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[3];
                    float _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0 = Vector1_5CB84537;
                    float _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2;
                    Unity_Multiply_float(_Split_b7f6798c5c3baf81a04496f4af428a21_R_1, _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0, _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2);
                    float _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0 = Vector1_745B9376;
                    float _Multiply_a07084ffbf220388b55751a6362f056b_Out_2;
                    Unity_Multiply_float(IN.TimeParameters.x, _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2);
                    float _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2;
                    Unity_Add_float(_Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2, _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2);
                    float _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1;
                    Unity_Sine_float(_Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2, _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1);
                    float _Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0 = Vector1_AF318A03;
                    float _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2;
                    Unity_Divide_float(_Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0, 100, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2);
                    float _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2;
                    Unity_Multiply_float(_Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2, _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2);
                    float _Property_02aa838086edbc889d6afefebe6be70d_Out_0 = Vector1_56BE0FD1;
                    float _Add_1113249fecc4d28da19af79ba352056d_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Add_1113249fecc4d28da19af79ba352056d_Out_2);
                    float _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_1113249fecc4d28da19af79ba352056d_Out_2, _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2);
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, 1, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
                    surface.Alpha = _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                    output.uv0 =                         input.texCoord0;
                    output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
    
                ENDHLSL
            }
        }
        SubShader
        {
            Tags
            {
                "RenderPipeline"="UniversalPipeline"
                "RenderType"="Transparent"
                "UniversalMaterialType" = "Unlit"
                "Queue"="Transparent"
            }
            Pass
            {
                Name "Pass"
                Tags
                {
                    // LightMode: <None>
                }
    
                // Render State
                Cull Back
                Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
                ZTest LEqual
                ZWrite Off
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile_fog
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma shader_feature _ _SAMPLE_GI
                // GraphKeywords: <None>
    
                // Defines
                #define _SURFACE_TYPE_TRANSPARENT 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define VARYINGS_NEED_POSITION_WS
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_UNLIT
                #define REQUIRE_DEPTH_TEXTURE
                #define REQUIRE_OPAQUE_TEXTURE
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS;
                    float4 texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 WorldSpacePosition;
                    float4 ScreenPosition;
                    float4 uv0;
                    float3 TimeParameters;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float4 interp1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.positionWS;
                    output.interp1.xyzw =  input.texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.positionWS = input.interp0.xyz;
                    output.texCoord0 = input.interp1.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float4 Color_234C1B0B;
                float Vector1_8DA20226;
                float4 Color_D12BF231;
                float Vector1_56BE0FD1;
                float Vector1_745B9376;
                float Vector1_5CB84537;
                float Vector1_AF318A03;
                float Vector1_63384718;
                float Vector1_73BD9798;
                float Vector1_D775EAAC;
                CBUFFER_END
                
                // Object and Global properties
                float4 Color_20C936C9;
    
                // Graph Functions
                
                void Unity_Divide_float(float A, float B, out float Out)
                {
                    Out = A / B;
                }
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
                {
                    Out = UV * Tiling + Offset;
                }
                
                
                inline float Unity_SimpleNoise_RandomValue_float (float2 uv)
                {
                    return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
                }
                
                inline float Unity_SimpleNnoise_Interpolate_float (float a, float b, float t)
                {
                    return (1.0-t)*a + (t*b);
                }
                
                
                inline float Unity_SimpleNoise_ValueNoise_float (float2 uv)
                {
                    float2 i = floor(uv);
                    float2 f = frac(uv);
                    f = f * f * (3.0 - 2.0 * f);
                
                    uv = abs(frac(uv) - 0.5);
                    float2 c0 = i + float2(0.0, 0.0);
                    float2 c1 = i + float2(1.0, 0.0);
                    float2 c2 = i + float2(0.0, 1.0);
                    float2 c3 = i + float2(1.0, 1.0);
                    float r0 = Unity_SimpleNoise_RandomValue_float(c0);
                    float r1 = Unity_SimpleNoise_RandomValue_float(c1);
                    float r2 = Unity_SimpleNoise_RandomValue_float(c2);
                    float r3 = Unity_SimpleNoise_RandomValue_float(c3);
                
                    float bottomOfGrid = Unity_SimpleNnoise_Interpolate_float(r0, r1, f.x);
                    float topOfGrid = Unity_SimpleNnoise_Interpolate_float(r2, r3, f.x);
                    float t = Unity_SimpleNnoise_Interpolate_float(bottomOfGrid, topOfGrid, f.y);
                    return t;
                }
                void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
                {
                    float t = 0.0;
                
                    float freq = pow(2.0, float(0));
                    float amp = pow(0.5, float(3-0));
                    t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
                
                    freq = pow(2.0, float(1));
                    amp = pow(0.5, float(3-1));
                    t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
                
                    freq = pow(2.0, float(2));
                    amp = pow(0.5, float(3-2));
                    t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
                
                    Out = t;
                }
                
                void Unity_Add_float4(float4 A, float4 B, out float4 Out)
                {
                    Out = A + B;
                }
                
                void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
                {
                    Out = A * B;
                }
                
                void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
                {
                    Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
                }
                
                void Unity_Subtract_float(float A, float B, out float Out)
                {
                    Out = A - B;
                }
                
                void Unity_Comparison_Less_float(float A, float B, out float Out)
                {
                    Out = A < B ? 1 : 0;
                }
                
                void Unity_Branch_float2(float Predicate, float2 True, float2 False, out float2 Out)
                {
                    Out = Predicate ? True : False;
                }
                
                void Unity_SceneColor_float(float4 UV, out float3 Out)
                {
                    Out = SHADERGRAPH_SAMPLE_SCENE_COLOR(UV.xy);
                }
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Sine_float(float In, out float Out)
                {
                    Out = sin(In);
                }
                
                void Unity_Comparison_Greater_float(float A, float B, out float Out)
                {
                    Out = A > B ? 1 : 0;
                }
                
                void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                {
                    Out = Predicate ? True : False;
                }
                
                void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
                {
                    Out = lerp(A, B, T);
                }
                
                void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
                {
                    Out = A * B;
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                    float Alpha;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _ScreenPosition_8ed4b323f4f106849eda05f041314f2c_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0);
                    float _Property_373d7310208ff486bbf8a3259833d1b8_Out_0 = Vector1_63384718;
                    float _Divide_593e951e650bbd80996dccbbe89f53ac_Out_2;
                    Unity_Divide_float(_Property_373d7310208ff486bbf8a3259833d1b8_Out_0, 100, _Divide_593e951e650bbd80996dccbbe89f53ac_Out_2);
                    float _Multiply_2e179bde7dfd688e85aaae302149f8c2_Out_2;
                    Unity_Multiply_float(_Divide_593e951e650bbd80996dccbbe89f53ac_Out_2, IN.TimeParameters.x, _Multiply_2e179bde7dfd688e85aaae302149f8c2_Out_2);
                    float2 _TilingAndOffset_f90ee46f27f3d081b4ddb84578c783f6_Out_3;
                    Unity_TilingAndOffset_float(IN.uv0.xy, float2 (1, 1), (_Multiply_2e179bde7dfd688e85aaae302149f8c2_Out_2.xx), _TilingAndOffset_f90ee46f27f3d081b4ddb84578c783f6_Out_3);
                    float _Property_ff0baa56ee3d568eb312f3a6f2b2d3af_Out_0 = Vector1_73BD9798;
                    float _SimpleNoise_badb01badbf2298ca74526e8b17673ab_Out_2;
                    Unity_SimpleNoise_float(_TilingAndOffset_f90ee46f27f3d081b4ddb84578c783f6_Out_3, _Property_ff0baa56ee3d568eb312f3a6f2b2d3af_Out_0, _SimpleNoise_badb01badbf2298ca74526e8b17673ab_Out_2);
                    float4 _Property_8cc4660029ca4884a11e0a85b0581a29_Out_0 = Color_20C936C9;
                    float _Property_1de02d5f49a08b8eab610a90e1911cb1_Out_0 = Vector1_D775EAAC;
                    float _Divide_58924c2a5e735c81b2309aa2eb82458b_Out_2;
                    Unity_Divide_float(_Property_1de02d5f49a08b8eab610a90e1911cb1_Out_0, 100, _Divide_58924c2a5e735c81b2309aa2eb82458b_Out_2);
                    float4 _Add_9ded394883e31188b2d77d852ecb6540_Out_2;
                    Unity_Add_float4(_Property_8cc4660029ca4884a11e0a85b0581a29_Out_0, (_Divide_58924c2a5e735c81b2309aa2eb82458b_Out_2.xxxx), _Add_9ded394883e31188b2d77d852ecb6540_Out_2);
                    float4 _Multiply_2d5921574ba3db8e96a47f3ed5a79378_Out_2;
                    Unity_Multiply_float((_SimpleNoise_badb01badbf2298ca74526e8b17673ab_Out_2.xxxx), _Add_9ded394883e31188b2d77d852ecb6540_Out_2, _Multiply_2d5921574ba3db8e96a47f3ed5a79378_Out_2);
                    float2 _TilingAndOffset_8e76997513c4ad858cdf0148ebee6db8_Out_3;
                    Unity_TilingAndOffset_float((_ScreenPosition_8ed4b323f4f106849eda05f041314f2c_Out_0.xy), float2 (1, 1), (_Multiply_2d5921574ba3db8e96a47f3ed5a79378_Out_2.xy), _TilingAndOffset_8e76997513c4ad858cdf0148ebee6db8_Out_3);
                    float _SceneDepth_cb726e53e537878f8dded5b13dbb196b_Out_1;
                    Unity_SceneDepth_Eye_float((float4(_TilingAndOffset_8e76997513c4ad858cdf0148ebee6db8_Out_3, 0.0, 1.0)), _SceneDepth_cb726e53e537878f8dded5b13dbb196b_Out_1);
                    float4 _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0);
                    float _Split_de4ec4e893dff3848faba8eddc2c33b8_R_1 = _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0[0];
                    float _Split_de4ec4e893dff3848faba8eddc2c33b8_G_2 = _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0[1];
                    float _Split_de4ec4e893dff3848faba8eddc2c33b8_B_3 = _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0[2];
                    float _Split_de4ec4e893dff3848faba8eddc2c33b8_A_4 = _ScreenPosition_8224cb8e01422e84939a0f447a510ae4_Out_0[3];
                    float _Subtract_e04a11cdf02ef4809bcac78822696f74_Out_2;
                    Unity_Subtract_float(_SceneDepth_cb726e53e537878f8dded5b13dbb196b_Out_1, _Split_de4ec4e893dff3848faba8eddc2c33b8_A_4, _Subtract_e04a11cdf02ef4809bcac78822696f74_Out_2);
                    float _Comparison_739ba6765d539c82bd0510fa86047a34_Out_2;
                    Unity_Comparison_Less_float(_Subtract_e04a11cdf02ef4809bcac78822696f74_Out_2, 0, _Comparison_739ba6765d539c82bd0510fa86047a34_Out_2);
                    float2 _Branch_8ec74c3ea8cc4689a1cf8811f1410039_Out_3;
                    Unity_Branch_float2(_Comparison_739ba6765d539c82bd0510fa86047a34_Out_2, (_ScreenPosition_8ed4b323f4f106849eda05f041314f2c_Out_0.xy), _TilingAndOffset_8e76997513c4ad858cdf0148ebee6db8_Out_3, _Branch_8ec74c3ea8cc4689a1cf8811f1410039_Out_3);
                    float3 _SceneColor_423c37856a8dff81aeff37fff8764a9c_Out_1;
                    Unity_SceneColor_float((float4(_Branch_8ec74c3ea8cc4689a1cf8811f1410039_Out_3, 0.0, 1.0)), _SceneColor_423c37856a8dff81aeff37fff8764a9c_Out_1);
                    float4 _Property_2431f4c9d874f78ebe1bc2867afaa2ec_Out_0 = Color_234C1B0B;
                    float4 _UV_cae19cd50907c986bfac8000fcc55360_Out_0 = IN.uv0;
                    float4 _Add_4b77fda1a266e5868c852226324046d5_Out_2;
                    Unity_Add_float4(_Property_2431f4c9d874f78ebe1bc2867afaa2ec_Out_0, _UV_cae19cd50907c986bfac8000fcc55360_Out_0, _Add_4b77fda1a266e5868c852226324046d5_Out_2);
                    float4 _Property_7e27e38310ef2784a384c60888aa7849_Out_0 = Color_D12BF231;
                    float4 _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0 = IN.uv0;
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_R_1 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[0];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_G_2 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[1];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_B_3 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[2];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_A_4 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[3];
                    float _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0 = Vector1_5CB84537;
                    float _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2;
                    Unity_Multiply_float(_Split_b7f6798c5c3baf81a04496f4af428a21_R_1, _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0, _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2);
                    float _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0 = Vector1_745B9376;
                    float _Multiply_a07084ffbf220388b55751a6362f056b_Out_2;
                    Unity_Multiply_float(IN.TimeParameters.x, _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2);
                    float _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2;
                    Unity_Add_float(_Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2, _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2);
                    float _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1;
                    Unity_Sine_float(_Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2, _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1);
                    float _Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0 = Vector1_AF318A03;
                    float _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2;
                    Unity_Divide_float(_Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0, 100, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2);
                    float _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2;
                    Unity_Multiply_float(_Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2, _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2);
                    float _Property_02aa838086edbc889d6afefebe6be70d_Out_0 = Vector1_56BE0FD1;
                    float _Property_ed5ff1176af7ba83b365b4b2dc2e779f_Out_0 = Vector1_8DA20226;
                    float _Divide_9cbdbc2bc747e38a9cae5fec062cc368_Out_2;
                    Unity_Divide_float(_Property_ed5ff1176af7ba83b365b4b2dc2e779f_Out_0, 1000, _Divide_9cbdbc2bc747e38a9cae5fec062cc368_Out_2);
                    float _Subtract_98378fe44c51a08a88c0dd33d0fcdee2_Out_2;
                    Unity_Subtract_float(_Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Divide_9cbdbc2bc747e38a9cae5fec062cc368_Out_2, _Subtract_98378fe44c51a08a88c0dd33d0fcdee2_Out_2);
                    float _Add_7df99c4416d7c68e8b3a6fff849116c8_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Subtract_98378fe44c51a08a88c0dd33d0fcdee2_Out_2, _Add_7df99c4416d7c68e8b3a6fff849116c8_Out_2);
                    float _Comparison_40e1062705411a84b8476f128b40d741_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_7df99c4416d7c68e8b3a6fff849116c8_Out_2, _Comparison_40e1062705411a84b8476f128b40d741_Out_2);
                    float _Branch_453a802f56019e8ba166f6e33820a826_Out_3;
                    Unity_Branch_float(_Comparison_40e1062705411a84b8476f128b40d741_Out_2, 0, 1, _Branch_453a802f56019e8ba166f6e33820a826_Out_3);
                    float4 _Lerp_f44b73cbec88f78c828ce3d15cb88ed1_Out_3;
                    Unity_Lerp_float4(_Add_4b77fda1a266e5868c852226324046d5_Out_2, _Property_7e27e38310ef2784a384c60888aa7849_Out_0, (_Branch_453a802f56019e8ba166f6e33820a826_Out_3.xxxx), _Lerp_f44b73cbec88f78c828ce3d15cb88ed1_Out_3);
                    float3 _Multiply_5f9efc17e50ea18d9d5c055b9adabd8a_Out_2;
                    Unity_Multiply_float(_SceneColor_423c37856a8dff81aeff37fff8764a9c_Out_1, (_Lerp_f44b73cbec88f78c828ce3d15cb88ed1_Out_3.xyz), _Multiply_5f9efc17e50ea18d9d5c055b9adabd8a_Out_2);
                    float _Add_1113249fecc4d28da19af79ba352056d_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Add_1113249fecc4d28da19af79ba352056d_Out_2);
                    float _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_1113249fecc4d28da19af79ba352056d_Out_2, _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2);
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, 1, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
                    surface.BaseColor = _Multiply_5f9efc17e50ea18d9d5c055b9adabd8a_Out_2;
                    surface.Alpha = _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                    output.WorldSpacePosition =          input.positionWS;
                    output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
                    output.uv0 =                         input.texCoord0;
                    output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "ShadowCaster"
                Tags
                {
                    "LightMode" = "ShadowCaster"
                }
    
                // Render State
                Cull Back
                Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
                ZTest LEqual
                ZWrite On
                ColorMask 0
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _SURFACE_TYPE_TRANSPARENT 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_SHADOWCASTER
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float4 texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float4 uv0;
                    float3 TimeParameters;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float4 interp0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyzw =  input.texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.texCoord0 = input.interp0.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float4 Color_234C1B0B;
                float Vector1_8DA20226;
                float4 Color_D12BF231;
                float Vector1_56BE0FD1;
                float Vector1_745B9376;
                float Vector1_5CB84537;
                float Vector1_AF318A03;
                float Vector1_63384718;
                float Vector1_73BD9798;
                float Vector1_D775EAAC;
                CBUFFER_END
                
                // Object and Global properties
                float4 Color_20C936C9;
    
                // Graph Functions
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Sine_float(float In, out float Out)
                {
                    Out = sin(In);
                }
                
                void Unity_Divide_float(float A, float B, out float Out)
                {
                    Out = A / B;
                }
                
                void Unity_Comparison_Greater_float(float A, float B, out float Out)
                {
                    Out = A > B ? 1 : 0;
                }
                
                void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                {
                    Out = Predicate ? True : False;
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float Alpha;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0 = IN.uv0;
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_R_1 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[0];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_G_2 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[1];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_B_3 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[2];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_A_4 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[3];
                    float _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0 = Vector1_5CB84537;
                    float _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2;
                    Unity_Multiply_float(_Split_b7f6798c5c3baf81a04496f4af428a21_R_1, _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0, _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2);
                    float _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0 = Vector1_745B9376;
                    float _Multiply_a07084ffbf220388b55751a6362f056b_Out_2;
                    Unity_Multiply_float(IN.TimeParameters.x, _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2);
                    float _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2;
                    Unity_Add_float(_Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2, _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2);
                    float _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1;
                    Unity_Sine_float(_Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2, _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1);
                    float _Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0 = Vector1_AF318A03;
                    float _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2;
                    Unity_Divide_float(_Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0, 100, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2);
                    float _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2;
                    Unity_Multiply_float(_Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2, _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2);
                    float _Property_02aa838086edbc889d6afefebe6be70d_Out_0 = Vector1_56BE0FD1;
                    float _Add_1113249fecc4d28da19af79ba352056d_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Add_1113249fecc4d28da19af79ba352056d_Out_2);
                    float _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_1113249fecc4d28da19af79ba352056d_Out_2, _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2);
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, 1, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
                    surface.Alpha = _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                    output.uv0 =                         input.texCoord0;
                    output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "DepthOnly"
                Tags
                {
                    "LightMode" = "DepthOnly"
                }
    
                // Render State
                Cull Back
                Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
                ZTest LEqual
                ZWrite On
                ColorMask 0
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _SURFACE_TYPE_TRANSPARENT 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_DEPTHONLY
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float4 texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float4 uv0;
                    float3 TimeParameters;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float4 interp0 : TEXCOORD0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyzw =  input.texCoord0;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.texCoord0 = input.interp0.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float4 Color_234C1B0B;
                float Vector1_8DA20226;
                float4 Color_D12BF231;
                float Vector1_56BE0FD1;
                float Vector1_745B9376;
                float Vector1_5CB84537;
                float Vector1_AF318A03;
                float Vector1_63384718;
                float Vector1_73BD9798;
                float Vector1_D775EAAC;
                CBUFFER_END
                
                // Object and Global properties
                float4 Color_20C936C9;
    
                // Graph Functions
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Sine_float(float In, out float Out)
                {
                    Out = sin(In);
                }
                
                void Unity_Divide_float(float A, float B, out float Out)
                {
                    Out = A / B;
                }
                
                void Unity_Comparison_Greater_float(float A, float B, out float Out)
                {
                    Out = A > B ? 1 : 0;
                }
                
                void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                {
                    Out = Predicate ? True : False;
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float Alpha;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0 = IN.uv0;
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_R_1 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[0];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_G_2 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[1];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_B_3 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[2];
                    float _Split_b7f6798c5c3baf81a04496f4af428a21_A_4 = _UV_6f1267cd4a4f6b8c9d18af15f7eedb7e_Out_0[3];
                    float _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0 = Vector1_5CB84537;
                    float _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2;
                    Unity_Multiply_float(_Split_b7f6798c5c3baf81a04496f4af428a21_R_1, _Property_4f7aae92b853da85956c0fd7469dc4f0_Out_0, _Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2);
                    float _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0 = Vector1_745B9376;
                    float _Multiply_a07084ffbf220388b55751a6362f056b_Out_2;
                    Unity_Multiply_float(IN.TimeParameters.x, _Property_7d1c5f931dfe7f8bb61a1fe5ccd7aca7_Out_0, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2);
                    float _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2;
                    Unity_Add_float(_Multiply_c48821dac71694859e6d01f7dc8bd6b6_Out_2, _Multiply_a07084ffbf220388b55751a6362f056b_Out_2, _Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2);
                    float _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1;
                    Unity_Sine_float(_Add_068b73da3bb6c48d9bce70e4e7c9d03e_Out_2, _Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1);
                    float _Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0 = Vector1_AF318A03;
                    float _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2;
                    Unity_Divide_float(_Property_6fe884b2bd79cd8ebcde9902b4feaab3_Out_0, 100, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2);
                    float _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2;
                    Unity_Multiply_float(_Sine_760e7551b6c0c284a416b07723a7c3a1_Out_1, _Divide_c4e337ab38b92b8ea564d7ffa749cce1_Out_2, _Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2);
                    float _Property_02aa838086edbc889d6afefebe6be70d_Out_0 = Vector1_56BE0FD1;
                    float _Add_1113249fecc4d28da19af79ba352056d_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Add_1113249fecc4d28da19af79ba352056d_Out_2);
                    float _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_1113249fecc4d28da19af79ba352056d_Out_2, _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2);
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, 1, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
                    surface.Alpha = _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                    output.uv0 =                         input.texCoord0;
                    output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
    
                ENDHLSL
            }
        }
    }
