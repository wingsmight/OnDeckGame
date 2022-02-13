using UnityEngine;
using System.Collections;

public class WaterMesh : MonoBehaviour
{
    [SerializeField] private GameObject meshObject;
    [SerializeField] private float spread = 0.05f;
    [SerializeField] private float waveStrength = 1.5f;
    [SerializeField] private float amplitude;
    [SerializeField] private float speed;
    [SerializeField] private float topOffset;


    private float waveElementIndex = 0;

    private float[] xPositions;
    private float[] yPositions;
    private float[] velocities;

    private GameObject[] meshobjects;
    private Mesh[] meshes;

    private float bottomPosition;
    private Vector3 startPosition;


    private void Awake()
    {
        startPosition = transform.position;
        transform.position = Vector3.zero;
    }
    private void Start()
    {
        SpawnWater(-10, 20, -2, -6);

        transform.position = startPosition;

        StartCoroutine(GenerateWaveRoutine());
    }
    private void OnTriggerStay2D(Collider2D Hit) // process unique buoyancy constant to each object
    {

    }
    private void FixedUpdate()
    {
        for (int i = 0; i < xPositions.Length; i++)
        {
            yPositions[i] = velocities[i];
        }

        float[] leftDeltas = new float[xPositions.Length];
        float[] rightDeltas = new float[xPositions.Length];

        for (int j = 0; j < 8; j++)
        {
            for (int i = 0; i < xPositions.Length; i++)
            {
                if (i > 0)
                {
                    leftDeltas[i] = spread * (yPositions[i] - yPositions[i - 1]);
                }
                if (i < xPositions.Length - 1)
                {
                    rightDeltas[i] = spread * (yPositions[i] - yPositions[i + 1]);
                }
            }

            for (int i = 0; i < xPositions.Length; i++)
            {
                if (i > 0)
                    yPositions[i - 1] += leftDeltas[i];
                if (i < xPositions.Length - 1)
                    yPositions[i + 1] += rightDeltas[i];
            }
        }

        UpdateMeshes();
    }


    private void SpawnWater(float left, float width, float topPosition, float bottomPosition)
    {
        int edgecount = Mathf.RoundToInt(width) * 5;
        int nodecount = edgecount + 1;

        xPositions = new float[nodecount];
        yPositions = new float[nodecount];
        velocities = new float[nodecount];

        meshobjects = new GameObject[edgecount];
        meshes = new Mesh[edgecount];

        this.bottomPosition = bottomPosition;

        for (int i = 0; i < nodecount; i++)
        {
            yPositions[i] = topPosition;
            xPositions[i] = left + width * i / edgecount;
            velocities[i] = 0;
        }

        for (int i = 0; i < edgecount; i++)
        {
            meshes[i] = new Mesh();

            Vector3[] Vertices = new Vector3[4];
            Vertices[0] = new Vector3(xPositions[i], yPositions[i], startPosition.z);
            Vertices[1] = new Vector3(xPositions[i + 1], yPositions[i + 1], startPosition.z);
            Vertices[2] = new Vector3(xPositions[i], bottomPosition, startPosition.z);
            Vertices[3] = new Vector3(xPositions[i + 1], bottomPosition, startPosition.z);

            Vector2[] UVs = new Vector2[4];
            UVs[0] = new Vector2(0, 1);
            UVs[1] = new Vector2(1, 1);
            UVs[2] = new Vector2(0, 0);
            UVs[3] = new Vector2(1, 0);

            int[] tris = new int[6] { 0, 1, 3, 3, 2, 0 };

            meshes[i].vertices = Vertices;
            meshes[i].uv = UVs;
            meshes[i].triangles = tris;

            meshobjects[i] = Instantiate(meshObject, Vector3.zero, Quaternion.identity) as GameObject;
            meshobjects[i].GetComponent<MeshFilter>().mesh = meshes[i];
            meshobjects[i].transform.parent = transform;
        }
    }
    private void UpdateMeshes()
    {
        for (int i = 0; i < meshes.Length; i++)
        {
            Vector3[] Vertices = new Vector3[4];
            Vertices[0] = new Vector3(xPositions[i], yPositions[i], startPosition.z);
            Vertices[1] = new Vector3(xPositions[i + 1], yPositions[i + 1], startPosition.z);
            Vertices[2] = new Vector3(xPositions[i], bottomPosition, startPosition.z);
            Vertices[3] = new Vector3(xPositions[i + 1], bottomPosition, startPosition.z);

            meshes[i].vertices = Vertices;

            var boxCollider = meshobjects[i].GetComponent<BoxCollider2D>();
            boxCollider.size = new Vector2(xPositions[i + 1] - xPositions[i], yPositions[i] - bottomPosition);
            boxCollider.offset = new Vector2(xPositions[i] + boxCollider.size.x / 2.0f, (yPositions[i] - boxCollider.size.y / 2.0f) - topOffset);

            meshes[i].RecalculateBounds();
        }
    }
    private IEnumerator GenerateWaveRoutine()
    {
        while (true)
        {
            for (int i = 0; i < velocities.Length; i++)
            {
                velocities[i] = Mathf.Sin(waveElementIndex + (i * amplitude)) * waveStrength;
            }
            waveElementIndex += speed;

            yield return new WaitForFixedUpdate();
        }
    }
}
