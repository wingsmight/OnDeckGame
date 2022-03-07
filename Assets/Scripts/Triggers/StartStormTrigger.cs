using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StartStormTrigger : MonoBehaviour
{
    [SerializeField] private Storm storm;


    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.TryGetComponent<Boat>(out var boat))
        {
            storm.CanBeEnabled = true;
        }
    }
}
