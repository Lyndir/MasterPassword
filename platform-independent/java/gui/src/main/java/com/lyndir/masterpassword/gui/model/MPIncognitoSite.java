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

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.MPAlgorithm;
import com.lyndir.masterpassword.MPResultType;
import com.lyndir.masterpassword.model.impl.MPBasicSite;
import javax.annotation.Nullable;


/**
 * @author lhunath, 14-12-16
 */
public class MPIncognitoSite extends MPBasicSite<MPIncognitoQuestion> {

    private final MPIncognitoUser user;

    public MPIncognitoSite(final MPIncognitoUser user, final String name) {
        this( user, name, null, null, null, null );
    }

    public MPIncognitoSite(final MPIncognitoUser user, final String name,
                           @Nullable final MPAlgorithm algorithm, @Nullable final UnsignedInteger counter,
                           @Nullable final MPResultType resultType, @Nullable final MPResultType loginType) {
        super( name, (algorithm == null)? user.getAlgorithm(): algorithm, counter, resultType, loginType );

        this.user = user;
    }

    @Override
    public MPIncognitoUser getUser() {
        return user;
    }
}
