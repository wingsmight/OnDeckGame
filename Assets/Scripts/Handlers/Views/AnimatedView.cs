using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimatedView : MonoBehaviour, IShowHidable
{
    [SerializeField] private Animator animator;


    private bool isShowing;


    public void Show()
    {
        isShowing = true;

        animator.Play("Show");
    }
    public void Hide()
    {
        isShowing = false;

        animator.Play("Hide");
    }


    public bool IsShowing => isShowing;
}
