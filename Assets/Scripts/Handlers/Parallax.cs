using UnityEngine;

public class Parallax : MonoBehaviour
{
    [SerializeField] private new GameObject camera;
    [SerializeField] private float parallaxEffect;


    private float startPositionX;
    private float length;


    private void Start()
    {
        startPositionX = transform.position.x;
        length = GetComponent<SpriteRenderer>().bounds.size.x;
    }
    private void Update()
    {
        float temp = camera.transform.position.x * (1.0f - parallaxEffect);
        float dist = camera.transform.position.x * parallaxEffect;

        transform.position = new Vector3(startPositionX + dist, transform.position.y, transform.position.z);

        if (temp > startPositionX + length / 1.2f)
            startPositionX += length * 1.71f;
        else if (temp < startPositionX - length / 1.2f)
            startPositionX -= length * 1.71f;
    }
}