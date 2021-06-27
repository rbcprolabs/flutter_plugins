package io.scer.native_pdf_renderer.utils

import android.graphics.Bitmap

fun parseCompressFormat(format: Int): Bitmap.CompressFormat {
    return when(format) {
        0 -> Bitmap.CompressFormat.JPEG
        1 -> Bitmap.CompressFormat.PNG
        2 -> Bitmap.CompressFormat.WEBP
        else -> Bitmap.CompressFormat.JPEG
    }
}
