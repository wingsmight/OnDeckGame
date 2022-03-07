using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EditorTimeScale : MonoBehaviour
{
#if UNITY_EDITOR
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.F7))
        {
            Time.timeScale -= 0.5f;
            print("Time.timeScale = " + Time.timeScale);
        }
        else if (Input.GetKeyDown(KeyCode.F9))
        {
            Time.timeScale += 0.5f;
            print("Time.timeScale = " + Time.timeScale);
        }
    }
#endif
}
