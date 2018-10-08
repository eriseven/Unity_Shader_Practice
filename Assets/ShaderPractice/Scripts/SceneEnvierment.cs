using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//using Utilities.Helpers;

public class SceneEnvierment : MonoBehaviour {

    public Cubemap irradianceMap;
    public Cubemap radianceMap;
    public Texture2D brdfLut;

	// Use this for initialization
	void Start () {
        Shader.SetGlobalTexture("_IrradianceMap", irradianceMap);
        Shader.SetGlobalTexture("_RadianceMap", radianceMap);
        Shader.SetGlobalTexture("_BDRF_Map", brdfLut);
	}
	
	// Update is called once per frame
	void Update () {
	}
}
