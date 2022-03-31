using System;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

[RequireComponent(typeof(MeshFilter), typeof(PolygonCollider2D))]
public class WaterGenerator : MonoBehaviour
{
    #region Constants
    [SerializeField] private float STANDARD_DRAG = 1.05f;
    #endregion

    #region Settings
    [Header("Settings")]
    [FormerlySerializedAs("topWaterColor")] [SerializeField] private Color topWaterColor;
    [SerializeField] private float longitude = 70.0f;
    [SerializeField] private int nodesPerUnit = 5;
    [SerializeField] private float waterDepth = 20.0f;
    [SerializeField] private float topWidth = 0.2f;
    [Header("SortingLayer")]
    [SerializeField] private string sortingLayerName = "Water";
    [SerializeField] private int sortingOrder = 10;

    [Header("Physics")]
    [Range(0.1f, 10.0f)] [SerializeField] private float amplitude = 1.0f;
    [Range(0.0f, 5.0f)] [SerializeField] private float disturbance = 0.4f;
    [Range(0.0f, 50.0f)] [SerializeField] private float buoyancyForce = 10.0f;
    [Range(0.0f, 100.0f)] [SerializeField] private float depthForce = 40.0f;
    [Range(0.0f, 20.0f)] [SerializeField] private float airDrag = 0.0f;
    [Range(0.0f, 20.0f)] [SerializeField] private float airGravityScale = 1.0f;
    #endregion

    #region References
    [SerializeField] private new Camera camera;
    [SerializeField] private PolygonCollider2D polygonCollider;
    [SerializeField] private MeshRenderer meshRenderer;
    [SerializeField] private LineRenderer lineRenderer;
    [SerializeField] private MeshFilter meshFilter;
    [SerializeField] private ObjectPool splashPool;
    #endregion

    #region Private Variables
    private List<WaterNode> nodes = new List<WaterNode>();
    private Vector3[] meshVertices;
    private float positionDelta;
    private Queue<Collider2D> interactionQueue = new Queue<Collider2D>();
    private float time = 0;
    //private Vector2 startPointOffset;
    private Mesh mesh;
    private Rect sizeRect;
    #endregion

    #region MonoBehaviour Functions
    private void Awake()
    {
        mesh = new Mesh();
    }
    private void Start()
    {
        ComputeCoeficients();
        InitializeStructures();
        InitializeSurface();
        CalculateCameraRect();
    }
    private void Update()
    {
        CheckCameraBounds();
    }
    private void FixedUpdate()
    {
        //time = (time + Time.fixedDeltaTime) % (2 * Mathf.PI);
        GenerateWaves();

        ProcessInteractionQueue();

        DrawBody();
        DrawTop();
    }
    private void OnTriggerEnter2D(Collider2D other)
    {
        var collisionPosition = new Vector2(other.transform.position.x, GetWavePoint(other.transform.position.x) + topWidth);// + startPointOffset;

        var splashPaticle = splashPool.Pull();

        splashPaticle.GameObject.SetActive(true);
        splashPaticle.GameObject.transform.position = collisionPosition;
        splashPaticle.GameObject.GetComponent<WaterSplash>().Play(other.attachedRigidbody.velocity.magnitude);

        DelayExecutor.Instance.Execute(() => splashPool.Push(splashPaticle),
            splashPaticle.GameObject.GetComponent<ParticleSystem>().main.duration);
    }
    private void OnTriggerStay2D(Collider2D other)
    {
        if (!interactionQueue.Contains(other))
        {
            interactionQueue.Enqueue(other);
        }
    }
    private void OnTriggerExit2D(Collider2D other)
    {
        ExitFromWater(other);
    }
    #endregion

    #region Buoyancy Forces Computations
    private void ExitFromWater(Collider2D other)
    {
        Vector2 normal = other.attachedRigidbody.velocity.normalized;
        float crossArea = (normal * other.bounds.size).magnitude;
        other.attachedRigidbody.drag = airDrag;// * STANDARD_DRAG * crossArea;
        other.attachedRigidbody.gravityScale = airGravityScale;
    }
    [SerializeField] private float xOffset;
    [SerializeField] private float minC;
    [SerializeField] private float xMagnitude;
    [SerializeField] private float cMagnitude;
    public float GetWavePoint(float x)
    {
        x -= camera.transform.position.x;
        x += xOffset;
        x += Mathf.Sin(Time.time) * xMagnitude;
        x = -x;
        if (x == 0.0f)
        {
            x = Mathf.Epsilon;
        }

        float a = Mathf.Sin(Time.time) * amplitude;
        float c = (Time.time % Mathf.PI) / cMagnitude + minC;
        return (a / x) * Mathf.Sin((2 * Mathf.PI / c) * x) + transform.position.y;
    }

