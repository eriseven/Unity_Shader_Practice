using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ViewBounds : MonoBehaviour
{

    public enum FitType {Box, Sphere};
    public FitType fitType;

    // Use this for initialization
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }


    void DrawBindingSphere()
    {
        var mf = GetComponent<MeshFilter>();
        if (mf != null && mf.sharedMesh != null)
        {
            var sphere = BoundingSphere.Calculate(mf.sharedMesh);

            sphere.center += transform.position;
            sphere.radius *= transform.lossyScale.x;
            Gizmos.DrawWireSphere(sphere.center, sphere.radius);
        }
    }

    void DrawBounds()
    {
        List<Renderer> renders = new List<Renderer>();
        GetComponentsInChildren<Renderer>(renders);
        var renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            renders.Add(renderer);
        }

        if (renders.Count == 0)
        {
            return;
        }

        Bounds bounds = new Bounds(transform.position, Vector3.zero);

        bool isFirstBounds = true;

        foreach (var r in renders)
        {
            if (isFirstBounds)
            {
                isFirstBounds = false;
                bounds = r.bounds;
            }
            else
            {
                bounds.Encapsulate(r.bounds);
            }
        }

        if (!isFirstBounds)
        {
            Gizmos.DrawWireCube(bounds.center, bounds.size);
        }
    }

    void OnDrawGizmosSelected()
    {
        if (fitType == FitType.Box)
        {
            DrawBounds();
        }
        else if (fitType == FitType.Sphere)
        {
            DrawBindingSphere();
        }
    }

}
