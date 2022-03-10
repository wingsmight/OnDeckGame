using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraFollow : MonoBehaviour
{
    [SerializeField] private Transform target;
    [SerializeField] private float dampTime = 0.15f;
    [SerializeField] private float leftLimit;
    [SerializeField] private float rightLimit;
    [SerializeField] private float bottomLimit;
    [SerializeField] private float topLimit;
    [SerializeField] private Vector2 offset = Vector2.zero;


    private Vector3 velocity = Vector3.zero;
    private new Camera camera;
    private float startSize;
    private float startLeftLimit;


    private void Awake()
    {
        this.camera = GetComponent<Camera>();
        startSize = camera.orthographicSize;
        startLeftLimit = leftLimit;
    }
    private void FixedUpdate()
    {
        Vector3 point = camera.WorldToViewportPoint(target.position);
        Vector3 delta = target.position - camera.ViewportToWorldPoint(new Vector3(0.5f, 0.5f, point.z));
        Vector3 destination = transform.position + delta;

        float cameraSizeRatioDiff = camera.orthographicSize / startSize;
        leftLimit = startLeftLimit + (cameraSizeRatioDiff - 1.0f) * camera.orthographicSize;

        transform.position = Vector3.SmoothDamp(transform.position, destination, ref velocity, dampTime);

        float positionX = Mathf.Clamp(transform.position.x, leftLimit, rightLimit);
        float positionY = Mathf.Clamp(transform.position.y, bottomLimit, topLimit);

        transform.position = new Vector3(positionX, positionY, transform.position.z);
        transform.position += (Vector3)offset;
    }
}
