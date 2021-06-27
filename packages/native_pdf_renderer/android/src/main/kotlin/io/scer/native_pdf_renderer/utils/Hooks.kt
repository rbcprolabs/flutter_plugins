package io.scer.native_pdf_renderer.utils

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

fun InputStream.toFile(file: File) {
    file.outputStream().use { this.copyTo(it) }
}

/**
 * Save bitmap to file
 */
fun Bitmap.toFile(file: File, format: Int, quality: Int = 100): File {
    val stream = FileOutputStream(file, false)
    val compressFormat = parseCompressFormat(format)
    this.compress(compressFormat, quality, stream)
    stream.flush()
    stream.close()
    return file
}

/**
 * Convert bitmap to byte array using ByteBuffer.
 */
fun Bitmap.toByteArray(format: Int): ByteArray {
    val stream = ByteArrayOutputStream()
    val compressFormat = parseCompressFormat(format)
    this.compress(compressFormat, 100, stream)
    return stream.toByteArray()
}
