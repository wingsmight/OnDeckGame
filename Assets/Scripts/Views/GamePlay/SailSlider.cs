using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SailSlider : MonoBehaviour
{
    [SerializeField] private Slider slider;
    [SerializeField] private BoatControl boatControl;


    private void Awake()
    {
        slider.onValueChanged.AddListener(SetSailHeight);
    }
    private void OnDestroy()
    {
        slider.onValueChanged.RemoveListener(SetSailHeight);
    }


    private void SetSailHeight(float height)
    {
        boatControl.SailHeight = height;
    }
}
