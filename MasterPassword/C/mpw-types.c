//
//  mpw-types.c
//  MasterPassword
//
//  Created by Maarten Billemont on 2012-02-01.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

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
    return MPSiteTypeGeneratedLong;
}

const char **mpw_templatesForType(MPSiteType type, size_t *count) {

    if (!(type & MPSiteTypeClassGenerated)) {
        ftl( "Not a generated type: %d", type );
        *count = 0;
        return NULL;
    }

    switch (type) {
        case MPSiteTypeGeneratedMaximum: {
            return alloc_array( *count, const char *,
                    "anoxxxxxxxxxxxxxxxxx", "axxxxxxxxxxxxxxxxxno" );
        }
        case MPSiteTypeGeneratedLong: {
            return alloc_array( *count, const char *,
                    "CvcvnoCvcvCvcv", "CvcvCvcvnoCvcv", "CvcvCvcvCvcvno",
                    "CvccnoCvcvCvcv", "CvccCvcvnoCvcv", "CvccCvcvCvcvno",
                    "CvcvnoCvccCvcv", "CvcvCvccnoCvcv", "CvcvCvccCvcvno",
                    "CvcvnoCvcvCvcc", "CvcvCvcvnoCvcc", "CvcvCvcvCvccno",
                    "CvccnoCvccCvcv", "CvccCvccnoCvcv", "CvccCvccCvcvno",
                    "CvcvnoCvccCvcc", "CvcvCvccnoCvcc", "CvcvCvccCvccno",
                    "CvccnoCvcvCvcc", "CvccCvcvnoCvcc", "CvccCvcvCvccno" );
        }
        case MPSiteTypeGeneratedMedium: {
            return alloc_array( *count, const char *,
                    "CvcnoCvc", "CvcCvcno" );
        }
        case MPSiteTypeGeneratedBasic: {
            return alloc_array( *count, const char *,
                    "aaanaaan", "aannaaan", "aaannaaa" );
        }
        case MPSiteTypeGeneratedShort: {
            return alloc_array( *count, const char *,
                    "Cvcn" );
        }
        case MPSiteTypeGeneratedPIN: {
            return alloc_array( *count, const char *,
                    "nnnn" );
        }
        case MPSiteTypeGeneratedName: {
            return alloc_array( *count, const char *,
                    "cvccvcvcv" );
        }
        case MPSiteTypeGeneratedPhrase: {
            return alloc_array( *count, const char *,
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
    if (!count)
        return NULL;

    char const *template = templates[seedByte % count];
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

    fprintf( stderr, "Not a variant name: %s", stdVariantName );
    abort();
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
            fprintf( stderr, "Unknown variant: %d", variant );
            abort();
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
            fprintf( stderr, "Unknown character class: %c", characterClass );
            abort();
        }
    }
}

const char mpw_characterFromClass(char characterClass, uint8_t seedByte) {

    const char *classCharacters = mpw_charactersInClass( characterClass );
    return classCharacters[seedByte % strlen( classCharacters )];
}