    private void ProcessInteractionQueue()
    {
        while (interactionQueue.Count > 0)
        {
            Collider2D obj = interactionQueue.Dequeue();

            if (obj != null && !obj.gameObject.CompareTag("IgnoreWater"))
            {
                AccuratePhysics(obj);
            }
        }
    }
    private void AccuratePhysics(Collider2D other)
    {
        Rigidbody2D rb = other.attachedRigidbody;
        Vector2 center = rb.worldCenterOfMass;
        Vector2 size = GetColliderSize(other);

        List<Vector2> vertices = new List<Vector2>() {
                center + (size * (Vector2.up + Vector2.left) / 2).Rotate(rb.rotation),
                center + (size * (Vector2.up + Vector2.right) / 2).Rotate(rb.rotation),
                center + (size * (Vector2.down + Vector2.right) / 2).Rotate(rb.rotation),
                center + (size * (Vector2.down + Vector2.left) / 2).Rotate(rb.rotation)
            };


        // Find the highest corner
        int upperCornerIndex = 0;
        for (int i = 0; i < 4; i++)
            if (vertices[i].y > vertices[upperCornerIndex].y) upperCornerIndex = i;

        // Get ready to compute submerged volume
        float volume = 0;
        var (leftNode, rightNode) = FindClosestSegment(vertices[upperCornerIndex]);

        if ((vertices[upperCornerIndex].y > leftNode.position.y || vertices[upperCornerIndex].y > rightNode.position.y)
        && (vertices[(upperCornerIndex + 2) % 4].y <= leftNode.position.y || vertices[(upperCornerIndex + 2) % 4].y <= rightNode.position.y))
        {
            // Add contact points between water & collider
            var (p1, p2) = FindIntersectionsOnSurface(vertices, rb.rotation, upperCornerIndex);

            // Remove unsubmerged vertices
            vertices.RemoveAll(vertex => !polygonCollider.OverlapPoint(vertex));

            vertices.Insert(0, p1);
            vertices.Insert(1, p2);
        }

        List<int> triangles = SplitIntoTriangles(vertices);

        Vector2 centroid = ComputeCentroid(vertices, triangles, out volume);

        float immersionDepth = leftNode.position.y - center.y;
        float fluidDensity = 0.7f;
        Vector2 buoyancy = -fluidDensity * Physics2D.gravity * volume * buoyancyForce;

        Vector2 normal = rb.velocity.normalized;
        float crossArea = (normal * other.bounds.size).magnitude;
        float referencePoint = (leftNode.position.y + rightNode.position.y) / 2.0f;
        float depth = referencePoint - centroid.y;

        rb.drag = Mathf.Clamp(STANDARD_DRAG * crossArea * (1 - Mathf.Clamp01(depth * depthForce)), 0.01f, float.PositiveInfinity);
        rb.gravityScale = 1.0f;

        if (volume != 0 && !float.IsNaN(centroid.x) && !float.IsNaN(centroid.y))
            rb.AddForceAtPosition(buoyancy, new Vector2(rb.position.x - (leftNode.position.y - rightNode.position.y), rb.position.y), ForceMode2D.Force);
    }
    private (Vector2 p1, Vector2 p2) FindIntersectionsOnSurface(List<Vector2> vertices, float rotation, int topIndex)
    {
        Vector2 upperCorner = vertices[(topIndex) % 4];
        Vector2 leftCorner = vertices[(topIndex + 3) % 4];
        Vector2 lowerCorner = vertices[(topIndex + 2) % 4];
        Vector2 rightCorner = vertices[(topIndex + 1) % 4];

        WaterNode leftNode = FindClosestSegment(leftCorner).leftNode;
        WaterNode rightNode = FindClosestSegment(rightCorner).rightNode;

        // Compute the line function that approximates the water surface
        float waterIncline = rightNode.position.x - leftNode.position.x != 0 ?
            (rightNode.position.y - leftNode.position.y) /
            (rightNode.position.x - leftNode.position.x) :
            float.NaN;
        float waterOffset = rightNode.position.y - waterIncline * rightNode.position.x;

        // Compute the line function that describes the left side of the collider
        float leftIncline;
        float leftOffset;
        if (leftNode.position.y < leftCorner.y)
        {
            leftIncline = lowerCorner.x - leftCorner.x != 0 ?
                (lowerCorner.y - leftCorner.y) /
                (lowerCorner.x - leftCorner.x) :
                float.NaN;
            leftOffset = lowerCorner.y - leftIncline * lowerCorner.x;
        }
        else
        {
            leftIncline = upperCorner.x - leftCorner.x != 0 ?
                (upperCorner.y - leftCorner.y) /
                (upperCorner.x - leftCorner.x) :
                float.NaN;
            leftOffset = upperCorner.y - leftIncline * upperCorner.x;
        }

        // Compute the line function that describes the right side of the collider
        float rightIncline;
        float rightOffset;
        if (rightNode.position.y < rightCorner.y)
        {
            rightIncline = lowerCorner.x - rightCorner.x != 0 ?
                (lowerCorner.y - rightCorner.y) /
                (lowerCorner.x - rightCorner.x) :
                float.NaN;
            rightOffset = lowerCorner.y - rightIncline * lowerCorner.x;
        }
        else
        {
            rightIncline = upperCorner.x - rightCorner.x != 0 ?
                (upperCorner.y - rightCorner.y) /
                (upperCorner.x - rightCorner.x) :
                float.NaN;
            rightOffset = upperCorner.y - rightIncline * upperCorner.x;
        }

        // Now compute each intersection
        Vector2 p1 = Vector2.zero;
        if (float.IsNaN(leftIncline))
        {
            p1.x = leftCorner.x;
            p1.y = waterIncline * p1.x + waterOffset;
        }
        else
        {
            p1.x =
                (leftOffset - waterOffset) /
                (waterIncline - leftIncline);
            p1.y = waterIncline * p1.x + waterOffset;
        }

        Vector2 p2 = Vector2.zero;
        if (float.IsNaN(rightIncline))
        {
            p2.x = rightCorner.x;
            p2.y = waterIncline * p2.x + waterOffset;
        }
        else
        {
            p2.x =
                (rightOffset - waterOffset) /
                (waterIncline - rightIncline);
            p2.y = waterIncline * p2.x + waterOffset;
        }

        return (p1, p2);
    }
    private void CalculateCameraRect()
    {
        var min = camera.ViewportToWorldPoint(camera.rect.min);
        Vector2 size = camera.ViewportToWorldPoint(camera.rect.max) - min;
        sizeRect = new Rect(min, size);
    }
    private List<int> SplitIntoTriangles(List<Vector2> vertices)
    {
        List<int> triangles = new List<int>();
        int origin = 0;

        for (int i = 1; i < vertices.Count - 1; i++)
        {
            triangles.AddRange(new int[] {
                    origin, i, i+1
                });
        }

        return triangles;
    }
    private float ComputeTriangleArea(Vector2 p1, Vector2 p2, Vector2 p3)
    {
        float[,] matrix = new float[,] {
                {p1.x, p1.y, 1},
                {p2.x, p2.y, 1},
                {p3.x, p3.y, 1}
            };

        return Mathf.Abs(Compute3x3Determinant(matrix)) / 2;
    }
    private Vector2 ComputeCentroid(List<Vector2> vertices, List<int> triangles, out float area)
    {
        Vector2 centroid = Vector2.zero;
        area = 0;

        for (int i = 0; i < triangles.Count; i += 3)
        {
            Vector2 tCentroid = ComputeTriangleCentroid(
                vertices[triangles[i]],
                vertices[triangles[i + 1]],
                vertices[triangles[i + 2]]
            );

            float tArea = ComputeTriangleArea(
                vertices[triangles[i]],
                vertices[triangles[i + 1]],
                vertices[triangles[i + 2]]
            );

            centroid += tArea * tCentroid;
            area += tArea;
        }
        centroid = centroid / area;

        return centroid;
    }
    private Vector2 ComputeTriangleCentroid(Vector2 p1, Vector2 p2, Vector2 p3)
    {
        return (p1 + p2 + p3) / 3;
    }
    private float Compute3x3Determinant(float[,] matrix)
    {
        if (matrix.Length != 9)
            throw new System.Exception("Matrix is not 3x3");

        float det = 0;
        for (int i = 0; i < 3; i++)
            det += (matrix[0, i] * (matrix[1, (i + 1) % 3] * matrix[2, (i + 2) % 3] - matrix[1, (i + 2) % 3] * matrix[2, (i + 1) % 3]));

        return det;
    }
    private Vector2 GetColliderSize(Collider2D other)
    {
        Vector2 size = Vector2.zero;

        switch (other)
        {
            case BoxCollider2D box:
                size = box.size;
                break;
            case CapsuleCollider2D capsule:
                size = capsule.size;
                break;
            case CircleCollider2D circle:
                size = circle.radius * Vector2.one;
                break;
            default:
                //Debug.LogError("Floating collider fell into generic case");
                size = other.bounds.size;
                break;
        }

        return size * other.transform.localScale;

    }
    private (WaterNode leftNode, WaterNode rightNode) FindClosestSegment(Vector2 point)
    {
        #region Binary Search
        int i;
        int start = 0;
        int end = nodes.Count - 1;

        float distance;
        float leftDistance;
        float rightDistance;

        while (start <= end)
        {
            i = (start + end) / 2;

            distance = Mathf.Abs(nodes[i].position.x - point.x);
            leftDistance = 0 <= i - 1 ? Mathf.Abs(nodes[i - 1].position.x - point.x) : distance;
            rightDistance = i + 1 < nodes.Count ? Mathf.Abs(nodes[i + 1].position.x - point.x) : distance;

            if (leftDistance < distance)
                end = i - 1;
            else if (rightDistance < distance)
                start = i + 1;
            else
            {
                if (0 == i)
                    return (nodes[i], nodes[i + 1]);
                else if (i == nodes.Count - 1)
                    return (nodes[i - 1], nodes[i]);
                if (0 < i - 1 && leftDistance < rightDistance)
                    return (nodes[i - 1], nodes[i]);
                else
                    return (nodes[i], nodes[i + 1]);
            }
        }


        return (null, null);
        #endregion
    }
    private void ComputeCoeficients()
    {
        positionDelta = 1f / nodesPerUnit;
    }
    #endregion

