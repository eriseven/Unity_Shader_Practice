using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public struct BoundingSphere
{
    public Vector3 center;
    public float radius;
    public BoundingSphere(Vector3 aCenter, float aRadius)
    {
        center = aCenter;
        radius = aRadius;
    }

    public void Encapsulate(Vector3 p)
    {
        var dist = (center - p).magnitude;

        if (dist <= radius)
        {
            return;
        }

        var t = (dist - radius) / (dist * 2.0f);

        var newRadius = (radius + dist) / 2.0f;
        var newCenter = Vector3.Lerp(center, p, t);

        radius = newRadius;
        center = newCenter;
    }

    public static BoundingSphere Calculate(Mesh mesh)
    {
        var sphere = new BoundingSphere(Vector3.zero, 0);
        bool isFirst = true;

        var vertices = mesh.vertices;
        var indices = mesh.GetIndices(0);

        foreach (var idx in indices)
        {
            var p = vertices[idx];
            if (isFirst)
            {
                isFirst = false;
                sphere = new BoundingSphere(p, 0);
            }
            else
            {
                sphere.Encapsulate(p);
            }
        }

        return sphere; 
    }

    public static BoundingSphere Calculate(IEnumerable<Vector3> aPoints)
    {
        var sphere = new BoundingSphere(Vector3.zero, 0);
        bool isFirst = true;

        foreach (var p in aPoints)
        {
            if (isFirst)
            {
                isFirst = false;
                sphere = new BoundingSphere(p, 0);
            }
            else
            {
                sphere.Encapsulate(p);
            }
        }

        return sphere;
    }

    public static BoundingSphere Calculate_(IEnumerable<Vector3> aPoints)
    {
        Vector3 xmin, xmax, ymin, ymax, zmin, zmax;
        xmin = ymin = zmin = Vector3.one * float.PositiveInfinity;
        xmax = ymax = zmax = Vector3.one * float.NegativeInfinity;
        foreach (var p in aPoints)
        {
            if (p.x < xmin.x) xmin = p;
            if (p.x > xmax.x) xmax = p;
            if (p.y < ymin.y) ymin = p;
            if (p.y > ymax.y) ymax = p;
            if (p.z < zmin.z) zmin = p;
            if (p.z > zmax.z) zmax = p;
        }
        var xSpan = (xmax - xmin).sqrMagnitude;
        var ySpan = (ymax - ymin).sqrMagnitude;
        var zSpan = (zmax - zmin).sqrMagnitude;
        var dia1 = xmin;
        var dia2 = xmax;
        var maxSpan = xSpan;
        if (ySpan > maxSpan)
        {
            maxSpan = ySpan;
            dia1 = ymin; dia2 = ymax;
        }
        if (zSpan > maxSpan)
        {
            dia1 = zmin; dia2 = zmax;
        }
        var center = (dia1 + dia2) * 0.5f;
        var sqRad = (dia2 - center).sqrMagnitude;
        var radius = Mathf.Sqrt(sqRad);
        foreach (var p in aPoints)
        {
            float d = (p - center).sqrMagnitude;
            if (d > sqRad)
            {
                var r = Mathf.Sqrt(d);
                radius = (radius + r) * 0.5f;
                sqRad = radius * radius;
                var offset = r - radius;
                center = (radius * center + offset * p) / r;
            }
        }
        return new BoundingSphere(center, radius);
    }
}
