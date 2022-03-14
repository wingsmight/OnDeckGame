using System;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

[RequireComponent(typeof(MeshFilter), typeof(PolygonCollider2D))]
public class WaterGenerator : MonoBehaviour
{
    #region Settings
    [SerializeField] private float STANDARD_DRAG = 1.05f;
    #endregion

    #region Settings
    [Header("Settings")]
    [FormerlySerializedAs("waterColor")] [SerializeField] private Color waterColor;
    [FormerlySerializedAs("topWaterColor")] [SerializeField] private Color topWaterColor;
    [SerializeField] private float longitude = 70.0f;
    [SerializeField] private int nodesPerUnit = 5;
    [SerializeField] private float waterDepth = 20.0f;
    [SerializeField] private float topWidth = 0.2f;

    [Header("Physics")]
    [Range(0, 0.1f)] [SerializeField] private float springConstant = 0.02f;
    [Range(0, 0.1f)] [SerializeField] private float damping = 0.02f;
    [Range(0.0f, .5f)] [SerializeField] private float spreadRatio = 0.33f;
    [Range(1, 10)] [SerializeField] private int spreadSpeed = 8;
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
    #endregion

    #region Private Variables
    private List<WaterNode> nodes = new List<WaterNode>();

    private float[] leftDeltas;
    private float[] rightDeltas;

    private Vector3[] meshVertices;
    private Vector2[] colliderPath;
    private int[] meshTriangles;

    private float positionDelta;
    private float massPerNode;
    private Queue<Collider2D> interactionQueue = new Queue<Collider2D>();
    private float time = 0;
    private Vector2 startPointOffset;
    private Mesh mesh;
    #endregion

