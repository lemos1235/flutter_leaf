package club.lemos.vpn.data;

import java.util.UUID;

public class VpnProfile {

    private UUID mUUID;
    private String proxy;

    private Integer mMTU;

    private String[] allowedApps;

    private String[] disallowedApps;

    public void setUUID(UUID uuid) {
        this.mUUID = uuid;
    }

    public UUID getUUID() {
        return mUUID;
    }

    public String getProxy() {
        return proxy;
    }

    public void setProxy(String proxy) {
        this.proxy = proxy;
    }

    public Integer getMTU() {
        return mMTU;
    }

    public void setMTU(Integer mtu) {
        this.mMTU = mtu;
    }

    public String[] getAllowedApps() {
        return allowedApps;
    }

    public void setAllowedApps(String[] allowedApps) {
        this.allowedApps = allowedApps;
    }

    public String[] getDisallowedApps() {
        return disallowedApps;
    }

    public void setDisallowedApps(String[] disallowedApps) {
        this.disallowedApps = disallowedApps;
    }
}
