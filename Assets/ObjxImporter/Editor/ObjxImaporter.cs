using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;

using ICSharpCode.SharpZipLib.Core;
using ICSharpCode.SharpZipLib.Zip;

using UnityEngine;
using UnityEditor;
using UnityEditor.Experimental.AssetImporters;

[ScriptedImporter(1, "objx")]
public class ObjxImaporter : ScriptedImporter
{
    public override void OnImportAsset(AssetImportContext ctx)
    {
        var assetPath = ctx.assetPath;

        var mesh_list = new List<Mesh>();
        try
        {
            var fs = new FileStream(assetPath, FileMode.Open, FileAccess.Read, FileShare.Read);
            var objxFile = new ZipFile(fs);
            Mesh unityMesh = new Mesh();

            foreach (ZipEntry zipEntry in objxFile)
            {
                if (!zipEntry.IsFile) {
                                continue;			// Ignore directories
                }

                
                string entryFileName = Path.GetFileName(zipEntry.Name).ToLower();
                if (entryFileName.EndsWith(".obj"))
                {
                    Debug.Log("read model:" + entryFileName);
                    Stream zipStream = objxFile.GetInputStream(zipEntry);
                    TextReader reader = new StreamReader(zipStream);
                    string objString = reader.ReadToEnd();

                    var mesh = ObjImporter.ImportObjString(objString);

                    if (entryFileName.Contains("pos"))
                    {
                        unityMesh.vertices = mesh.vertices;
                        unityMesh.triangles = mesh.triangles;
                    }

                    if (entryFileName.Contains("uv1"))
                    {
                        unityMesh.uv = mesh.uv;
                    }

                    if (entryFileName.Contains("uv2"))
                    {
                        unityMesh.uv2 = mesh.uv;
                    }

                    if (entryFileName.Contains("nor"))
                    {
                        unityMesh.normals = mesh.normals;
                    }

                    if (entryFileName.Contains("col"))
                    {
                        Color[] colors = new Color[mesh.normals.Length];
                        //unityMesh.colors32 = new Color32[mesh.normals.Length];
                        for (int i = 0; i < colors.Length; i++)
                        {
                            Vector3 col = mesh.normals[i];
                            colors[i] = new Color(col.x, col.y, col.z);
                            //unityMesh.colors32[i] = Color.red;
                            //unityMesh.colors32[i] = new Color32(255, 0, 0, 255);
                        }

                        unityMesh.colors = colors;
                    }

                    if (entryFileName.Contains("tan"))
                    {
                        Vector4[] tangents = new Vector4[mesh.normals.Length];

                        for (int i = 0; i < tangents.Length; i++)
                        {
                            Vector3 col = mesh.normals[i];
                            tangents[i] = new Vector4(col.x, col.y, col.z, 1.0f);
                        }

                        unityMesh.tangents = tangents;
                    }

                    //if (entryFileName.Contains("tex1"))
                    //{
                    //    Vector2[] uv2 = new Vector2[mesh.normals.Length];

                    //    for (int i = 0; i < uv2.Length; i++)
                    //    {
                    //        Vector3 _uv = mesh.normals[i];
                    //        uv2[i] = new Vector2(_uv.x, _uv.y);
                    //    }

                    //    unityMesh.uv2 = uv2;
                    //}
                }
            }

            unityMesh.RecalculateBounds();
            ctx.SetMainObject(unityMesh);
        }
        catch (System.Exception)
        {
            throw;
        }

    }
}
