using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spawner : MonoBehaviour
{
    [SerializeField] private Boat spawnObject;


    private Vector3 spawnPosition;


    private void Awake()
    {
        spawnPosition = transform.position;
        spawnObject.OnDestroyed += Spawn;
    }
    private void Start()
    {
        Spawn();
    }
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.S))
        {
            Spawn();
        }
    }


    public void Spawn()
    {
        spawnObject.gameObject.SetActive(true);
        spawnObject.transform.position = spawnPosition;
    }
}
