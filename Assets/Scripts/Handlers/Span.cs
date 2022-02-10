using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public struct Span
{
    public float start;
    public float finish;

    public float Length => finish - start;
    public float medium => start + Length / 2.0f;
}
