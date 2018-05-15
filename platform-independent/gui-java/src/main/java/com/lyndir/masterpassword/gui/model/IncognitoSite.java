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
import com.lyndir.masterpassword.model.*;
import com.lyndir.masterpassword.model.impl.MPBasicSite;
import java.util.Collection;


/**
 * @author lhunath, 14-12-16
 */
public class IncognitoSite extends MPBasicSite {

    private final IncognitoUser user;

    public IncognitoSite(final IncognitoUser user, final String siteName) {
        super( siteName, user.getAlgorithm() );

        this.user = user;
    }

    @Override
    public MPUser<? extends MPSite> getUser() {
        return user;
    }

    @Override
    public Collection<MPQuestion> getQuestions() {
        return ImmutableList.of();
    }
}
