package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.ifNotNullElse;
import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.lyndir.masterpassword.*;
import javax.annotation.Nullable;
import org.joda.time.DateTime;
import org.joda.time.Instant;


/**
 * @author lhunath, 14-12-05
 */
public class MPSite {

    public static final MPSiteType DEFAULT_TYPE    = MPSiteType.GeneratedLong;
    public static final int        DEFAULT_COUNTER = 1;

    private int        mpVersion;
    private Instant    lastUsed;
    private String     siteName;
    private MPSiteType siteType;
    private int        siteCounter;
    private int        uses;
    private String     loginName;

    public MPSite(final String siteName) {
        this( siteName, DEFAULT_TYPE, DEFAULT_COUNTER );
    }

    public MPSite(final String siteName, final MPSiteType siteType, final int siteCounter) {
        this.mpVersion = MasterKey.ALGORITHM;
        this.lastUsed = new Instant();
        this.siteName = siteName;
        this.siteType = siteType;
        this.siteCounter = siteCounter;
    }

    protected MPSite(final int mpVersion, final Instant lastUsed, final String siteName, final MPSiteType siteType, final int siteCounter,
                  final int uses, final String loginName, final String importContent) {
        this.mpVersion = mpVersion;
        this.lastUsed = lastUsed;
        this.siteName = siteName;
        this.siteType = siteType;
        this.siteCounter = siteCounter;
        this.uses = uses;
        this.loginName = loginName;
    }

    public String resultFor(final MasterKey masterKey) {
        return resultFor( masterKey, MPSiteVariant.Password, null );
    }

    public String resultFor(final MasterKey masterKey, final MPSiteVariant variant, final String context) {
        return masterKey.encode( siteName, siteType, siteCounter, variant, context );
    }

    @Nullable
    protected String exportContent() {
        return null;
    }

    public int getMPVersion() {
        return mpVersion;
    }

    public void setMPVersion(final int mpVersion) {
        this.mpVersion = mpVersion;
    }

    public Instant getLastUsed() {
        return lastUsed;
    }

    public void setLastUsed(final Instant lastUsed) {
        this.lastUsed = lastUsed;
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

    public int getUses() {
        return uses;
    }

    public void setUses(final int uses) {
        this.uses = uses;
    }

    public String getLoginName() {
        return loginName;
    }

    public void setLoginName(final String loginName) {
        this.loginName = loginName;
    }
}
