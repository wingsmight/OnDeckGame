using UnityEngine;

public class Parallax : MonoBehaviour
{
    [SerializeField] private new Transform cameraTransofrm;
    [SerializeField] private float parallaxEffect;


    private float startPositionX;
    private float startCameraPositionX;


    private void Awake()
    {
        startPositionX = transform.position.x;
        startCameraPositionX = cameraTransofrm.position.x;
    }
    private void Update()
    {
        float offset = (cameraTransofrm.transform.position.x - startCameraPositionX) * parallaxEffect;

        transform.position = new Vector3(startPositionX + offset, transform.position.y, transform.position.z);
    }
}