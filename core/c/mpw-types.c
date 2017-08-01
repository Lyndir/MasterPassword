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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#ifdef COLOR
#include <curses.h>
#include <term.h>
#endif

#include "mpw-types.h"
#include "mpw-util.h"

const MPPasswordType mpw_typeWithName(const char *typeName) {

    // Lower-case and trim optionally leading "Generated" string from typeName to standardize it.
    size_t stdTypeNameOffset = 0;
    size_t stdTypeNameSize = strlen( typeName );
    if (strstr( typeName, "Generated" ) == typeName)
        stdTypeNameSize -= (stdTypeNameOffset = strlen( "Generated" ));
    char stdTypeName[stdTypeNameSize + 1];
    for (size_t c = 0; c < stdTypeNameSize; ++c)
        stdTypeName[c] = (char)tolower( typeName[c + stdTypeNameOffset] );
    stdTypeName[stdTypeNameSize] = '\0';

    // Find what password type is represented by the type name.
    if (0 == strncmp( "maximum", stdTypeName, strlen( stdTypeName ) ) || 0 == strncmp( "x", stdTypeName, 1 ))
        return MPPasswordTypeGeneratedMaximum;
    if (0 == strncmp( "long", stdTypeName, strlen( stdTypeName ) ) || 0 == strncmp( "l", stdTypeName, 1 ))
        return MPPasswordTypeGeneratedLong;
    if (0 == strncmp( "medium", stdTypeName, strlen( stdTypeName ) ) || 0 == strncmp( "m", stdTypeName, 1 ))
        return MPPasswordTypeGeneratedMedium;
    if (0 == strncmp( "basic", stdTypeName, strlen( stdTypeName ) ) || 0 == strncmp( "b", stdTypeName, 1 ))
        return MPPasswordTypeGeneratedBasic;
    if (0 == strncmp( "short", stdTypeName, strlen( stdTypeName ) ) || 0 == strncmp( "s", stdTypeName, 1 ))
        return MPPasswordTypeGeneratedShort;
    if (0 == strncmp( "pin", stdTypeName, strlen( stdTypeName ) ) || 0 == strncmp( "i", stdTypeName, 1 ))
        return MPPasswordTypeGeneratedPIN;
    if (0 == strncmp( "name", stdTypeName, strlen( stdTypeName ) ) || 0 == strncmp( "n", stdTypeName, 1 ))
        return MPPasswordTypeGeneratedName;
    if (0 == strncmp( "phrase", stdTypeName, strlen( stdTypeName ) ) || 0 == strncmp( "p", stdTypeName, 1 ))
        return MPPasswordTypeGeneratedPhrase;

    ftl( "Not a generated type name: %s", stdTypeName );
    return MPPasswordTypeDefault;
}

const char **mpw_templatesForType(MPPasswordType type, size_t *count) {

    if (!(type & MPPasswordTypeClassGenerated)) {
        ftl( "Not a generated type: %d", type );
        *count = 0;
        return NULL;
    }

    switch (type) {
        case MPPasswordTypeGeneratedMaximum:
            return mpw_alloc_array( *count, const char *,
                    "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" );
        case MPPasswordTypeGeneratedLong:
            return mpw_alloc_array( *count, const char *,
                    "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno",
                    "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno",
                    "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno",
                    "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno",
                    "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno",
                    "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno",
                    "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" );
        case MPPasswordTypeGeneratedMedium:
            return mpw_alloc_array( *count, const char *,
                    "CvcnoCvc", "CvcCvcno" );
        case MPPasswordTypeGeneratedBasic:
            return mpw_alloc_array( *count, const char *,
                    "aaanaaan", "aannaaan", "aaannaaa" );
        case MPPasswordTypeGeneratedShort:
            return mpw_alloc_array( *count, const char *,
                    "Cvcn" );
        case MPPasswordTypeGeneratedPIN:
            return mpw_alloc_array( *count, const char *,
                    "nnnn" );
        case MPPasswordTypeGeneratedName:
            return mpw_alloc_array( *count, const char *,
                    "cvccvcvcv" );
        case MPPasswordTypeGeneratedPhrase:
            return mpw_alloc_array( *count, const char *,
                    "cvcc cvc cvccvcv cvc", "cvc cvccvcvcv cvcv", "cv cvccv cvc cvcvccv" );
        default: {
            ftl( "Unknown generated type: %d", type );
            *count = 0;
            return NULL;
        }
    }
}

const char *mpw_templateForType(MPPasswordType type, uint8_t seedByte) {

    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    char const *template = count? templates[seedByte % count]: NULL;
    free( templates );
    return template;
}

const MPKeyPurpose mpw_purposeWithName(const char *purposeName) {

    // Lower-case and trim optionally leading "generated" string from typeName to standardize it.
    size_t stdPurposeNameSize = strlen( purposeName );
    char stdPurposeName[stdPurposeNameSize + 1];
    for (size_t c = 0; c < stdPurposeNameSize; ++c)
        stdPurposeName[c] = (char)tolower( purposeName[c] );
    stdPurposeName[stdPurposeNameSize] = '\0';

    if (strncmp( "authentication", stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeAuthentication;
    if (strncmp( "identification", stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeIdentification;
    if (strncmp( "recovery", stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeRecovery;

    ftl( "Not a purpose name: %s", stdPurposeName );
}

const char *mpw_scopeForPurpose(MPKeyPurpose purpose) {

    switch (purpose) {
        case MPKeyPurposeAuthentication:
            return "com.lyndir.masterpassword";
        case MPKeyPurposeIdentification:
            return "com.lyndir.masterpassword.login";
        case MPKeyPurposeRecovery:
            return "com.lyndir.masterpassword.answer";
        default: {
            ftl( "Unknown purpose: %d", purpose );
            return "";
        }
    }
}

const char *mpw_charactersInClass(char characterClass) {

    switch (characterClass) {
        case 'V':
            return "AEIOU";
        case 'C':
            return "BCDFGHJKLMNPQRSTVWXYZ";
        case 'v':
            return "aeiou";
        case 'c':
            return "bcdfghjklmnpqrstvwxyz";
        case 'A':
            return "AEIOUBCDFGHJKLMNPQRSTVWXYZ";
        case 'a':
            return "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz";
        case 'n':
            return "0123456789";
        case 'o':
            return "@&%?,=[]_:-+*$#!'^~;()/.";
        case 'x':
            return "AEIOUaeiouBCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz0123456789!@#$%^&*()";
        case ' ':
            return " ";
        default: {
            ftl( "Unknown character class: %c", characterClass );
            return "";
        }
    }
}

const char mpw_characterFromClass(char characterClass, uint8_t seedByte) {

    const char *classCharacters = mpw_charactersInClass( characterClass );
    return classCharacters[seedByte % strlen( classCharacters )];
}
