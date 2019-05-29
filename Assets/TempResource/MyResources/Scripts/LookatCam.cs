using UnityEngine;
using System.Collections;
using System.Linq;

public class LookatCam : MonoBehaviour
{
    Camera main;
    private void Start()
    {
        main = Camera.allCameras.Where(cam => cam.gameObject.name == "Main Camera").First();
    }
    private void LateUpdate()
    {
        transform.LookAt(main.transform);
    }
}

