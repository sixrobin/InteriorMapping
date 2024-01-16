namespace InteriorMapping
{
    using System.Collections.Generic;
    using UnityEngine;

    public class BuildingMeshCreator : MonoBehaviour
    {
        /// <summary>
        /// Creates a building cube mesh.
        /// </summary>
        [ContextMenu("Create Building Mesh")]
        private void CreateBuildingMesh()
        {
            List<Vector3> vertices = new()
            {
                // Front.
                new Vector3(0f, 0f, 0f),
                new Vector3(1f, 0f, 0f),
                new Vector3(0f, 1f, 0f),
                new Vector3(1f, 1f, 0f),
                // Right.
                new Vector3(1f, 0f, 0f),
                new Vector3(1f, 0f, 1f),
                new Vector3(1f, 1f, 0f),
                new Vector3(1f, 1f, 1f),
                // Back.
                new Vector3(1f, 0f, 1f),
                new Vector3(0f, 0f, 1f),
                new Vector3(1f, 1f, 1f),
                new Vector3(0f, 1f, 1f),
                // Left.
                new Vector3(0f, 0f, 1f),
                new Vector3(0f, 0f, 0f),
                new Vector3(0f, 1f, 1f),
                new Vector3(0f, 1f, 0f),
                // Top.
                new Vector3(0f, 1f, 0f),
                new Vector3(1f, 1f, 0f),
                new Vector3(0f, 1f, 1f),
                new Vector3(1f, 1f, 1f),
            };

            for (int i = 0; i < vertices.Count; ++i)
                vertices[i] -= new Vector3(1f, 0f, 1f) * 0.5f;
            
            List<Vector2> uv = new()
            {
                new Vector2(0f, 0f),
                new Vector2(1f, 0f),
                new Vector2(0f, 1f),
                new Vector2(1f, 1f),
                
                new Vector2(0f, 0f),
                new Vector2(1f, 0f),
                new Vector2(0f, 1f),
                new Vector2(1f, 1f),
                
                new Vector2(0f, 0f),
                new Vector2(1f, 0f),
                new Vector2(0f, 1f),
                new Vector2(1f, 1f),
                
                new Vector2(0f, 0f),
                new Vector2(1f, 0f),
                new Vector2(0f, 1f),
                new Vector2(1f, 1f),
                
                new Vector2(0f, 0f),
                new Vector2(1f, 0f),
                new Vector2(0f, 1f),
                new Vector2(1f, 1f),
            };

            List<int> triangles = new()
            {
                0, 2, 1,
                1, 2, 3,
                4, 6, 5,
                5, 6, 7,
                8, 10, 9,
                9, 10, 11,
                12, 14, 13,
                13, 14, 15,
                16, 18, 17,
                17, 18, 19,
            };

            Mesh cube = new()
            {
                vertices = vertices.ToArray(),
                triangles = triangles.ToArray(),
                uv = uv.ToArray(),
            };
            
            cube.RecalculateNormals();
            cube.RecalculateTangents();
            cube.RecalculateBounds();
            cube.Optimize();

            this.GetComponent<MeshFilter>().mesh = cube;
        }
    }
}
