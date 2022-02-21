using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class CookieCountView : MonoBehaviour
{
    private const string LABEL = "Cookie count: ";


    [SerializeField] private TextMeshProUGUI textView;


    private void Update()
    {
        textView.text = LABEL + PlayerData.CoockieCount.ToString();
    }
}
