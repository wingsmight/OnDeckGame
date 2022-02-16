using UnityEngine;

public class WaterNode
{
    Vector2 positionBase;
    public Vector2 position;
    public float velocity;
    public float acceleration;
    public float disturbance;

    // const float massPerNode = 0.04f;

    #region Properties
    public float Displacement
    {
        get => position.y - positionBase.y;
    }
    #endregion

    #region Public Functions

    #region Construnctors
    public WaterNode(Vector2 position)
    {
        positionBase = position;
        this.position = position;
    }
    public WaterNode(Vector2 position, float disturbance)
    {
        positionBase = position;
        this.position = positionBase;
        this.position.y += disturbance;
    }
    #endregion

    public void Update(float springConstant, float damping, float massPerNode)
    {
        float force = springConstant * Displacement + velocity * damping;
        acceleration = -force / massPerNode + disturbance * Time.fixedDeltaTime;
        disturbance += -disturbance * damping;

        position.y += velocity * Time.fixedDeltaTime;
        velocity += acceleration;
    }
    public float Splash(float splasherMass, float splasherVelocity, float massPerNode)
    {
        splasherVelocity = Mathf.Min(0f, splasherVelocity);

        this.velocity =
            (2 * splasherMass * splasherVelocity + (massPerNode - splasherMass) * this.velocity) /
            (splasherMass + massPerNode)
        ;

        // this.velocity += (splasherMass / massPerNode) * .3f * splasherVelocity;
        return
            ((splasherMass - massPerNode) * splasherVelocity + 2 * massPerNode * this.velocity) /
            (splasherMass + massPerNode)
        ;
    }
    public void SplashPrime(float staticVelocity, float splasherMass, float massPerNode)
    {
        this.velocity =
            (massPerNode - splasherMass) * this.velocity /
            (splasherMass + massPerNode)
        ;
    }
    public void Disturb(float positionDelta)
    {
        this.position.y = positionBase.y + positionDelta;
    }
    #endregion
}
