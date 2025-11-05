// File path: android/app/src/main/kotlin/com/yourcompany/yourapp/MediaScannerPlugin.kt

package com.ironcircles.ironcirclesapp

import android.content.Context
import android.media.MediaScannerConnection
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class MediaScannerPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "media_scanner_channel")
        context = binding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanFile" -> {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    scanFile(filePath, result)
                } else {
                    result.error("INVALID_ARGUMENT", "File path cannot be null", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun scanFile(filePath: String, result: Result) {
        val file = File(filePath)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "The specified file does not exist", null)
            return
        }

        MediaScannerConnection.scanFile(
            context,
            arrayOf(filePath),
            null
        ) { path, uri ->
            if (uri != null) {
                result.success(true)
            } else {
                result.error("SCAN_FAILED", "Failed to scan file", null)
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}