using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class PlayerData
{
    private const int MIN_COOKIE_COUNT = 0;


    private static int cookieCount = 0;


    public static void IncreaseCoockieCount(int count = 1)
    {
        cookieCount += count;
    }
    public static void DecreaseCoockieCount(int count = 1)
    {
        cookieCount -= count;
        cookieCount = Mathf.Max(MIN_COOKIE_COUNT, cookieCount);
    }


    public static int CoockieCount => cookieCount;
}
