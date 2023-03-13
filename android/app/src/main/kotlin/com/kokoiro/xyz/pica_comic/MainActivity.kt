package com.kokoiro.xyz.pica_comic
import android.view.KeyEvent
import android.view.WindowManager

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterFragmentActivity() {
    var volumeListen = VolumeListen()
    var listening = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        val channel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kokoiro.xyz.pica_comic/volume")
        channel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    listening = true
                    volumeListen.whenUp = {
                        events.success(1)
                    }
                    volumeListen.whenDown = {
                        events.success(2)
                    }
                }
                override fun onCancel(arguments: Any?) {
                    listening = false
                }
        })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"com.kokoiro.xyz.pica_comic/screenshot").setMethodCallHandler{
                _, _ ->
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"com.kokoiro.xyz.pica_comic/secure").setMethodCallHandler{
                _, result ->
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if(listening){
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    volumeListen.down()
                    return true
                }
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    volumeListen.up()
                    return true
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }
}

class VolumeListen{
    var whenUp = fun() {}
    var whenDown = fun() {}
    fun up(){
        whenUp()
    }
    fun down(){
        whenDown()
    }
}
