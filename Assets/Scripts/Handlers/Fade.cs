using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public abstract class Fade : MonoBehaviour
{
    protected const float MIN_FLOAT = 0.0f;
    protected const float MAX_FLOAT = 1.0f;


    [SerializeField] protected float speed = MAX_FLOAT;
    [SerializeField] protected bool isShowOnAwake = true;


    public delegate void ChangedEventHandler(bool state);
    public event ChangedEventHandler OnActiveChanged;


    protected virtual void Awake()
    {
        SetVisible(isShowOnAwake);
    }


    public virtual void Appear(float finishAlpha = MAX_FLOAT)
    {
        StopAllCoroutines();
        if (gameObject.activeInHierarchy)
        {
            StartCoroutine(FadeIn(finishAlpha));
        }
        else
        {
            Debug.Log("Coroutine FadeIn couldn't be started because the game object is inactive");
            Alpha = MAX_FLOAT;
        }
    }
    public virtual void Disappear()
    {
        StopAllCoroutines();
        if (gameObject.activeInHierarchy)
        {
            StartCoroutine(FadeOut());
        }
        else
        {
            Debug.Log("Coroutine FadeOut couldn't be started because the game object is inactive");

            Alpha = MIN_FLOAT;
        }
    }
    public virtual void SetVisible(bool state)
    {
        StopAllCoroutines();

        Alpha = state ? MAX_FLOAT : MIN_FLOAT;
    }

    private IEnumerator FadeOut()
    {
        while (Alpha > 0)
        {
            Alpha -= Time.deltaTime * speed;
            yield return null;
        }

        SetVisible(false);

        OnActiveChanged?.Invoke(false);
    }
    private IEnumerator FadeIn(float finishAlpha = MAX_FLOAT)
    {
        while (Alpha < finishAlpha)
        {
            Alpha += Time.deltaTime * speed;
            yield return null;
        }

        SetVisible(true);

        OnActiveChanged?.Invoke(true);
    }


    public bool IsShowing => Alpha > MIN_FLOAT;

    protected abstract float Alpha
    {
        get;
        set;
    }
}
