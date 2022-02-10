using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spawner : MonoBehaviour
{
    [SerializeField] private GameObject spawnObject;


    private Vector3 spawnPosition;


    private void Awake()
    {
        spawnPosition = transform.position;
    }
    private void Start()
    {
        Spawn();
    }


    private void Spawn()
    {
        spawnObject.transform.position = spawnPosition;
    }
}
