using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Storm : MonoBehaviour
{
    [SerializeField] private WaterGenerator waterGenerator;
    [SerializeField] private Span amplitudeSpan;
    [SerializeField] private float duration;
    [SerializeField] private float amplitudeSpeed;
    [SerializeField] private float amplitudeSpeedSpread;
    [SerializeField] [Range(0.0f, 100.0f)] private float chance = 50.0f;
    [SerializeField] private Wind wind;
    [SerializeField] private LocationGeneration locationGeneration;
    [SerializeField] private Boat boat;
    [SerializeField] private Sky sky;
    [SerializeField] private Animator stormySkyAnimator;


    private bool isEnabled = false;
    private float speedSign = 1.0f;
    private Coroutine enableCoroutine;
    private float enabledDistance;
    private bool canBeEnabled = false;
    private float defaultAmplitude = 1.0f;


    private void Awake()
    {
        defaultAmplitude = waterGenerator.Amplitude;
        sky.onStateChanged += OnSkyChanged;
    }
    private void FixedUpdate()
    {
        if (!isEnabled)
            return;

        waterGenerator.Amplitude += speedSign * (amplitudeSpeed + UnityEngine.Random.Range(-amplitudeSpeedSpread, amplitudeSpeedSpread)) * Time.fixedDeltaTime;

        if (waterGenerator.Amplitude > amplitudeSpan.finish)
        {
            waterGenerator.Amplitude = amplitudeSpan.finish;
            speedSign *= -1;
        }
        else if (waterGenerator.Amplitude < amplitudeSpan.start)
        {
            waterGenerator.Amplitude = amplitudeSpan.start;
            speedSign *= -1;
        }
    }


    public void Enable()
    {
        canBeEnabled = false;
        isEnabled = true;
        wind.StartSwitchBehaviour();
        enabledDistance = boat.transform.position.x;
        locationGeneration.Hide();
        stormySkyAnimator.Play("Show", 0, 0);

        if (enableCoroutine != null)
        {
            StopCoroutine(enableCoroutine);
        }
        enableCoroutine = DelayExecutor.Instance.Execute(Disable, duration);
    }
    public void Disable()
    {
        enabledDistance = boat.transform.position.x - enabledDistance;
        isEnabled = false;
        wind.StopSwitchBehaviour();
        stormySkyAnimator.StopPlayback();

        locationGeneration.Shift(enabledDistance);
        locationGeneration.Show();
        canBeEnabled = false;

        StartCoroutine(ReturnToDefaultAmplitude());
    }

    private IEnumerator ReturnToDefaultAmplitude()
    {
        while (Mathf.Abs(waterGenerator.Amplitude - defaultAmplitude) > Mathf.Epsilon * 4)
        {
            waterGenerator.Amplitude += speedSign * (amplitudeSpeed + UnityEngine.Random.Range(-amplitudeSpeedSpread, amplitudeSpeedSpread)) * Time.fixedDeltaTime;

            if (waterGenerator.Amplitude > amplitudeSpan.finish)
            {
                waterGenerator.Amplitude = amplitudeSpan.finish;
                speedSign *= -1;
            }
            else if (waterGenerator.Amplitude < amplitudeSpan.start)
            {
                waterGenerator.Amplitude = amplitudeSpan.start;
                speedSign *= -1;
            }

            yield return new WaitForEndOfFrame();
        }
    }
    private void OnSkyChanged(SkyState newState)
    {
        if (canBeEnabled && UnityEngine.Random.Range(0.0f, 100.0f) < chance)
        {
            Enable();
        }
    }


    public bool CanBeEnabled
    {
        get { return canBeEnabled; }
        set { canBeEnabled = value; }
    }
}
