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

package com.lyndir.masterpassword.model.impl;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import org.joda.time.Instant;
import org.joda.time.ReadableInstant;


/**
 * @author lhunath, 14-12-05
 */
public class MPFileSite extends MPBasicSite<MPFileQuestion> {

    private final MPFileUser user;

    @Nullable
    private String          url;
    private int             uses;
    private ReadableInstant lastUsed;

    @Nullable
    private String resultState;
    @Nullable
    private String loginState;

    public MPFileSite(final MPFileUser user, final String name) {
        this( user, name, null, null, null );
    }

    public MPFileSite(final MPFileUser user, final String name,
                      @Nullable final MPAlgorithm algorithm, @Nullable final UnsignedInteger counter,
                      @Nullable final MPResultType resultType) {
        this( user, name, algorithm, counter, resultType, null,
              null, null, null, 0, new Instant() );
    }

    protected MPFileSite(final MPFileUser user, final String name,
                         @Nullable final MPAlgorithm algorithm, @Nullable final UnsignedInteger counter,
                         @Nullable final MPResultType resultType, @Nullable final String resultState,
                         @Nullable final MPResultType loginType, @Nullable final String loginState,
                         @Nullable final String url, final int uses, final ReadableInstant lastUsed) {
        super( name, (algorithm == null)? user.getAlgorithm(): algorithm, counter,
               (resultType == null)? user.getDefaultType(): resultType, loginType );

        this.user = user;
        this.resultState = resultState;
        this.loginState = loginState;
        this.url = url;
        this.uses = uses;
        this.lastUsed = lastUsed;
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

    public String getResult()
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getResult( MPKeyPurpose.Authentication, null );
    }

    public String getResult(final MPKeyPurpose keyPurpose, @Nullable final String keyContext)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getResult( keyPurpose, keyContext, getResultState() );
    }

    public String getLogin()
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getLogin( getLoginState() );
    }

    @Nullable
    public String getResultState() {
        return resultState;
    }

    public void setSitePassword(final MPResultType resultType, @Nullable final String password)
            throws MPKeyUnavailableException, MPAlgorithmException {
        setResultType( resultType );

        if (password == null)
            this.resultState = null;
        else
            this.resultState = getState(
                    MPKeyPurpose.Authentication, null, getCounter(), getResultType(), password );
    }

    @Nullable
    public String getLoginState() {
        return loginState;
    }

    public void setLoginName(@Nonnull final MPResultType loginType, @Nullable final String loginName)
            throws MPKeyUnavailableException, MPAlgorithmException {
        setLoginType( loginType );

        if (loginName == null)
            this.loginState = null;
        else
            this.loginState = getState(
                    MPKeyPurpose.Identification, null, null, getLoginType(), loginName );
    }

    @Override
    public MPFileUser getUser() {
        return user;
    }
}
