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

import com.lyndir.lhunath.opal.system.logging.Logger;
import org.jetbrains.annotations.NonNls;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
@SuppressWarnings({ "HardcodedFileSeparator", "SpellCheckingInspection" })
public enum MPTemplateCharacterClass {

    UpperVowel( 'V', "AEIOU" ),
    UpperConsonant( 'C', "BCDFGHJKLMNPQRSTVWXYZ" ),
    LowerVowel( 'v', "aeiou" ),
    LowerConsonant( 'c', "bcdfghjklmnpqrstvwxyz" ),
    UpperAlphanumeric( 'A', "AEIOUBCDFGHJKLMNPQRSTVWXYZ" ),
    Alphanumeric( 'a', "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz" ),
    Numeric( 'n', "0123456789" ),
    Other( 'o', "@&%?,=[]_:-+*$#!'^~;()/." ),
    Any( 'x', "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz0123456789!@#$%^&*()" ),
    Space( ' ', " " );

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPTemplateCharacterClass.class );

    private final char   identifier;
    private final char[] characters;

    MPTemplateCharacterClass(final char identifier, @NonNls final String characters) {

        this.identifier = identifier;
        this.characters = characters.toCharArray();
    }

    public char getIdentifier() {

        return identifier;
    }

    public char getCharacterAtRollingIndex(final int index) {

        return characters[index % characters.length];
    }

    public static MPTemplateCharacterClass forIdentifier(final char identifier) {
        for (final MPTemplateCharacterClass characterClass : values())
            if (characterClass.getIdentifier() == identifier)
                return characterClass;

        throw logger.bug( "No character class defined for identifier: %s", identifier );
    }
}
