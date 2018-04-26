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

import com.lyndir.masterpassword.MPInvalidatedException;
import com.lyndir.masterpassword.MPMasterKey;
import javax.annotation.Nonnull;


/**
 * @author lhunath, 14-12-07
 */
public interface MPMarshaller {

    @Nonnull
    String marshall(MPFileUser user, MPMasterKey masterKey, ContentMode contentMode)
            throws MPInvalidatedException, MPMarshalException;

    enum ContentMode {
        PROTECTED( "Export of site names and stored passwords (unless device-private) encrypted with the master key." ),
        VISIBLE( "Export of site names and passwords in clear-text." );

        private final String description;
        private boolean redacted;

        ContentMode(final String description) {
            this.description = description;
        }

        public String description() {
            return description;
        }

        public boolean isRedacted() {
            return redacted;
        }
    }
}
