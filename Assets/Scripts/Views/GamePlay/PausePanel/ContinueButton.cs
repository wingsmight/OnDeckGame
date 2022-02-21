using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ContinueButton : UIButton
{
    [SerializeField] private PausePanel pausePanel;


    protected override void OnClick()
    {
        Time.timeScale = 1.0f;

        pausePanel.Hide();
    }
}
