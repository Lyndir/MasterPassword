package com.lyndir.masterpassword.gui.model;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.MPResultType;
import com.lyndir.masterpassword.MasterKey;


/**
 * @author lhunath, 14-12-16
 */
public abstract class Site {

    public abstract String getSiteName();

    public abstract void setSiteName(String siteName);

    public abstract MPResultType getResultType();

    public abstract void setResultType(MPResultType resultType);

    public abstract MasterKey.Version getAlgorithmVersion();

    public abstract void setAlgorithmVersion(MasterKey.Version algorithmVersion);

    public abstract UnsignedInteger getSiteCounter();

    public abstract void setSiteCounter(UnsignedInteger siteCounter);

    @Override
    public String toString() {
        return strf( "{%s: %s}", getClass().getSimpleName(), getSiteName() );
    }
}
