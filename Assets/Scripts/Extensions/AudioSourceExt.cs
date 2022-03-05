using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class AudioSourceExt
{
    public static IEnumerator FadeVolumeRoutine(this AudioSource audioSource, float finishVolume, float duration, bool isStopAt0 = true)
    {
        float timeElapsed = 0.0f;
        float startVolume = audioSource.volume;
        while (timeElapsed < duration)
        {
            audioSource.volume = Mathf.Lerp(startVolume, finishVolume, timeElapsed / duration);
            timeElapsed += Time.deltaTime;

            yield return new WaitForEndOfFrame();
        }

        audioSource.volume = finishVolume;

        if (isStopAt0 && audioSource.volume < Mathf.Epsilon)
        {
            audioSource.Stop();
        }
    }
}
