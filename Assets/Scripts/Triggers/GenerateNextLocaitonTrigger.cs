using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateNextLocaitonTrigger : MonoBehaviour
{
    [SerializeField] private LocationGeneration generation;


    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.TryGetComponent<Boat>(out var boat))
        {
            generation.Generate();
        }
    }
}
