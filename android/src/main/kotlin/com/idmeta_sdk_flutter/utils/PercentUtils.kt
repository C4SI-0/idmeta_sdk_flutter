package com.idmeta_sdk_flutter.utils

import kotlin.math.roundToInt

/**
 * Convert the float number to integer percentage, e.g. 0.564 -> 56, 0.715 -> 72.
 */
fun Float.toIntPercent(): Int {
    return (this * 100).roundToInt()
}
