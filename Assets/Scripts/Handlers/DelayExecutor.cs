using System;
using System.Collections;
using UnityEngine;


public class DelayExecutor : MonoBehaviourSingleton<DelayExecutor>
{
    public Coroutine Execute(Action action, float delay)
    {
        return StartCoroutine(ExecuteRoutine(action, delay));
    }

    private IEnumerator ExecuteRoutine(Action action, float delay)
    {
        yield return new WaitForSeconds(delay);

        action?.Invoke();
    }
}