    #region Surface Control
    private void CheckCameraBounds()
    {
        var vertExtent = camera.orthographicSize;
        var horzExtent = vertExtent * Screen.width / Screen.height;

        var cameraMinPosX = -horzExtent + camera.transform.position.x;
        var cameraMaxPosX = horzExtent + camera.transform.position.x;

        var minNodePosX = nodes[0].position.x + positionDelta;
        var maxNodePosX = nodes[nodes.Count - 1].position.x - positionDelta;

        if (minNodePosX > cameraMinPosX)
        {
            for (int i = 0; i < minNodePosX - cameraMinPosX; i++)
            {
                PlaceNodesBackward();
            }
        }
        else if (maxNodePosX < cameraMaxPosX)
        {
            for (int i = 0; i < cameraMaxPosX - maxNodePosX; i++)
            {
                PlaceNodesForward();
            }
        }
    }
    private void PlaceNodesBackward()
    {
        float disturbance;
        WaterNode cycledNode;
        for (int i = 1; i <= nodesPerUnit; i++)
        {
            cycledNode = nodes[nodes.Count - 1];
            nodes.Remove(cycledNode);

            disturbance = GetWavePoint(time);

            cycledNode.position.x = nodes[0].position.x - (positionDelta);
            cycledNode.position.y = transform.position.y + disturbance;

            nodes.Insert(0, cycledNode);

            time = (time + Time.fixedDeltaTime) % (2 * Mathf.PI);

        }
    }
    private void PlaceNodesForward()
    {
        float disturbance;
        WaterNode cycledNode;
        for (int i = 1; i <= nodesPerUnit; i++)
        {
            cycledNode = nodes[0];
            nodes.Remove(cycledNode);

            disturbance = GetWavePoint(time);

            cycledNode.position.x = nodes[nodes.Count - 1].position.x + (positionDelta);
            cycledNode.position.y = transform.position.y + disturbance;

            nodes.Add(cycledNode);

            time = (time + Time.fixedDeltaTime) % (2 * Mathf.PI);
        }
    }
    private void GenerateWaves(float offsetX = 0.0f)
    {
        for (int i = 0; i < nodes.Count; i++)
        {
            var positionX = nodes[i].position.x;
            var positionY = GetWavePoint(positionX + offsetX);
            nodes[i].position = new Vector2(positionX, positionY);
        }
    }
    private void InitializeSurface()
    {
        int nodeAmount = ((int)(longitude * nodesPerUnit));

        positionDelta = 1f / nodesPerUnit;

        for (int count = 0; count <= nodeAmount / 2; count++)
        {
            Vector2 rightPosition = (Vector2)transform.position + Vector2.right * (positionDelta * count);
            Vector2 leftPosition = (Vector2)transform.position + Vector2.left * (positionDelta * count);

            nodes.Add(new WaterNode(rightPosition, disturbance));
            if (count > 0)
            {
                nodes.Insert(0, new WaterNode(leftPosition, disturbance));
            }
        }
    }
    private void InitializeStructures()
    {
        int nodeAmount = ((int)(longitude * nodesPerUnit)) + 1;

        meshVertices = new Vector3[nodeAmount * 2];
    }
    #endregion

