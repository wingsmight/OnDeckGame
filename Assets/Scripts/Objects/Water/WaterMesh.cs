using UnityEngine;
using System.Collections;

public class WaterMesh : MonoBehaviour
{
    [SerializeField] private GameObject meshObject;
    [SerializeField] private float springconstant = 0.02f;
    [SerializeField] private float damping = 0.04f;
    [SerializeField] private float spread = 0.05f;
    [SerializeField] private float waveStrength = 1.5f;
    [SerializeField] private float startWavePosition = -100.0f;
    [SerializeField] private float amplitude;
    [SerializeField] private float speed;


    private float waveElementIndex = 0;
    private LineRenderer topLine;

    private float[] xpositions;
    private float[] ypositions;
    private float[] velocities;
    private float[] accelerations;

    private GameObject[] meshobjects;
    private GameObject[] colliders;
    private Mesh[] meshes;

    private float baseheight;
    private float left;
    private float bottom;
    private float positionZ = -1f;


    private void Awake()
    {
        this.positionZ = transform.position.z;
    }
    private void Start()
    {
        SpawnWater(-10, 20, -2, -6);
        StartCoroutine(GenerateWaveRoutine());
    }
    private void OnTriggerStay2D(Collider2D Hit) // process unique buoyancy constant to each object
    {

    }
    private void FixedUpdate()
    {
        for (int i = 0; i < xpositions.Length; i++)
        {
            ypositions[i] = velocities[i];
        }

        float[] leftDeltas = new float[xpositions.Length];
        float[] rightDeltas = new float[xpositions.Length];

        for (int j = 0; j < 8; j++)
        {
            for (int i = 0; i < xpositions.Length; i++)
            {
                if (i > 0)
                {
                    leftDeltas[i] = spread * (ypositions[i] - ypositions[i - 1]);
                }
                if (i < xpositions.Length - 1)
                {
                    rightDeltas[i] = spread * (ypositions[i] - ypositions[i + 1]);
                }
            }

            for (int i = 0; i < xpositions.Length; i++)
            {
                if (i > 0)
                    ypositions[i - 1] += leftDeltas[i];
                if (i < xpositions.Length - 1)
                    ypositions[i + 1] += rightDeltas[i];
            }
        }

        UpdateMeshes();
    }


    private void SpawnWater(float Left, float Width, float Top, float Bottom)
    {
        int edgecount = Mathf.RoundToInt(Width) * 5;
        int nodecount = edgecount + 1;

        topLine = gameObject.AddComponent<LineRenderer>();
        topLine.positionCount = nodecount;
        topLine.startWidth = 0.1f;
        topLine.endWidth = 0.1f;

        xpositions = new float[nodecount];
        ypositions = new float[nodecount];
        velocities = new float[nodecount];
        accelerations = new float[nodecount];

        meshobjects = new GameObject[edgecount];
        meshes = new Mesh[edgecount];
        colliders = new GameObject[edgecount];

        baseheight = Top;
        bottom = Bottom;
        left = Left;

        for (int i = 0; i < nodecount; i++)
        {
            ypositions[i] = Top;
            xpositions[i] = Left + Width * i / edgecount;
            topLine.SetPosition(i, new Vector3(xpositions[i], Top, positionZ));
            accelerations[i] = 0;
            velocities[i] = 0;
        }

        for (int i = 0; i < edgecount; i++)
        {
            meshes[i] = new Mesh();

            Vector3[] Vertices = new Vector3[4];
            Vertices[0] = new Vector3(xpositions[i], ypositions[i], positionZ);
            Vertices[1] = new Vector3(xpositions[i + 1], ypositions[i + 1], positionZ);
            Vertices[2] = new Vector3(xpositions[i], bottom, positionZ);
            Vertices[3] = new Vector3(xpositions[i + 1], bottom, positionZ);

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
            Vertices[0] = new Vector3(xpositions[i], ypositions[i], positionZ);
            Vertices[1] = new Vector3(xpositions[i + 1], ypositions[i + 1], positionZ);
            Vertices[2] = new Vector3(xpositions[i], bottom, positionZ);
            Vertices[3] = new Vector3(xpositions[i + 1], bottom, positionZ);

            meshes[i].vertices = Vertices;

            var boxCollider = meshobjects[i].GetComponent<BoxCollider2D>();
            boxCollider.size = new Vector2(xpositions[i + 1] - xpositions[i], ypositions[i] - bottom);
            boxCollider.offset = new Vector2(xpositions[i] + boxCollider.size.x / 2.0f, ypositions[i] - boxCollider.size.y / 2.0f);
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
