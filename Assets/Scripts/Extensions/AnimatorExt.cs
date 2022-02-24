using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class AnimatorExt
{
    public static string GetCurrentName(this Animator animator, int layer = 0)
    {
        AnimatorStateInfo info = animator.GetCurrentAnimatorStateInfo(layer);

        foreach (AnimationClip clip in animator.runtimeAnimatorController.animationClips)
        {
            if (info.IsName(clip.name))
                return clip.name;
        }

        return null;
    }
    public static AnimationClip GetCurrentClip(this Animator animator, int layer = 0)
    {
        AnimatorStateInfo info = animator.GetCurrentAnimatorStateInfo(layer);

        foreach (AnimationClip clip in animator.runtimeAnimatorController.animationClips)
        {
            if (info.IsName(clip.name))
                return clip;
        }

        return null;
    }
    public static AnimationClip GetClip(this Animator animator, string name, int layer = 0)
    {
        return animator.runtimeAnimatorController.animationClips.FirstOrDefault(x => x.name == name);
    }
}
