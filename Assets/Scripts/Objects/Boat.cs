using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Boat : MonoBehaviour
{
    private const float CRUSH_MASS = 10000.0f;


    [SerializeField] private new Rigidbody2D rigidbody;
    [SerializeField] private Span sailHeightLimit;
    [SerializeField] private Animator animator;
    [SerializeField] private new Collider2D collider;


    public event Action OnDestroyed;

    private float mass;


    private void Awake()
    {
        mass = rigidbody.mass;
    }
    private void OnEnable()
    {
        transform.localRotation = Quaternion.Euler(Vector3.zero);
        rigidbody.mass = mass;
        animator.enabled = false;
    }


    public void Crash()
    {
        rigidbody.mass = CRUSH_MASS;
        animator.enabled = true;
        animator.Play("Crash", 0, 0);

        StartCoroutine(DestroyRoutine(animator.GetClip("Crash").length));
    }

    private void Destroy()
    {
        gameObject.SetActive(false);

        OnDestroyed?.Invoke();
    }
    private IEnumerator DestroyRoutine(float delay)
    {
        yield return new WaitForSeconds(delay);

        Destroy();
    }


    public Rigidbody2D Rigidbody => rigidbody;
    public Span SailHeightLimit => sailHeightLimit;
    public Collider2D Collider => collider;
}
