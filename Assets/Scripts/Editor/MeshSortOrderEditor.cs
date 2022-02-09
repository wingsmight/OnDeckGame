using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(MeshSortOrder))]
public class MeshSortOrderEditor : UnityEditor.Editor
{
    public override void OnInspectorGUI()
    {
        var renderer = (target as MeshSortOrder).gameObject.GetComponent<Renderer>();

        if (!renderer)
        {
            return;
        }

        string[] sortLayerNames = GetSortingLayerNames();
        int sortLayerSelection = GetSortingLayerIndex(renderer, sortLayerNames);

        GUIContent[] sortingLayerContexts = GetSortingLayerContexts();
        int newSortingLayerIndex = EditorGUILayout.Popup(new GUIContent("Sorting Layer"), sortLayerSelection, sortingLayerContexts);
        if (newSortingLayerIndex == sortingLayerContexts.Length - 1)
        {
            EditorApplication.ExecuteMenuItem("Edit/Project Settings/Tags and Layers");
        }
        else if (newSortingLayerIndex != sortLayerSelection)
        {
            string newSortingLayerName = sortLayerNames[newSortingLayerIndex];

            Undo.RecordObject(renderer, "Edit Sorting Layer ID");
            renderer.sortingLayerName = newSortingLayerName;

            EditorUtility.SetDirty(renderer);
        }

        int newSortingLayerOrder = EditorGUILayout.IntField("Order in Layer", renderer.sortingOrder);
        if (newSortingLayerOrder != renderer.sortingOrder)
        {
            Undo.RecordObject(renderer, "Edit Sorting Order");
            renderer.sortingOrder = newSortingLayerOrder;
            EditorUtility.SetDirty(renderer);
        }
    }
    public static GUIContent[] GetSortingLayerContexts()
    {
        List<GUIContent> contexts = new List<GUIContent>();

        foreach (string layerName in GetSortingLayerNames())
        {
            contexts.Add(new GUIContent(layerName));
        }

        contexts.Add(GUIContent.none);
        contexts.Add(new GUIContent("Edit Layers..."));

        return contexts.ToArray();
    }
    public static string[] GetSortingLayerNames()
    {
        Type internalEditorUtilityType = typeof(UnityEditorInternal.InternalEditorUtility);
        PropertyInfo sortingLayersProperty = internalEditorUtilityType.GetProperty("sortingLayerNames", BindingFlags.Static | BindingFlags.NonPublic);
        return (string[])sortingLayersProperty.GetValue(null, new object[0]);
    }
    public int[] GetSortingLayerUniqueIDs()
    {
        Type internalEditorUtilityType = typeof(UnityEditorInternal.InternalEditorUtility);
        PropertyInfo sortingLayerUniqueIDsProperty = internalEditorUtilityType.GetProperty("sortingLayerUniqueIDs", BindingFlags.Static | BindingFlags.NonPublic);
        return (int[])sortingLayerUniqueIDsProperty.GetValue(null, new object[0]);
    }
    public static int GetSortingLayerIndex(Renderer renderer, string[] layerNames)
    {
        for (int i = 0; i < layerNames.Length; ++i)
        {
            if (layerNames[i] == renderer.sortingLayerName)
                return i;

            if (layerNames[i] == "Default" && String.IsNullOrEmpty(renderer.sortingLayerName))
                return i;
        }

        return 0;
    }
    public static int GetSortingLayerIdIndex(Renderer renderer, int[] layerIds)
    {
        for (int i = 0; i < layerIds.Length; ++i)
        {
            if (layerIds[i] == renderer.sortingLayerID)
                return i;
        }

        return 0;
    }
}