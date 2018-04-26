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
import com.lyndir.masterpassword.MPAlgorithm;
import com.lyndir.masterpassword.MPMasterKey;
import com.lyndir.masterpassword.model.MPIncorrectMasterPasswordException;
import com.lyndir.masterpassword.model.MPUser;
import java.util.Collection;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 2014-06-08
 */
public class IncognitoUser extends MPUser<IncognitoSite> {

    private final String fullName;

    public IncognitoUser(final String fullName) {
        this.fullName = fullName;
    }

    @Override
    public String getFullName() {
        return fullName;
    }

    @Override
    public MPAlgorithm getAlgorithm() {
        return MPMasterKey.Version.CURRENT.getAlgorithm();
    }

    @Override
    public void addSite(final IncognitoSite site) {
    }

    @Override
    public void deleteSite(final IncognitoSite site) {
    }

    @Override
    public Collection<IncognitoSite> findSites(final String query) {
        return ImmutableList.of();
    }

    @Nonnull
    @Override
    public MPMasterKey authenticate(final char[] masterPassword)
            throws MPIncorrectMasterPasswordException {
        return key = new MPMasterKey( getFullName(), masterPassword );
    }
}
