using UnityEngine;

public class WaterNode
{
    Vector2 positionBase;
    public Vector2 position;
    public float velocity;


    public WaterNode(Vector2 position, float disturbance = 0.0f)
    {
        positionBase = position;
        this.position = positionBase;
        this.position.y += disturbance;
    }
}