    #region Draw Functions
    private void DrawBody()
    {
        CalculateCameraRect();

        for (int i = 0; i < nodes.Count; i++)
        {
            meshVertices[i] = nodes[i].position - (Vector2)transform.position;
            meshVertices[meshVertices.Length - i - 1] = new Vector2(nodes[i].position.x, -waterDepth);
        }

        meshRenderer.sortingLayerName = sortingLayerName;
        meshRenderer.sortingOrder = sortingOrder;

        polygonCollider.SetPath(0, meshVertices.Select(x => new Vector2(x.x, x.y)).ToList());

        mesh.Clear();
        mesh = polygonCollider.CreateMesh(true, true);

        int pointCount = polygonCollider.GetTotalPointCount();
        Vector2[] points = polygonCollider.points.ToArray();
        Vector3[] vertices = new Vector3[pointCount];
        Vector2[] uv = new Vector2[pointCount];
        for (int j = 0; j < pointCount; j++)
        {
            Vector2 actual = points[j] + (Vector2)transform.position;
            vertices[j] = new Vector3(Mathf.Clamp(actual.x, sizeRect.xMin, sizeRect.xMax),
                                        Mathf.Clamp(actual.y, sizeRect.yMin, sizeRect.yMax) - transform.position.y, 0);
            uv[j] = new Vector2(Mathf.InverseLerp(sizeRect.xMin, sizeRect.xMax, vertices[j].x),
                                Mathf.InverseLerp(sizeRect.yMin, sizeRect.yMax, vertices[j].y + transform.position.y));
        }

        int[] indices = new int[pointCount * 3];
        for (int i = 0, z = 0; i + 5 < indices.Length; i += 6, z++)
        {
            indices[i + 0] = z + 0;
            indices[i + 1] = vertices.Length - 1 - z;
            indices[i + 2] = z + 1;

            indices[i + 3] = z + 1;
            indices[i + 4] = vertices.Length - 1 - z;
            indices[i + 5] = vertices.Length - 2 - z;
        }

        mesh.vertices = vertices;
        mesh.uv = uv;
        mesh.triangles = indices;

        meshFilter.mesh = mesh;
    }
    private void DrawTop()
    {
        lineRenderer.startWidth = lineRenderer.endWidth = topWidth;
        lineRenderer.startColor = lineRenderer.endColor = topWaterColor;
        lineRenderer.positionCount = meshVertices.Length;
        lineRenderer.SetPositions(meshVertices);
    }
    #endregion

