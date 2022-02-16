using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Vector3Ext
{
    public static Vector2 Rotate(this Vector2 vector, float degrees)
    {
        degrees = degrees % 360;
        float radians = Mathf.Deg2Rad * degrees;

        return new Vector2(
            Mathf.Cos(radians) * vector.x - Mathf.Sin(radians) * vector.y,
            Mathf.Sin(radians) * vector.x + Mathf.Cos(radians) * vector.y
        );
    }
}
