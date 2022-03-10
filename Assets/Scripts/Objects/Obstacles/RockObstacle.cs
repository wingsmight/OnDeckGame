using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RockObstacle : MonoBehaviour
{
    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.TryGetComponent<Boat>(out Boat boat))
        {
            boat.Crash();
        }
    }
}
