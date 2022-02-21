using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(CanvasGroup))]
public class FadeAnimation : Fade
{
    protected CanvasGroup canvasGroup;
    private bool isBlockRaycasts;
    private bool isInteractable;


    protected override void Awake()
    {
        isBlockRaycasts = CanvasGroup.blocksRaycasts;
        isInteractable = CanvasGroup.interactable;

        base.Awake();
    }


    public override void Appear(float finishAlpha = MAX_FLOAT)
    {
        CanvasGroup.blocksRaycasts = isBlockRaycasts;

        base.Appear();
    }
    public override void SetVisible(bool state)
    {
        CanvasGroup.interactable = isInteractable && state;
        CanvasGroup.blocksRaycasts = isBlockRaycasts && state;

        base.SetVisible(state);
    }


    protected override float Alpha { get => CanvasGroup.alpha; set => CanvasGroup.alpha = value; }

    private CanvasGroup CanvasGroup
    {
        get
        {
            if (canvasGroup == null)
            {
                canvasGroup = GetComponent<CanvasGroup>();
            }
            return canvasGroup;
        }
    }
}
