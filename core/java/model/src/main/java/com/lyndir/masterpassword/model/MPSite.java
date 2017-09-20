//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

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

    public static final UnsignedInteger DEFAULT_COUNTER = UnsignedInteger.ONE;

    private final MPUser            user;
    private       String            siteName;
    @Nullable
    private       String            siteContent;
    private       UnsignedInteger   siteCounter;
    private       MPResultType      resultType;
    private       MasterKey.Version algorithmVersion;

    @Nullable
    private String       loginContent;
    @Nullable
    private MPResultType loginType;

    @Nullable
    private String  url;
    private int     uses;
    private Instant lastUsed;

    public MPSite(final MPUser user, final String siteName) {
        this( user, siteName, DEFAULT_COUNTER, MPResultType.DEFAULT );
    }

    public MPSite(final MPUser user, final String siteName, final UnsignedInteger siteCounter, final MPResultType resultType) {
        this.user = user;
        this.siteName = siteName;
        this.siteCounter = siteCounter;
        this.resultType = resultType;
        this.algorithmVersion = MasterKey.Version.CURRENT;
        this.lastUsed = new Instant();
    }

    protected MPSite(final MPUser user, final String siteName, @Nullable final String siteContent, final UnsignedInteger siteCounter,
                     final MPResultType resultType, final MasterKey.Version algorithmVersion,
                     @Nullable final String loginContent, @Nullable final MPResultType loginType,
                     @Nullable final String url, final int uses, final Instant lastUsed) {
        this.user = user;
        this.siteName = siteName;
        this.siteContent = siteContent;
        this.siteCounter = siteCounter;
        this.resultType = resultType;
        this.algorithmVersion = algorithmVersion;
        this.loginContent = loginContent;
        this.loginType = loginType;
        this.url = url;
        this.uses = uses;
        this.lastUsed = lastUsed;
    }

    public String resultFor(final MasterKey masterKey) {
        return resultFor( masterKey, MPKeyPurpose.Authentication, null );
    }

    public String resultFor(final MasterKey masterKey, final MPKeyPurpose purpose, @Nullable final String context) {
        return masterKey.siteResult( siteName, siteCounter, purpose, context, resultType, siteContent, algorithmVersion );
    }

    public String loginFor(final MasterKey masterKey) {
        if (loginType == null)
            loginType = MPResultType.GeneratedName;

        return masterKey.siteResult( siteName, DEFAULT_COUNTER, MPKeyPurpose.Identification, null, loginType, loginContent,
                                     algorithmVersion );
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

    @Nullable
    public String getSiteContent() {
        return siteContent;
    }

    public MPResultType getResultType() {
        return resultType;
    }

    public void setResultType(final MPResultType resultType) {
        this.resultType = resultType;
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

    @Nullable
    public MPResultType getLoginType() {
        return loginType;
    }

    @Nullable
    public String getLoginContent() {
        return loginContent;
    }

    public void setLoginName(final MasterKey masterKey, @Nullable final MPResultType loginType, @Nullable final String result) {
        this.loginType = loginType;
        if (this.loginType != null)
            if (result == null)
                this.loginContent = null;
            else
                this.loginContent = masterKey.siteState(
                        siteName, DEFAULT_COUNTER, MPKeyPurpose.Identification, null, this.loginType, result, algorithmVersion );
    }

    @Nullable
    public String getUrl() {
        return url;
    }

    public void setUrl(@Nullable final String url) {
        this.url = url;
    }

    @Override
    public boolean equals(final Object obj) {
        return (this == obj) || ((obj instanceof MPSite) && Objects.equals( getSiteName(), ((MPSite) obj).getSiteName() ));
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getSiteName() );
    }

    @Override
    public String toString() {
        return strf( "{MPSite: %s}", getSiteName() );
    }
}
