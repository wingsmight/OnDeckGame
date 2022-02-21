using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class ShowHideList : MonoBehaviour, IShowHidable
{
    [SerializeField] [RequireInterface(typeof(IShowHidable))] private List<MonoBehaviour> views;


    public void Show()
    {
        Views.ForEach(x => x.Show());
    }
    public void Hide()
    {
        Views.ForEach(x => x.Hide());
    }


    private List<IShowHidable> Views => views.Select(x => x.GetComponent<IShowHidable>()).ToList();

    public bool IsShowing => Views.All(x => x.IsShowing);
}
