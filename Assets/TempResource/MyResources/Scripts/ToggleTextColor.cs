using UnityEngine;
using UnityEngine.UI;


public class ToggleTextColor : MonoBehaviour
{
    public Color normalColor;
    public Color highLightColor;

    private Toggle toggle;
    private Text textLabel;

    void Start()
    {
        toggle = GetComponent<Toggle>();
        var label = transform.Find("Label");
        textLabel = label.GetComponent<Text>();

        toggle.onValueChanged.AddListener(ChangeTextColor);
    }

    void ChangeTextColor(bool flag)
    {
        textLabel.color = flag ? highLightColor : normalColor;
    }
}
