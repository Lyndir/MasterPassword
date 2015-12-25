package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.*;
import java.util.Objects;
import javax.annotation.Nullable;
import org.joda.time.Instant;


/**
 * @author lhunath, 14-12-05
 */
public class MPSite {

    public static final MPSiteType      DEFAULT_TYPE    = MPSiteType.GeneratedLong;
    public static final UnsignedInteger DEFAULT_COUNTER = UnsignedInteger.valueOf( 1 );

    private final MPUser            user;
    private       MasterKey.Version algorithmVersion;
    private       Instant           lastUsed;
    private       String            siteName;
    private       MPSiteType        siteType;
    private       UnsignedInteger   siteCounter;
    private       int               uses;
    private       String            loginName;

    public MPSite(final MPUser user, final String siteName) {
        this( user, siteName, DEFAULT_TYPE, DEFAULT_COUNTER );
    }

    public MPSite(final MPUser user, final String siteName, final MPSiteType siteType, final UnsignedInteger siteCounter) {
        this.user = user;
        this.algorithmVersion = MasterKey.Version.CURRENT;
        this.lastUsed = new Instant();
        this.siteName = siteName;
        this.siteType = siteType;
        this.siteCounter = siteCounter;
    }

    protected MPSite(final MPUser user, final MasterKey.Version algorithmVersion, final Instant lastUsed, final String siteName,
                     final MPSiteType siteType, final UnsignedInteger siteCounter, final int uses, @Nullable final String loginName,
                     @Nullable final String importContent) {
        this.user = user;
        this.algorithmVersion = algorithmVersion;
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

    public String resultFor(final MasterKey masterKey, final MPSiteVariant variant, @Nullable final String context) {
        return masterKey.encode( siteName, siteType, siteCounter, variant, context );
    }

    public MPUser getUser() {
        return user;
    }

    @Nullable
    protected String exportContent() {
        return null;
    }

    public MasterKey.Version getAlgorithmVersion() {
        return algorithmVersion;
    }

    public void setAlgorithmVersion(final MasterKey.Version mpVersion) {
        this.algorithmVersion = mpVersion;
    }

    public Instant getLastUsed() {
        return lastUsed;
    }

    public void updateLastUsed() {
        lastUsed = new Instant();
        user.updateLastUsed();
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

    public UnsignedInteger getSiteCounter() {
        return siteCounter;
    }

    public void setSiteCounter(final UnsignedInteger siteCounter) {
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

    @Override
    public boolean equals(final Object obj) {
        return this == obj || obj instanceof MPSite && Objects.equals( siteName, ((MPSite) obj).siteName );
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( siteName );
    }

    @Override
    public String toString() {
        return strf( "{MPSite: %s}", siteName );
    }
}
