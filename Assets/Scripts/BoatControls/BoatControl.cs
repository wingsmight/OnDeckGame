using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoatControl : MonoBehaviour
{
    [SerializeField] private Boat boat;
    [SerializeField] private float sailRigidity = 1.0f;
    [SerializeField] private Vector2 calmForce = new Vector2(1.0f, 0.0f);
    [SerializeField] private Collider2D waterCollider;
    [SerializeField] private ForceMode2D forceMode;


    private float sailHeight;


    private void Awake()
    {
        sailHeight = boat.SailHeightLimit.start;
    }
    private void FixedUpdate()
    {
        MoveSail(sailHeight);
    }


    private void MoveSail(float height)
    {
        boat.Rigidbody.AddForce(calmForce * sailRigidity * height, forceMode);
    }


    public float SailHeight { get => sailHeight; set => sailHeight = value; }
}
