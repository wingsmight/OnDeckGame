using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class LogObstacle : MonoBehaviour
{
    [SerializeField] private float sinkMass = 4.0f;
    [SerializeField] private float floatDuration = 4.0f;


    private float startMass;
    private new Rigidbody2D rigidbody;
    private bool isSinking = false;


    private void Awake()
    {
        rigidbody = GetComponent<Rigidbody2D>();
        startMass = rigidbody.mass;
    }
    private void OnMouseDown()
    {
        if (!isSinking)
        {
            rigidbody.mass = sinkMass;

            StartCoroutine(FloatRoutine());
        }
    }


    private IEnumerator FloatRoutine()
    {
        isSinking = true;

        float timeElapsed = 0.0f;
        float sinkMass = rigidbody.mass;
        float floatMass = startMass;
        while (timeElapsed < floatDuration)
        {
            rigidbody.mass = Mathf.Lerp(sinkMass, floatMass, timeElapsed / floatDuration);
            timeElapsed += Time.deltaTime;

            yield return new WaitForEndOfFrame();
        }

        rigidbody.mass = floatMass;
        isSinking = false;
    }
}
