using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraZoom : MonoBehaviour
{
    [SerializeField] private Rigidbody2D target;
    [Space]
    [SerializeField] private float factor;
    [SerializeField] private Span sizeLimit;


    private new Camera camera;
    private float startSize;
    private Vector3[] childrenLocalScales = new Vector3[0];


    private void Awake()
    {
        this.camera = GetComponent<Camera>();
        startSize = camera.orthographicSize;

        childrenLocalScales = new Vector3[transform.childCount];
        for (int i = 0; i < childrenLocalScales.Length; i++)
        {
            childrenLocalScales[i] = transform.GetChild(i).localScale;
        }
    }
    private void Update()
    {
        camera.orthographicSize = startSize + target.velocity.x * factor;
        camera.orthographicSize = Mathf.Clamp(camera.orthographicSize, sizeLimit.start, sizeLimit.finish);

        float cameraSizeRatioDiff = camera.orthographicSize / startSize;

        for (int i = 0; i < childrenLocalScales.Length; i++)
        {
            transform.GetChild(i).localScale = childrenLocalScales[i] * cameraSizeRatioDiff;
        }
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
