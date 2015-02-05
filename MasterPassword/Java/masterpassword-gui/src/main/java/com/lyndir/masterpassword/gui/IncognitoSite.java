package com.lyndir.masterpassword.gui;

import com.lyndir.masterpassword.MPSiteType;
import com.lyndir.masterpassword.MasterKey;


/**
 * @author lhunath, 14-12-16
 */
public class IncognitoSite extends Site {

    private String            siteName;
    private MPSiteType        siteType;
    private int               siteCounter;
    private MasterKey.Version algorithmVersion;

    public IncognitoSite(final String siteName, final MPSiteType siteType, final int siteCounter,
                         final MasterKey.Version algorithmVersion) {
        this.siteName = siteName;
        this.siteType = siteType;
        this.siteCounter = siteCounter;
        this.algorithmVersion = algorithmVersion;
    }

    public String getSiteName() {
        return siteName;
    }

    public void setSiteName(final String siteName) {
        this.siteName = siteName;
    }

    public MPSiteType getSiteType() {
        return siteType;
    }

    public void setSiteType(final MPSiteType siteType) {
        this.siteType = siteType;
    }

    @Override
    public MasterKey.Version getAlgorithmVersion() {
        return algorithmVersion;
    }

    @Override
    public void setAlgorithmVersion(final MasterKey.Version algorithmVersion) {
        this.algorithmVersion = algorithmVersion;
    }

    public int getSiteCounter() {
        return siteCounter;
    }

    public void setSiteCounter(final int siteCounter) {
        this.siteCounter = siteCounter;
    }
}
