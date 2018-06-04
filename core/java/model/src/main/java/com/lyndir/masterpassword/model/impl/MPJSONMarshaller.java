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

import static com.lyndir.masterpassword.model.impl.MPJSONFile.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.lyndir.masterpassword.MPAlgorithmException;
import com.lyndir.masterpassword.MPKeyUnavailableException;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 2017-09-20
 */
public class MPJSONMarshaller implements MPMarshaller {

    @Nonnull
    @Override
    public String marshall(final MPFileUser user)
            throws MPKeyUnavailableException, MPMarshalException, MPAlgorithmException {

        try {
            return objectMapper.writeValueAsString( user.getJSON().write( user ) );
        }
        catch (final JsonProcessingException e) {
            throw new MPMarshalException( "Couldn't compose JSON for: " + user, e );
        }
    }
}
