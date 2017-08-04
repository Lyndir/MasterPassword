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
    if (0 == strcmp( "x", stdTypeName )
        || strncmp( mpw_nameForType( MPPasswordTypeGeneratedMaximum ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPPasswordTypeGeneratedMaximum;
    if (0 == strcmp( "l", stdTypeName )
        || strncmp( mpw_nameForType( MPPasswordTypeGeneratedLong ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPPasswordTypeGeneratedLong;
    if (0 == strcmp( "m", stdTypeName )
        || strncmp( mpw_nameForType( MPPasswordTypeGeneratedMedium ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPPasswordTypeGeneratedMedium;
    if (0 == strcmp( "b", stdTypeName )
        || strncmp( mpw_nameForType( MPPasswordTypeGeneratedBasic ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPPasswordTypeGeneratedBasic;
    if (0 == strcmp( "s", stdTypeName )
        || strncmp( mpw_nameForType( MPPasswordTypeGeneratedShort ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPPasswordTypeGeneratedShort;
    if (0 == strcmp( "i", stdTypeName )
        || strncmp( mpw_nameForType( MPPasswordTypeGeneratedPIN ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPPasswordTypeGeneratedPIN;
    if (0 == strcmp( "n", stdTypeName )
        || strncmp( mpw_nameForType( MPPasswordTypeGeneratedName ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPPasswordTypeGeneratedName;
    if (0 == strcmp( "p", stdTypeName )
        || strncmp( mpw_nameForType( MPPasswordTypeGeneratedPhrase ), stdTypeName, strlen( stdTypeName ) ) == 0)
        return MPPasswordTypeGeneratedPhrase;

    dbg( "Not a generated type name: %s\n", stdTypeName );
    return (MPPasswordType)ERR;
}

const char *mpw_nameForType(MPPasswordType passwordType) {

    switch (passwordType) {
        case MPPasswordTypeGeneratedMaximum:
            return "maximum";
        case MPPasswordTypeGeneratedLong:
            return "long";
        case MPPasswordTypeGeneratedMedium:
            return "medium";
        case MPPasswordTypeGeneratedBasic:
            return "basic";
        case MPPasswordTypeGeneratedShort:
            return "short";
        case MPPasswordTypeGeneratedPIN:
            return "pin";
        case MPPasswordTypeGeneratedName:
            return "name";
        case MPPasswordTypeGeneratedPhrase:
            return "phrase";
        case MPPasswordTypeStoredPersonal:
            return "personal";
        case MPPasswordTypeStoredDevice:
            return "device";
        default: {
            dbg( "Unknown password type: %d\n", passwordType );
            return NULL;
        }
    }
}

const char **mpw_templatesForType(MPPasswordType type, size_t *count) {

    if (!(type & MPPasswordTypeClassGenerated)) {
        dbg( "Not a generated type: %d\n", type );
        return NULL;
    }

    switch (type) {
        case MPPasswordTypeGeneratedMaximum:
            return mpw_alloc_array( count, const char *,
                    "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" );
        case MPPasswordTypeGeneratedLong:
            return mpw_alloc_array( count, const char *,
                    "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno",
                    "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno",
                    "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno",
                    "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno",
                    "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno",
                    "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno",
                    "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" );
        case MPPasswordTypeGeneratedMedium:
            return mpw_alloc_array( count, const char *,
                    "CvcnoCvc", "CvcCvcno" );
        case MPPasswordTypeGeneratedBasic:
            return mpw_alloc_array( count, const char *,
                    "aaanaaan", "aannaaan", "aaannaaa" );
        case MPPasswordTypeGeneratedShort:
            return mpw_alloc_array( count, const char *,
                    "Cvcn" );
        case MPPasswordTypeGeneratedPIN:
            return mpw_alloc_array( count, const char *,
                    "nnnn" );
        case MPPasswordTypeGeneratedName:
            return mpw_alloc_array( count, const char *,
                    "cvccvcvcv" );
        case MPPasswordTypeGeneratedPhrase:
            return mpw_alloc_array( count, const char *,
                    "cvcc cvc cvccvcv cvc", "cvc cvccvcvcv cvcv", "cv cvccv cvc cvcvccv" );
        default: {
            dbg( "Unknown generated type: %d\n", type );
            return NULL;
        }
    }
}

const char *mpw_templateForType(MPPasswordType type, uint8_t seedByte) {

    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    char const *template = templates && count? templates[seedByte % count]: NULL;
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

    if (strncmp( mpw_nameForPurpose( MPKeyPurposeAuthentication ), stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeAuthentication;
    if (strncmp( mpw_nameForPurpose( MPKeyPurposeIdentification ), stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeIdentification;
    if (strncmp( mpw_nameForPurpose( MPKeyPurposeRecovery ), stdPurposeName, strlen( stdPurposeName ) ) == 0)
        return MPKeyPurposeRecovery;

    dbg( "Not a purpose name: %s\n", stdPurposeName );
    return (MPKeyPurpose)ERR;
}

const char *mpw_nameForPurpose(MPKeyPurpose purpose) {

    switch (purpose) {
        case MPKeyPurposeAuthentication:
            return "authentication";
        case MPKeyPurposeIdentification:
            return "identification";
        case MPKeyPurposeRecovery:
            return "recovery";
        default: {
            dbg( "Unknown purpose: %d\n", purpose );
            return NULL;
        }
    }
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
            dbg( "Unknown purpose: %d\n", purpose );
            return NULL;
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
            dbg( "Unknown character class: %c\n", characterClass );
            return NULL;
        }
    }
}

const char mpw_characterFromClass(char characterClass, uint8_t seedByte) {

    const char *classCharacters = mpw_charactersInClass( characterClass );
    if (!classCharacters)
        return '\0';

    return classCharacters[seedByte % strlen( classCharacters )];
}
