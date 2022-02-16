using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

[RequireComponent(typeof(LineRenderer), typeof(MeshFilter), typeof(PolygonCollider2D))]
public class WaterGenerator : MonoBehaviour
{
    #region Singleton
    static WaterGenerator instance;
    public static WaterGenerator Instance
    {
        get => instance;
    }
    #endregion

    #region Settings
    [Header("Settings")]
    [SerializeField] bool isBackLane = false;
    [FormerlySerializedAs("waterColor")] public Color waterColor;
    public float longitude;
    public int nodesPerUnit = 5;
    public float waterDepth;
    public int despawnDistance = 5;
    [Min(1)] public int performanceFactor = 2;

    [Header("Physics")]
    [Range(0, 0.1f)] public float springConstant;
    [Range(0, 0.1f)] public float damping;
    [Range(0.0f, .5f)] public float spreadRatio;
    [Range(1, 10)] public int spreadSpeed;
    [Range(0.1f, 10.0f)] [SerializeField] private float waveIntensity;
    #endregion

    #region References
    // [Header("References")]
    private LineRenderer surface;
    private Mesh mesh;
    private ParticleSystem particles;
    private AreaEffector2D effector;
    #endregion

    #region Private Variables
    private List<WaterNode> nodes;

    private float[] leftDeltas;
    private float[] rightDeltas;

    private Vector3[] meshVertices;
    private Vector2[] colliderPath;
    private int[] meshTriangles;
    private Color[] meshColors;

    private float positionDelta;
    private float massPerNode;
    private Queue<Collider2D> interactionQueue;
    private System.Random random;
    private float time = 0;

    private Camera cam;

    private const float standardDrag = 1.05f;
    #endregion

    #region MonoBehaviour Functions

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (particles != null)
        {
            ParticleSystem.ShapeModule shape = particles.shape;
            shape.position = other.transform.position - transform.position;

            particles.Play();
        }

        ReactToCollision(other);

