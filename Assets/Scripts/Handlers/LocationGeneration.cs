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
    [SerializeField] private GameObject[] triggerObjects = new GameObject[0];


    private float locationPositionX = 0;
    private int prevLocationIndex = 0;
    private Trigger[] triggers = new Trigger[0];


    private void Awake()
    {
        triggers = new Trigger[triggerObjects.Length];
        for (int i = 0; i < triggers.Length; i++)
        {
            triggers[i] = new Trigger(triggerObjects[i], triggerObjects[i].transform.position);
        }

        for (int i = 0; i < locations.Length; i++)
        {
            if (locations[i].gameObject.activeInHierarchy)
            {
                prevLocationIndex = i;

                break;
            }
        }
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
        foreach (var trigger in triggers)
        {
            trigger.gameObject.transform.position = new Vector3(locationPositionX + trigger.startPosition.x, trigger.startPosition.y, trigger.startPosition.z);
        }

        prevLocationIndex = locationIndex;
    }
    public void Show()
    {
        locations.ToList().ForEach(x => x.gameObject.SetActive(true));
        triggerObjects.ToList().ForEach(x => x.SetActive(true));
    }
    public void Hide()
    {
        locations.ToList().ForEach(x => x.gameObject.SetActive(false));
        triggerObjects.ToList().ForEach(x => x.SetActive(false));
    }
    public void Shift(float enabledDistance)
    {
        foreach (var location in locations)
        {
            location.transform.position += new Vector3(enabledDistance, 0, 0);
        }
        foreach (var triggerObject in triggerObjects)
        {
            triggerObject.transform.position += new Vector3(enabledDistance, 0, 0);
        }
    }

    private void SetNextPosition()
    {
        locationPositionX = locations[prevLocationIndex].transform.position.x;
        locationPositionX = locationPositionX + distance + Random.Range(-spread, spread);
    }


    private class Trigger
    {
        public GameObject gameObject;
        public Vector3 startPosition;


        public Trigger(GameObject gameObject, Vector3 startPosition)
        {
            this.gameObject = gameObject;
            this.startPosition = startPosition;
        }
    }
}
