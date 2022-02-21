using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LocationGeneration : MonoBehaviour
{
    [SerializeField] private Boat boat;
    [SerializeField] private float distance;
    [SerializeField] private float spread;
    [SerializeField] private Location[] locations;
    [SerializeField] private GenerateNextLocaitonTrigger generationTrigger;


    private float locationPositionX = 0;
    private int prevLocationIndex = 0;


    private void Awake()
    {
        for (int i = 0; i < locations.Length; i++)
        {
            if (locations[i].gameObject.activeInHierarchy)
            {
                prevLocationIndex = i;

                break;
            }
        }

        Generate();
    }


    private void SetNextPosition()
    {
        locationPositionX = locationPositionX + distance + Random.Range(-spread, spread);
    }
    public void Generate()
    {
        SetNextPosition();

        int locationIndex = 0;
        do
        {
            locationIndex = Random.Range(0, locations.Length);
        }
        while (locationIndex == prevLocationIndex);


        var location = locations[locationIndex];
        location.transform.position = new Vector3(locationPositionX, location.transform.position.y, location.transform.position.z);
        location.gameObject.SetActive(true);
        generationTrigger.transform.position = new Vector3(locationPositionX, generationTrigger.transform.position.y, generationTrigger.transform.position.z);

        prevLocationIndex = locationIndex;
    }
}
