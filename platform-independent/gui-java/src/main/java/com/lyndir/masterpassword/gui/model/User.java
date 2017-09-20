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

import com.google.common.base.Preconditions;
import com.lyndir.masterpassword.MasterKey;
import com.lyndir.masterpassword.model.IncorrectMasterPasswordException;
import java.util.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-06-08
 */
public abstract class User {

    @Nullable
    protected MasterKey key;

    public abstract String getFullName();

    @SuppressWarnings("MethodCanBeVariableArityMethod")
    public abstract void authenticate(char[] masterPassword)
            throws IncorrectMasterPasswordException;

    public int getAvatar() {
        return 0;
    }

    public boolean isKeyAvailable() {
        return key != null;
    }

    @Nonnull
    public MasterKey getKey() {
        return Preconditions.checkNotNull( key, "User is not authenticated: " + getFullName() );
    }

    public abstract Iterable<Site> findSitesByName(String siteName);

    public abstract void addSite(Site site);

    public abstract void deleteSite(Site site);

    @Override
    public boolean equals(final Object obj) {
        return (this == obj) || ((obj instanceof User) && Objects.equals( getFullName(), ((User) obj).getFullName() ));
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getFullName() );
    }

    @Override
    public String toString() {
        return getFullName();
    }
}