    #region Gizmos
    private void OnDrawGizmos()
    {
#if UNITY_EDITOR
        Gizmos.color = topWaterColor;

        Gizmos.DrawCube(
            transform.position + Vector3.down * waterDepth / 2,
            Vector2.right * longitude + Vector2.down * waterDepth
        );

        int nodeAmount = ((int)(longitude * nodesPerUnit));
        positionDelta = 1f / nodesPerUnit;
        var gizmosNodes = new List<Vector2>(nodeAmount);
        for (int count = 0; count <= nodeAmount / 2; count++)
        {
            Vector2 rightPosition = (Vector2)transform.position + Vector2.right * (positionDelta * count);
            Vector2 leftPosition = (Vector2)transform.position + Vector2.left * (positionDelta * count);

            gizmosNodes.Add(rightPosition);
            if (count > 0)
            {
                gizmosNodes.Insert(0, leftPosition);
            }
        }
        for (int i = 0; i < nodeAmount; i++)
        {
            var positionX = gizmosNodes[i].x;
            var positionY = GetWavePoint(positionX);
            gizmosNodes[i] = new Vector2(positionX, positionY);
        }
        for (int i = 0; i < gizmosNodes.Count - 1; i++)
        {
            Gizmos.DrawLine(gizmosNodes[i], gizmosNodes[i + 1]);
        }
#endif
    }
    #endregion


    public float Amplitude { get => amplitude; set => amplitude = value; }
}
