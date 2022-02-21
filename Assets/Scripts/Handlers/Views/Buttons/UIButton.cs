using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

[RequireComponent(typeof(Button))]
public abstract class UIButton : MonoBehaviour
{
    private const string CLICK_SOUND_PATH = "Sounds/?";


    [SerializeField] private bool hasSound;


    protected Button button;
    protected AudioClip clickSound;


    protected virtual void Awake()
    {
        clickSound = (AudioClip)Resources.Load(CLICK_SOUND_PATH);

        button = GetComponent<Button>();
        button.onClick.AddListener(ActButton);
    }
    protected virtual void OnDestroy()
    {
        button.onClick.RemoveListener(ActButton);
    }


    protected abstract void OnClick();

    private void ActButton()
    {
        if (clickSound != null && hasSound)
        {
            AudioSource.PlayClipAtPoint(clickSound, Vector3.zero);
        }

        OnClick();
    }


    public Button Button => button;
}
