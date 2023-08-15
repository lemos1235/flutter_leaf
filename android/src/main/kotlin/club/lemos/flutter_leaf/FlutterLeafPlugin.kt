package club.lemos.flutter_leaf

import android.app.Activity
import android.app.Service
import android.content.ComponentName
import android.content.Intent
import android.content.ServiceConnection
import android.net.VpnService
import android.os.Bundle
import android.os.IBinder
import androidx.annotation.NonNull
import club.lemos.vpn.logic.VpnStateService

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** FlutterLeafPlugin */
class FlutterLeafPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

  private lateinit var channel: MethodChannel

  private lateinit var eventChannel: EventChannel

  private lateinit var activityBinding: ActivityPluginBinding

  private var vpnStateService: VpnStateService? = null

  private val vpnStateServiceConnection = object : ServiceConnection {
    override fun onServiceConnected(name: ComponentName, service: IBinder) {
      val vpnState = (service as VpnStateService.LocalBinder).service
      vpnState.setStateListener(VpnStateHandler);
      vpnStateService = vpnState
    }

    override fun onServiceDisconnected(name: ComponentName) {
      vpnStateService = null
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_leaf")
    channel.setMethodCallHandler(this)

    // Register event channel to handle state change.
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_leaf_states")
    eventChannel.setStreamHandler(VpnStateHandler)

    flutterPluginBinding.applicationContext.bindService(
      Intent(flutterPluginBinding.applicationContext, VpnStateService::class.java),
      vpnStateServiceConnection,
      Service.BIND_AUTO_CREATE
    )
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
  }

  override fun onDetachedFromActivity() {
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityBinding = binding
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "prepare" -> {
        val intent = VpnService.prepare(activityBinding.activity.applicationContext)
        if (intent == null) {
          // vpn is permitted
          result.success(true)
        } else {
          // grant permission
          var listener: PluginRegistry.ActivityResultListener? = null
          listener = PluginRegistry.ActivityResultListener { req, res, _ ->
            result.success(req == 0 && res == Activity.RESULT_OK)
            listener?.let { activityBinding.removeActivityResultListener(it) }
            true
          }
          activityBinding.addActivityResultListener(listener)
          activityBinding.activity.startActivityForResult(intent, 0)
        }
      }

      "prepared" -> {
        val intent = VpnService.prepare(activityBinding.activity.applicationContext)
        result.success(intent == null)
      }

      "connect" -> {
        val intent = VpnService.prepare(activityBinding.activity.applicationContext)
        if (intent != null) {
          // Not prepared yet.
          result.success(false)
          return
        }
        val args = call.arguments as Map<*, *>
        val profileInfo = Bundle()
        profileInfo.putString("configContent", args["configContent"] as String)
        if (args.containsKey("mtu")) {
          profileInfo.putInt("mtu", args["mtu"] as Int)
        }
        if (args.containsKey("allowedApps")) {
          profileInfo.putString("allowedApps", args["allowedApps"] as String)
        }
        if (args.containsKey("disallowedApps")) {
          profileInfo.putString("disallowedApps", args["disallowedApps"] as String)
        }

        vpnStateService?.connect(profileInfo)
        result.success(true)
      }

      "getCurrentState" -> {
        result.success(VpnStateHandler.vpnState.ordinal)
      }

      "disconnect" -> vpnStateService?.disconnect()
      "switchProxy" -> {
        val args = call.arguments as Map<*, *>
        vpnStateService?.switchProxy(args["configContent"] as String)
        result.success(true)
      }

      else -> result.notImplemented()
    }
  }
}
