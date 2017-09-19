package com.lyndir.masterpassword.gui.model;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.MPResultType;
import com.lyndir.masterpassword.MasterKey;


/**
 * @author lhunath, 14-12-16
 */
public class IncognitoSite extends Site {

    private String            siteName;
    private UnsignedInteger   siteCounter;
    private MPResultType      resultType;
    private MasterKey.Version algorithmVersion;

    public IncognitoSite(final String siteName, final UnsignedInteger siteCounter, final MPResultType resultType,
                         final MasterKey.Version algorithmVersion) {
        this.siteName = siteName;
        this.siteCounter = siteCounter;
        this.resultType = resultType;
        this.algorithmVersion = algorithmVersion;
    }

    @Override
    public String getSiteName() {
        return siteName;
    }

    @Override
    public void setSiteName(final String siteName) {
        this.siteName = siteName;
    }

    @Override
    public MPResultType getResultType() {
        return resultType;
    }

    @Override
    public void setResultType(final MPResultType resultType) {
        this.resultType = resultType;
    }

    @Override
    public MasterKey.Version getAlgorithmVersion() {
        return algorithmVersion;
    }

    @Override
    public void setAlgorithmVersion(final MasterKey.Version algorithmVersion) {
        this.algorithmVersion = algorithmVersion;
    }

    @Override
    public UnsignedInteger getSiteCounter() {
        return siteCounter;
    }

    @Override
    public void setSiteCounter(final UnsignedInteger siteCounter) {
        this.siteCounter = siteCounter;
    }
}
