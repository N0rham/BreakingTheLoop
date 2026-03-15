using System.Collections.Generic;
using JetBrains.Annotations;
using PolymindGames.Options;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using Toolbox;

namespace PolymindGames.Editor
{
    [UsedImplicitly]
    public sealed class OptionsPage : RootToolPage
    {
        private IEnumerable<IEditorToolPage> _subPages;
        
        public override string DisplayName => "Options";
        public override int Order => 3;

        public override void DrawContent()
        {
            GUILayout.BeginVertical();
            {
                GUILayout.Label(DisplayName, GUIStyles.Title);
                
                GUILayout.BeginVertical(EditorStyles.helpBox);
                DrawPageLinks(GetSubPages());
                GUILayout.FlexibleSpace();
                GUILayout.EndVertical();
            }
            GUILayout.EndVertical();
        }
        
        public override IEnumerable<IEditorToolPage> GetSubPages()
        {
            _subPages ??= CreateSubPages();
            return _subPages;
        }
        
        public override bool IsCompatibleWithObject(Object unityObject) => false;

        private static IEnumerable<IEditorToolPage> CreateSubPages()
        {
            var pages = new List<IEditorToolPage>();

            // Existing UserOptions sub-pages
            var types = typeof(UserOptions).GetAllChildClasses();
            types.RemoveAll(type => type.GetCustomAttribute(typeof(CreateAssetMenuAttribute)) == null);

            for (var i = 0; i < types.Count; i++)
            {
                var type = types[i];
                string pageName = ObjectNames.NicifyVariableName(type.Name);
                pages.Add(new ObjectInspectorToolPage(pageName, type, 0, LoadObject));

                Object LoadObject() => Resources.LoadAll(UserOptionsPersistence.OptionsAssetPath, type).FirstOrDefault();
            }

            // Post-processing volume profile sub-pages
            pages.Add(new PostProcessingPage());

            return pages;
        }
    }

    /// <summary>
    /// Tool page that exposes all URP VolumeProfile assets under Assets/Settings
    /// so post-processing overrides can be edited directly inside the Game Manager window.
    /// </summary>
    internal sealed class PostProcessingPage : ToolPage
    {
        private List<VolumeProfileEntry> _profiles;
        private Vector2 _scroll;

        public override string DisplayName => "Post Processing";
        public override int Order => 100;
        public override string Description => "Edit post-processing volume profiles used in the project.";
        public override bool IsCompatibleWithObject(Object unityObject) => false;

        public override void Refresh() => _profiles = null;

        public override void Dispose()
        {
            if (_profiles == null) return;
            foreach (var entry in _profiles)
                entry.Dispose();
        }

        public override void DrawContent()
        {
            GUILayout.Label(DisplayName, GUIStyles.Title);

            _profiles ??= LoadProfiles();

            if (_profiles.Count == 0)
            {
                EditorGUILayout.HelpBox("No VolumeProfile assets found under Assets/Settings.", MessageType.Info);
                return;
            }

            _scroll = EditorGUILayout.BeginScrollView(_scroll);
            foreach (var entry in _profiles)
                entry.Draw();
            EditorGUILayout.EndScrollView();
        }

        private static List<VolumeProfileEntry> LoadProfiles()
        {
            var result = new List<VolumeProfileEntry>();
            var guids = AssetDatabase.FindAssets("t:VolumeProfile", new[] { "Assets/Settings" });
            foreach (var guid in guids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                var profile = AssetDatabase.LoadAssetAtPath<VolumeProfile>(path);
                if (profile != null)
                    result.Add(new VolumeProfileEntry(profile));
            }
            return result;
        }

        private sealed class VolumeProfileEntry
        {
            private readonly VolumeProfile _profile;
            private readonly InspectorEditorWrapper _inspector;
            private bool _foldout = true;

            public VolumeProfileEntry(VolumeProfile profile)
            {
                _profile = profile;
                _inspector = new InspectorEditorWrapper();
                _inspector.SetTarget(profile);
            }

            public void Dispose() => _inspector.SetTarget(null);

            public void Draw()
            {
                GUILayout.Space(4f);
                _foldout = EditorGUILayout.Foldout(_foldout, _profile.name, true, EditorStyles.foldoutHeader);
                if (_foldout)
                    _inspector.Draw(EditorStyles.helpBox);
            }
        }
    }
}