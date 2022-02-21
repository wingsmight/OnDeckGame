using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShowHideSwitchButton : UIButton
{
    [SerializeField] [RequireInterface(typeof(IShowHidable))] private MonoBehaviour view;


    protected override void OnClick()
    {
        if (!View.IsShowing)
        {
            View.Show();
        }
        else
        {
            View.Hide();
        }
    }


    private IShowHidable View => view.GetComponent<IShowHidable>();
}
