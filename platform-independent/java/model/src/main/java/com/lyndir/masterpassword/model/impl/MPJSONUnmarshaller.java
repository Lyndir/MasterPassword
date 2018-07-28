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

import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.lyndir.masterpassword.MPAlgorithmException;
import com.lyndir.masterpassword.MPKeyUnavailableException;
import com.lyndir.masterpassword.model.MPIncorrectMasterPasswordException;
import java.io.File;
import java.io.IOException;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 2017-09-20
 */
public class MPJSONUnmarshaller implements MPUnmarshaller {

    @Nonnull
    @Override
    public MPFileUser readUser(@Nonnull final File file)
            throws IOException, MPMarshalException {

        try {
            return objectMapper.readValue( file, MPJSONFile.class ).readUser( file );
        }
        catch (final JsonParseException e) {
            throw new MPMarshalException( "Couldn't parse JSON.", e );
        }
        catch (final JsonMappingException e) {
            throw new MPMarshalException( "Couldn't map JSON.", e );
        }
    }

    @Override
    public void readSites(final MPFileUser user)
            throws IOException, MPMarshalException, MPIncorrectMasterPasswordException, MPKeyUnavailableException, MPAlgorithmException {

        try {
            user.ignoreChanges();
            if (user.getFile().exists())
                objectMapper.readValue( user.getFile(), MPJSONFile.class ).readSites( user );
            user.setComplete();
            user.endChanges();
        }
        catch (final JsonParseException e) {
            throw new MPMarshalException( "Couldn't parse JSON.", e );
        }
        catch (final JsonMappingException e) {
            throw new MPMarshalException( "Couldn't map JSON.", e );
        }
    }
}
