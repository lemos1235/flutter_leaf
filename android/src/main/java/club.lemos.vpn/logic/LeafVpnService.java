package club.lemos.vpn.logic;

import android.app.Service;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.net.VpnService;
import android.os.Bundle;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.UUID;

import club.lemos.vpn.data.VpnProfile;
import club.lemos.flutter_leaf.VpnState;

public class LeafVpnService extends VpnService {

    private static final String TAG = LeafVpnService.class.getSimpleName();

    public static final String DISCONNECT_ACTION = "club.lemos.vpn.logic.LeafVpnService.DISCONNECT";

    public static final String SWITCH_PROXY_ACTION = "club.lemos.vpn.logic.LeafVpnService.SWITCH_PROXY";

    private static final String ADDRESS = "10.255.0.1";

    private static final String ROUTE = "0.0.0.0";
    private static final String DNS = "1.1.1.1";

    public static final String confTemplate = "" +
            "[General]\n" +
            "loglevel = info\n" +
            "dns-server = 223.5.5.5\n" +
            "tun-fd = TUN-FD\n" +
            "[Proxy]\n" +
            "Direct = direct\n" +
            "SOCKS5 = SOCKS_PROXY\n" +
            "[Rule]\n" +
            "FINAL, SOCKS5\n";

    private ParcelFileDescriptor tun;

    private Integer mfd;

    private VpnProfile mProfile;

    private Thread mConnectionHandler;

    private VpnStateService mService;

    private final Object mServiceLock = new Object();

    public final native void runLeaf(String configPath);

    public final native void stopLeaf();

    public final native void reloadLeaf();

    public LeafVpnService() {
        System.loadLibrary("leafandroid");
    }

    private final ServiceConnection mServiceConnection = new ServiceConnection() {

        @Override
        public void onServiceDisconnected(ComponentName name) {    /* since the service is local this is theoretically only called when the process is terminated */
            Log.i(TAG, "onServiceDisconnected");
            stopVpn();
            synchronized (mServiceLock) {
                mService = null;
            }
        }

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            Log.i(TAG, "onServiceConnected");
            synchronized (mServiceLock) {
                mService = ((VpnStateService.LocalBinder) service).getService();
                startVpn();
            }
        }
    };

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "onStartCommand");
        if (intent != null) {
            if (DISCONNECT_ACTION.equals(intent.getAction())) {
                mProfile = null;
                stopVpn();
            } else if (SWITCH_PROXY_ACTION.equals(intent.getAction())) {
                Bundle bundle = intent.getExtras();
                String proxy = bundle.getString("PROXY");
                mProfile.setProxy(decodeProxyUrl(proxy));
                switchProxy();
            } else {
                Bundle bundle = intent.getExtras();
                VpnProfile profile = new VpnProfile();
                profile.setUUID(UUID.randomUUID());
                String proxy = bundle.getString("PROXY");
                profile.setProxy(decodeProxyUrl(proxy));
                profile.setMTU(bundle.getInt("MTU", 1500));
                if (bundle.containsKey("allowedApps")) {
                    profile.setAllowedApps(bundle.getString("allowedApps").split(","));
                }
                if (bundle.containsKey("disallowedApps")) {
                    profile.setDisallowedApps(bundle.getString("disallowedApps").split(","));
                }
                mProfile = profile;
                synchronized (mServiceLock) {
                    if (mService != null) {
                        startVpn();
                    }
                }
            }
        }
        return START_NOT_STICKY;
    }

    private String decodeProxyUrl(String uriString) {
        try {
            URI uri = new URI(uriString);
            String schema = uri.getScheme();
            String host = uri.getHost();
            int port = uri.getPort();
            StringBuilder sb = new StringBuilder();
            sb.append(schema);
            sb.append(",");
            sb.append(host);
            sb.append(",");
            sb.append(port);
            sb.append(",");
            String userInfo = uri.getUserInfo();
            if (userInfo != null && !userInfo.isEmpty()) {
                String[] credentials = userInfo.split(":");
                String username = credentials[0];
                sb.append("username=");
                sb.append(username);
                if (credentials.length > 1) {
                    String password = credentials[1];
                    sb.append(",");
                    sb.append("password=");
                    sb.append(password);
                }
            }
            return sb.toString();
        } catch (URISyntaxException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "onCreate");
        bindService(new Intent(this, VpnStateService.class),
                mServiceConnection, Service.BIND_AUTO_CREATE);
    }

    @Override
    public void onRevoke() {
        stopVpn();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        unbindService(mServiceConnection);
    }

    public void setState(VpnState state) {
        synchronized (mServiceLock) {
            if (mService != null) {
                mService.changeVpnState(state);
            }
        }
    }

    public void startVpn() {
        Log.i(TAG, "startVpn");
        setState(VpnState.CONNECTING);
        if (tun == null) {
            try {
                Builder builder = new Builder()
                        .setMtu(mProfile.getMTU())
                        .addAddress(ADDRESS, 30)
                        .addRoute(ROUTE, 0)
                        .addDnsServer(DNS);
                if (mProfile.getAllowedApps() != null) {
                    for (String appPackage : mProfile.getAllowedApps()) {
                        if (!appPackage.equals(this.getApplication().getPackageName())) {
                            builder.addAllowedApplication(appPackage);
                        }
                    }
                } else {
                    builder.addDisallowedApplication(this.getApplication().getPackageName());
                    if (mProfile.getDisallowedApps() != null) {
                        for (String appPackage : mProfile.getDisallowedApps()) {
                            builder.addDisallowedApplication(appPackage);
                        }
                    }
                }
                tun = builder.establish();
            } catch (PackageManager.NameNotFoundException e) {
                throw new RuntimeException(e);
            }
        }
        startProxy();
    }

    public void stopVpn() {
        setState(VpnState.DISCONNECTING);
        try {
            stopProxy();
            if (tun != null) {
                tun.close();
                tun = null;
            }
            Log.i(TAG, "VPN is stopped");
            setState(VpnState.DISCONNECTED);
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
            e.printStackTrace();
            setState(VpnState.ERROR);
        }
    }

    private void startProxy() {
        try {
            if (mProfile != null) {
                mConnectionHandler = new Thread(() -> {
                    File configFile = new File(this.getFilesDir(), "config.conf");
                    mfd = tun.detachFd();
                    String configContent =
                            confTemplate.replace("TUN-FD",
                                            String.valueOf(mfd))
                                    .replace("SOCKS_PROXY",
                                            mProfile.getProxy());
                    Log.i(TAG, "config content" + configContent);
                    try (FileOutputStream fos = new FileOutputStream(configFile)) {
                        fos.write(configContent.getBytes());
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                    runLeaf(configFile.getAbsolutePath());
                });
                mConnectionHandler.start();
                mConnectionHandler.setUncaughtExceptionHandler((t, e) -> {
                    System.out.println(t.getName() + "has error :" + e.getMessage());
                });
                Log.i(TAG, "VPN is started");
                setState(VpnState.CONNECTED);
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
            e.printStackTrace();
            setState(VpnState.ERROR);
        }
    }

    private void switchProxy() {
        File configFile = new File(this.getFilesDir(), "config.conf");
        String configContent =
                confTemplate.replace("TUN-FD",
                                String.valueOf(mfd))
                        .replace("SOCKS_PROXY", mProfile.getProxy());
        Log.i(TAG, "config content" + configContent);
        try (FileOutputStream fos = new FileOutputStream(configFile)) {
            fos.write(configContent.getBytes());
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        reloadLeaf();
    }

    private void stopProxy() throws InterruptedException {
        stopLeaf();
        mConnectionHandler.join();
    }

}
