using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;

using WindowsInput;
using WindowsInput.Native;

// original source by "Mavina" http://answers.unity3d.com/answers/1204307/view.html
// usage: Place this script into Editor/ folder, then you can press F5 to enter/exit Play Mode

public class EditorShortCutKeys : ScriptableObject
{
    static IInputSimulator inputSimulator = new InputSimulator();

    [MenuItem("ShortCutKeys/Play Game _F5")] // shortcut key F5 to Play (and exit playmode also)
    static void PlaySplashScene()
    {
        if (!Application.isPlaying)
        {
            string[] guids = AssetDatabase.FindAssets("MainScene t:scene");
            if (guids.Length != 0)
            {
                EditorSceneManager.SaveScene(SceneManager.GetActiveScene(), "", false); // optional: save before run
                EditorSceneManager.OpenScene(AssetDatabase.GUIDToAssetPath(guids[0]));
                EditorApplication.ExecuteMenuItem("Edit/Play");
            }
        }
        else
        {
            EditorApplication.ExecuteMenuItem("Edit/Play");
        }
    }

    [MenuItem("ShortCutKeys/Run Current Scene #_F5")] // shortcut key F5 to Play (and exit playmode also)
    static void PlayGame()
    {
        EditorApplication.ExecuteMenuItem("Edit/Play");
    }

    [MenuItem("ShortCutKeys/Pause _F6")] // shortcut key F5 to Play (and exit playmode also)
    static void PauseGame()
    {
        EditorApplication.ExecuteMenuItem("Edit/Pause");
    }

    [MenuItem("ShortCutKeys/Step _F7")] // shortcut key F5 to Play (and exit playmode also)
    static void StepGame()
    {
        EditorApplication.ExecuteMenuItem("Edit/Step");
    }

    [MenuItem("ShortCutKeys/Toggle Selected GameObject _F1")] // shortcut key F5 to Play (and exit playmode also)
    static void ToggleSelectedObjectActivity()
    {
        if (Selection.activeGameObject == null) return;
        Selection.activeGameObject.SetActive(!Selection.activeGameObject.activeSelf);
    }

    [MenuItem("ShortCutKeys/Open C# Project _F3")] // shortcut key F5 to Play (and exit playmode also)
    static void OpenCSharpProject()
    {
        EditorApplication.ExecuteMenuItem("Assets/Open C# Project");
    }

    [MenuItem("ShortCutKeys/Align Camera With View _F4")] // shortcut key F5 to Play (and exit playmode also)
    static void AlignCameraWithView()
    {
        var mainCamera = Camera.main;
        if (mainCamera)
        {
            Selection.activeGameObject = mainCamera.gameObject;
            SceneView sceneView = SceneView.sceneViews[0] as SceneView;
            if (sceneView)
            {
                sceneView.Focus();
            }

            EditorApplication.ExecuteMenuItem("GameObject/Align With View");
        }
    }

    //[MenuItem("ShortCutKeys/Lock View to Player _F3")] // shortcut key F5 to Play (and exit playmode also)
    //static void LockViewToPlayer()
    //{
    //    GameObject goPlayer = PlayerController.Instance.entity.gameObject;
    //    if (goPlayer != null)
    //    {
    //        Selection.activeGameObject = goPlayer;
    //        SceneView sceneView = SceneView.sceneViews[0] as SceneView;
    //        if (sceneView)
    //        {
    //            sceneView.Focus();
    //        }

    //        inputSimulator.Keyboard.ModifiedKeyStroke(VirtualKeyCode.SHIFT, VirtualKeyCode.VK_F)
    //            .Sleep(100)
    //            .Mouse.VerticalScroll(1000);
    //    }
    //}

    //static System.WeakReference refScene;
    //[MenuItem("ShortCutKeys/Toggle Scene Display _F4")] // shortcut key F5 to Play (and exit playmode also)
    //static void ToggleSceneDisplay()
    //{
    //    if (refScene == null || refScene.IsAlive == false)
    //    {
    //        GameObject goScene = GameObject.Find("scene");
    //        if (goScene != null)
    //        {
    //            refScene = new System.WeakReference(goScene);
    //        }
    //    }

    //    if (refScene != null && refScene.IsAlive)
    //    {
    //        GameObject goScene = refScene.Target as GameObject;
    //        goScene.SetActive(!goScene.activeSelf);
    //    }

    //}

    [MenuItem("ShortCutKeys/Find in Project _F9")] // shortcut key F5 to Play (and exit playmode also)
    static void FindInProject()
    {
        inputSimulator.Keyboard.ModifiedKeyStroke(VirtualKeyCode.CONTROL, VirtualKeyCode.VK_5)
            .ModifiedKeyStroke(VirtualKeyCode.CONTROL, VirtualKeyCode.VK_F);
    }

    [MenuItem("ShortCutKeys/Find in Hierarchy _F10")] // shortcut key F5 to Play (and exit playmode also)
    static void FindInHierarchy()
    {
        inputSimulator.Keyboard.ModifiedKeyStroke(VirtualKeyCode.CONTROL, VirtualKeyCode.VK_4)
            .ModifiedKeyStroke(VirtualKeyCode.CONTROL, VirtualKeyCode.VK_F);
    }

    //[MenuItem("ShortCutKeys/Toggle Pathfinding Data Display _F8")]
    //static void TogglePathfindingDataDisplay()
    //{
    //    NavGraph _graph = AstarPath.active.astarData.FindGraphOfType(typeof(NavMeshGraph));
    //    if (_graph != null)
    //    {
    //        _graph.drawGizmos = !_graph.drawGizmos;
    //        if (!Application.isPlaying || EditorApplication.isPaused) SceneView.RepaintAll();
    //    }
    //}

}