        Vector2 normal = other.attachedRigidbody.velocity.normalized;
        float crossArea = (normal * other.bounds.size).magnitude;
        other.attachedRigidbody.drag = standardDrag * crossArea;
    }

    void OnTriggerStay2D(Collider2D other)
    {
        if (!interactionQueue.Contains(other) && other.gameObject.GetComponent<Joint2D>() == null)
            interactionQueue.Enqueue(other);

        if (Mathf.Abs(other.attachedRigidbody.velocity.x) >= 1 && particles != null)
        {
            ParticleSystem.ShapeModule shape = particles.shape;
            shape.position = other.transform.position - transform.position;

            particles.Play();
        }

        Vector2 normal = other.attachedRigidbody.velocity.normalized;
        float crossArea = (normal * other.bounds.size).magnitude;
        other.attachedRigidbody.drag = standardDrag * crossArea;
    }

    void OnTriggerExit2D(Collider2D other)
    {
        if (!other.gameObject.CompareTag("Player"))
        {
            Vector2 normal = other.attachedRigidbody.velocity.normalized;
            float crossArea = (normal * other.bounds.size).magnitude;
            other.attachedRigidbody.drag = .001f * standardDrag * crossArea;
        }
    }

    void Awake()
    {
        if (instance is null)
            instance = this;

        effector = GetComponent<AreaEffector2D>();
        particles = GetComponent<ParticleSystem>();
        surface = GetComponent<LineRenderer>();
        nodes = new List<WaterNode>();
        interactionQueue = new Queue<Collider2D>();
        random = new System.Random();
        cam = Camera.main;
    }

    // Start is called before the first frame update
    void Start()
    {
        ComputeCoeficients();
        InitializeStructures();
        InitializeSurface();
        DrawBody();
    }

    // Update is called once per frame
    void Update()
    {
        CheckCameraBounds();
    }

    void FixedUpdate()
    {
        GenerateWaves();

        ProcessInteractionQueue();
        // ReactToCollisions(); 

        ApplySpringForces();
        PropagateWaves();

        DrawBody();
    }
    #endregion

    #region Buoyancy Forces Computations
    void ProcessInteractionQueue()
    {
        while (interactionQueue.Count > 0)
        {
            Collider2D obj = interactionQueue.Dequeue();

            if (obj != null && !obj.gameObject.CompareTag("IgnoreWater"))
            {
                // if (!obj.attachedRigidbody.freezeRotation)
                // {
                AccuratePhysics(obj);
                // }
                // else
                // {
                //     // SimplifiedPhysics(obj);
                // }

                // ReactToCollision(obj);
            }
        }
    }
    void SimplifiedPhysics(Collider2D other)
    {
        Rigidbody2D rb = other.attachedRigidbody;
        PolygonCollider2D waterBody = GetComponent<PolygonCollider2D>();

        Vector2 center = rb.worldCenterOfMass;
        Vector2 size = GetColliderSize(other);

        Vector2[] centroids = new Vector2[] {
                center,
                center + (size * (Vector2.up) / 4).Rotate(rb.rotation),
                center + (size * (Vector2.left) / 4).Rotate(rb.rotation),
                center + (size * (Vector2.right) / 4).Rotate(rb.rotation),
                center + (size * (Vector2.down) / 4).Rotate(rb.rotation),
                center + (size * (Vector2.up + Vector2.left) / 4).Rotate(rb.rotation),
                center + (size * (Vector2.up + Vector2.right) / 4).Rotate(rb.rotation),
                center + (size * (Vector2.down + Vector2.right) / 4).Rotate(rb.rotation),
                center + (size * (Vector2.down + Vector2.left) / 4).Rotate(rb.rotation)
            };

        float volume = 0;
        float volumePerDivision = size.x * size.y / centroids.Length;
        foreach (Vector2 centroid in centroids)
        {
            if (waterBody.OverlapPoint(centroid))
                volume += volumePerDivision;
        }

        float fluidDensity = 1f;
        float dragCoefficient = .38f;
        float crossSection = rb.velocity.y > 0 ? other.bounds.size.x : other.bounds.size.y; // this one might need a better solution

        Vector2 buoyancy = -fluidDensity * Physics2D.gravity * volume;
        float drag = .5f * rb.velocity.sqrMagnitude * dragCoefficient * crossSection;

        rb.AddForce(-drag * rb.velocity.normalized);
        rb.AddForce(buoyancy);
    }
    void AccuratePhysics(Collider2D other)
    {
        Rigidbody2D rb = other.attachedRigidbody;
        PolygonCollider2D waterBody = GetComponent<PolygonCollider2D>();

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

            // Debug.Log($"Intersections: {intersections[0]} {intersections[1]}");
            // Debug.Log($"Submerged Area (approx.): {(intersections[0].y -(center.y - size.y/2)) * size.x}");

            // Remove unsubmerged vertices
            vertices.RemoveAll(vertex => !waterBody.OverlapPoint(vertex));

            vertices.Insert(0, p1);
            vertices.Insert(1, p2);
        }

        // Debug.Log("Vertices:");
        // foreach (var vertex in vertices)
        //     Debug.Log(vertex);

        // Split the unsubmerged volume into triangles
        List<int> triangles = SplitIntoTriangles(vertices);

        // Compute the submerged volume & its centroid
        Vector2 centroid = ComputeCentroid(vertices, triangles, out volume);

        // Debug.Log($"Buoyancy Centroid: {centroid}\nSubmerged Volume: {volume}");

        float fluidDensity = 1f;
        Vector2 buoyancy = -fluidDensity * Physics2D.gravity * volume;

        if (volume != 0 && !float.IsNaN(centroid.x) && !float.IsNaN(centroid.y))
            rb.AddForceAtPosition(buoyancy, centroid);

        // print($"Buoyancy: {buoyancy}\nWeight: {Physics2D.gravity * rb.mass}");
        // print($"1/2 A Triangle Area: {ComputeTriangleArea(new Vector2(0,0),new Vector2(0,1),new Vector2(1,0))}");
    }
    (Vector2 p1, Vector2 p2) FindIntersectionsOnSurface(List<Vector2> vertices, float rotation, int topIndex)
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
    List<int> SplitIntoTriangles(List<Vector2> vertices)
    {
        List<int> triangles = new List<int>();
        int origin = 0;

        // print($"Vertex Count: {vertices.Count}");
        for (int i = 1; i < vertices.Count - 1; i++)
        {
            triangles.AddRange(new int[] {
                    origin, i, i+1
                });
        }

        return triangles;
    }
    float ComputeTriangleArea(Vector2 p1, Vector2 p2, Vector2 p3)
    {
        float[,] matrix = new float[,] {
                {p1.x, p1.y, 1},
                {p2.x, p2.y, 1},
                {p3.x, p3.y, 1}
            };

        return Mathf.Abs(Compute3x3Determinant(matrix)) / 2;
    }
    Vector2 ComputeCentroid(List<Vector2> vertices, List<int> triangles, out float area)
    {
        Vector2 centroid = Vector2.zero;
        area = 0;

        // print($"Triangle Count: {triangles.Count}");
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

            // Debug.Log($"tArea: {tArea}");
            centroid += tArea * tCentroid;
            area += tArea;
        }
        // Debug.Log($"Sum of centroids*area: {centroid}\nTotal area: {area}");
        centroid = centroid / area;

        return centroid;
    }
    Vector2 ComputeTriangleCentroid(Vector2 p1, Vector2 p2, Vector2 p3)
    {
        return (p1 + p2 + p3) / 3;
    }
    float Compute3x3Determinant(float[,] matrix)
    {
        if (matrix.Length != 9)
            throw new System.Exception("Matrix is not 3x3");

        float det = 0;
        for (int i = 0; i < 3; i++)
            det += (matrix[0, i] * (matrix[1, (i + 1) % 3] * matrix[2, (i + 2) % 3] - matrix[1, (i + 2) % 3] * matrix[2, (i + 1) % 3]));

        return det;
    }
    public static Vector2 GetColliderSize(Collider2D other)
    {
        Vector2 size = Vector2.zero;

        switch (other)
        {
            case BoxCollider2D box:
                // Debug.Log("It's a box");
                size = box.size;
                break;
            case CapsuleCollider2D capsule:
                // Debug.Log("It's a capsule");
                size = capsule.size;
                break;
            case CircleCollider2D circle:
                // Debug.Log("It's a circle");
                size = circle.radius * Vector2.one;
                break;
            default:
                Debug.LogError("Floating collider fell into generic case");
                size = other.bounds.size;
                break;
        }

        return size * other.transform.localScale;

    }
    (WaterNode leftNode, WaterNode rightNode) FindClosestSegment(Vector2 point)
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
        // throw new System.Exception("Was unable to find closest segment to the node.");
        #endregion
    }
    void ComputeCoeficients()
    {
        positionDelta = 1f / nodesPerUnit;
        massPerNode = (1f / nodesPerUnit) * waterDepth;
    }
    #endregion

    #region Surface Control
    void CheckCameraBounds()
    {
        Vector2 WorldUnitsInCamera;
        WorldUnitsInCamera.y = cam.orthographicSize * 2;
        WorldUnitsInCamera.x = WorldUnitsInCamera.y * Screen.width / Screen.height;

        Vector2 leftMostPos = nodes[0].position;
        float bound = Camera.main.transform.position.x - WorldUnitsInCamera.x / 2 - despawnDistance;

        if (leftMostPos.x < bound)
        {
            for (int i = 0; i < bound - leftMostPos.x; i++) CycleNodes();
        }
    }

    public void CycleNodes()
    {
        float disturbance;
        WaterNode cycledNode;
        for (int i = 1; i <= nodesPerUnit; i++)
        {
            cycledNode = nodes[0];
            nodes.Remove(cycledNode);

            disturbance = waveIntensity * (isBackLane ? Mathf.Cos(time) : Mathf.Sin(time));

            cycledNode.position.x = nodes[nodes.Count - 1].position.x + (positionDelta);
            cycledNode.position.y = transform.position.y + disturbance;

            nodes.Add(cycledNode);

            time = (time + Time.fixedDeltaTime) % (2 * Mathf.PI);
        }
    }

    void GenerateWaves()
    {
        float disturbance = waveIntensity * (isBackLane ? Mathf.Cos(time) : Mathf.Sin(time));
        time = (time + Time.fixedDeltaTime) % (2 * Mathf.PI);

        nodes[nodes.Count - 1].Disturb(disturbance);
    }
    void ApplySpringForces()
    {
        for (int i = 0; i < nodes.Count; i++)
        {
            if (i < nodes.Count - 1)
                nodes[i].Update(springConstant, damping, massPerNode);
            surface.SetPosition(i, nodes[i].position);
        }
    }
    void PropagateWaves()
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
    void ReactToCollisions()
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
    void ReactToCollision(Collider2D splasher)
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
    void InitializeSurface()
    {
        int nodeAmount = ((int)(longitude * nodesPerUnit));

        positionDelta = 1f / nodesPerUnit;
        surface.positionCount = nodeAmount + 1;

        List<Vector3> positions = new List<Vector3>();
        for (int count = 0; count <= nodeAmount / 2; count++)
        {
            Vector2 rightPosition = (Vector2)transform.position + Vector2.right * (positionDelta * count);
            Vector2 leftPosition = (Vector2)transform.position + Vector2.left * (positionDelta * count);

            nodes.Add(new WaterNode(rightPosition));
            positions.Add(rightPosition);

            if (count > 0)
            {
                nodes.Insert(0, new WaterNode(leftPosition));
                positions.Insert(0, rightPosition);
            }
        }
        surface.SetPositions(positions.ToArray());
    }
    void InitializeStructures()
    {
        int nodeAmount = ((int)(longitude * nodesPerUnit)) + 1;

        leftDeltas = new float[nodeAmount];
        rightDeltas = new float[nodeAmount];

        mesh = new Mesh();

        meshVertices = new Vector3[2 * nodeAmount];
        colliderPath = new Vector2[nodeAmount / performanceFactor + 3];

        meshTriangles = new int[6 * (nodeAmount)];
        for (int i = 1; i < nodeAmount; i++)
        {
            meshTriangles[6 * (i - 1)] = 0 + (i - 1) * 2;
            meshTriangles[6 * (i - 1) + 1] = 2 + (i - 1) * 2;
            meshTriangles[6 * (i - 1) + 2] = 1 + (i - 1) * 2;

            meshTriangles[6 * (i - 1) + 3] = 2 + (i - 1) * 2;
            meshTriangles[6 * (i - 1) + 4] = 3 + (i - 1) * 2;
            meshTriangles[6 * (i - 1) + 5] = 1 + (i - 1) * 2;
        }

        meshColors = new Color[2 * nodeAmount];
        for (int i = 0; i < meshColors.Length; i++)
            meshColors[i] = waterColor;
    }
    void DrawBody()
    {
        Vector3 node;
        for (int i = 0; i < nodes.Count; i++)
        {
            // Weave the mesh by adding the nodes in pairs from left to right
            // First the upper node
            node = (Vector3)nodes[i].position - transform.position;
            meshVertices[2 * i] = node;
            if (i % performanceFactor == 0) colliderPath[i / performanceFactor] = node;

            // Then the lower node
            node.y = transform.position.y - waterDepth;
            meshVertices[2 * i + 1] = node;
        }

#if UNITY_EDITOR
        for (int i = 0; i < meshColors.Length; i++)
            meshColors[i] = waterColor;
#endif

        // Add the two last nodes that close the polygon properly, and that give it depth.
        colliderPath[nodes.Count / performanceFactor] = meshVertices[2 * nodes.Count - 2];
        colliderPath[nodes.Count / performanceFactor + 1] = meshVertices[2 * nodes.Count - 1];
        colliderPath[nodes.Count / performanceFactor + 2] = meshVertices[1];

        mesh.Clear();
        mesh.vertices = meshVertices;
        mesh.triangles = meshTriangles;
        mesh.colors = meshColors;

        mesh.RecalculateNormals();

        MeshRenderer renderer = GetComponent<MeshRenderer>();
        renderer.sortingLayerName = "Water";
        renderer.sortingOrder = 10;

        GetComponent<MeshFilter>().mesh = mesh;
        GetComponent<PolygonCollider2D>().SetPath(0, colliderPath);

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
}
