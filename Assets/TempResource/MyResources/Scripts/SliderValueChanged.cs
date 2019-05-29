using UnityEngine;
using UnityEngine.UI;

public class SliderValueChanged : MonoBehaviour {

	public void OnSliderValueChanged(Text text)
    {
        var slider = GetComponent<Slider>();
        text.text = slider.value.ToString();
    }
	
}
