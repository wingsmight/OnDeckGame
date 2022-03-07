using UnityEngine;

public class MonoBehaviourSingleton<T> : MonoBehaviour
    where T : MonoBehaviour
{
    private static T instance;
    private static object _lock = new object();
    private static bool isPlaceOnDontDestroy;
    public static bool applicationIsQuitting = false;


    protected virtual void Awake()
    {
        if(!isPlaceOnDontDestroy)
        {
            DontDestroyOnLoad(gameObject);
            isPlaceOnDontDestroy = true;
        }

        //if (GetType() == typeof(Achievements))
        {
            var instances = FindObjectsOfType<T>();
            if (instances.Length > 1)
            {
                for (int i = 0; i < instances.Length; i++)
                {
                    if (instances[i] != instance && instance != null)
                    {
                        Debug.Log("Destroy(" + this.GetType() + ");");

                        Destroy(instances[i]);
                        return;
                    }
                }
            }
        }
    }
    protected virtual void OnDestroy()
    {
        applicationIsQuitting = true;
    }


    public static T Instance
    {
        get
        {
            //if (applicationIsQuitting)
            //{
            //    return null;
            //}

            //lock (_lock)
            {
                var instances = FindObjectsOfType<T>();
                //if (instances.Length > 0 && instances[0].GetType() == typeof(Achievements))
                {
                    if (instances.Length > 1)
                    {
                        for (int i = 0; i < instances.Length; i++)
                        {
                            if (instances[i] != instance && instance != null)
                            {
                                Destroy(instances[i]);
                            }
                        }
                    }
                }

                if (instance == null)
                {
                    instance = FindObjectOfType<T>();


                    if (instance == null)
                    {
                        var singleton = new GameObject("[SINGLETON] " + typeof(T));
                        instance = singleton.AddComponent<T>();
                        DontDestroyOnLoad(singleton);
                        isPlaceOnDontDestroy = true;
                    }

                }

                return instance;
            }
        }
    }
}