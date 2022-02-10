using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoatControl : MonoBehaviour
{
    [SerializeField] private Boat boat;
    [SerializeField] private float sailRigidity = 1.0f;
    [SerializeField] private Vector2 calmForce = new Vector2(1.0f, 0.0f);


    private float sailHeight;


    private void Awake()
    {
        sailHeight = boat.SailHeightLimit.medium;
    }
    private void FixedUpdate()
    {
        MoveSail(sailHeight);
    }


    private void MoveSail(float height)
    {
        boat.Rigidbody.AddForce(calmForce * sailRigidity * height, ForceMode2D.Impulse);
    }


    public float SailHeight { get => sailHeight; set => sailHeight = value; }
}
