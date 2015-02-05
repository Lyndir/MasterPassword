package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.lyndir.masterpassword.MPSiteType;
import com.lyndir.masterpassword.MasterKey;


/**
 * @author lhunath, 14-12-16
 */
public abstract class Site {

    public abstract String getSiteName();

    public abstract void setSiteName(final String siteName);

    public abstract MPSiteType getSiteType();

    public abstract void setSiteType(final MPSiteType siteType);

    public abstract MasterKey.Version getAlgorithmVersion();

    public abstract void setAlgorithmVersion(final MasterKey.Version algorithmVersion);

    public abstract int getSiteCounter();

    public abstract void setSiteCounter(final int siteCounter);

    @Override
    public String toString() {
        return strf( "{%s: %s}", getClass().getSimpleName(), getSiteName() );
    }
}
