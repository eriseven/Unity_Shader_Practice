using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spawner : MonoBehaviour {

    public GameObject prefab;

    public uint row = 5;
    public uint col = 5;

    public bool isStandardShader = false;

	// Use this for initialization
	void Start () {
        Spawn(row, col);
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    void Spawn(uint row, uint col)
    {
        if (prefab == null) return;

        float cap = 2.0f;
        Vector3 pos = Vector3.zero - new Vector3(row * cap / 2.0f, 0.0f, col * cap / 2.0f);

        MaterialPropertyBlock props = new MaterialPropertyBlock();

        for (int i = 0; i < row; i++)
        {
            for (int j = 0; j < col; j++)
            {
                var go = GameObject.Instantiate(prefab);
                go.transform.position = pos + new Vector3(i * cap, 0, j * cap);
                go.transform.parent = this.transform;

                if (isStandardShader)
                {
                    props.SetFloat("_Metallic", (float)i / (float)(row - 1));
                    props.SetFloat("_Glossiness", 1.0f - (float)j / (float)(col - 1));
                }
                else
                {
                    props.SetFloat("_Metal", (float)i / (float)(row - 1));
                    props.SetFloat("_Rough", (float)j / (float)(col - 1));
                }


                var mr = go.GetComponentInChildren<MeshRenderer>();
                mr.SetPropertyBlock(props);
            }
        }
    }

}
