using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class HideList : MonoBehaviour, IHidable
{
    [SerializeField] [RequireInterface(typeof(IHidable))] private List<MonoBehaviour> views;


    public void Hide()
    {
        Views.ForEach(x => x.Hide());
    }


    private List<IHidable> Views => views.Select(x => x.GetComponent<IHidable>()).ToList();
}
