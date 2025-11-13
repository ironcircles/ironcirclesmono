package com.ironcircles.ironcirclesapp
import android.view.View
import android.os.Bundle
//import android.view.WindowManager;
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.view.WindowManager.LayoutParams;
import io.flutter.embedding.engine.FlutterEngine
import androidx.core.app.ActivityCompat

class MainActivity: FlutterActivity(), ActivityCompat.OnRequestPermissionsResultCallback {
    private var voicePlatformPlugin: VoicePlatformPlugin? = null

    override fun onCreate(savedInstanceState: Bundle?) {


        if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
            this.finish()
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
        getWindow().addFlags(LayoutParams.FLAG_SECURE);
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the MediaScannerPlugin
        flutterEngine.plugins.add(MediaScannerPlugin())
        // Register the custom voice platform channel
        voicePlatformPlugin = VoicePlatformPlugin(this).also { it.start(flutterEngine) }
    }

    override fun onStart() {
        super.onStart()
        window.decorView.visibility = View.VISIBLE;
    }

    override fun onStop() {
        super.onStop()
        window.decorView.visibility = View.GONE;
    }

    override fun onDestroy() {
        voicePlatformPlugin?.stop()
        voicePlatformPlugin = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        voicePlatformPlugin?.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}