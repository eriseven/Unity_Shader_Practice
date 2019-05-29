using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SSS : MonoBehaviour {
    
    public Shader lightShader;
    public Shader blurShader;
    Camera mCamera;
    RenderTexture rt;
    Material blurMaterial;
    public bool enableBlur = true;
    public float size = 2f;
    void Start ()
    {
        mCamera = GetComponent<Camera>();
        blurMaterial = new Material(blurShader);
    }

    private void StencilBlit(RenderTexture source, RenderTexture destination, Material mat, int pass, RenderTexture stencil)
    {
        if (stencil == null)
        {
            Graphics.Blit(source, destination, mat, pass);
            return;
        }

        Graphics.SetRenderTarget(destination.colorBuffer, stencil.depthBuffer);
        GL.Clear(false, true, Color.clear);
        GL.PushMatrix();
        GL.LoadOrtho();
        mat.mainTexture = source;
        mat.SetPass(pass);
        GL.Begin(GL.QUADS);
        GL.TexCoord2(0.0f, 1.0f); GL.Vertex3(0.0f, 1.0f, 0.1f);
        GL.TexCoord2(1.0f, 1.0f); GL.Vertex3(1.0f, 1.0f, 0.1f);
        GL.TexCoord2(1.0f, 0.0f); GL.Vertex3(1.0f, 0.0f, 0.1f);
        GL.TexCoord2(0.0f, 0.0f); GL.Vertex3(0.0f, 0.0f, 0.1f);
        GL.End();
        GL.PopMatrix();
    }

    void LateUpdate ()
    {
        if (rt != null)
            RenderTexture.ReleaseTemporary(rt);

        rt = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32);
        
        mCamera.targetTexture = rt;
        mCamera.RenderWithShader(lightShader, "RenderType");
        mCamera.targetTexture = null;

        if (enableBlur)
        {
            blurMaterial.SetFloat("_Size", size);

            // vertical blur
            RenderTexture rt2 = RenderTexture.GetTemporary(rt.width, rt.height, 0, rt.format);
            rt2.filterMode = FilterMode.Bilinear;
            StencilBlit(rt, rt2, blurMaterial, 0, rt);

            // horizontal blur
            RenderTexture rt3 = RenderTexture.GetTemporary(rt.width, rt.height, 0, rt.format);
            rt3.filterMode = FilterMode.Bilinear;
            StencilBlit(rt2, rt3, blurMaterial, 1, rt);

            RenderTexture.ReleaseTemporary(rt);
            RenderTexture.ReleaseTemporary(rt2);
            rt = rt3;
        }

        Shader.SetGlobalTexture("_SSSLightTexture", rt);
    }
}
