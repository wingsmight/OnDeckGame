using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraZoom : MonoBehaviour
{
    private new Camera camera;


    private void Awake()
    {
        this.camera = GetComponent<Camera>();
    }


    public IEnumerator Zoom(float targetScale, float duration)
    {
        float timeElapsed = 0.0f;
        float startScale = camera.orthographicSize;
        while (timeElapsed < duration)
        {
            camera.orthographicSize = Mathf.Lerp(startScale, targetScale, timeElapsed / duration);
            timeElapsed += Time.deltaTime;

            yield return new WaitForEndOfFrame();
        }

        camera.orthographicSize = targetScale;
    }
}
