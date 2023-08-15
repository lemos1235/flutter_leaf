package club.lemos.vpn.logic;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;

import androidx.annotation.Nullable;

import club.lemos.flutter_leaf.StateListener;
import club.lemos.flutter_leaf.VpnState;

public class VpnStateService extends Service {

    private static final String TAG = VpnStateService.class.getSimpleName();

    private final IBinder mBinder = new LocalBinder();

    private Bundle mProfileInfo;

    public StateListener stateListener;

    public VpnState vpnState;

    public void changeVpnState(VpnState vpnState) {
        this.vpnState = vpnState;
        this.stateListener.stateChanged(vpnState);
    }

    public void setStateListener(StateListener stateListener) {
        this.stateListener = stateListener;
    }

    public class LocalBinder extends Binder {
        // vpnStateServiceConnection.onServiceConnected, get current service
        public VpnStateService getService() {
            return VpnStateService.this;
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    public void connect(Bundle profileInfo) {
        if (!VpnState.CONNECTED.equals(vpnState)) {
            Context context = getApplicationContext();
            Intent intent = new Intent(context, LeafVpnService.class);
            if (profileInfo == null) {
                profileInfo = mProfileInfo;
            } else {
                mProfileInfo = profileInfo;
            }
            intent.putExtras(profileInfo);
            context.startService(intent);
        }
    }

    public void disconnect() {
        if (VpnState.CONNECTED.equals(vpnState)) {
            Context context = getApplicationContext();
            Intent intent = new Intent(context, LeafVpnService.class);
            intent.setAction(LeafVpnService.DISCONNECT_ACTION);
            context.startService(intent);
        }
    }

    public void switchProxy(String configContent) {
        if (VpnState.CONNECTED.equals(vpnState)) {
            Context context = getApplicationContext();
            Intent intent = new Intent(context, LeafVpnService.class);
            Bundle profileInfo = new Bundle(mProfileInfo);
            profileInfo.putString("configContent", configContent);
            mProfileInfo = profileInfo;
            intent.putExtras(mProfileInfo);
            intent.setAction(LeafVpnService.SWITCH_PROXY_ACTION);
            context.startService(intent);
        }
    }
}
