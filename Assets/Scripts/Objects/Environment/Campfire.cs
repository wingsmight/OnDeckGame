using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Campfire : MonoBehaviour
{
    [SerializeField] private Sky sky;
    [SerializeField] private Animator animator;
    [Space]
    [SerializeField] private float eveningBurnDelay = 95.0f;


    private void Awake()
    {
        sky.onStateChanged += SwitchBurning;
    }


    public void SwitchBurning(SkyState skyState)
    {
        if (skyState == SkyState.Evening)
        {
            DelayExecutor.Instance.Execute(Burn, eveningBurnDelay);
        }
        else if (skyState == SkyState.Morning)
        {
            PutOut();
        }
    }
    public void Burn()
    {
        animator.Play("Burn", 0, 0);
    }
    public void PutOut()
    {
        animator.Play("PutOut", 0, 0);
    }
}
