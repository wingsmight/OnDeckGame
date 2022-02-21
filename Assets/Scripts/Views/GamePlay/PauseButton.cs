using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PauseButton : UIButton
{
    [SerializeField] private PausePanel pausePanel;


    protected override void OnClick()
    {
        Time.timeScale = 0.0f;

        pausePanel.Show();
    }
}
