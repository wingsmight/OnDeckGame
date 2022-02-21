using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CookieObject : MonoBehaviour
{
    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.TryGetComponent<Boat>(out Boat boat))
        {
            PlayerData.IncreaseCoockieCount();

            gameObject.SetActive(false);
        }
    }
}
