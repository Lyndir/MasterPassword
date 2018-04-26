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

import com.google.common.base.Preconditions;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.masterpassword.*;
import java.util.Collection;
import java.util.Objects;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class MPUser<S extends MPSite> {

    @Nullable
    protected MPMasterKey key;

    public abstract String getFullName();

    public boolean isMasterKeyAvailable() {
        return key != null;
    }

    @Nonnull
    public MPMasterKey getMasterKey() {
        return Preconditions.checkNotNull( key, "User is not authenticated: " + getFullName() );
    }

    public String exportKeyID()
            throws MPInvalidatedException {
        return CodeUtils.encodeHex( getMasterKey().getKeyID( getAlgorithm() ) );
    }

    public abstract MPAlgorithm getAlgorithm();

    public int getAvatar() {
        return 0;
    }

    public abstract void addSite(S site);

    public abstract void deleteSite(S site);

    public abstract Collection<S> findSites(String query);

    @Nonnull
    public abstract MPMasterKey authenticate(char[] masterPassword)
            throws MPIncorrectMasterPasswordException;

    @Override
    public int hashCode() {
        return Objects.hashCode( getFullName() );
    }

    @Override
    public boolean equals(final Object obj) {
        return (this == obj) || ((obj instanceof MPUser) && Objects.equals( getFullName(), ((MPUser<?>) obj).getFullName() ));
    }

    @Override
    public String toString() {
        return strf( "{%s: %s}", getClass().getSimpleName(), getFullName() );
    }
}
