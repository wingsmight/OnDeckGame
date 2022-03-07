using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Wind : MonoBehaviour
{
    [SerializeField] private AreaEffector2D areaEffector;
    [SerializeField] private AudioClip sound;
    [SerializeField] private AudioSource audioSource;
    [SerializeField] private Boat boat;
    [Space]
    [SerializeField] private float strength = 5.0f;
    [SerializeField] [Min(0.0f)] private float strengthSpread = 10.0f;
    [SerializeField] [Min(0.0f)] private float changeStateDuration = 3.0f;
    [SerializeField] [Min(0.0f)] private float calmDuration = 10.0f;
    [SerializeField] [Min(0.0f)] private float windDuration = 10.0f;
    [SerializeField] [Min(0.0f)] private float durationSpread = 10.0f;
    [SerializeField] private float torgue;


    private Coroutine fadeSoundCoroutine;
    private Coroutine switchCoroutine;


    private void Awake()
    {
        areaEffector.enabled = true;
    }
    private void Update()
    {
        if (IsEnabled)
        {
            boat.Rigidbody.AddTorque(torgue);
        }
    }


    public void Enable()
    {
        StartCoroutine(ChangeForceSmoothlyRoutine(0.0f, strength, changeStateDuration));
        areaEffector.enabled = true;
        areaEffector.forceVariation = strengthSpread;

        audioSource.volume = 0.0f;
        audioSource.clip = sound;
        audioSource.loop = true;
        audioSource.time = Random.Range(0.0f, sound.length);
        audioSource.Play();

        if (fadeSoundCoroutine != null)
        {
            StopCoroutine(fadeSoundCoroutine);
        }
        fadeSoundCoroutine = StartCoroutine(audioSource.FadeVolumeRoutine(1.0f, changeStateDuration));
    }
    public void Disable()
    {
        StartCoroutine(ChangeForceSmoothlyRoutine(strength, 0.0f, changeStateDuration));
        areaEffector.enabled = false;
        areaEffector.forceVariation = 0.0f;

        if (fadeSoundCoroutine != null)
        {
            StopCoroutine(fadeSoundCoroutine);
        }
        fadeSoundCoroutine = StartCoroutine(audioSource.FadeVolumeRoutine(0.0f, changeStateDuration));
    }
    public void StartSwitchBehaviour()
    {
        StopSwitchBehaviour();
        switchCoroutine = StartCoroutine(SwitchRandomlyRoutine());
    }
    public void StopSwitchBehaviour()
    {
        Disable();
        if (switchCoroutine != null)
        {
            StopCoroutine(switchCoroutine);
        }
    }

    private IEnumerator ChangeForceSmoothlyRoutine(float startForce, float finishForce, float duration)
    {
        float timeElapsed = 0.0f;
        while (timeElapsed < duration)
        {
            areaEffector.forceMagnitude = Mathf.Lerp(startForce, finishForce, timeElapsed / duration);
            timeElapsed += Time.deltaTime;

            yield return new WaitForEndOfFrame();
        }

        areaEffector.forceMagnitude = finishForce;
    }
    private IEnumerator SwitchRandomlyRoutine()
    {
        while (true)
        {
            Enable();

            var randomWindDuration = Random.Range(windDuration - durationSpread, windDuration + durationSpread);
            yield return new WaitForSeconds(randomWindDuration);

            Disable();

            var randomCalmDuration = Random.Range(calmDuration - durationSpread, calmDuration + durationSpread);
            yield return new WaitForSeconds(randomCalmDuration);
        }
    }


    public bool IsEnabled => areaEffector.enabled;
}
