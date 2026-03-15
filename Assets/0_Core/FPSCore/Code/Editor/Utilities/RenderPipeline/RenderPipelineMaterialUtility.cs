using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System;

#if POLYMIND_GAMES_FPS_URP
using UnityEditor.Rendering;
using UnityEditor.Rendering.Universal;
#endif

namespace PolymindGames.Editor
{
    /// <summary>
    /// Utility class for managing materials across different render pipelines.
    /// </summary>
    public static class RenderPipelineMaterialUtility
    {
        private const string ConvertMaterialsToHdrpMenu = "Edit/Rendering/Materials/Convert All Built-in Materials to HDRP";

        /// <summary>
        /// Converts all materials in the project to the specified render pipeline type.
        /// </summary>
        /// <param name="targetPipelineType">The render pipeline type to convert materials to.</param>
        /// <param name="path"></param>
        public static void ConvertAllMaterialsAtPath(RenderPipelineType targetPipelineType, string path = "Assets/PolymindGames")
        {
            switch (targetPipelineType)
            {
                case RenderPipelineType.BIRP: ConvertMaterialsToBuiltIn(path); break;
                case RenderPipelineType.HDRP: ConvertMaterialsToHdrp(); break;
                case RenderPipelineType.URP: ConvertMaterialsToUrp(path); break;
                default: throw new ArgumentOutOfRangeException(nameof(targetPipelineType), targetPipelineType, null);
            }
        }

        /// <summary>
        /// Converts all materials in the project to HDRP.
        /// </summary>
        private static void ConvertMaterialsToHdrp()
        {
            EditorApplication.ExecuteMenuItem(ConvertMaterialsToHdrpMenu);
        }
        
