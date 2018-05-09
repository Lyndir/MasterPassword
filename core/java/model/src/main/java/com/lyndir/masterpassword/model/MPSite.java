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

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.*;
import java.util.Objects;
import javax.annotation.Nullable;


/**
 * @author lhunath, 14-12-16
 */
public abstract class MPSite {

    public abstract MPUser<?> getUser();

    public abstract String getSiteName();

    public abstract void setSiteName(String siteName);

    public abstract UnsignedInteger getSiteCounter();

    public abstract void setSiteCounter(UnsignedInteger siteCounter);

    public abstract MPResultType getResultType();

    public abstract void setResultType(MPResultType resultType);

    public abstract MPResultType getLoginType();

    public abstract void setLoginType(@Nullable MPResultType loginType);

    public abstract MPAlgorithm getAlgorithm();

    public abstract void setAlgorithm(MPAlgorithm algorithm);

    public String getResult(final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                            @Nullable final String siteContent)
            throws MPKeyUnavailableException {

        return getUser().getMasterKey().siteResult(
                getSiteName(), getSiteCounter(), keyPurpose, keyContext, getResultType(), siteContent, getAlgorithm() );
    }

    public String getLogin(@Nullable final String loginContent)
            throws MPKeyUnavailableException {

        return getUser().getMasterKey().siteResult(
                getSiteName(), getAlgorithm().mpw_default_counter(), MPKeyPurpose.Identification, null,
                getLoginType(), loginContent, getAlgorithm() );
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
        return strf( "{%s: %s}", getClass().getSimpleName(), getSiteName() );
    }
}
