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

import com.google.common.collect.ImmutableList;
import com.lyndir.masterpassword.MasterKey;
import com.lyndir.masterpassword.model.IncorrectMasterPasswordException;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2014-06-08
 */
public class IncognitoUser extends User {

    private final String fullName;

    public IncognitoUser(final String fullName) {
        this.fullName = fullName;
    }

    @Override
    public String getFullName() {
        return fullName;
    }

    @Override
    public void authenticate(final char[] masterPassword)
            throws IncorrectMasterPasswordException {
        this.key = new MasterKey( getFullName(), masterPassword );
    }

    @Override
    public Iterable<Site> findSitesByName(final String siteName) {
        return ImmutableList.of();
    }

    @Override
    public void addSite(final Site site) {
    }

    @Override
    public void deleteSite(final Site site) {
    }
}
