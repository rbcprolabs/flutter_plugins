package io.scer.native_pdf_renderer.document

import android.annotation.TargetApi
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.Build
import io.scer.native_pdf_renderer.utils.toByteArray
import io.scer.native_pdf_renderer.utils.toFile
import java.io.File

@TargetApi(Build.VERSION_CODES.LOLLIPOP)
class Page(
    private val id: String,
    private val documentId: String,
    private val pageRenderer: PdfRenderer.Page
) {
    /** Page number in document */
    private val number: Int get() = pageRenderer.index

    private val width: Int get() = pageRenderer.width
    private val height: Int get() = pageRenderer.height

    val infoMap: Map<String, Any>
        get() =
            mapOf(
                "documentId" to documentId,
                "id" to id,
                "pageNumber" to number,
                "width" to width,
                "height" to height
            )

    fun close() {
        pageRenderer.close()
    }

    fun render(file: File, width: Int, height: Int, background: Int, format: Int, crop: Boolean, cropX: Int, cropY: Int, cropW: Int, cropH: Int, quality: Int): Data {
        val bitmap = Bitmap.createBitmap(
            width,
            height,
            Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(background)

        pageRenderer.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

        if (crop && (cropW != width || cropH != height)) {
            val cropped = Bitmap.createBitmap(bitmap, cropX, cropY, cropW, cropH)
            cropped.toFile(file, format, quality)
            return Data(
                cropW,
                cropH,
                file.absolutePath
            )
        } else {
            bitmap.toFile(file, format, quality)
            return Data(
                width,
                height,
                file.absolutePath
            )
        }
    }

    data class Data(
        val width: Int,
        val height: Int,
        val path: String
    ) {
        val toMap: Map<String, Any>
            get() =
                mapOf(
                    "width" to width,
                    "height" to height,
                    "path" to path
                )

        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false

            other as Data

            if (!path.contentEquals(other.path)) return false

            return true
        }

        override fun hashCode(): Int = width.hashCode()
            .times(31).plus(height.hashCode())
            .times(31).plus(path.hashCode())
    }
}
