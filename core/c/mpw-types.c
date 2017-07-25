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

const MPSiteType mpw_typeWithName(const char *typeName) {

    // Lower-case and trim optionally leading "Generated" string from typeName to standardize it.
    size_t stdTypeNameOffset = 0;
    size_t stdTypeNameSize = strlen( typeName );
    if (strstr(typeName, "Generated" ) == typeName)
        stdTypeNameSize -= (stdTypeNameOffset = strlen( "Generated" ));
    char stdTypeName[stdTypeNameSize + 1];
    for (size_t c = 0; c < stdTypeNameSize; ++c)
        stdTypeName[c] = (char)tolower( typeName[c + stdTypeNameOffset] );
    stdTypeName[stdTypeNameSize] = '\0';

    // Find what site type is represented by the type name.
    if (0 == strcmp( stdTypeName, "x" ) || 0 == strcmp( stdTypeName, "max" ) || 0 == strcmp( stdTypeName, "maximum" ))
        return MPSiteTypeGeneratedMaximum;
    if (0 == strcmp( stdTypeName, "l" ) || 0 == strcmp( stdTypeName, "long" ))
        return MPSiteTypeGeneratedLong;
    if (0 == strcmp( stdTypeName, "m" ) || 0 == strcmp( stdTypeName, "med" ) || 0 == strcmp( stdTypeName, "medium" ))
        return MPSiteTypeGeneratedMedium;
    if (0 == strcmp( stdTypeName, "b" ) || 0 == strcmp( stdTypeName, "basic" ))
        return MPSiteTypeGeneratedBasic;
    if (0 == strcmp( stdTypeName, "s" ) || 0 == strcmp( stdTypeName, "short" ))
        return MPSiteTypeGeneratedShort;
    if (0 == strcmp( stdTypeName, "i" ) || 0 == strcmp( stdTypeName, "pin" ))
        return MPSiteTypeGeneratedPIN;
    if (0 == strcmp( stdTypeName, "n" ) || 0 == strcmp( stdTypeName, "name" ))
        return MPSiteTypeGeneratedName;
    if (0 == strcmp( stdTypeName, "p" ) || 0 == strcmp( stdTypeName, "phrase" ))
        return MPSiteTypeGeneratedPhrase;

    ftl( "Not a generated type name: %s", stdTypeName );
    return MPSiteTypeDefault;
}

const char **mpw_templatesForType(MPSiteType type, size_t *count) {

    if (!(type & MPSiteTypeClassGenerated)) {
        ftl( "Not a generated type: %d", type );
        *count = 0;
        return NULL;
    }

    switch (type) {
        case MPSiteTypeGeneratedMaximum: {
            return mpw_alloc_array( *count, const char *,
                    "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" );
        }
        case MPSiteTypeGeneratedLong: {
            return mpw_alloc_array( *count, const char *,
                    "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno",
                    "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno",
                    "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno",
                    "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno",
                    "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno",
                    "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno",
                    "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" );
        }
        case MPSiteTypeGeneratedMedium: {
            return mpw_alloc_array( *count, const char *,
                    "CvcnoCvc", "CvcCvcno" );
        }
        case MPSiteTypeGeneratedBasic: {
            return mpw_alloc_array( *count, const char *,
                    "aaanaaan", "aannaaan", "aaannaaa" );
        }
        case MPSiteTypeGeneratedShort: {
            return mpw_alloc_array( *count, const char *,
                    "Cvcn" );
        }
        case MPSiteTypeGeneratedPIN: {
            return mpw_alloc_array( *count, const char *,
                    "nnnn" );
        }
        case MPSiteTypeGeneratedName: {
            return mpw_alloc_array( *count, const char *,
                    "cvccvcvcv" );
        }
        case MPSiteTypeGeneratedPhrase: {
            return mpw_alloc_array( *count, const char *,
                    "cvcc cvc cvccvcv cvc", "cvc cvccvcvcv cvcv", "cv cvccv cvc cvcvccv" );
        }
        default: {
            ftl( "Unknown generated type: %d", type );
            *count = 0;
            return NULL;
        }
    }
}

const char *mpw_templateForType(MPSiteType type, uint8_t seedByte) {

    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    char const *template = count? templates[seedByte % count]: NULL;
    free( templates );
    return template;
}

const MPSiteVariant mpw_variantWithName(const char *variantName) {

    // Lower-case and trim optionally leading "generated" string from typeName to standardize it.
    size_t stdVariantNameSize = strlen( variantName );
    char stdVariantName[stdVariantNameSize + 1];
    for (size_t c = 0; c < stdVariantNameSize; ++c)
        stdVariantName[c] = (char)tolower( variantName[c] );
    stdVariantName[stdVariantNameSize] = '\0';

    if (0 == strcmp( stdVariantName, "p" ) || 0 == strcmp( stdVariantName, "password" ))
        return MPSiteVariantPassword;
    if (0 == strcmp( stdVariantName, "l" ) || 0 == strcmp( stdVariantName, "login" ))
        return MPSiteVariantLogin;
    if (0 == strcmp( stdVariantName, "a" ) || 0 == strcmp( stdVariantName, "answer" ))
        return MPSiteVariantAnswer;

    ftl( "Not a variant name: %s", stdVariantName );
}

const char *mpw_scopeForVariant(MPSiteVariant variant) {

    switch (variant) {
        case MPSiteVariantPassword: {
            return "com.lyndir.masterpassword";
        }
        case MPSiteVariantLogin: {
            return "com.lyndir.masterpassword.login";
        }
        case MPSiteVariantAnswer: {
            return "com.lyndir.masterpassword.answer";
        }
        default: {
            ftl( "Unknown variant: %d", variant );
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
        }
    }
}

const char mpw_characterFromClass(char characterClass, uint8_t seedByte) {

    const char *classCharacters = mpw_charactersInClass( characterClass );
    return classCharacters[seedByte % strlen( classCharacters )];
}
