using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Sky : MonoBehaviour
{
    [SerializeField] private float firstStateDelay = 75.0f;
    [SerializeField] private float stateDuration = 120.0f;


    public event Action<SkyState> onStateChanged;

    private SkyState currentState = SkyState.Morning;


    private void Start()
    {
        StartCoroutine(ChangeState());
    }


    private IEnumerator ChangeState()
    {
        yield return new WaitForSeconds(firstStateDelay);
        SetNextState();

        while (true)
        {
            yield return new WaitForSeconds(stateDuration);

            SetNextState();
        }
    }
    private void SetNextState()
    {
        if ((int)currentState < System.Enum.GetValues(typeof(SkyState)).Length - 1)
        {
            currentState++;
        }
        else
        {
            currentState = (SkyState)0;
        }

        onStateChanged?.Invoke(currentState);
    }
}