        /// <summary>
        /// Converts all materials in the project to URP.
        /// </summary>
        private static void ConvertMaterialsToUrp(string path)
        {
#if POLYMIND_GAMES_FPS_URP
            int convertedCount = 0;
            int skippedCount = 0;
            int unsupportedCount = 0;

            var materialGuids = AssetDatabase.FindAssets($"t:{nameof(Material)}", new[] { path });
            foreach (var materialGuid in materialGuids)
            {
                string materialPath = AssetDatabase.GUIDToAssetPath(materialGuid);
                var material = AssetDatabase.LoadAssetAtPath<Material>(materialPath);
                if (material == null || material.shader == null)
                {
                    skippedCount++;
                    continue;
                }

                if (TryConvertToUrp(material, out bool unsupported))
                    convertedCount++;
                else
                {
                    skippedCount++;
                    if (unsupported)
                        unsupportedCount++;
                }
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log($"Converted {convertedCount} material(s) to URP under {path}. Skipped {skippedCount} (unsupported: {unsupportedCount}).");
#endif
        }

#if POLYMIND_GAMES_FPS_URP
        private static bool TryConvertToUrp(Material material, out bool unsupported)
        {
            unsupported = false;

            string shaderName = material.shader.name;
            if (shaderName.StartsWith("Universal Render Pipeline/", StringComparison.Ordinal))
                return false;

            if (shaderName.StartsWith("Skybox/", StringComparison.Ordinal))
            {
                unsupported = true;
                return false;
            }

            if (shaderName == "Standard" || shaderName == "Standard (Specular setup)")
                return UpgradeWith(material, new StandardUpgrader(shaderName));

            if (shaderName == "Autodesk Interactive")
                return UpgradeWith(material, new AutodeskInteractiveUpgrader(shaderName));

            if (shaderName == "Particles/Standard Surface" || shaderName == "Particles/Standard Unlit" || shaderName == "Particles/VertexLit Blended")
                return UpgradeWith(material, new ParticleUpgrader(shaderName));

            if (shaderName.StartsWith("Legacy Shaders/Particles/", StringComparison.Ordinal))
                return ConvertLegacyParticleMaterial(material);

            unsupported = true;
            return false;
        }

        private static bool UpgradeWith(Material material, MaterialUpgrader upgrader)
        {
            var upgraders = new List<MaterialUpgrader> { upgrader };
            string message = string.Empty;
            bool upgraded = MaterialUpgrader.Upgrade(material, upgraders, MaterialUpgrader.UpgradeFlags.LogMessageWhenNoUpgraderFound, ref message);
            if (upgraded)
                EditorUtility.SetDirty(material);

            return upgraded;
        }

        private static bool ConvertLegacyParticleMaterial(Material material)
        {
            Shader targetShader = Shader.Find("Universal Render Pipeline/Particles/Unlit");
            if (targetShader == null)
                return false;

            var previous = new Material(material);

            material.shader = targetShader;
            CopyTexture(previous, material, "_MainTex", "_BaseMap");
            CopyColor(previous, material, ResolveLegacyParticleColor(previous), "_BaseColor");
            CopyFloat(previous, material, "_Cutoff", "_Cutoff");
            CopyFloat(previous, material, "_FlipbookMode", "_FlipbookBlending");
            CopyFloat(previous, material, "_SoftParticlesEnabled", "_SoftParticlesEnabled");
            CopyFloat(previous, material, "_CameraFadingEnabled", "_CameraFadingEnabled");

            ApplyLegacyParticleBlend(previous, material);
            EditorUtility.SetDirty(material);
            UnityEngine.Object.DestroyImmediate(previous);
            return true;
        }

        private static string ResolveLegacyParticleColor(Material material)
        {
            if (material.HasProperty("_TintColor"))
                return "_TintColor";

            return material.HasProperty("_Color") ? "_Color" : string.Empty;
        }

        private static void ApplyLegacyParticleBlend(Material previous, Material material)
        {
            float legacyMode = previous.HasProperty("_Mode") ? previous.GetFloat("_Mode") : 2f;

            switch ((int)legacyMode)
            {
                case 0:
                    SetFloat(material, "_Surface", 0f);
                    material.DisableKeyword("_SURFACE_TYPE_TRANSPARENT");
                    break;
                case 1:
                    SetFloat(material, "_Surface", 0f);
                    SetFloat(material, "_AlphaClip", 1f);
                    material.DisableKeyword("_SURFACE_TYPE_TRANSPARENT");
                    break;
                case 3:
                    SetTransparent(material, 1f);
                    break;
                case 4:
                    SetTransparent(material, 2f);
                    break;
                case 6:
                    SetTransparent(material, 3f);
                    break;
                default:
                    SetTransparent(material, 0f);
                    break;
            }

            material.renderQueue = previous.renderQueue >= 0 ? previous.renderQueue : (int)UnityEngine.Rendering.RenderQueue.Transparent;
        }

        private static void SetTransparent(Material material, float blendMode)
        {
            SetFloat(material, "_Surface", 1f);
            SetFloat(material, "_Blend", blendMode);
            material.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
        }

        private static void CopyTexture(Material source, Material target, string sourceProperty, string targetProperty)
        {
            if (!source.HasProperty(sourceProperty) || !target.HasProperty(targetProperty))
                return;

            target.SetTexture(targetProperty, source.GetTexture(sourceProperty));
            target.SetTextureScale(targetProperty, source.GetTextureScale(sourceProperty));
            target.SetTextureOffset(targetProperty, source.GetTextureOffset(sourceProperty));
        }

        private static void CopyColor(Material source, Material target, string sourceProperty, string targetProperty)
        {
            if (string.IsNullOrEmpty(sourceProperty) || !source.HasProperty(sourceProperty) || !target.HasProperty(targetProperty))
                return;

            target.SetColor(targetProperty, source.GetColor(sourceProperty));
        }

        private static void CopyFloat(Material source, Material target, string sourceProperty, string targetProperty)
        {
            if (!source.HasProperty(sourceProperty) || !target.HasProperty(targetProperty))
                return;

            target.SetFloat(targetProperty, source.GetFloat(sourceProperty));
        }

        private static void SetFloat(Material material, string propertyName, float value)
        {
            if (material.HasProperty(propertyName))
                material.SetFloat(propertyName, value);
        }
#endif
        
        /// <summary>
        /// Converts all materials in the project to the Built-in Render Pipeline.
        /// </summary>
        private static void ConvertMaterialsToBuiltIn(string path)
        {
            var settings = Resources.Load<MaterialConversionSettings>("Editor/MaterialConversionSettings");
            if (settings == null)
            {
                Debug.LogError("No convert settings found.");
                return;
            }
            
            ConvertAllMaterials(settings, path);
            Resources.UnloadAsset(settings);
        }

        private static void ConvertAllMaterials(MaterialConversionSettings settings, string path)
        {
            var materialGuids = AssetDatabase.FindAssets($"t:{nameof(Material)}", new[] { path });
            var lookup = settings.GetLookup();
            
            // Get all materials in the project
            foreach (var materialGuid in materialGuids)
            {
                var materialPath = AssetDatabase.GUIDToAssetPath(materialGuid);
                var material = AssetDatabase.LoadAssetAtPath<Material>(materialPath);

                if (material == null)
                    continue;
                
                if (lookup.TryGetValue(material.shader, out var convertInfo))
                    MaterialConvertUtility.ConvertMaterial(material, convertInfo, materialPath);
            }

            // Refresh the AssetDatabase to apply changes
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }
}