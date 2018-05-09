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

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.joda.time.Instant;
import org.joda.time.ReadableInstant;


/**
 * @author lhunath, 14-12-05
 */
public class MPFileSite extends MPSite {

    private final MPFileUser user;

    private String          siteName;
    @Nullable
    private String          siteState;
    private UnsignedInteger siteCounter;
    private MPResultType    resultType;
    private MPAlgorithm     algorithm;

    @Nullable
    private String       loginState;
    private MPResultType loginType;

    @Nullable
    private String          url;
    private int             uses;
    private ReadableInstant lastUsed;

    public MPFileSite(final MPFileUser user, final String siteName) {
        this( user, siteName, null, null, user.getAlgorithm() );
    }

    public MPFileSite(final MPFileUser user, final String siteName, @Nullable final UnsignedInteger siteCounter,
                      @Nullable final MPResultType resultType, final MPAlgorithm algorithm) {
        this( user, siteName, null, siteCounter, resultType, algorithm,
              null, null, null, 0, new Instant() );
    }

    protected MPFileSite(final MPFileUser user, final String siteName, @Nullable final String siteState,
                         @Nullable final UnsignedInteger siteCounter, @Nullable final MPResultType resultType, final MPAlgorithm algorithm,
                         @Nullable final String loginState, @Nullable final MPResultType loginType,
                         @Nullable final String url, final int uses, final ReadableInstant lastUsed) {
        this.user = user;
        this.siteName = siteName;
        this.siteState = siteState;
        this.siteCounter = ifNotNullElse( siteCounter, user.getAlgorithm().mpw_default_counter() );
        this.resultType = ifNotNullElse( resultType, user.getAlgorithm().mpw_default_password_type() );
        this.algorithm = algorithm;
        this.loginState = loginState;
        this.loginType = ifNotNullElse( loginType, getAlgorithm().mpw_default_login_type() );
        this.url = url;
        this.uses = uses;
        this.lastUsed = lastUsed;
    }

    public String getResult()
            throws MPKeyUnavailableException {

        return getResult( MPKeyPurpose.Authentication, null );
    }

    public String getResult(final MPKeyPurpose keyPurpose, @Nullable final String keyContext)
            throws MPKeyUnavailableException {

        return getResult( keyPurpose, keyContext, siteState );
    }

    public String getLogin()
            throws MPKeyUnavailableException {

        return getLogin( loginState );
    }

    @Override
    public MPUser<?> getUser() {
        return user;
    }

    @Override
    public String getSiteName() {
        return siteName;
    }

    @Override
    public void setSiteName(final String siteName) {
        this.siteName = siteName;
    }

    @Nullable
    public String getSiteState() {
        return siteState;
    }

    public void setSitePassword(final MPResultType resultType, @Nullable final String result)
            throws MPKeyUnavailableException {
        this.resultType = resultType;

        if (result == null)
            this.siteState = null;
        else
            this.siteState = user.getMasterKey().siteState(
                    siteName, siteCounter, MPKeyPurpose.Authentication, null, resultType, result, algorithm );
    }

    @Override
    public UnsignedInteger getSiteCounter() {
        return siteCounter;
    }

    @Override
    public void setSiteCounter(final UnsignedInteger siteCounter) {
        this.siteCounter = siteCounter;
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
    public MPResultType getLoginType() {
        return loginType;
    }

    @Override
    public void setLoginType(@Nullable final MPResultType loginType) {
        this.loginType = ifNotNullElse( loginType, getAlgorithm().mpw_default_login_type() );

    }

    @Override
    public MPAlgorithm getAlgorithm() {
        return algorithm;
    }

    @Override
    public void setAlgorithm(final MPAlgorithm algorithm) {
        this.algorithm = algorithm;
    }

    @Nullable
    public String getLoginState() {
        return loginState;
    }

    public void setLoginName(@Nonnull final MPResultType loginType, @Nonnull final String loginName)
            throws MPKeyUnavailableException {
        this.loginType = loginType;
        this.loginState = user.getMasterKey().siteState(
                siteName, algorithm.mpw_default_counter(), MPKeyPurpose.Identification, null,
                this.loginType, loginName, algorithm );
    }

    @Nullable
    public String getUrl() {
        return url;
    }

    public void setUrl(@Nullable final String url) {
        this.url = url;
    }

    public int getUses() {
        return uses;
    }

    public ReadableInstant getLastUsed() {
        return lastUsed;
    }

    public void use() {
        uses++;
        lastUsed = new Instant();
        user.use();
    }
}
