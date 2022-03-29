using UnityEngine;

public class Parallax : MonoBehaviour
{
    [SerializeField] private Transform cameraTransform;
    [SerializeField] private float parallaxEffect;


    private float startPositionX;
    private float startCameraPositionX;


    private void Awake()
    {
        startPositionX = transform.position.x;
        startCameraPositionX = cameraTransform.position.x;
    }
    private void Update()
    {
        float offset = (cameraTransform.transform.position.x - startCameraPositionX) * parallaxEffect;

        transform.position = new Vector3(startPositionX + offset, transform.position.y, transform.position.z);
    }
}