package club.lemos.vpn.data;

import java.util.UUID;

public class VpnProfile {

    private UUID mUUID;
    private String configContent;

    private Integer mMTU;

    private String[] allowedApps;

    private String[] disallowedApps;

    public void setUUID(UUID uuid) {
        this.mUUID = uuid;
    }

    public UUID getUUID() {
        return mUUID;
    }

    public String getConfigContent() {
        return configContent;
    }

    public void setConfigContent(String configContent) {
        this.configContent = configContent;
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
