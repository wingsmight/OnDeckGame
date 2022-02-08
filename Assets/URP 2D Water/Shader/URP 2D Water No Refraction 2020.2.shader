Shader "Azerilo/URP 2D Water No Refraction"
    {
        Properties
        {
            Color_234C1B0B("Water Top Color", Color) = (1, 1, 1, 0)
            Vector1_8DA20226("Water Top Width", Float) = 5
            Color_D12BF231("Water Color", Color) = (0.01960784, 0.6588235, 0.8588235, 0)
            Vector1_56BE0FD1("Water Level", Range(0, 1)) = 0.8
            Vector1_745B9376("Wave Speed", Float) = 3
            Vector1_5CB84537("Wave Frequency", Float) = 18
            Vector1_AF318A03("Wave Depth", Range(0, 20)) = 1.4
            Vector1_AE30F744("Water Opacity", Range(0, 1)) = 0.5
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
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_UNLIT
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
                float Vector1_AE30F744;
                CBUFFER_END
                
                // Object and Global properties
                float4 Color_20C936C9;
    
                // Graph Functions
                
                void Unity_Add_float4(float4 A, float4 B, out float4 Out)
                {
                    Out = A + B;
                }
                
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
                
                void Unity_Subtract_float(float A, float B, out float Out)
                {
                    Out = A - B;
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
                    float _Add_1113249fecc4d28da19af79ba352056d_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Add_1113249fecc4d28da19af79ba352056d_Out_2);
                    float _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_1113249fecc4d28da19af79ba352056d_Out_2, _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2);
                    float _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0 = Vector1_AE30F744;
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
                    surface.BaseColor = (_Lerp_f44b73cbec88f78c828ce3d15cb88ed1_Out_3.xyz);
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
                float Vector1_AE30F744;
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
                    float _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0 = Vector1_AE30F744;
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
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
                float Vector1_AE30F744;
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
                    float _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0 = Vector1_AE30F744;
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
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
                #define VARYINGS_NEED_TEXCOORD0
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_UNLIT
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
                float Vector1_AE30F744;
                CBUFFER_END
                
                // Object and Global properties
                float4 Color_20C936C9;
    
                // Graph Functions
                
                void Unity_Add_float4(float4 A, float4 B, out float4 Out)
                {
                    Out = A + B;
                }
                
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
                
                void Unity_Subtract_float(float A, float B, out float Out)
                {
                    Out = A - B;
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
                    float _Add_1113249fecc4d28da19af79ba352056d_Out_2;
                    Unity_Add_float(_Multiply_fdd6b73180e3858fa5fc065d48e419a4_Out_2, _Property_02aa838086edbc889d6afefebe6be70d_Out_0, _Add_1113249fecc4d28da19af79ba352056d_Out_2);
                    float _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2;
                    Unity_Comparison_Greater_float(_Split_b7f6798c5c3baf81a04496f4af428a21_G_2, _Add_1113249fecc4d28da19af79ba352056d_Out_2, _Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2);
                    float _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0 = Vector1_AE30F744;
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
                    surface.BaseColor = (_Lerp_f44b73cbec88f78c828ce3d15cb88ed1_Out_3.xyz);
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
                float Vector1_AE30F744;
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
                    float _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0 = Vector1_AE30F744;
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
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
                float Vector1_AE30F744;
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
                    float _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0 = Vector1_AE30F744;
                    float _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3;
                    Unity_Branch_float(_Comparison_9e92e65e6497ca8eac41208ea7d9f17e_Out_2, 0, _Property_14cd5d55d97e4089bcf6367e1e350403_Out_0, _Branch_9da848ed469ee88b867bbe3abf39a245_Out_3);
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
