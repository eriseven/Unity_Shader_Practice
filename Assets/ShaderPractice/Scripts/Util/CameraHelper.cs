using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[RequireComponent(typeof(Camera))]
public class CameraHelper : MonoBehaviour
{
    public Camera Camera
    {
        get
        {
            if (_camera == null)
            {
                _camera = GetComponent<Camera>();
            }
            if (_camera == null)
            {
                _camera = gameObject.AddComponent<Camera>();
            }
            return _camera;
        }
    }

    private Camera _camera;

    public Transform target;

    public void Lookat()
    {
        if (target != null)
        {
            transform.LookAt(target, Vector3.up);
        }
    }

#if UNITY_EDITOR
    [InspectorButton("Lookat", 150)]
    public bool LookatTarget;
#endif

    void PositionCamera()
    {
        if (target == null) return;

        Bounds bounds = target.GetComponent<Renderer>().bounds;
        float cameraDistance = 2.0f; // Constant factor
        Vector3 objectSizes = bounds.max - bounds.min;
        float objectSize = Mathf.Max(objectSizes.x, objectSizes.y, objectSizes.z);
        float cameraView = 2.0f * Mathf.Tan(0.5f * Mathf.Deg2Rad * Camera.fieldOfView); // Visible height 1 meter in front
        float distance = cameraDistance * objectSize / cameraView; // Combined wanted distance from the object
        distance += 0.5f * objectSize; // Estimated offset from the center to the outside of the object
        Camera.transform.position = bounds.center - distance * Camera.transform.forward;
    }

    void PositionCamera_()
    {
        if (target == null) return;

        Bounds objectBounds = target.GetComponent<Renderer>().bounds;
        Vector3 objectFrontCenter = objectBounds.center - target.forward * objectBounds.extents.z;

        //Get the far side of the triangle by going up from the center, at a 90 degree angle of the camera's forward vector.
        Vector3 triangleFarSideUpAxis = Quaternion.AngleAxis(90, target.right) * transform.forward;
        //Calculate the up point of the triangle.
        const float MARGIN_MULTIPLIER = 1.5f;
        Vector3 triangleUpPoint = objectFrontCenter + triangleFarSideUpAxis * objectBounds.extents.y * MARGIN_MULTIPLIER;

        //The angle between the camera and the top point of the triangle is half the field of view.
        //The tangent of this angle equals the length of the opposing triangle side over the desired distance between the camera and the object's front.
        float desiredDistance = Vector3.Distance(triangleUpPoint, objectFrontCenter) / Mathf.Tan(Mathf.Deg2Rad * GetComponent<Camera>().fieldOfView / 2);

        transform.position = -transform.forward * desiredDistance + objectFrontCenter;
    }

#if UNITY_EDITOR
    [InspectorButton("PositionCamera", 150)]
    public bool FitTarget;
#endif

}
