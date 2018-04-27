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

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.*;
import javax.annotation.Nullable;
import org.joda.time.Instant;


/**
 * @author lhunath, 14-12-05
 */
public class MPFileSite extends MPSite {

    private final MPFileUser      user;
    private       String          siteName;
    @Nullable
    private       String          siteContent;
    private       UnsignedInteger siteCounter;
    private       MPResultType    resultType;
    private       MPAlgorithm     algorithm;

    @Nullable
    private String       loginContent;
    @Nullable
    private MPResultType loginType;

    @Nullable
    private String  url;
    private int     uses;
    private Instant lastUsed;

    public MPFileSite(final MPFileUser user, final String siteName) {
        this( user, siteName,
              user.getAlgorithm().mpw_default_counter(),
              user.getAlgorithm().mpw_default_type(),
              user.getAlgorithm() );
    }

    public MPFileSite(final MPFileUser user, final String siteName, final UnsignedInteger siteCounter, final MPResultType resultType,
                      final MPAlgorithm algorithm) {
        this.user = user;
        this.siteName = siteName;
        this.siteCounter = siteCounter;
        this.resultType = resultType;
        this.algorithm = algorithm;
        this.lastUsed = new Instant();
    }

    protected MPFileSite(final MPFileUser user, final String siteName, @Nullable final String siteContent,
                         final UnsignedInteger siteCounter,
                         final MPResultType resultType, final MPAlgorithm algorithm,
                         @Nullable final String loginContent, @Nullable final MPResultType loginType,
                         @Nullable final String url, final int uses, final Instant lastUsed) {
        this.user = user;
        this.siteName = siteName;
        this.siteContent = siteContent;
        this.siteCounter = siteCounter;
        this.resultType = resultType;
        this.algorithm = algorithm;
        this.loginContent = loginContent;
        this.loginType = loginType;
        this.url = url;
        this.uses = uses;
        this.lastUsed = lastUsed;
    }

    public String resultFor(final MPMasterKey masterKey)
            throws MPInvalidatedException {

        return resultFor( masterKey, MPKeyPurpose.Authentication, null );
    }

    public String resultFor(final MPMasterKey masterKey, final MPKeyPurpose keyPurpose, @Nullable final String keyContext)
            throws MPInvalidatedException {

        return resultFor( masterKey, keyPurpose, keyContext, getSiteContent() );
    }

    public String loginFor(final MPMasterKey masterKey)
            throws MPInvalidatedException {

        if (loginType == null)
            loginType = MPResultType.GeneratedName;

        return loginFor( masterKey, loginType, loginContent );
    }

    public MPFileUser getUser() {
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
    public String getSiteContent() {
        return siteContent;
    }

    public void setSitePassword(final MPMasterKey masterKey, final MPResultType resultType, @Nullable final String result)
            throws MPInvalidatedException {
        this.resultType = resultType;

        if (result == null)
            this.siteContent = null;
        else
            this.siteContent = masterKey.siteState(
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
    public MPAlgorithm getAlgorithm() {
        return algorithm;
    }

    @Override
    public void setAlgorithm(final MPAlgorithm algorithm) {
        this.algorithm = algorithm;
    }

    @Nullable
    public MPResultType getLoginType() {
        return loginType;
    }

    @Nullable
    public String getLoginContent() {
        return loginContent;
    }

    public void setLoginName(final MPMasterKey masterKey, @Nullable final MPResultType loginType, @Nullable final String result)
            throws MPInvalidatedException {
        this.loginType = loginType;
        if (this.loginType != null)
            if (result == null)
                this.loginContent = null;
            else
                this.loginContent = masterKey.siteState(
                        siteName, algorithm.mpw_default_counter(), MPKeyPurpose.Identification, null, this.loginType, result,
                        algorithm );
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

    public Instant getLastUsed() {
        return lastUsed;
    }

    public void use() {
        uses++;
        lastUsed = new Instant();
        user.use();
    }
}
