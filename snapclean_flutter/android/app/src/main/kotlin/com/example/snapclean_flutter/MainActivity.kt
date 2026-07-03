package com.example.snapclean_flutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val imageImportChannel = "snapclean/image_import"
    private val pickImagesRequest = 4102
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, imageImportChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImages" -> pickImages(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun pickImages(result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("picker_busy", "The image picker is already open.", null)
            return
        }
        pendingPickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        try {
            startActivityForResult(intent, pickImagesRequest)
        } catch (error: Exception) {
            pendingPickResult = null
            result.error("picker_unavailable", error.message, null)
        }
    }

    @Deprecated("Deprecated in Android API, still supported by FlutterActivity.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickImagesRequest) return

        val result = pendingPickResult ?: return
        pendingPickResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return
        }

        val uris = mutableListOf<Uri>()
        val clipData = data.clipData
        if (clipData != null) {
            for (index in 0 until clipData.itemCount) {
                uris.add(clipData.getItemAt(index).uri)
            }
        } else {
            data.data?.let { uris.add(it) }
        }

        try {
            val paths = uris.mapIndexedNotNull { index, uri ->
                copyUriToCache(uri, index)
            }
            result.success(paths)
        } catch (error: Exception) {
            result.error("copy_failed", error.message, null)
        }
    }

    private fun copyUriToCache(uri: Uri, index: Int): String? {
        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: Exception) {
            // Some providers grant temporary read access only; copying still works.
        }
        val input = contentResolver.openInputStream(uri) ?: return null
        val directory = File(cacheDir, "snapclean_imports").apply { mkdirs() }
        val output = File(directory, "image_${System.currentTimeMillis()}_$index.jpg")
        input.use { source ->
            output.outputStream().use { target ->
                source.copyTo(target)
            }
        }
        return output.absolutePath
    }
}
