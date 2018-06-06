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

package com.lyndir.masterpassword;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.Locale;
import javax.annotation.Nullable;
import org.jetbrains.annotations.Contract;
import org.jetbrains.annotations.NonNls;


/**
 * @author lhunath, 14-12-02
 */
public enum MPKeyPurpose {
    /**
     * Generate a key for authentication.
     */
    Authentication( "authentication", "Generate a key for authentication.", "com.lyndir.masterpassword" ),

    /**
     * Generate a name for identification.
     */
    Identification( "identification", "Generate a name for identification.", "com.lyndir.masterpassword.login" ),

    /**
     * Generate a recovery token.
     */
    Recovery( "recovery", "Generate a recovery token.", "com.lyndir.masterpassword.answer" );

    static final Logger logger = Logger.get( MPResultType.class );

    private final String shortName;
    private final String description;
    private final String scope;

    MPKeyPurpose(final String shortName, final String description, @NonNls final String scope) {
        this.shortName = shortName;
        this.description = description;
        this.scope = scope;
    }

    public String getShortName() {
        return shortName;
    }

    public String getDescription() {
        return description;
    }

    public String getScope() {
        return scope;
    }

    /**
     * @param shortNamePrefix The name for the purpose to look up.  It is a case insensitive prefix of the purpose's short name.
     *
     * @return The purpose registered with the given name.
     */
    @Nullable
    @Contract("!null -> !null")
    public static MPKeyPurpose forName(@Nullable final String shortNamePrefix) {

        if (shortNamePrefix == null)
            return null;

        for (final MPKeyPurpose type : values())
            if (type.getShortName().toLowerCase( Locale.ROOT ).startsWith( shortNamePrefix.toLowerCase( Locale.ROOT ) ))
                return type;

        throw logger.bug( "No purpose for name: %s", shortNamePrefix );
    }

    @JsonCreator
    public static MPKeyPurpose forInt(final int keyPurpose) {

        return values()[keyPurpose];
    }

    @JsonValue
    public int toInt() {

        return ordinal();
    }
}
