package com.devsinntechnologies.iqraquran

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Shares its FlutterEngine with the recitation media service, so playback
// controls from the notification and lock screen reach the running app.
class MainActivity: AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VerseVideoEncoder.CHANNEL)
        channel.setMethodCallHandler(VerseVideoEncoder(channel))
        FloatingRecitationBubble.attach(
            this,
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FloatingRecitationBubble.CHANNEL),
        )
    }

    // The floating logo shows over other apps only while this app is not
    // on screen; inside the app, Flutter draws its own.
    override fun onStart() {
        super.onStart()
        FloatingRecitationBubble.setAppVisible(true)
    }

    override fun onStop() {
        super.onStop()
        if (!isChangingConfigurations) FloatingRecitationBubble.setAppVisible(false)
    }
}