    #region MonoBehaviour Functions
    private void Awake()
    {
        mesh = new Mesh();
        startPointOffset = transform.position;
        transform.position = new Vector3(0, disturbance, 0);
        lineRenderer.transform.position += (Vector3)startPointOffset;
    }
    private void Start()
    {
        ComputeCoeficients();
        InitializeStructures();
        InitializeSurface();
    }
    private void Update()
    {
        CheckCameraBounds();
    }
    private void FixedUpdate()
    {
        time = (time + Time.fixedDeltaTime) % (2 * Mathf.PI);
        GenerateWaves(time);

        ProcessInteractionQueue();

        DrawBody();
        DrawTop();
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
    public float GetWavePoint(float x)
    {
        return amplitude * Mathf.Sin(x);
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
        rb.drag = STANDARD_DRAG * crossArea * (1 - Mathf.Clamp01(depth * depthForce));
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
        massPerNode = (1f / nodesPerUnit) * waterDepth;
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
    private void GenerateWaves(float offsetX)
    {
        for (int i = 0; i < nodes.Count; i++)
        {
            var positionX = nodes[i].position.x;
            var positionY = GetWavePoint(positionX + offsetX);
            nodes[i].position = new Vector2(positionX, positionY);
        }
    }
    private void ApplySpringForces()
    {
        for (int i = 0; i < nodes.Count; i++)
        {
            if (i < nodes.Count - 1)
                nodes[i].Update(springConstant, damping, massPerNode);
        }
    }
    private void PropagateWaves()
    {
        // do some passes where nodes pull on their neighbours
        for (int j = 0; j < spreadSpeed; j++)
        {
            for (int i = nodes.Count - 1; i >= 0; i--)
            {
                if (i > 0)
                {
                    leftDeltas[i] = spreadRatio * (nodes[i].position.y - nodes[i - 1].position.y);
                    nodes[i - 1].velocity += leftDeltas[i];
                }
                if (i < nodes.Count - 1)
                {
                    rightDeltas[i] = spreadRatio * (nodes[i].position.y - nodes[i + 1].position.y);
                    nodes[i + 1].velocity += rightDeltas[i];
                }
            }

            for (int i = 0; i < nodes.Count; i++)
            {
                if (i > 0)
                    nodes[i - 1].position.y += leftDeltas[i] * Time.fixedDeltaTime;
                if (i < nodes.Count - 1)
                    nodes[i + 1].position.y += rightDeltas[i] * Time.fixedDeltaTime;
            }
        }
    }
    private void ReactToCollisions()
    {
        Dictionary<Collider2D, List<WaterNode>> splashedNodes = new Dictionary<Collider2D, List<WaterNode>>();

        LayerMask mask;
        if (gameObject.layer == LayerMask.NameToLayer("Back Water"))
            mask = LayerMask.GetMask("Back Entities");
        else
            mask = LayerMask.GetMask("Default");

        foreach (WaterNode node in nodes)
        {
            Collider2D splasher = Physics2D.OverlapCircle(
                node.position + Vector2.down * positionDelta,
                positionDelta,
                mask
            );

            if (splasher != null)
            {
                if (!splashedNodes.ContainsKey(splasher))
                    splashedNodes.Add(splasher, new List<WaterNode>());

                splashedNodes[splasher].Add(node);
            }
        }

        float massPerSplash;
        float velocity;
        foreach (Collider2D splasher in splashedNodes.Keys)
        {
            massPerSplash = splasher.attachedRigidbody.mass / splashedNodes[splasher].Count;
            velocity = splasher.attachedRigidbody.velocity.y;

            foreach (WaterNode node in splashedNodes[splasher])
                node.Splash(massPerSplash, velocity, massPerNode);
        }
    }
    private void ReactToCollision(Collider2D splasher)
    {
        int start = Mathf.FloorToInt((splasher.bounds.center.x - splasher.bounds.extents.x) - nodes[0].position.x) * nodesPerUnit;
        int end = Mathf.CeilToInt((splasher.bounds.center.x + splasher.bounds.extents.x) - nodes[0].position.x) * nodesPerUnit;

        start = start >= 0 ? start : 0;
        end = end < nodes.Count ? end : nodes.Count - 1;

        LayerMask mask;
        if (gameObject.layer == LayerMask.NameToLayer("Back Water"))
            mask = LayerMask.GetMask("Back Entities");
        else
            mask = LayerMask.GetMask("Default");

        float splasherMass = splasher.attachedRigidbody.mass;
        float massPerSplash = splasherMass / (end - start);
        Vector2 velocity = splasher.attachedRigidbody.velocity;

        for (int i = start; i <= end; i++)
        {
            bool splashed = Physics2D.OverlapCircle(
                nodes[i].position + Vector2.down * positionDelta,
                positionDelta,
                mask
            );

            if (splashed)
                velocity.y += nodes[i].Splash(massPerSplash, velocity.y, massPerNode) * massPerSplash / splasher.attachedRigidbody.mass;
        }

        if (!float.IsNaN(velocity.x) && !float.IsNaN(velocity.y))
            splasher.attachedRigidbody.velocity = velocity;
    }
    #endregion

    #region Draw Functions
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

        leftDeltas = new float[nodeAmount];
        rightDeltas = new float[nodeAmount];

        meshVertices = new Vector3[nodeAmount * 2];
    }
    private void DrawBody()
    {
        for (int i = 0; i < nodes.Count; i++)
        {
            meshVertices[i] = nodes[i].position - new Vector2(0, transform.position.y);
            meshVertices[meshVertices.Length - i - 1] = new Vector2(nodes[i].position.x, -waterDepth);
        }

        meshRenderer.sortingLayerName = "Water";
        meshRenderer.sortingOrder = 10;

        polygonCollider.SetPath(0, meshVertices.Select(x => new Vector2(x.x, x.y)).ToList());
        polygonCollider.offset = startPointOffset;

        mesh.Clear();
        mesh = polygonCollider.CreateMesh(true, true);

        var meshColors = new Color[mesh.vertexCount];
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            meshColors[i] = waterColor;
        }
        mesh.colors = meshColors;

        mesh.RecalculateNormals();
        GetComponent<MeshFilter>().mesh = mesh;
    }
    private void DrawTop()
    {
        lineRenderer.startWidth = lineRenderer.endWidth = topWidth;
        lineRenderer.startColor = lineRenderer.endColor = topWaterColor;
        lineRenderer.positionCount = meshVertices.Length;
        lineRenderer.SetPositions(meshVertices);
        //lineRenderer.SetPositions(meshVertices.Select(x => new Vector3(x.x, x.y + transform.position.y, x.z)).ToArray());
    }
    #endregion

    #region Gizmos
    private void OnDrawGizmos()
    {
#if UNITY_EDITOR
        Gizmos.color = waterColor;
        Gizmos.DrawLine(
            transform.position - Vector3.right * longitude / 2,
            transform.position + Vector3.right * longitude / 2);
        Gizmos.DrawCube(
            transform.position + Vector3.down * waterDepth / 2,
            Vector3.right * longitude + Vector3.down * waterDepth
        );
#endif
    }
    #endregion


    public float Amplitude { get => amplitude; set => amplitude = value; }
}
