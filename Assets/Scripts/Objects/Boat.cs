using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Boat : MonoBehaviour
{
    [SerializeField] private new Rigidbody2D rigidbody;
    [SerializeField] private Span sailHeightLimit;


    public Rigidbody2D Rigidbody => rigidbody;
    public Span SailHeightLimit => sailHeightLimit;
}
