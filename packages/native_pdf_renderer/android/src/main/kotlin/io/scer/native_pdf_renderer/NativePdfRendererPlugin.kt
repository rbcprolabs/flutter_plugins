package io.scer.native_pdf_renderer

import androidx.annotation.NonNull

import android.annotation.TargetApi
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.scer.native_pdf_renderer.resources.DocumentRepository
import io.scer.native_pdf_renderer.resources.PageRepository
import io.scer.native_pdf_renderer.resources.RepositoryItemNotFoundException
import io.scer.native_pdf_renderer.utils.CreateRendererException
import io.scer.native_pdf_renderer.utils.randomFilename
import io.scer.native_pdf_renderer.utils.toFile
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException

/**
 * NativePdfRendererPlugin
 */
@TargetApi(Build.VERSION_CODES.LOLLIPOP)
class NativePdfRendererPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var binding : FlutterPlugin.FlutterPluginBinding
    private val documents = DocumentRepository()
    private val pages = PageRepository()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        binding = flutterPluginBinding;
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "io.scer.native_pdf_renderer")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, rawResult: Result) {
        val result = MethodResultWrapper(rawResult)
        when(call.method) {
            "open.document.data" -> openDocumentDataHandler(call, result)
            "open.document.file" -> openDocumentFileHandler(call, result)
            "open.document.asset" -> openDocumentAssetHandler(call, result)
            "open.page" -> openPageHandler(call, result)
            "close.document" -> closeDocumentHandler(call, result)
            "close.page" -> closePageHandler(call, result)
            "render" -> renderHandler(call, result)
            else -> result.notImplemented()
        }
    }

    private fun openDocumentDataHandler(call: MethodCall, result: Result) {
        Thread {
            try {
                val data = call.arguments<ByteArray>()!!
                val documentRenderer = openDataDocument(data)
                result.success(documents.register(documentRenderer).infoMap)
            } catch (e: NullPointerException) {
                result.error("PDF_RENDER", "Need call arguments: data!", null)
            } catch (e: IOException) {
                result.error("PDF_RENDER", "Can't open file", null)
            } catch (e: CreateRendererException) {
                result.error("PDF_RENDER", "Can't create PDF renderer", null)
            } catch (e: Exception) {
                result.error("PDF_RENDER", "Unknown error", null)
            }
        }.start()
    }

    private fun openDocumentFileHandler(call: MethodCall, result: Result) {
        Thread {
            try {
                val path = call.arguments<String>()!!
                val documentRenderer = openFileDocument(File(path))
                result.success(documents.register(documentRenderer).infoMap)
            } catch (e: NullPointerException) {
                result.error("PDF_RENDER", "Need call arguments: path", null)
            } catch (e: FileNotFoundException) {
                result.error("PDF_RENDER", "File not found", null)
            } catch (e: IOException) {
                result.error("PDF_RENDER", "Can't open file", null)
            } catch (e: CreateRendererException) {
                result.error("PDF_RENDER", "Can't create PDF renderer", null)
            } catch (e: Exception) {
                result.error("PDF_RENDER", "Unknown error", null)
            }
        }.start()
    }

    private fun openDocumentAssetHandler(call: MethodCall, result: Result) {
        Thread {
            try {
                val path = call.arguments<String>()!!
                val documentRenderer = openAssetDocument(path)
                result.success(documents.register(documentRenderer).infoMap)
            } catch (e: NullPointerException) {
                result.error("PDF_RENDER", "Need call arguments: path", null)
            } catch (e: FileNotFoundException) {
                result.error("PDF_RENDER", "File not found", null)
            } catch (e: IOException) {
                result.error("PDF_RENDER", "Can't open file", null)
            } catch (e: CreateRendererException) {
                result.error("PDF_RENDER", "Can't create PDF renderer", null)
            } catch (e: Exception) {
                result.error("PDF_RENDER", "Unknown error", null)
            }
        }.start()

    }

    private fun closeDocumentHandler(call: MethodCall, result: Result) {
        try {
            val id = call.arguments<String>()
            documents.close(id)
            result.success(null)
        } catch (e: NullPointerException) {
            result.error("PDF_RENDER", "Need call arguments: id!", null)
        } catch (e: RepositoryItemNotFoundException) {
            result.error("PDF_RENDER", "Document not exist in documents repository", null)
        } catch (e: Exception) {
            result.error("PDF_RENDER", "Unknown error", null)
        }
    }

    private fun closePageHandler(call: MethodCall, result: Result) {
        try {
            val id = call.arguments<String>()
            pages.close(id)
            result.success(null)
        } catch (e: NullPointerException) {
            result.error("PDF_RENDER", "Need call arguments: id!", null)
        } catch (e: RepositoryItemNotFoundException) {
            result.error("PDF_RENDER", "Page not exist in pages repository", null)
        } catch (e: Exception) {
            result.error("PDF_RENDER", "Unknown error", null)
        }
    }

    private fun openPageHandler(call: MethodCall, result: Result) {
        Thread {
            try {
                val documentId = call.argument<String>("documentId")!!
                val pageNumber = call.argument<Int>("page")!!

                val pageRenderer = documents.get(documentId).openPage(pageNumber)
                result.success(pages.register(documentId, pageRenderer).infoMap)
            } catch (e: NullPointerException) {
                result.error("PDF_RENDER", "Need call arguments: documentId & page!", null)
            } catch (e: RepositoryItemNotFoundException) {
                result.error("PDF_RENDER", "Document not exist in documents", null)
            } catch (e: Exception) {
                result.error("PDF_RENDER", "Unknown error", null)
            }
        }.start()
    }

    private fun renderHandler(call: MethodCall, result: Result) {
        Thread {
            try {
                val pageId = call.argument<String>("pageId")!!
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val format = call.argument<Int>("format") ?: 1 //0 Bitmap.CompressFormat.PNG
                val backgroundColor = call.argument<String>("backgroundColor")
                val color = if (backgroundColor != null) Color.parseColor(backgroundColor) else Color.TRANSPARENT

                val crop = call.argument<Boolean>("crop")!!;
                val cropX = if (crop) call.argument<Int>("crop_x")!! else 0;
                val cropY = if (crop) call.argument<Int>("crop_y")!! else 0;
                val cropH = if (crop) call.argument<Int>("crop_height")!! else 0;
                val cropW = if (crop) call.argument<Int>("crop_width")!! else 0;

                val quality = call.argument<Int>("quality") ?: 100

                val page = pages.get(pageId)

                val tempOutFileExtension = when (format) {
                    0 -> "jpg"
                    1 -> "png"
                    2 -> "webp"
                    else -> "jpg"
                }
                val tempOutFolder = File(binding.applicationContext.cacheDir, "native_pdf_renderer_cache")
                tempOutFolder.mkdirs()
                val tempOutFile = File(tempOutFolder, "$randomFilename.$tempOutFileExtension")

                val results = page.render(tempOutFile, width, height, color, format, crop, cropX, cropY, cropW, cropH, quality).toMap
                result.success(results)

            } catch (e: Exception) {
                result.error("PDF_RENDER", "Unexpected error", e)
            }
        }.start()
    }

    private fun openDataDocument(data: ByteArray): Pair<ParcelFileDescriptor, PdfRenderer>? {
        val tempDataFile = File(binding.applicationContext.cacheDir, "$randomFilename.pdf")
        if (!tempDataFile.exists()) {
            tempDataFile.writeBytes(data)
        }
        Log.d("PDF_RENDER", "OpenDataDocument. Created file: " + tempDataFile.path)
        return openFileDocument(tempDataFile)
    }

    private fun openAssetDocument(assetPath: String): Pair<ParcelFileDescriptor, PdfRenderer>?{
        val fullAssetPath = binding.flutterAssets.getAssetFilePathByName(assetPath)
        val tempAssetFile = File(binding.applicationContext.cacheDir, "$randomFilename.pdf")
        if (!tempAssetFile.exists()) {
            val inputStream = binding.applicationContext.assets.open(fullAssetPath)
            inputStream.toFile(tempAssetFile)
            inputStream.close()
        }
        Log.d("PDF_RENDER", "OpenAssetDocument. Created file: " + tempAssetFile.path)
        return openFileDocument(tempAssetFile)
    }

    private fun openFileDocument(file: File): Pair<ParcelFileDescriptor, PdfRenderer> {
        Log.d("PDF_RENDER", "OpenFileDocument. File: " + file.path)
        val fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        return if (fileDescriptor != null) {
            val pdfRenderer = PdfRenderer(fileDescriptor)
            Pair(fileDescriptor, pdfRenderer)
        } else throw CreateRendererException()
    }

    // MethodChannel.Result wrapper that responds on the platform thread.
    private class MethodResultWrapper internal constructor(private val methodResult: Result) : Result {
        private val handler: Handler = Handler(Looper.getMainLooper())

        override fun success(result: Any?) {
            handler.post { methodResult.success(result) }
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            handler.post { methodResult.error(errorCode, errorMessage, errorDetails) }
        }

        override fun notImplemented() {
            handler.post { methodResult.notImplemented() }
        }
    }
}

