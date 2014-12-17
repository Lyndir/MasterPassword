package com.lyndir.masterpassword.gui;

import com.lyndir.masterpassword.MPSiteType;


/**
 * @author lhunath, 14-12-16
 */
public class IncognitoSite extends Site {

    private String     siteName;
    private MPSiteType siteType;
    private int        siteCounter;

    public IncognitoSite(final String siteName, final MPSiteType siteType, final int siteCounter) {
        this.siteName = siteName;
        this.siteType = siteType;
        this.siteCounter = siteCounter;
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

    public int getSiteCounter() {
        return siteCounter;
    }

    public void setSiteCounter(final int siteCounter) {
        this.siteCounter = siteCounter;
    }
}
