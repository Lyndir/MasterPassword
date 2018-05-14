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

package com.lyndir.masterpassword.gui.model;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.ifNotNullElse;

import com.google.common.collect.ImmutableCollection;
import com.google.common.collect.ImmutableList;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.MPAlgorithm;
import com.lyndir.masterpassword.MPResultType;
import com.lyndir.masterpassword.model.*;
import java.util.Collection;
import javax.annotation.Nullable;


/**
 * @author lhunath, 14-12-16
 */
public class IncognitoSite extends MPSite {

    private final IncognitoUser user;

    private String          siteName;
    private UnsignedInteger siteCounter;
    private MPResultType    resultType;
    private MPResultType loginType;
    private MPAlgorithm     algorithm;

    public IncognitoSite(final IncognitoUser user, final String siteName, final UnsignedInteger siteCounter, final MPResultType resultType,
                         final MPAlgorithm algorithm) {
        this.user = user;
        this.siteName = siteName;
        this.siteCounter = siteCounter;
        this.resultType = resultType;
        this.algorithm = algorithm;
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

    @Override
    public Collection<MPQuestion> getQuestions() {
        return ImmutableList.of();
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
