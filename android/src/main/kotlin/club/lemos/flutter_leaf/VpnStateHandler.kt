package club.lemos.flutter_leaf

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

enum class VpnState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    DISCONNECTING,
    ERROR,
}

interface StateListener {

    fun stateChanged(state: VpnState)
}

object VpnStateHandler : EventChannel.StreamHandler, StateListener {

    private var eventSink: EventChannel.EventSink? = null

    var vpnState: VpnState = VpnState.DISCONNECTED

    private val handler = Handler(Looper.getMainLooper())

    override fun stateChanged(state: VpnState) {
        vpnState = state
        handler.post {
            eventSink?.success(state.ordinal)
        }
    }

    override fun onListen(p0: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }
}