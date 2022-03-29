using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterSplash : MonoBehaviour
{
    [SerializeField] private new ParticleSystem particleSystem;
    [SerializeField] private float velocitySizeRatio = 1.0f;
    [SerializeField] private float velocityCountRatio = 1.0f;
    [SerializeField] private float velocitySpeedRatio = 1.0f;


    private ParticleSystem.MainModule particlesMainModule;
    private ParticleSystem.MinMaxCurve initStartSize;
    private ParticleSystem.MinMaxCurve initStartSpeed;
    private int initStartCount;


    private void Awake()
    {
        particlesMainModule = particleSystem.main;
    }


    public void Play(float velocityMagnitude)
    {
        float minStartSize = initStartSize.constantMin + velocityMagnitude * velocitySizeRatio;
        float maxStartSize = initStartSize.constantMax + velocityMagnitude * velocitySizeRatio;
        particlesMainModule.startSize = new ParticleSystem.MinMaxCurve(minStartSize, maxStartSize);

        particlesMainModule.maxParticles = (int)(initStartCount + velocityMagnitude * velocityCountRatio);

        float minStartSpeed = initStartSpeed.constantMin + velocityMagnitude * velocitySizeRatio;
        float maxStartSpeed = initStartSpeed.constantMax + velocityMagnitude * velocitySizeRatio;
        particlesMainModule.startSpeed = new ParticleSystem.MinMaxCurve(minStartSpeed, maxStartSpeed);

        particleSystem.Play();
    }
}
